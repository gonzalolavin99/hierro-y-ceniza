class_name EnemyAttackState
extends EnemyState
## Ataque del enemigo: una secuencia de tajos. Antes de cada uno brilla el filo (aviso).
## Si el jugador desvía el ÚLTIMO tajo, el enemigo retrocede expuesto (Recoil).
## Los tajos con "danger" son ataques peligrosos: aviso ROJO y no se pueden bloquear ni desviar.

## Cada tajo: preparación (windup), tajo activo, pausa tras el tajo, posturas del arma.
## anim/from/impact: animación, segundo en que empieza y segundo del impacto dentro de ella.
const PATTERNS: Dictionary[StringName, Array] = {
	&"single": [
		{"windup": 0.65, "active": 0.14, "after": 0.7, "anim": &"slash_c", "from": 0.1, "impact": 0.83},
	],
	# Combo a dos manos: el 2º tajo sigue de forma natural al 1º (mismo clip de Mixamo).
	&"double": [
		{"windup": 0.55, "active": 0.14, "after": 0.3, "anim": &"combo_two_hand", "from": 0.15, "impact": 0.63},
		{"windup": 0.28, "active": 0.14, "after": 0.7, "anim": &"combo_two_hand", "from": 0.95, "impact": 1.33},
	],
	&"thrust_combo": [
		{"windup": 0.5, "active": 0.14, "after": 0.25, "anim": &"slash_d", "from": 0.0, "impact": 0.47},
		{"windup": 0.45, "active": 0.12, "after": 0.8, "anim": &"combo_two_hand", "from": 1.8, "impact": 2.25},
	],
	# --- Ataques peligrosos (aviso rojo). Preparación más larga para que dé tiempo a reaccionar. ---
	# Barrido bajo: hay que saltarlo.
	&"sweep": [
		{"windup": 0.75, "active": 0.2, "after": 0.8, "anim": &"sweep_low", "from": 0.0, "impact": 0.45, "danger": HitData.Kind.SWEEP},
	],
	# Estocada: pisar la hoja (paso rápido hacia él) o esquivar a un lado.
	&"thrust": [
		{"windup": 0.8, "active": 0.16, "after": 0.8, "anim": &"slash_d", "from": 0.0, "impact": 0.47, "danger": HitData.Kind.THRUST},
	],
	# Agarre: hay que esquivar o saltar; ni la guardia ni el desvío sirven.
	&"grab": [
		{"windup": 0.75, "active": 0.2, "after": 0.9, "anim": &"shove", "from": 0.1, "impact": 0.62, "danger": HitData.Kind.GRAB},
	],
	# Tajo normal que encadena una estocada (obliga a cambiar de la guardia al paso).
	&"slash_thrust": [
		{"windup": 0.55, "active": 0.14, "after": 0.25, "anim": &"slash_c", "from": 0.1, "impact": 0.83},
		{"windup": 0.7, "active": 0.16, "after": 0.8, "anim": &"slash_d", "from": 0.0, "impact": 0.47, "danger": HitData.Kind.THRUST},
	],
	# --- Bandido ---
	# Tajo rápido de una mano: menos preparación (hay que reaccionar antes).
	&"quick": [
		{"windup": 0.42, "active": 0.12, "after": 0.55, "anim": &"slash_a", "from": 0.1, "impact": 0.53},
	],
	# Ráfaga de tres tajos seguidos (todos se desvían; desviar los tres le hace mucho daño de postura).
	&"flurry": [
		{"windup": 0.34, "active": 0.12, "after": 0.12, "anim": &"combo_one_hand", "from": 0.75, "impact": 1.00},
		{"windup": 0.3, "active": 0.12, "after": 0.12, "anim": &"combo_one_hand", "from": 1.7, "impact": 1.95},
		{"windup": 0.36, "active": 0.12, "after": 0.75, "anim": &"combo_one_hand", "from": 2.7, "impact": 2.98},
	],
	# Embestida: se lanza desde lejos con un tajo (cierra la distancia de golpe).
	&"lunge": [
		{"windup": 0.5, "active": 0.14, "after": 0.7, "anim": &"slash_b", "from": 0.0, "impact": 0.33, "lunge": true},
	],
	# --- Lancero (golpes con la lanza; se para más lejos, ver Enemy.strike_distance) ---
	# Estocada larga y directa (normal: se desvía).
	&"spear_thrust": [
		{"windup": 0.55, "active": 0.14, "after": 0.65, "anim": &"slash_d", "from": 0.0, "impact": 0.47},
	],
	# Golpe amplio de lado con el asta.
	&"spear_swing": [
		{"windup": 0.6, "active": 0.16, "after": 0.7, "anim": &"combo_two_hand", "from": 0.15, "impact": 0.63},
	],
	# --- Arquero ---
	# Patada para quitárselo de encima cuando te pegas a él.
	&"kick_push": [
		{"windup": 0.45, "active": 0.14, "after": 0.6, "anim": &"kick", "from": 0.25, "impact": 0.5},
	],
	# Contraataque tras bloquear varios golpes: más rápido.
	&"counter": [
		{"windup": 0.3, "active": 0.12, "after": 0.25, "anim": &"combo_one_hand", "from": 0.75, "impact": 1.00},
		{"windup": 0.3, "active": 0.12, "after": 0.7, "anim": &"combo_one_hand", "from": 1.7, "impact": 1.95},
	],
}

const DAMAGE: float = 20.0
const POSTURE_DAMAGE: float = 22.0
## Postura que sufre este enemigo cuando le desvían un tajo.
const DEFLECT_POSTURE: float = 24.0
## Daño de los ataques peligrosos (más que un tajo normal: castigan no leer el aviso).
const DANGER_DAMAGE: Dictionary = {HitData.Kind.SWEEP: 28.0, HitData.Kind.THRUST: 30.0, HitData.Kind.GRAB: 38.0}
## Postura que sufre al pisarle la estocada.
const COUNTER_POSTURE: float = 45.0

enum Phase { WINDUP, ACTIVE, AFTER }

## Embestida: desde qué fracción de la preparación se lanza, dónde se para y velocidad máxima.
const LUNGE_FROM: float = 0.45
const LUNGE_STOP: float = 1.4
const LUNGE_MAX_SPEED: float = 11.0

## Golpe retrasado: poco antes del impacto la espada se queda arriba (casi quieta) y luego cae.
const HOLD_LEAD: float = 0.22
## Mientras aguanta, la animación sigue avanzando muy despacio: congelarla del todo queda robótico.
const HOLD_CREEP: float = 0.06

var _swings: Array
var _index: int
var _phase: Phase
var _timer: float
var _deflected_last: bool
## Retraso y amago del tajo actual: se deciden al empezar su preparación y ya no cambian.
var _delay: float
var _feint: bool
var _holding: bool
var _held: bool
var _hold_left: float
var _forced_delay: float = -1.0
var _forced_feint: bool = false


func enter(msg: Dictionary) -> void:
	# "delay"/"feint" solo los usan las pruebas para forzar un golpe retrasado o un amago.
	_forced_delay = msg.get("delay", -1.0)
	_forced_feint = msg.get("feint", false)
	_swings = PATTERNS[msg.get("pattern", &"single")]
	Squad.take_turn(enemy)
	_index = 0
	_set_phase(Phase.WINDUP)


func exit() -> void:
	enemy.body.set_spear_thrust(0.0, Vector3.ZERO)
	Squad.end_turn(enemy)
	enemy.hitbox.deactivate()
	enemy.body.set_trail(false)


func physics_update(delta: float) -> void:
	var swing: Dictionary = _swings[_index]
	_timer += delta

	_update_spear_thrust(swing)
	match _phase:
		Phase.WINDUP:
			# Sigue al jugador mientras se prepara; se lanza al final de la preparación.
			enemy.face_target(delta, 1.5)
			if swing.get("lunge", false) and _timer >= swing["windup"] * LUNGE_FROM:
				_lunge(swing["windup"] + _delay - _timer + swing["active"] * 0.5)
			else:
				enemy.apply_root_motion()
			_update_hold(swing, delta)
			if _feint and _held:
				_cancel_feint()
			elif _timer >= swing["windup"] + _delay:
				_set_phase(Phase.ACTIVE)
		Phase.ACTIVE:
			if swing.get("lunge", false):
				_lunge(swing["active"] * 0.5 - _timer)
			else:
				enemy.apply_root_motion()
			if _timer >= swing["active"]:
				_set_phase(Phase.AFTER)
		Phase.AFTER:
			enemy.apply_root_motion()
			var last: bool = _index == _swings.size() - 1
			if last and _deflected_last:
				machine.transition_to(&"Recoil")
			elif _timer >= swing["after"]:
				if last:
					machine.transition_to(&"Idle")
				else:
					_index += 1
					_set_phase(Phase.WINDUP)


## Lo llama Enemy cuando el jugador pisa la hoja de la estocada: mucha postura y queda expuesto.
func on_countered() -> void:
	enemy.hitbox.deactivate()
	enemy.body.set_trail(false)
	enemy.posture.add(COUNTER_POSTURE)
	if state_is_active() and not enemy.posture.is_broken:
		machine.transition_to(&"Recoil", {"long": true})


## ¿Está haciendo ahora un barrido? (para que el pisotón lo interrumpa)
func is_sweeping() -> bool:
	return state_is_active() and _swings[_index].get("danger", HitData.Kind.NORMAL) == HitData.Kind.SWEEP


## Lo llama Enemy cuando el jugador desvía este tajo.
func on_deflected() -> void:
	enemy.posture.add(DEFLECT_POSTURE)
	enemy.hitbox.deactivate()
	if state_is_active():
		enemy.body.play_action(&"block_impact", 0.0, 1.6, 0.04)
		enemy.push = -enemy.get_facing() * 2.2  # Choque de espadas: retrocede
		_deflected_last = _index == _swings.size() - 1


## Lancero: las estocadas usan una animación de espada, así que la lanza se apunta al frente durante la
## preparación y se estira de golpe en el instante del impacto (la punta llega a donde hace daño).
func _update_spear_thrust(swing: Dictionary) -> void:
	if enemy.body.weapon != Mannequin.Weapon.SPEAR or swing["anim"] != &"slash_d":
		enemy.body.set_spear_thrust(0.0, Vector3.ZERO)
		return
	var amount: float = 0.0
	match _phase:
		Phase.WINDUP:
			amount = smoothstep(0.3, 1.0, _timer / maxf(swing["windup"] + _delay, 0.01)) * 0.6
		Phase.ACTIVE:
			amount = 1.0
		Phase.AFTER:
			amount = 1.0 - clampf(_timer / 0.35, 0.0, 1.0)
	enemy.body.set_spear_thrust(amount, enemy.get_facing())


## Embestida: avanza lo justo para llegar a distancia de golpe en `time_left` segundos.
func _lunge(time_left: float) -> void:
	var dist: float = enemy.distance_to_target()
	var dir: Vector3 = enemy.direction_to_target()
	var speed: float = 0.0
	if dist > LUNGE_STOP:
		speed = minf((dist - LUNGE_STOP) / maxf(time_left, 0.08), LUNGE_MAX_SPEED)
	enemy.velocity.x = dir.x * speed
	enemy.velocity.z = dir.z * speed


## Retraso del tajo actual (segundos que aguanta arriba), decidido al empezar su preparación.
func current_delay() -> float:
	return _delay


## Golpe retrasado: poco antes del impacto congela la animación (espada en alto) y luego la reanuda
## para que llegue al impacto justo al terminar la espera.
func _update_hold(swing: Dictionary, delta: float) -> void:
	if _delay <= 0.0 or _held:
		return
	if not _holding and _timer >= swing["windup"] - HOLD_LEAD:
		_holding = true
		_hold_left = _delay
		enemy.body.set_action_speed(HOLD_CREEP)
	elif _holding:
		_hold_left -= delta
		if _hold_left <= 0.0:
			_holding = false
			_held = true
			if not _feint:
				var remaining: float = swing["impact"] - enemy.body.action_time()
				enemy.body.set_action_speed(clampf(remaining / HOLD_LEAD, 0.3, 3.0))


## Amago: tras aguantar el golpe, no lo suelta y vuelve a la guardia (castiga desviar sin mirar).
func _cancel_feint() -> void:
	enemy.body.stop_action(0.25)
	enemy.push = -enemy.get_facing() * 1.0
	machine.transition_to(&"Idle", {"wait": 0.3})


func state_is_active() -> bool:
	return machine.current == self


func _set_phase(phase: Phase) -> void:
	var swing: Dictionary = _swings[_index]
	_phase = phase
	_timer = 0.0
	match phase:
		Phase.WINDUP:
			_deflected_last = false
			_holding = false
			_held = false
			var danger: bool = swing.get("danger", HitData.Kind.NORMAL) != HitData.Kind.NORMAL
			# Los ataques peligrosos nunca se retrasan: su aviso rojo tiene que ser fiable.
			if danger:
				_delay = 0.0
			elif _forced_delay >= 0.0:
				_delay = _forced_delay
			else:
				_delay = enemy.mind.choose_delay()
			_feint = _forced_feint if _forced_delay >= 0.0 else (_delay > 0.0 and enemy.mind.choose_feint())
			enemy.body.set_blocking(false)
			enemy.body.play_shaped(swing["anim"], swing["from"], swing["impact"], swing["windup"] + swing["active"] * 0.5)
			var kind: HitData.Kind = swing.get("danger", HitData.Kind.NORMAL)
			if kind == HitData.Kind.NORMAL:
				enemy.body.glint()
				Sfx.play(&"glint", enemy.lock_point())
			else:
				enemy.body.danger_flash()
				Sfx.play(&"danger", enemy.lock_point())
				Voice.say(&"soldier", &"danger", enemy.lock_point())
				enemy.danger_warned.emit(kind)
			if kind == HitData.Kind.NORMAL and _index == 0:
				Voice.say(&"soldier", &"attack", enemy.lock_point())
		Phase.ACTIVE:
			var hit := HitData.create(enemy, DAMAGE, POSTURE_DAMAGE, DEFLECT_POSTURE)
			hit.kind = swing.get("danger", HitData.Kind.NORMAL)
			if hit.is_perilous():
				hit.damage = DANGER_DAMAGE[hit.kind]
			hit.damage *= enemy.damage_scale
			enemy.hitbox.activate(hit)
			enemy.body.set_trail(true)
			Sfx.play(&"swing", enemy.lock_point())
		Phase.AFTER:
			enemy.hitbox.deactivate()
			enemy.body.set_trail(false)
