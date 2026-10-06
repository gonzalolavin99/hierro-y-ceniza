extends EnemyState
## Postura rota (o vida a cero): queda expuesto al golpe mortal.
## Si la vida es cero, se queda así hasta recibir el golpe mortal.

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	enemy.hitbox.deactivate()
	enemy.body.set_blocking(false)
	enemy.body.play_action(&"kneel_hit", 0.0, 1.0, 0.1)
	get_tree().create_timer(0.5, false).timeout.connect(_kneel)
	CombatFX.shake(0.3)
	Sfx.play(&"posture_break", enemy.lock_point())


func exit() -> void:
	enemy.body.stop_action(0.25)


## Tras el golpe, se queda de rodillas expuesto.
func _kneel() -> void:
	if machine.current == self:
		enemy.body.play_action(&"kneel", 0.0, 1.0, 0.2)


func physics_update(delta: float) -> void:
	_elapsed += delta
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta)
	if enemy.health.current > 0.0 and _elapsed >= enemy.broken_duration:
		enemy.posture.reset()
		enemy.posture.add(enemy.posture.max_posture * 0.5)  # Se recupera a medias
		machine.transition_to(&"Idle", {"wait": 0.4})
