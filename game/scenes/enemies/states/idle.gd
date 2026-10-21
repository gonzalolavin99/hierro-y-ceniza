extends EnemyState
## En guardia: mira al jugador y espera un momento antes de atacar.

const PATTERNS: Array[StringName] = [&"single", &"double", &"double", &"thrust_combo", &"single", &"double"]
## Ataques peligrosos (aviso rojo): alrededor de 1 de cada 3 ataques.
const DANGER_PATTERNS: Array[StringName] = [&"sweep", &"thrust", &"slash_thrust"]
## El agarre necesita estar cerca.
const GRAB_RANGE: float = 1.9

var _wait: float


func enter(msg: Dictionary) -> void:
	_wait = msg.get("wait", randf_range(0.5, 1.3))
	enemy.body.set_blocking(true)
	enemy.body.stop_action(0.2)


func physics_update(delta: float) -> void:
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta)
	if not enemy.has_target():
		return
	enemy.face_target(delta)
	if enemy.distance_to_target() > enemy.attack_range:
		machine.transition_to(&"Chase")
		return
	_wait -= delta
	if _wait <= 0.0:
		machine.transition_to(&"Attack", {"pattern": _pick_pattern()})


func _pick_pattern() -> StringName:
	if randf() < 0.33:
		var options: Array[StringName] = DANGER_PATTERNS.duplicate()
		if enemy.distance_to_target() <= GRAB_RANGE:
			options.append(&"grab")
		return options.pick_random()
	return PATTERNS.pick_random()
