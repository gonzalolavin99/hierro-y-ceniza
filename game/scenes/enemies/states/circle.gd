class_name EnemyCircle
extends EnemyState
## Pelea en grupo: mientras otro compañero tiene el turno de ataque (Squad), espera a distancia con la
## guardia alta, rodeando al jugador. Se separa de sus compañeros para no quedar en fila y tiende a
## abrirse hacia los costados y la espalda del jugador (le obliga a mover la cámara y la posición).

## Distancia a la que espera (fuera del alcance de su espada y de la del jugador).
const RADIUS: float = 3.6
const STRAFE_SPEED: float = 1.5
## Separación angular mínima entre compañeros, vista desde el jugador (75°).
const MIN_SPREAD: float = deg_to_rad(75.0)
## Cuánto tiende a rodear hacia la espalda del jugador (0 = nada, 1 = a toda velocidad).
const FLANK_BIAS: float = 0.35
## Distancia mínima a un compañero (para no chocar).
const PERSONAL_SPACE: float = 1.4

var _sway: float
var _sway_timer: float


func enter(_msg: Dictionary) -> void:
	enemy.body.set_blocking(true)
	enemy.body.stop_action(0.2)
	_sway = 1.0 if randf() < 0.5 else -1.0
	_sway_timer = randf_range(1.5, 3.0)


func physics_update(delta: float) -> void:
	if not enemy.has_target():
		machine.transition_to(&"Idle")
		return
	if Squad.request_turn(enemy):
		machine.transition_to(&"Chase")
		return
	enemy.face_target(delta)

	var to_me: Vector3 = enemy.global_position - enemy.target.global_position
	to_me.y = 0.0
	var dist: float = to_me.length()
	if dist < 0.01:
		return
	var radial: Vector3 = to_me / dist
	var angle: float = atan2(to_me.x, to_me.z)
	# Dirección de "rodear" (ángulo creciente alrededor del jugador).
	var tangent := Vector3(radial.z, 0.0, -radial.x)

	var spread_push: float = 0.0
	var separation := Vector3.ZERO
	for node in enemy.get_tree().get_nodes_in_group("enemies"):
		var other := node as Enemy
		if other == null or other == enemy or other.is_dead() or not other.has_target():
			continue
		var other_to: Vector3 = other.global_position - enemy.target.global_position
		var diff: float = angle_difference(angle, atan2(other_to.x, other_to.z))
		if absf(diff) < MIN_SPREAD:
			spread_push -= signf(diff) * (MIN_SPREAD - absf(diff)) / MIN_SPREAD
		var away: Vector3 = enemy.global_position - other.global_position
		away.y = 0.0
		if away.length() < PERSONAL_SPACE and away.length() > 0.01:
			separation += away.normalized() * (PERSONAL_SPACE - away.length()) / PERSONAL_SPACE

	# Hacia la espalda del jugador, sin pasarse: se para al quedar a ~120° de su frente.
	var back: Vector3 = -enemy.target.get_facing()
	var to_back: float = angle_difference(angle, atan2(back.x, back.z))
	var flank: float = signf(to_back) * FLANK_BIAS if absf(to_back) > deg_to_rad(60.0) else 0.0

	_sway_timer -= delta
	if _sway_timer <= 0.0:
		_sway = -_sway
		_sway_timer = randf_range(1.5, 3.0)
	var sway: float = _sway * 0.3 if absf(spread_push) < 0.05 and flank == 0.0 else 0.0

	var side: float = clampf(spread_push * 2.5 + flank + sway, -1.0, 1.0)
	var inward: float = clampf((dist - RADIUS) * 1.5, -1.0, 1.0)
	var move: Vector3 = tangent * side * STRAFE_SPEED - radial * inward * enemy.walk_speed * 0.6 + separation * 2.0
	var speed: float = minf(move.length(), enemy.walk_speed)
	enemy.move_horizontal(move.normalized() if speed > 0.05 else Vector3.ZERO, speed, delta, 8.0)
