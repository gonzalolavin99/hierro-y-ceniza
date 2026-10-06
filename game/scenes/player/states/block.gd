extends PlayerState
## Guardia (mantener LB). Pulsar LB justo antes del golpe = DESVÍO (lo resuelve Player.receive_hit).
## Con la guardia alta la postura se recupera más rápido.


func enter(_msg: Dictionary) -> void:
	player.weapon.go(&"block", 0.06)
	player.posture.regen_multiplier = player.block_posture_regen


func exit() -> void:
	player.posture.regen_multiplier = 1.0


func physics_update(delta: float) -> void:
	var direction: Vector3 = player.get_move_direction()
	player.move_horizontal(direction, player.block_move_speed * minf(direction.length(), 1.0), player.ground_acceleration, delta)
	if player.lock_target:
		player.face_direction(player.direction_to_lock_target(), delta)
	else:
		player.face_direction(direction, delta * 0.5)
	player.apply_gravity(delta)

	if player.wants_attack():
		if not player.try_deathblow():
			machine.transition_to(&"Attack")
	elif player.wants_jump():
		player.do_jump()
		machine.transition_to(&"Air")
	elif Input.is_action_just_pressed("dodge"):
		machine.transition_to(&"Dash")
	elif not Input.is_action_pressed("block"):
		machine.transition_to(&"Ground")
