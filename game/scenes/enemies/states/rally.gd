extends EnemyState
## Jefe: tras un golpe mortal que no es el último, cae de rodillas, se rehace (vida y postura llenas) y
## vuelve a la pelea en la fase siguiente. Mientras se rehace no se le puede golpear.

const DURATION: float = 2.4
## Cuándo empieza a levantarse.
const RISE_AT: float = 1.6

var _elapsed: float
var _rising: bool


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	_rising = false
	enemy.set_vulnerable(false)
	enemy.body.set_blocking(false)
	enemy.body.play_action(&"kneel", 0.0, 1.0, 0.25)


func exit() -> void:
	enemy.set_vulnerable(true)


func physics_update(delta: float) -> void:
	_elapsed += delta
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta, 10.0)
	if not _rising and _elapsed >= RISE_AT:
		_rising = true
		enemy.body.stop_action(0.6)
	if _elapsed >= DURATION:
		machine.transition_to(&"Idle", {"wait": 0.2})
