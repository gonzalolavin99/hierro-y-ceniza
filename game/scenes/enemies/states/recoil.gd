extends EnemyState
## Le desviaron el último tajo: retrocede desequilibrado. Momento ideal para contraatacar.

const DURATION: float = 0.7
## Tras pisarle la estocada queda expuesto más tiempo.
const LONG_DURATION: float = 1.2

var _elapsed: float
var _duration: float


func enter(msg: Dictionary) -> void:
	_elapsed = 0.0
	_duration = LONG_DURATION if msg.get("long", false) else DURATION
	enemy.push -= enemy.get_facing() * 2.0
	enemy.body.set_blocking(false)
	enemy.body.play_action(&"hit", 0.0, 1.3, 0.05)


func physics_update(delta: float) -> void:
	_elapsed += delta
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta, 10.0)
	if _elapsed >= _duration:
		machine.transition_to(&"Idle", {"wait": randf_range(0.3, 0.8)})
