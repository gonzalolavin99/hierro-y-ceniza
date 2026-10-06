extends EnemyState
## Le desviaron el último tajo: retrocede desequilibrado. Momento ideal para contraatacar.

const DURATION: float = 0.7

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	enemy.velocity -= enemy.get_facing() * 3.0
	enemy.body.set_blocking(false)
	enemy.body.play_action(&"hit", 0.0, 1.3, 0.05)


func physics_update(delta: float) -> void:
	_elapsed += delta
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta, 10.0)
	if _elapsed >= DURATION:
		machine.transition_to(&"Idle", {"wait": randf_range(0.3, 0.8)})
