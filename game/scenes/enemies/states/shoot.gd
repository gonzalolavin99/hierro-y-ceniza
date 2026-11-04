extends EnemyState
## Arquero: saca una flecha y tensa el arco, apunta un instante (destello de aviso en el arco) y suelta.
## Apunta a donde estás al soltar, no adonde vas: moverse de lado o el paso rápido la esquivan, y la
## guardia la bloquea (o la desvía, pulsada justo a tiempo).

enum Phase { DRAW, AIM, RECOVER }

## Sacar la flecha y tensar (la animación dura 1,03 s; se ajusta a este tiempo).
const DRAW_TIME: float = 0.95
## Apuntando con el arco tenso: el destello avisa de que va a soltar.
const AIM_TIME: float = 0.6
const RECOVER_TIME: float = 0.55

var _phase: Phase
var _timer: float


func enter(_msg: Dictionary) -> void:
	enemy.body.set_blocking(false)
	enemy.body.play_timed(&"bow_draw", 0.0, 1.0, DRAW_TIME, 0.15)
	_set_phase(Phase.DRAW)


func physics_update(delta: float) -> void:
	_timer += delta
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta, 10.0)
	enemy.face_target(delta, 1.2)
	match _phase:
		Phase.DRAW:
			if not enemy.has_target():
				machine.transition_to(&"Idle")
			elif _timer >= DRAW_TIME:
				enemy.body.play_action(&"bow_aim", 0.4, 1.0, 0.12)
				enemy.body.glint()
				Sfx.play(&"glint", enemy.lock_point())
				_set_phase(Phase.AIM)
		Phase.AIM:
			if _timer >= AIM_TIME:
				_release()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			if _timer >= RECOVER_TIME:
				machine.transition_to(&"Idle", {"wait": randf_range(enemy.idle_wait.x, enemy.idle_wait.y)})


func _release() -> void:
	enemy.body.play_action(&"bow_shoot", 0.0, 1.0, 0.06)
	Sfx.play(&"crossbow", enemy.lock_point(), -3.0)
	var from: Vector3 = enemy.global_position + Vector3.UP * 1.45 + enemy.get_facing() * 0.6
	var chest: Vector3 = enemy.target.global_position + Vector3.UP * 1.2
	Arrow.spawn(enemy.get_parent(), from, chest, enemy)


func _set_phase(phase: Phase) -> void:
	_phase = phase
	_timer = 0.0
