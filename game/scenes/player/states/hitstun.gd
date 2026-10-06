extends PlayerState
## Golpe recibido: retroceso breve sin poder actuar.

var _elapsed: float


func enter(msg: Dictionary) -> void:
	_elapsed = 0.0
	var from: Vector3 = msg.get("from", player.get_facing())
	player.velocity = -from * 4.0
	player.snap_facing(from)
	player.weapon.go(&"idle", 0.1)


func physics_update(delta: float) -> void:
	_elapsed += delta
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_acceleration * 0.4, delta)
	player.apply_gravity(delta)
	player.model.rotation.x = -0.25 * (1.0 - _elapsed / player.hitstun_duration)
	if _elapsed >= player.hitstun_duration:
		player.model.rotation.x = 0.0
		machine.transition_to(&"Ground" if player.is_on_floor() else &"Air")
