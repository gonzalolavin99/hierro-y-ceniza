extends PlayerState
## Descansar en un campamento (Y / E junto a la fogata): Kael se arrodilla junto al fuego, la pantalla
## se funde a negro, recupera vida, vendajes y herramientas, los enemigos vuelven a su puesto y este
## campamento pasa a ser su punto de reaparición. Luego la pantalla se aclara y se levanta.

## Se arrodilla y empieza a oscurecer.
const FADE_OUT_FROM: float = 0.5
const FADE_OUT: float = 0.8
## Con la pantalla en negro: aquí se repone todo.
const RESTORE_AT: float = 1.4
const FADE_IN_FROM: float = 2.6
const FADE_IN: float = 0.9
const DURATION: float = 3.6

var _fire: Campfire
var _elapsed: float
var _restored: bool
var _faded_out: bool
var _faded_in: bool


func enter(msg: Dictionary) -> void:
	_fire = msg.get("fire") as Campfire
	_elapsed = 0.0
	_restored = false
	_faded_out = false
	_faded_in = false
	player.lock_target = null
	player.body.set_blocking(false)
	player.body.play_action(&"kneel", 0.0, 1.0, 0.3)
	if _fire:
		player.snap_facing(_fire.global_position - player.global_position)


func exit() -> void:
	player.body.stop_action(0.4)
	if not _faded_in:
		Camps.fade_to(0.0, 0.3)


func physics_update(delta: float) -> void:
	_elapsed += delta
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_deceleration, delta)
	player.apply_gravity(delta)
	if not _faded_out and _elapsed >= FADE_OUT_FROM:
		_faded_out = true
		Camps.fade_to(1.0, FADE_OUT, "Descansas junto al fuego")
	if not _restored and _elapsed >= RESTORE_AT:
		_restored = true
		if _fire:
			_fire.rest(player)
			# Queda en su sitio junto al fuego, mirándolo.
			player.global_position = _fire.rest_position()
			player.reset_physics_interpolation()
			player.model.rotation.y = deg_to_rad(_fire.rest_facing_degrees())
			player.camera_rig.recenter()
	if not _faded_in and _elapsed >= FADE_IN_FROM:
		_faded_in = true
		Camps.fade_to(0.0, FADE_IN)
	if _elapsed >= DURATION:
		machine.transition_to(&"Ground")
