extends PlayerState
## Paso rápido (como Sekiro): desplazamiento corto con invulnerabilidad al inicio.
## Sin dirección en el stick = paso hacia atrás.
## Si se mantiene el botón al terminar, se pasa a correr.

## A partir de qué fracción del paso se permite cancelar con un salto.
const JUMP_CANCEL_FROM: float = 0.6

var _direction: Vector3
var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	var input_dir: Vector3 = player.get_move_direction()
	if input_dir.length_squared() > 0.04:
		_direction = input_dir.normalized()
		player.model.rotation.y = atan2(-_direction.x, -_direction.z)
	else:
		_direction = -player.get_facing()
	player.invulnerable = true


func exit() -> void:
	player.invulnerable = false
	player.dash_cooldown_timer = player.dash_cooldown


func physics_update(delta: float) -> void:
	_elapsed += delta
	var t: float = _elapsed / player.dash_duration

	# Rápido al principio, frena al final (el promedio da exactamente dash_distance).
	var speed: float = player.dash_distance / player.dash_duration * 2.0 * (1.0 - t)
	player.velocity.x = _direction.x * speed
	player.velocity.z = _direction.z * speed
	player.apply_gravity(delta)
	player.invulnerable = _elapsed < player.dash_invulnerable_time

	if t >= JUMP_CANCEL_FROM and player.wants_jump():
		player.do_jump()
		machine.transition_to(&"Air")
	elif t >= 1.0:
		if not player.is_on_floor():
			machine.transition_to(&"Air")
		elif Input.is_action_pressed("dodge") and player.get_move_direction().length_squared() > 0.04:
			machine.transition_to(&"Sprint")
		else:
			machine.transition_to(&"Ground")
