extends PlayerState
## Combo de ataque con RB (3 golpes). Cada golpe: preparación → tajo (activo) → recuperación.
## Pulsar RB durante el tajo o la recuperación encadena el siguiente golpe.
## En la recuperación se puede cancelar con guardia (LB) o paso rápido (B), como en Sekiro.

## anim/from/impact: animación, segundo en que empieza y segundo del impacto dentro de ella.
## Los tres golpes son tramos seguidos de un mismo combo de Mixamo, así se encadenan con naturalidad.
const COMBO: Array[Dictionary] = [
	{"windup": 0.13, "active": 0.12, "recovery": 0.30, "damage": 12.0, "posture": 10.0,
		"anim": &"combo_one_hand", "from": 0.72, "impact": 1.00},
	{"windup": 0.12, "active": 0.12, "recovery": 0.30, "damage": 12.0, "posture": 10.0,
		"anim": &"combo_one_hand", "from": 1.68, "impact": 1.95},
	{"windup": 0.17, "active": 0.14, "recovery": 0.45, "damage": 18.0, "posture": 16.0,
		"anim": &"combo_one_hand", "from": 2.62, "impact": 2.98},
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

	# El cuerpo avanza lo que la animación avanza (sin patinar ni atravesar al enemigo).
	player.apply_root_motion(player.lock_target)
	# Durante la preparación sigue un poco al objetivo fijado.
	if _phase == Phase.WINDUP and player.lock_target:
		player.face_direction(player.direction_to_lock_target(), delta * 0.6)

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
			player.body.set_blocking(false)
			player.body.play_timed(data["anim"], data["from"], data["impact"], data["windup"] + data["active"] * 0.5)
		Phase.ACTIVE:
			player.hitbox.activate(HitData.create(player, data["damage"], data["posture"]))
			Sfx.play(&"swing", player.global_position + Vector3.UP * 1.3, -2.0)
		Phase.RECOVERY:
			player.hitbox.deactivate()
			player.body.set_action_speed(1.2)
