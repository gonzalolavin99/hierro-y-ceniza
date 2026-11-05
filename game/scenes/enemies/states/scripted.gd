class_name EnemyScripted
extends EnemyState
## En una escena: no decide nada. Camina a `walk_velocity` (m/s, en el mundo) si la escena se lo pide,
## o se queda quieto. La escena lo saca de aquí al terminar.

var walk_velocity: Vector3 = Vector3.ZERO


func enter(_msg: Dictionary) -> void:
	walk_velocity = Vector3.ZERO
	enemy.body.set_blocking(false)


func physics_update(delta: float) -> void:
	if walk_velocity.length_squared() > 0.001:
		enemy.velocity.x = walk_velocity.x
		enemy.velocity.z = walk_velocity.z
		enemy.face_direction(walk_velocity.normalized(), delta)
	else:
		enemy.move_horizontal(Vector3.ZERO, 0.0, delta, 20.0)
