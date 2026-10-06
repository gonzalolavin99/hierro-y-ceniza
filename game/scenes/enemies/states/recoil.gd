extends EnemyState
## Le desviaron el último tajo: retrocede desequilibrado. Momento ideal para contraatacar.

const DURATION: float = 0.7

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	enemy.velocity -= enemy.get_facing() * 3.0
	enemy.weapon.go(&"windup_right", 0.15)


func physics_update(delta: float) -> void:
	_elapsed += delta
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta, 10.0)
	enemy.model.rotation.x = 0.2 * sin(_elapsed / DURATION * PI)
	if _elapsed >= DURATION:
		enemy.model.rotation.x = 0.0
		machine.transition_to(&"Idle", {"wait": randf_range(0.3, 0.8)})
