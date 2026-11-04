extends EnemyState
## En guardia: mira al jugador y espera un momento antes de atacar.


var _wait: float


func enter(msg: Dictionary) -> void:
	_wait = msg.get("wait", randf_range(enemy.idle_wait.x, enemy.idle_wait.y))
	enemy.body.set_blocking(true)
	enemy.body.stop_action(0.2)


func physics_update(delta: float) -> void:
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
	_wait -= delta
	if _wait <= 0.0:
		# En grupo, ataca solo quien tiene el turno; los demás esperan rodeando.
		if not Squad.request_turn(enemy):
			machine.transition_to(&"Circle")
			return
		# La mente elige el ataque según lo que ha leído del jugador.
		machine.transition_to(&"Attack", {"pattern": enemy.mind.pick_pattern(enemy.distance_to_target())})
