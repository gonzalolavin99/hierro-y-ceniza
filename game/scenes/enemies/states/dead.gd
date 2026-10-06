extends EnemyState
## Muerto: cae y (solo en el escenario de pruebas) reaparece después de unos segundos.

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	enemy.set_vulnerable(false)
	enemy.died.emit()
	enemy.body.set_blocking(false)
	enemy.body.play_action(&"death", 0.0, 1.1, 0.06)


func physics_update(delta: float) -> void:
	_elapsed += delta
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta)
	if enemy.respawn_delay > 0.0 and _elapsed >= enemy.respawn_delay:
		enemy.respawn()
		machine.transition_to(&"Idle")
