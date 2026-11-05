extends EnemyState
## Se acerca al jugador con la guardia alta.


func enter(_msg: Dictionary) -> void:
	enemy.body.set_blocking(true)
	enemy.body.stop_action(0.2)
	# La primera vez que te ve en esta vida, te habla.
	if not enemy.has_spoken_to_target:
		enemy.has_spoken_to_target = true
		Voice.say(enemy.voice, &"spot", enemy.lock_point())


func physics_update(delta: float) -> void:
	if not enemy.has_target():
		machine.transition_to(&"Idle")
		return
	enemy.face_target(delta)
	# Otro compañero está atacando: no se mete, espera rodeando.
	if Squad.is_busy_for(enemy) and enemy.distance_to_target() <= EnemyCircle.RADIUS:
		machine.transition_to(&"Circle")
		return
	# Ágiles (jefes): a media distancia, a veces atacan desde lejos (cuchillos, salto) en vez de acercarse.
	if enemy.wants_ranged_attack() and randf() < delta * 1.2 and Squad.request_turn(enemy):
		enemy.last_ranged = Squad.clock()
		machine.transition_to(&"Attack", {"pattern": enemy.ranged_patterns.pick_random()})
		return
	enemy.move_horizontal(enemy.direction_to_target(), enemy.walk_speed, delta)
	if enemy.distance_to_target() <= enemy.attack_range * (0.8 if enemy.ranged else 0.9):
		machine.transition_to(&"Idle", {"wait": randf_range(0.2, 0.6)})
