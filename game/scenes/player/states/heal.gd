extends PlayerState
## Vendarse (X / R): Kael se para, se aprieta un vendaje y recupera parte de la vida. Mientras tanto no
## se mueve ni se cubre: curarse cerca de un enemigo es arriesgado (y los enemigos lo castigan).
## Si le golpean antes de terminar de apretarlo, no se cura pero tampoco gasta el vendaje.

const DURATION: float = 1.4
## Momento en que el vendaje queda apretado: cura y se gasta.
const APPLY_AT: float = 0.9
## Desde aquí puede cancelar con un paso rápido (ya curado).
const CANCEL_FROM: float = 1.05

var _elapsed: float
var _applied: bool


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	_applied = false
	player.body.set_blocking(false)
	# Provisional hasta tener una animación de vendarse: se lleva la mano al cuello y al hombro.
	player.body.play_timed(&"heal", 0.9, 2.3, DURATION, 0.15)
	Sfx.play(&"bandage", player.global_position + Vector3.UP * 1.3)


func exit() -> void:
	player.body.stop_action(0.2)


func physics_update(delta: float) -> void:
	_elapsed += delta
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_deceleration, delta)
	player.apply_gravity(delta)
	if not _applied and _elapsed >= APPLY_AT:
		_applied = true
		player.apply_bandage()
	if _elapsed >= CANCEL_FROM and Input.is_action_just_pressed("dodge"):
		machine.transition_to(&"Dash")
	elif _elapsed >= DURATION:
		machine.transition_to(&"Ground")
