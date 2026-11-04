extends EnemyState
## Esquiva (enemigos ágiles como el bandido): al ver empezar tu ataque se aparta de un salto, hacia
## atrás o en diagonal. Al principio no le alcanzan los golpes (igual que tu paso rápido) y, al
## terminar, a veces contraataca con una embestida desde donde ha caído.

const DURATION: float = 0.42
const DISTANCE: float = 2.4
## Segundos del principio en que los golpes no le alcanzan.
const UNTOUCHABLE: float = 0.22
## Probabilidad de embestir al terminar la esquiva.
const COUNTER_CHANCE: float = 0.5

var _direction: Vector3
var _elapsed: float
var _counter: StringName
var _counter_chance: float


func enter(msg: Dictionary) -> void:
	_counter = msg.get("counter", &"lunge")
	_counter_chance = msg.get("counter_chance", COUNTER_CHANCE)
	_elapsed = 0.0
	var back: Vector3 = -enemy.get_facing()
	var right: Vector3 = enemy.get_facing().cross(Vector3.UP)
	var anim: StringName = &"dodge_back"
	_direction = back
	# A veces en diagonal hacia atrás (se lee peor y te descoloca).
	if not msg.get("back", false) and randf() < 0.4:
		var side: float = 1.0 if randf() < 0.5 else -1.0
		_direction = (back + right * side * 0.9).normalized()
		anim = &"dodge_right" if side > 0.0 else &"dodge_left"
	enemy.evading = true
	enemy.blocks_in_a_row = 0
	enemy.body.set_blocking(false)
	# El tramo en que la animación se desplaza (0,15 → 0,85 s), comprimido en lo que dura la esquiva.
	enemy.body.play_timed(anim, 0.15, 0.85, DURATION)


func exit() -> void:
	enemy.evading = false
	enemy.body.stop_action(0.15)


func physics_update(delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / DURATION, 0.0, 1.0)
	# Rápido al principio y frena al final; el promedio recorre DISTANCE.
	var speed: float = 2.0 * DISTANCE / DURATION * (1.0 - t)
	enemy.velocity.x = _direction.x * speed
	enemy.velocity.z = _direction.z * speed
	enemy.face_target(delta)
	enemy.evading = _elapsed < UNTOUCHABLE
	if t >= 1.0:
		if randf() < _counter_chance and enemy.has_target():
			machine.transition_to(&"Attack", {"pattern": _counter})
		else:
			machine.transition_to(&"Idle", {"wait": randf_range(0.2, 0.5)})
