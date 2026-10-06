extends PlayerState
## En el suelo: quieto o corriendo con el stick.


func physics_update(delta: float) -> void:
	var direction: Vector3 = player.get_move_direction()
	player.move_horizontal(direction, player.run_speed * minf(direction.length(), 1.0), player.ground_acceleration, delta)
	player.face_direction(direction, delta)
	player.apply_gravity(delta)

	if player.wants_jump():
		player.do_jump()
		machine.transition_to(&"Air")
	elif Input.is_action_just_pressed("dodge") and player.dash_cooldown_timer <= 0.0:
		machine.transition_to(&"Dash")
	elif not player.is_on_floor() and player.coyote_timer <= 0.0:
		machine.transition_to(&"Air")
