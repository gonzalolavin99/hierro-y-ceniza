extends EnemyState
## Avisa antes de atacar (Paso 4; docs/12 §3B, docs/15 §D). Un soldado de la aldea (Enemy.warns_first) ve a Kael
## cerca: se pone en guardia, lo mira y le dice «¡Atrás! No te acerques a las casas.». No ataca. Pelea
## (Enemy.alert, que también avisa a los compañeros) si Kael se acerca a menos de WARN_CLOSE o si sigue cerca
## WARN_TIME segundos después del aviso. Si Kael lo golpea, receive_hit ya llama a alert. Si Kael se aleja más de
## WARN_LEAVE (o muere), vuelve tranquilo a su puesto (Patrol).

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	enemy.body.set_blocking(true)
	enemy.body.stop_action(0.2)
	_try_warn()


func physics_update(delta: float) -> void:
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta)
	if enemy.alerted:
		machine.transition_to(&"Chase")
		return
	if enemy.target == null or enemy.target.is_dead() or enemy.distance_to_target() > Enemy.WARN_LEAVE:
		machine.transition_to(&"Patrol")
		return
	enemy.face_target(delta)
	var distance: float = enemy.distance_to_target()
	if distance <= Enemy.WARN_CLOSE:
		enemy.alert()
		return
	# La frase puede no salir todavía (habla el narrador o un compañero ya está avisando). Se reintenta, y la
	# cuenta de WARN_TIME no empieza hasta haber avisado en esta vida.
	if not enemy.has_warned:
		_try_warn()
		return
	if distance <= Enemy.WARN_RANGE:
		_elapsed += delta
		if _elapsed >= Enemy.WARN_TIME:
			enemy.alert()


func _try_warn() -> void:
	if not enemy.has_warned and Voice.say(enemy.voice, &"warn", enemy.lock_point()):
		enemy.has_warned = true
