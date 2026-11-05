extends PlayerState
## En una escena: Kael no responde a los controles; se queda quieto (o lo mueve la escena).


func enter(_msg: Dictionary) -> void:
	player.body.set_blocking(false)
	player.body.stop_action(0.2)


func physics_update(delta: float) -> void:
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_acceleration, delta)
	player.apply_gravity(delta)
