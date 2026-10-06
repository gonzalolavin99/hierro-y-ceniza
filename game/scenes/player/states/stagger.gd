extends PlayerState
## Postura rota: el personaje queda aturdido y no puede actuar durante un momento.

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0


func exit() -> void:
	player.posture.reset()


func physics_update(delta: float) -> void:
	_elapsed += delta
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_acceleration, delta)
	player.apply_gravity(delta)
	# Tambaleo visual simple hasta tener animaciones.
	player.model.rotation.z = sin(_elapsed * 18.0) * 0.12 * (1.0 - _elapsed / player.stagger_duration)

	if _elapsed >= player.stagger_duration:
		player.model.rotation.z = 0.0
		machine.transition_to(&"Ground" if player.is_on_floor() else &"Air")
