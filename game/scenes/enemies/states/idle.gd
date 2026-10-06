extends EnemyState
## En guardia: mira al jugador y espera un momento antes de atacar.

const PATTERNS: Array[StringName] = [&"single", &"double", &"double", &"thrust_combo"]

var _wait: float


func enter(msg: Dictionary) -> void:
	_wait = msg.get("wait", randf_range(0.5, 1.3))
	enemy.weapon.go(&"block", 0.2)


func physics_update(delta: float) -> void:
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta)
	if not enemy.has_target():
		return
	enemy.face_target(delta)
	if enemy.distance_to_target() > enemy.attack_range:
		machine.transition_to(&"Chase")
		return
	_wait -= delta
	if _wait <= 0.0:
		machine.transition_to(&"Attack", {"pattern": PATTERNS.pick_random()})
