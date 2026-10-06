extends EnemyState
## Postura rota (o vida a cero): queda expuesto al golpe mortal.
## Si la vida es cero, se queda así hasta recibir el golpe mortal.

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	enemy.hitbox.deactivate()
	enemy.weapon.go(&"end_low", 0.25)
	CombatFX.shake(0.3)


func exit() -> void:
	enemy.model.rotation.x = 0.0
	enemy.model.position.y = 0.0


func physics_update(delta: float) -> void:
	_elapsed += delta
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta)
	# Encorvado hacia delante.
	enemy.model.rotation.x = lerpf(enemy.model.rotation.x, -0.45, 1.0 - exp(-10.0 * delta))
	enemy.model.position.y = lerpf(enemy.model.position.y, -0.25, 1.0 - exp(-10.0 * delta))
	if enemy.health.current > 0.0 and _elapsed >= enemy.broken_duration:
		enemy.posture.reset()
		enemy.posture.add(enemy.posture.max_posture * 0.5)  # Se recupera a medias
		machine.transition_to(&"Idle", {"wait": 0.4})
