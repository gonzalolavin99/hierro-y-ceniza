extends PlayerState
## Combo de ataque con RB (3 golpes). Cada golpe: preparación → tajo (activo) → recuperación.
## Pulsar RB durante el tajo o la recuperación encadena el siguiente golpe.
## En la recuperación se puede cancelar con guardia (LB) o paso rápido (B), como en Sekiro.

const COMBO: Array[Dictionary] = [
	{"windup": 0.11, "active": 0.12, "recovery": 0.30, "damage": 12.0, "posture": 10.0, "lunge": 4.0,
		"from": &"windup_right", "to": &"end_left"},
	{"windup": 0.10, "active": 0.12, "recovery": 0.30, "damage": 12.0, "posture": 10.0, "lunge": 3.5,
		"from": &"windup_left", "to": &"end_right"},
	{"windup": 0.17, "active": 0.14, "recovery": 0.45, "damage": 18.0, "posture": 16.0, "lunge": 5.0,
		"from": &"windup_high", "to": &"end_low"},
]

enum Phase { WINDUP, ACTIVE, RECOVERY }

var _index: int
var _phase: Phase
var _timer: float
var _queued: bool
var _direction: Vector3


func enter(msg: Dictionary) -> void:
	_index = msg.get("combo", 0)
	_queued = false
	player.consume_attack()
	_direction = player.attack_direction()
	player.snap_facing(_direction)
	_set_phase(Phase.WINDUP)


func exit() -> void:
	player.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var data: Dictionary = COMBO[_index]
	_timer += delta
	player.apply_gravity(delta)

	# Pequeño avance durante el golpe (no si ya estamos pegados al enemigo).
	var close: bool = player.lock_target != null and player.global_position.distance_to(player.lock_target.global_position) < 1.5
	var lunge: float = 0.0 if close or _phase == Phase.RECOVERY else data["lunge"]
	player.move_horizontal(_direction * lunge, lunge, 80.0, delta)

	if _phase != Phase.WINDUP and player.wants_attack():
		# Si hay un enemigo expuesto, el golpe mortal tiene prioridad sobre el combo.
		if player.try_deathblow():
			return
		_queued = true
		player.consume_attack()

	match _phase:
		Phase.WINDUP:
			if _timer >= data["windup"]:
				_set_phase(Phase.ACTIVE)
		Phase.ACTIVE:
			if _timer >= data["active"]:
				_set_phase(Phase.RECOVERY)
		Phase.RECOVERY:
			if _queued and _index < COMBO.size() - 1:
				machine.transition_to(&"Attack", {"combo": _index + 1})
			elif Input.is_action_just_pressed("block") or Input.is_action_pressed("block"):
				machine.transition_to(&"Block")
			elif Input.is_action_just_pressed("dodge"):
				machine.transition_to(&"Dash")
			elif _timer >= data["recovery"]:
				machine.transition_to(&"Ground")


func _set_phase(phase: Phase) -> void:
	var data: Dictionary = COMBO[_index]
	_phase = phase
	_timer = 0.0
	match phase:
		Phase.WINDUP:
			player.weapon.go(data["from"], data["windup"])
		Phase.ACTIVE:
			player.weapon.go(data["to"], data["active"], Tween.EASE_IN_OUT)
			player.hitbox.activate(HitData.create(player, data["damage"], data["posture"]))
		Phase.RECOVERY:
			player.hitbox.deactivate()
			player.weapon.go(&"idle", data["recovery"])
