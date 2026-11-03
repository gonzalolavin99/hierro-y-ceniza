extends PlayerState
## Usar el arma secundaria equipada (LT): un gesto breve, sale el virote o la bomba y se recupera.

## Lanzamiento de la bomba de pólvora sin objetivo fijado: a esta distancia por delante.
const THROW_DISTANCE: float = 7.0
const MAX_THROW_DISTANCE: float = 12.0

var _tool: StringName
var _elapsed: float
var _released: bool


func enter(_msg: Dictionary) -> void:
	_tool = player.tools.current
	player.tools.consume()
	_elapsed = 0.0
	_released = false
	player.body.set_blocking(false)
	if player.lock_target:
		player.snap_facing(player.direction_to_lock_target())
	var data: Dictionary = PlayerTools.DATA[_tool]
	# Gestos provisionales hasta tener animaciones propias: brazo al frente (ballesta) o lanzamiento.
	if _tool == &"crossbow":
		player.body.play_timed(&"slash_d", 0.2, 0.47, data["windup"])
	else:
		player.body.play_timed(&"slash_c", 0.3, 0.83, data["windup"])
		Sfx.play(&"swing", player.global_position + Vector3.UP * 1.4, -6.0)
		Voice.say(&"kael", &"throw", player.global_position + Vector3.UP * 1.6)


func exit() -> void:
	player.body.stop_action(0.2)


func physics_update(delta: float) -> void:
	_elapsed += delta
	var data: Dictionary = PlayerTools.DATA[_tool]
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_deceleration, delta)
	if player.lock_target:
		player.face_direction(player.direction_to_lock_target(), delta)
	player.apply_gravity(delta)
	if not _released and _elapsed >= data["windup"]:
		_released = true
		_release()
	if _elapsed >= data["windup"] + data["recovery"]:
		machine.transition_to(&"Ground")


func _release() -> void:
	var level: Node = player.get_parent()
	var hand: Vector3 = player.global_position + Vector3.UP * 1.35 + player.get_facing() * 0.4
	match _tool:
		&"crossbow":
			var aim: Vector3 = player.lock_target.lock_point() if player.lock_target else hand + player.get_facing() * 10.0
			Bolt.spawn(level, hand, aim - hand, player)
			Sfx.play(&"crossbow", hand)
		&"smoke":
			# Se estrella contra el suelo justo delante: la nube envuelve a ambos.
			Bomb.throw(level, hand, player.global_position + player.get_facing() * 0.8, 0.22, Bomb.Kind.SMOKE, player)
		&"powder":
			var target: Vector3 = player.global_position + player.get_facing() * THROW_DISTANCE
			if player.lock_target:
				target = player.lock_target.global_position
			var offset: Vector3 = target - player.global_position
			if offset.length() > MAX_THROW_DISTANCE:
				target = player.global_position + offset.normalized() * MAX_THROW_DISTANCE
			var flight: float = clampf(0.25 + offset.length() * 0.05, 0.3, 0.8)
			Bomb.throw(level, hand, target, flight, Bomb.Kind.POWDER, player)
