extends EnemyState
## Muerto: cae y (solo en el escenario de pruebas) reaparece después de unos segundos.

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	enemy.set_vulnerable(false)
	enemy.died.emit()


func physics_update(delta: float) -> void:
	_elapsed += delta
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta)
	enemy.model.rotation.x = lerpf(enemy.model.rotation.x, PI / 2.0, 1.0 - exp(-5.0 * delta))
	if enemy.respawn_delay > 0.0 and _elapsed >= enemy.respawn_delay:
		enemy.respawn()
		machine.transition_to(&"Idle")
