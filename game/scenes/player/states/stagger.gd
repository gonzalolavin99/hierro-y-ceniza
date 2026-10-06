extends PlayerState
## Postura rota: el personaje queda aturdido y no puede actuar durante un momento.

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	player.body.set_blocking(false)
	player.body.play_action(&"hit", 0.0, 0.9, 0.05)


func exit() -> void:
	player.posture.reset()


func physics_update(delta: float) -> void:
	_elapsed += delta
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_acceleration, delta)
	player.apply_gravity(delta)

	if _elapsed >= player.stagger_duration:
		machine.transition_to(&"Ground" if player.is_on_floor() else &"Air")
