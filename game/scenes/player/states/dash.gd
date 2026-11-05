extends PlayerState
## Esquiva (B). Con dirección: **voltereta** hacia donde apunta el stick (también con un enemigo fijado:
## Kael se gira hacia donde rueda). Sin dirección: paso rápido hacia atrás (como en los souls).
## Invulnerable al principio. Si se venía corriendo, la voltereta es la de carrera (más larga y lanzada).
## Si se mantiene B sin soltar, al terminar se pasa a correr.
## Tras la esquiva hay una breve recuperación: así encadenar esquivas no es más rápido que trotar.
## Durante ella se puede atacar, saltar o poner la guardia, pero no volver a esquivar.

## A partir de qué fracción de la esquiva se permite cancelar con un salto o un ataque.
const JUMP_CANCEL_FROM: float = 0.6
## Recuperación tras el paso atrás (s). La voltereta trae la suya (Player.roll_recovery).
const RECOVERY: float = 0.36
## Tramos útiles de las animaciones de voltereta (segundos de la animación): del salto a estar de pie.
const ROLL_SEGMENT: Vector2 = Vector2(0.85, 2.0)
const ROLL_RUN_SEGMENT: Vector2 = Vector2(0.45, 1.17)
## A partir de esta velocidad (m/s) se considera que venía corriendo.
const RUNNING_SPEED: float = 6.5

var _direction: Vector3
var _elapsed: float
## B mantenido sin soltar desde que empezó la esquiva (solo así se pasa a correr; pulsarlo de nuevo no).
var _held: bool
var _roll: bool
var _duration: float
var _recovery: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	_held = true
	var input_dir: Vector3 = player.get_move_direction()
	var running: bool = Vector2(player.velocity.x, player.velocity.z).length() > RUNNING_SPEED
	_roll = input_dir.length_squared() > 0.04
	if _roll:
		_direction = input_dir.normalized()
		player.snap_facing(_direction)
		_duration = player.roll_duration
		_recovery = player.roll_recovery
	else:
		_direction = -player.get_facing()  # Sin dirección: paso atrás
		_duration = player.dash_duration
		_recovery = RECOVERY
	player.invulnerable = true
	player.dashed.emit()
	player.dash_direction = _direction
	# Esquivar hacia el enemigo puede pisar la hoja de su estocada.
	var to_enemy: Vector3 = player.direction_to_lock_target() if player.lock_target else player.get_facing()
	if _roll and _direction.dot(to_enemy) > 0.5:
		player.counter_timer = player.counter_window
	player.body.set_blocking(false)
	if not _roll:
		player.body.play_timed(&"dodge_back", 0.15, 0.85, _duration)
	elif running:
		player.body.play_timed(&"roll_run", ROLL_RUN_SEGMENT.x, ROLL_RUN_SEGMENT.y, _duration, 0.08)
	else:
		player.body.play_timed(&"roll", ROLL_SEGMENT.x, ROLL_SEGMENT.y, _duration, 0.08)


func exit() -> void:
	player.invulnerable = false
	player.body.stop_action(0.15)
	player.dash_cooldown_timer = player.dash_cooldown


## ¿Es una voltereta (y no el paso atrás)?
func is_roll() -> bool:
	return _roll


func physics_update(delta: float) -> void:
	var previous_elapsed: float = _elapsed
	_held = _held and Input.is_action_pressed("dodge")
	_elapsed += delta
	var t: float = clampf(_elapsed / maxf(_duration, 0.01), 0.0, 1.0)
	if _elapsed > _duration:
		_recover(delta)
		return
	# Rápido al principio, frena al final (el total da exactamente la distancia de la esquiva).
	# El cálculo vive en Player para poder comprobar su curva con una prueba automática.
	var speed: float = player.roll_speed_for_interval(previous_elapsed, _elapsed, delta) if _roll \
		else player.dash_speed_for_interval(previous_elapsed, _elapsed, delta)
	player.velocity.x = _direction.x * speed
	player.velocity.z = _direction.z * speed
	player.apply_gravity(delta)
	var invulnerable_for: float = player.roll_invulnerable_time if _roll else player.dash_invulnerable_time
	player.invulnerable = _elapsed < invulnerable_for

	if t >= JUMP_CANCEL_FROM and player.wants_jump():
		player.do_jump()
		machine.transition_to(&"Air")
	elif t >= JUMP_CANCEL_FROM and player.wants_attack() and player.is_on_floor():
		if not player.try_deathblow():
			machine.transition_to(&"Attack", {"move": &"dodge_attack"})
	elif t >= 1.0:
		if not player.is_on_floor():
			machine.transition_to(&"Air")
		elif _held and player.get_move_direction().length_squared() > 0.04:
			machine.transition_to(&"Sprint")


## Tras la esquiva: frena del todo; se puede atacar, saltar o cubrirse; si se mantiene B, se corre.
func _recover(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, 40.0 * delta)
	player.velocity.z = move_toward(player.velocity.z, 0.0, 40.0 * delta)
	player.apply_gravity(delta)
	if not player.is_on_floor():
		machine.transition_to(&"Air")
	elif _held and player.get_move_direction().length_squared() > 0.04:
		machine.transition_to(&"Sprint")
	elif player.wants_jump():
		player.do_jump()
		machine.transition_to(&"Air")
	elif player.wants_attack():
		if not player.try_deathblow():
			machine.transition_to(&"Attack", {"move": &"dodge_attack"})
	elif player.wants_block():
		machine.transition_to(&"Block")
	elif _elapsed >= _duration + _recovery:
		machine.transition_to(&"Ground")
