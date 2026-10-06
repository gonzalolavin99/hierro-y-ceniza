extends PlayerState
## Golpe mortal: el jugador se lanza sobre el enemigo expuesto y lo remata.

const DURATION: float = 0.6
const STRIKE_AT: float = 0.22

var _target: Enemy
var _elapsed: float
var _struck: bool


func enter(msg: Dictionary) -> void:
	_target = msg["target"]
	_elapsed = 0.0
	_struck = false
	player.invulnerable = true
	player.weapon.go(&"windup_high", STRIKE_AT * 0.8)


func exit() -> void:
	player.invulnerable = false


func physics_update(delta: float) -> void:
	_elapsed += delta
	player.apply_gravity(delta)

	var to: Vector3 = _target.global_position - player.global_position
	to.y = 0.0
	player.snap_facing(to)
	# Acercarse hasta quedar a ~1,1 m del enemigo.
	if _elapsed < STRIKE_AT and to.length() > 1.1:
		var dir: Vector3 = to.normalized()
		var speed: float = (to.length() - 1.1) / maxf(STRIKE_AT - _elapsed, 0.05)
		player.velocity.x = dir.x * speed
		player.velocity.z = dir.z * speed
	else:
		player.velocity.x = 0.0
		player.velocity.z = 0.0

	if not _struck and _elapsed >= STRIKE_AT:
		_struck = true
		player.weapon.go(&"end_low", 0.08, Tween.EASE_IN)
		_target.receive_deathblow(player)

	if _elapsed >= DURATION:
		machine.transition_to(&"Ground")
