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
	# --- Capitana Varga (duelista acrobática) ---
	# leap: salta hacia ti y cae con el tajo · hop: salto hacia atrás (sin golpe) · throw: lanza N cuchillos
	# (en abanico) en vez de tajar · no_hit: tramo sin golpe.
	# Combo de cuatro: tres tajos muy seguidos y un cuarto que se hace esperar y se lanza hacia ti.
	&"varga_combo": [
		{"windup": 0.3, "active": 0.12, "after": 0.08, "anim": &"combo_one_hand", "from": 0.75, "impact": 1.00},
		{"windup": 0.2, "active": 0.12, "after": 0.08, "anim": &"combo_one_hand", "from": 1.7, "impact": 1.95},
		{"windup": 0.22, "active": 0.12, "after": 0.1, "anim": &"combo_one_hand", "from": 2.7, "impact": 2.98},
		{"windup": 0.55, "active": 0.14, "after": 0.6, "anim": &"slash_b", "from": 0.0, "impact": 0.33, "lunge": true},
	],
	# Torbellino: giro completo con dos tajos.
	&"varga_spin": [
		{"windup": 0.34, "active": 0.12, "after": 0.05, "anim": &"spin", "from": 0.25, "impact": 0.52},
		{"windup": 0.42, "active": 0.14, "after": 0.65, "anim": &"spin", "from": 0.6, "impact": 1.12},
	],
	# Salto desde lejos: vuela hacia ti y cae con un tajo vertical.
	&"varga_leap": [
		{"windup": 0.7, "active": 0.14, "after": 0.65, "anim": &"leap", "from": 0.3, "impact": 1.23, "leap": true},
	],
	# Salto y, al caer, dos tajos rápidos.
	&"varga_leap_combo": [
		{"windup": 0.7, "active": 0.14, "after": 0.08, "anim": &"leap", "from": 0.3, "impact": 1.23, "leap": true},
		{"windup": 0.24, "active": 0.12, "after": 0.08, "anim": &"combo_one_hand", "from": 1.7, "impact": 1.95},
		{"windup": 0.26, "active": 0.12, "after": 0.65, "anim": &"combo_one_hand", "from": 2.7, "impact": 2.98},
	],
	# Salta hacia atrás y lanza tres cuchillos seguidos (se desvían como un tajo).
	&"varga_knives": [
		{"windup": 0.42, "active": 0.02, "after": 0.05, "anim": &"dodge_back", "from": 0.15, "impact": 0.85, "hop": true, "no_hit": true},
		{"windup": 0.3, "active": 0.04, "after": 0.08, "anim": &"slash_d", "from": 0.2, "impact": 0.47, "throw": 1},
		{"windup": 0.2, "active": 0.04, "after": 0.08, "anim": &"slash_d", "from": 0.2, "impact": 0.47, "throw": 1},
		{"windup": 0.24, "active": 0.04, "after": 0.6, "anim": &"slash_d", "from": 0.2, "impact": 0.47, "throw": 1},
	],
	# A distancia: dos cuchillos sin saltar.
	&"varga_knives_far": [
		{"windup": 0.36, "active": 0.04, "after": 0.1, "anim": &"slash_d", "from": 0.2, "impact": 0.47, "throw": 1},
		{"windup": 0.24, "active": 0.04, "after": 0.55, "anim": &"slash_d", "from": 0.2, "impact": 0.47, "throw": 1},
	],
	# Fase 2: abanico de tres cuchillos a la vez (hay que desviar o rodar a un lado), y luego salta.
	&"varga_fan": [
		{"windup": 0.42, "active": 0.02, "after": 0.05, "anim": &"dodge_back", "from": 0.15, "impact": 0.85, "hop": true, "no_hit": true},
		{"windup": 0.34, "active": 0.04, "after": 0.1, "anim": &"slash_d", "from": 0.2, "impact": 0.47, "throw": 3},
		{"windup": 0.65, "active": 0.14, "after": 0.65, "anim": &"leap", "from": 0.3, "impact": 1.23, "leap": true},
	],
	# Fase 2: combo largo (cinco tajos y torbellino).
	&"varga_combo_long": [
		{"windup": 0.28, "active": 0.12, "after": 0.06, "anim": &"combo_one_hand", "from": 0.75, "impact": 1.00},
		{"windup": 0.18, "active": 0.12, "after": 0.06, "anim": &"combo_one_hand", "from": 1.7, "impact": 1.95},
		{"windup": 0.2, "active": 0.12, "after": 0.06, "anim": &"combo_one_hand", "from": 2.7, "impact": 2.98},
		{"windup": 0.3, "active": 0.12, "after": 0.05, "anim": &"spin", "from": 0.25, "impact": 0.52},
		{"windup": 0.4, "active": 0.14, "after": 0.65, "anim": &"spin", "from": 0.6, "impact": 1.12},
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
## En el aire por un salto (leap/hop): la velocidad la manda el salto, no la animación.
var _airborne: bool = false
var _air_time: float = 0.0


func enter(msg: Dictionary) -> void:
	# "delay"/"feint" solo los usan las pruebas para forzar un golpe retrasado o un amago.
	_forced_delay = msg.get("delay", -1.0)
	_forced_feint = msg.get("feint", false)
	_swings = PATTERNS[msg.get("pattern", &"single")]
	_airborne = false
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
	if _airborne:
		_air_time += delta
		if _air_time > 0.15 and enemy.is_on_floor():
			_airborne = false
			enemy.velocity.x = 0.0
			enemy.velocity.z = 0.0
	match _phase:
		Phase.WINDUP:
			# Sigue al jugador mientras se prepara; se lanza al final de la preparación.
			enemy.face_target(delta, 1.5)
			if _airborne:
				pass  # En pleno salto: sigue la trayectoria.
			elif swing.get("lunge", false) and _timer >= swing["windup"] * LUNGE_FROM:
				_lunge(swing["windup"] + _delay - _timer + swing["active"] * 0.5)
			else:
				enemy.apply_root_motion()
			_update_hold(swing, delta)
			if _feint and _held:
				_cancel_feint()
			elif _timer >= swing["windup"] + _delay:
				_set_phase(Phase.ACTIVE)
		Phase.ACTIVE:
			if _airborne:
				pass
			elif swing.get("lunge", false):
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


## Salto hacia el jugador: cae a distancia de golpe justo al llegar el impacto (`seconds`).
func _leap_at_target(seconds: float) -> void:
	var to: Vector3 = enemy.direction_to_target()
	var dist: float = enemy.distance_to_target()
	_jump(seconds, to * clampf((dist - 1.3) / maxf(seconds, 0.1), 0.0, 14.0))
	Sfx.play(&"swing", enemy.lock_point(), -4.0)


## Salto que dura `seconds` en el aire, con esa velocidad horizontal.
func _jump(seconds: float, horizontal: Vector3) -> void:
	enemy.velocity = Vector3(horizontal.x, enemy.gravity * seconds * 0.5, horizontal.z)
	_airborne = true
	_air_time = 0.0


## Lanza `count` cuchillos al pecho del jugador (si son varios, en abanico).
func _throw_knives(count: int) -> void:
	if enemy.target == null:
		return
	var from: Vector3 = enemy.global_position + Vector3.UP * 1.4 + enemy.get_facing() * 0.5
	var chest: Vector3 = enemy.target.global_position + Vector3.UP * 1.1
	var spread: float = deg_to_rad(9.0)
	for i in count:
		var angle: float = (i - (count - 1) * 0.5) * spread
		var aim: Vector3 = from + (chest - from).rotated(Vector3.UP, angle)
		ThrowingKnife.throw(enemy.get_parent(), from, aim, enemy)
	Sfx.play(&"swing", enemy.lock_point(), -1.0, 0.2)


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
			# Los ataques peligrosos nunca se retrasan: su aviso rojo tiene que ser fiable. Los saltos y
			# lanzamientos tampoco (la trayectoria ya está calculada).
			if danger or swing.has("leap") or swing.has("hop") or swing.has("throw"):
				_delay = 0.0
			elif _forced_delay >= 0.0:
				_delay = _forced_delay
			else:
				_delay = enemy.mind.choose_delay()
			_feint = _forced_feint if _forced_delay >= 0.0 else (_delay > 0.0 and enemy.mind.choose_feint())
			enemy.body.set_blocking(false)
			enemy.body.play_shaped(swing["anim"], swing["from"], swing["impact"], swing["windup"] + swing["active"] * 0.5)
			if swing.get("leap", false):
				_leap_at_target(swing["windup"] + swing["active"] * 0.5)
			elif swing.get("hop", false):
				_jump(0.42, -enemy.get_facing() * 6.0)
			var kind: HitData.Kind = swing.get("danger", HitData.Kind.NORMAL)
			if kind == HitData.Kind.NORMAL:
				enemy.body.glint()
				Sfx.play(&"glint", enemy.lock_point())
			else:
				enemy.body.danger_flash()
				Sfx.play(&"danger", enemy.lock_point())
				Voice.say(enemy.voice, &"danger", enemy.lock_point())
				enemy.danger_warned.emit(kind)
			if kind == HitData.Kind.NORMAL and _index == 0:
				Voice.say(enemy.voice, &"attack", enemy.lock_point())
		Phase.ACTIVE:
			if swing.get("no_hit", false):
				return
			if swing.has("throw"):
				_throw_knives(int(swing["throw"]))
				return
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
