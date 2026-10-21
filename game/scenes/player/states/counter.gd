extends PlayerState
## Pisar la hoja: tras contrarrestar una estocada, el personaje queda un instante sobre el arma
## del enemigo (como el "mikiri" de Sekiro). Breve; luego vuelve a moverse con normalidad.

const DURATION: float = 0.45

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	player.invulnerable = true
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player.body.set_blocking(false)
	# Patada provisional hasta tener una animación propia de pisar la hoja.
	player.body.play_action(&"kick", 0.2, 1.4, 0.05)


func exit() -> void:
	player.invulnerable = false
	player.body.stop_action(0.15)


func physics_update(delta: float) -> void:
	_elapsed += delta
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_deceleration, delta)
	if player.lock_target:
		player.face_direction(player.direction_to_lock_target(), delta)
	player.apply_gravity(delta)
	if _elapsed >= DURATION:
		machine.transition_to(&"Ground")
