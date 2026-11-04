extends EnemyState
## En guardia: mira al jugador y espera un momento antes de atacar.


var _wait: float


func enter(msg: Dictionary) -> void:
	_wait = msg.get("wait", randf_range(enemy.idle_wait.x, enemy.idle_wait.y))
	enemy.body.set_blocking(true)
	enemy.body.stop_action(0.2)


func physics_update(delta: float) -> void:
	# Quieto, salvo el que ataca a distancia cuando te acercas (retrocede): un solo movimiento por
	# fotograma, para que "frenar" y "retroceder" no se anulen.
	var retreating: bool = enemy.has_target() and enemy.ranged and enemy.too_close() \
		and enemy.distance_to_target() > enemy.MELEE_RANGE
	if retreating:
		enemy.move_horizontal(-enemy.direction_to_target(), enemy.walk_speed * 0.8, delta)
	else:
		enemy.move_horizontal(Vector3.ZERO, 0.0, delta)
	if not enemy.alerted:
		machine.transition_to(&"Patrol")
		return
	if not enemy.has_target():
		return
	enemy.face_target(delta)
	if enemy.distance_to_target() > enemy.attack_range:
		machine.transition_to(&"Chase")
		return
	# Armas largas o a distancia: si te pegas a él, recupera distancia.
	if enemy.too_close() and not enemy.ranged:
		if Squad.clock() - enemy.last_keep_away > enemy.KEEP_AWAY_COOLDOWN:
			enemy.last_keep_away = Squad.clock()
			machine.transition_to(&"Evade", {"back": true, "counter": &"spear_thrust", "counter_chance": 0.6})
			return
	_wait -= delta
	if _wait <= 0.0:
		# A distancia y con tiro limpio, dispara cuando le toca el turno (en grupo, nunca a la vez que
		# un tajo de otro: una amenaza cada vez).
		if enemy.ranged and enemy.distance_to_target() > enemy.MELEE_RANGE:
			if enemy.has_clear_shot() and Squad.request_turn(enemy):
				machine.transition_to(&"Shoot")
			else:
				_wait = 0.2
			return
		# En grupo, ataca solo quien tiene el turno; los demás esperan rodeando.
		if not Squad.request_turn(enemy):
			machine.transition_to(&"Circle")
			return
		# La mente elige el ataque según lo que ha leído del jugador.
		machine.transition_to(&"Attack", {"pattern": enemy.mind.pick_pattern(enemy.distance_to_target())})
