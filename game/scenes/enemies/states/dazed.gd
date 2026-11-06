extends EnemyState
## Aturdido por el humo: tose, se tapa y se tambalea. Ni ataca ni bloquea: ventana para golpear.

const DURATION: float = 2.6
## Cada cuánto tose (pequeña sacudida).
const COUGH_EVERY: float = 0.7

var _elapsed: float
var _next_cough: float
var _duration: float = DURATION


## msg "seconds": cuánto dura (la fruta de Frank aturde menos que el humo).
func enter(msg: Dictionary) -> void:
	_duration = msg.get("seconds", DURATION)
	_elapsed = 0.0
	_next_cough = 0.15
	enemy.hitbox.deactivate()
	enemy.body.set_trail(false)
	enemy.body.set_blocking(false)
	# Reacción lenta y encorvada (provisional hasta tener una animación de tos).
	enemy.body.play_action(&"hit", 0.05, 0.45, 0.15)


func exit() -> void:
	enemy.body.stop_action(0.3)


func physics_update(delta: float) -> void:
	_elapsed += delta
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta, 10.0)
	if _elapsed >= _next_cough:
		_next_cough += COUGH_EVERY
		enemy.body.flinch(enemy.get_facing(), 0.45)
	if _elapsed >= _duration:
		machine.transition_to(&"Idle", {"wait": randf_range(0.2, 0.5)})
