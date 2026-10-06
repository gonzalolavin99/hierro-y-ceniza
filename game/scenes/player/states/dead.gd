extends PlayerState
## Muerte (temporal): cae y reaparece en el punto de inicio.
## En el Hito 3 aquí entrará el campamento, la pérdida de experiencia
## y la voz del narrador: "No… no fue así".

const RESPAWN_AFTER: float = 2.5

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	player.hitbox.deactivate()
	player.lock_target = null
	player.body.set_blocking(false)
	player.body.play_action(&"death", 0.0, 1.0, 0.08)


func physics_update(delta: float) -> void:
	_elapsed += delta
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_acceleration, delta)
	player.apply_gravity(delta)
	if _elapsed >= RESPAWN_AFTER:
		player.respawn()
		machine.transition_to(&"Ground")
