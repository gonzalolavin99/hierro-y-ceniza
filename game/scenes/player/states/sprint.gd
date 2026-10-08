extends PlayerState
## Correr: se entra manteniendo el botón de paso rápido después del paso.


func physics_update(delta: float) -> void:
	var direction: Vector3 = player.get_move_direction()
	player.move_horizontal(direction.normalized(), player.sprint_speed, player.ground_acceleration, delta)
	player.face_direction(direction, delta)
	player.apply_gravity(delta)

	if player.wants_attack():
		if not player.try_deathblow():
			machine.transition_to(&"Attack", {"move": &"run_attack"})
	elif player.wants_jump():
		player.do_jump()
		machine.transition_to(&"Air")
	elif not Input.is_action_pressed("dodge") or direction.length_squared() < 0.01:
		machine.transition_to(&"Ground")
	elif not player.is_on_floor() and player.coyote_timer <= 0.0:
		machine.transition_to(&"Air")
