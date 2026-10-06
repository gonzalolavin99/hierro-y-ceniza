extends EnemyState
## Se acerca al jugador con la guardia alta.


func enter(_msg: Dictionary) -> void:
	enemy.body.set_blocking(true)
	enemy.body.stop_action(0.2)


func physics_update(delta: float) -> void:
	if not enemy.has_target():
		machine.transition_to(&"Idle")
		return
	enemy.face_target(delta)
	enemy.move_horizontal(enemy.direction_to_target(), enemy.walk_speed, delta)
	if enemy.distance_to_target() <= enemy.attack_range * 0.9:
		machine.transition_to(&"Idle", {"wait": randf_range(0.2, 0.6)})
