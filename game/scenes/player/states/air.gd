extends PlayerState
## En el aire: saltando o cayendo. Hay algo de control, pero limitado.


func enter(_msg: Dictionary) -> void:
	player.body.set_blocking(false)
	player.body.play_action(&"jump", 0.2, 1.0, 0.1)


func exit() -> void:
	player.body.stop_action(0.12)


func physics_update(delta: float) -> void:
	var direction: Vector3 = player.get_move_direction()
	var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	# Conserva el impulso si venías corriendo.
	var max_speed: float = maxf(player.run_speed, horizontal_speed)
	if direction.length_squared() > 0.0:
		player.move_horizontal(direction, max_speed * minf(direction.length(), 1.0), player.air_acceleration, delta)
	player.face_direction(direction, delta * 0.5)
	player.apply_gravity(delta)

	# Salto "coyote": recién salido de una cornisa todavía se puede saltar.
	if player.wants_attack() and not player.is_on_floor():
		machine.transition_to(&"Attack", {"move": &"air_attack"})
	elif player.wants_jump():
		player.do_jump()
	elif player.is_on_floor() and player.velocity.y <= 0.0:
		if Input.is_action_pressed("dodge") and direction.length_squared() > 0.04:
			machine.transition_to(&"Sprint")
		else:
			machine.transition_to(&"Ground")
