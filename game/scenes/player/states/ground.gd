extends PlayerState
## En el suelo: quieto o corriendo con el stick. Con objetivo fijado, camina de lado mirándolo.


func enter(_msg: Dictionary) -> void:
	player.body.set_blocking(false)
	player.body.stop_action(0.18)


func physics_update(delta: float) -> void:
	var direction: Vector3 = player.get_move_direction()
	var speed: float = player.lock_on_speed_for(direction) if player.lock_target else player.run_speed
	if player.crouching:
		speed = player.crouch_speed
	player.move_horizontal(direction, speed * minf(direction.length(), 1.0), player.ground_acceleration, delta)
	if player.lock_target:
		player.face_direction(player.direction_to_lock_target(), delta)
	else:
		player.face_direction(direction, delta)
	player.apply_gravity(delta)

	if player.wants_jump():
		player.do_jump()
		machine.transition_to(&"Air")
	elif player.wants_attack():
		if not player.try_deathblow():
			machine.transition_to(&"Attack", {"move": &"light_1"})
	elif Input.is_action_just_pressed("heavy_attack"):
		machine.transition_to(&"Attack", {"move": &"heavy"})
	elif player.wants_rest():
		machine.transition_to(&"Rest", {"fire": player.wants_rest()})
	elif Input.is_action_just_pressed("kick"):
		machine.transition_to(&"Attack", {"move": &"kick"})
	elif player.wants_block():
		machine.transition_to(&"Block")
	elif player.wants_tool():
		machine.transition_to(&"Tool")
	elif player.wants_heal():
		machine.transition_to(&"Heal")
	elif Input.is_action_just_pressed("dodge") and player.dash_cooldown_timer <= 0.0:
		machine.transition_to(&"Dash")
	elif not player.is_on_floor() and player.coyote_timer <= 0.0:
		machine.transition_to(&"Air")
