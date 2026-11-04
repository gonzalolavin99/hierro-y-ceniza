class_name Enemy
extends CharacterBody3D
## Enemigo humano base. Bloquea cuando no está atacando (como en Sekiro): la forma de vencerlo
## es presionar su postura con ataques y desvíos hasta romperla, y entonces dar el golpe mortal.

signal died
## Empieza la preparación de un ataque peligroso (aviso rojo). kind: HitData.Kind.
signal danger_warned(kind: int)

@export var display_name: String = "Soldado"
@export var walk_speed: float = 3.0
@export var turn_speed: float = 8.0
@export var gravity: float = 24.0
## Distancia a la que detecta al jugador.
@export var aggro_range: float = 12.0
@export var attack_range: float = 2.4
@export var broken_duration: float = 3.0
## Tras cuántos bloqueos seguidos contraataca.
@export var blocks_before_counter: int = 3
## Solo para pruebas: reaparece tras morir. 0 = no reaparece.
@export var respawn_delay: float = 5.0

@export_group("Tipo")
## Ataques normales de este tipo (vacío = los del soldado). Ver EnemyAttackState.PATTERNS.
@export var moveset: Array[StringName] = []
## Ataques peligrosos (aviso rojo). &"grab" solo se usa de cerca.
@export var danger_moveset: Array[StringName] = [&"sweep", &"thrust", &"slash_thrust", &"grab"]
## Proporción de ataques peligrosos.
@export var danger_ratio: float = 0.33
## Segundos que espera en guardia antes de atacar (mínimo, máximo).
@export var idle_wait: Vector2 = Vector2(0.5, 1.3)
## Probabilidad de apartarse de un salto al ver empezar tu ataque (en vez de bloquear).
@export var evade_chance: float = 0.0
## Multiplicador del daño de sus golpes.
@export var damage_scale: float = 1.0
## ¿Puede bloquear con su arma? (el arquero no).
@export var can_block: bool = true
## Distancia a la que se para al lanzar un golpe (más con armas largas como la lanza).
@export var strike_distance: float = 1.3
## Si te acercas más que esto, recupera distancia (0 = no le importa). El lancero salta atrás;
## el que ataca a distancia retrocede caminando.
@export var keep_away_range: float = 0.0
## Ataca a distancia (arquero): dispara cuando le toca atacar y estás lejos.
@export var ranged: bool = false

@export_group("Sigilo")
## Empieza sin saber que estás ahí (patrulla o guardia). Si es false, está alerta desde el principio
## (el soldado de práctica de la arena).
@export var starts_unaware: bool = false
## Puntos de su ronda (posiciones en el mundo). Vacío = vigila quieto en su puesto.
@export var patrol_points: PackedVector3Array = PackedVector3Array()
@export var patrol_speed: float = 1.1

@onready var model: Node3D = $Model
@onready var body: Mannequin = $Model/Mannequin
@onready var hitbox: Hitbox = $Model/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: Health = $Health
@onready var posture: Posture = $Posture
@onready var state_machine: StateMachine = $StateMachine
@onready var _lock_point: Marker3D = $LockPoint
@onready var _body_collision: CollisionShape3D = $Collision

## Postura que sufre al recibir un pisotón.
const STOMP_POSTURE: float = 30.0

# --- Percepción (sigilo) ---
## Vista: hasta dónde ve y su ángulo (a cada lado de hacia donde mira).
const VIEW_RANGE: float = 15.0
const VIEW_HALF_ANGLE: float = deg_to_rad(60.0)
## Sospecha por segundo al verte (se multiplica: más cerca, más rápido).
const SIGHT_RATE: float = 0.6
## Agachado cuesta más verte.
const CROUCH_SIGHT: float = 0.45
## Sospecha por segundo al oírte (dentro del radio de ruido del jugador).
const HEAR_BASE: float = 0.5
const HEAR_RATE: float = 0.9
## Solo con oírte no te descubre del todo (se acerca a mirar); hace falta verte, salvo muy de cerca.
const HEARING_MAX: float = 0.8
const HEARING_CLOSE: float = 2.0
## Tras unos segundos sin verte ni oírte, la sospecha baja.
const CALM_DELAY: float = 2.0
const CALM_RATE: float = 0.2
## Desde esta sospecha deja la ronda y va a mirar (signo "?").
const SUSPICIOUS_AT: float = 0.35
## Al descubrirte avisa a los compañeros que estén a esta distancia.
const ALARM_RADIUS: float = 12.0
## Si te pierde (lejos o escondido) durante este tiempo, se calma y vuelve a buscar y a patrullar.
const LOSE_TIME: float = 4.0
## Golpe mortal por sorpresa: distancia máxima.
const STEALTH_KILL_RANGE: float = 2.4
## Al recuperar distancia con un salto, no lo repite hasta pasado este tiempo.
const KEEP_AWAY_COOLDOWN: float = 2.5
## Más cerca que esto, el que ataca a distancia se defiende con una patada.
const MELEE_RANGE: float = 2.2
## Esquiva: solo si el ataque empieza a esta distancia, y tras este tiempo de reacción.
const EVADE_RANGE: float = 3.2
const EVADE_REACTION: float = 0.1

var target: Player
## Lo que ha aprendido de los hábitos del jugador (ver EnemyMind).
var mind: EnemyMind = EnemyMind.new()
var blocks_in_a_row: int = 0
## Ya le habló al jugador en esta vida (frase al verlo).
var has_spoken_to_target: bool = false
## Velocidad que "pide" la animación actual (su paso real).
var root_motion_velocity: Vector3 = Vector3.ZERO
## Empujón que se suma al movimiento y se desvanece (choques, golpes).
var push: Vector3 = Vector3.ZERO
## Sabe que estás ahí y pelea (si no, patrulla o sospecha).
var alerted: bool = true
## Sospecha: 0 = tranquilo, 1 = te ha descubierto.
var awareness: float = 0.0
## Dónde te vio u oyó por última vez.
var last_known: Vector3 = Vector3.ZERO
## Hacia dónde mira en su puesto (se toma al empezar; las pruebas pueden cambiarlo).
var post_direction: Vector3 = Vector3.FORWARD
var _calm_timer: float = 0.0
var _lost_time: float = 0.0
var _alarm_in: float = -1.0
var _mark: Label3D
var _mark_timer: float = 0.0
## Durante el inicio de una esquiva no le alcanzan los golpes (como el paso rápido del jugador).
var evading: bool = false
var _saw_player_attack: bool = false
var _evade_in: float = -1.0
## Momento (reloj de Squad) del último salto para recuperar distancia.
var last_keep_away: float = -100.0
var _spawn: Transform3D
var _base_posture_regen: float


func _ready() -> void:
	add_to_group("enemies")
	_spawn = global_transform
	_base_posture_regen = posture.regen_rate
	state_machine.setup(self)
	posture.broken.connect(_on_posture_broken)
	health.died.connect(_on_health_depleted)
	hitbox.hit_landed.connect(_on_hit_landed)
	_build_mark()
	mind.configure(moveset, danger_moveset, danger_ratio)
	post_direction = get_facing()
	alerted = not starts_unaware
	if starts_unaware:
		state_machine.transition_to(&"Patrol")


func _physics_process(delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Player
		if target:
			target.deflected.connect(mind.on_player_deflect)
			target.dashed.connect(mind.on_player_dash)
	if target:
		mind.observe_guard(target.state_machine.current.name == &"Block", delta)
		if alerted and distance_to_target() <= aggro_range:
			DebugOverlay.watch("IA lee", mind.describe())
	_update_awareness(delta)
	_update_mark(delta)
	_watch_player_attack(delta)
	# Con poca vida, la postura se recupera más lento (como en Sekiro).
	posture.regen_multiplier = 0.25 + 0.75 * health.ratio()
	velocity.y -= gravity * delta
	root_motion_velocity = body.consume_root_motion() / maxf(delta, 0.0001)
	state_machine.physics_update(delta)
	# El empujón se suma solo durante este movimiento: no se acumula en la velocidad.
	velocity += push
	move_and_slide()
	velocity -= push
	push = push.move_toward(Vector3.ZERO, 14.0 * delta)
	body.update_locomotion(velocity, get_facing())


# --- Utilidades para los estados ------------------------------------------------

func has_target() -> bool:
	return alerted and target != null and not target.is_dead() and distance_to_target() <= aggro_range


func distance_to_target() -> float:
	return global_position.distance_to(target.global_position) if target else INF


func direction_to_target() -> Vector3:
	var to: Vector3 = target.global_position - global_position
	to.y = 0.0
	return to.normalized()


func get_facing() -> Vector3:
	return -model.global_basis.z


func face_target(delta: float, speed_multiplier: float = 1.0) -> void:
	face_direction(direction_to_target(), delta, speed_multiplier)


func face_direction(dir: Vector3, delta: float, speed_multiplier: float = 1.0) -> void:
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		return
	# El modelo gira dentro del cuerpo: si el enemigo está colocado girado en el nivel, la dirección
	# del mundo hay que pasarla a la del cuerpo (si no, mira justo al revés).
	var local: Vector3 = global_basis.orthonormalized().inverse() * dir.normalized()
	var yaw: float = atan2(-local.x, -local.z)
	model.rotation.y = lerp_angle(model.rotation.y, yaw, 1.0 - exp(-turn_speed * speed_multiplier * delta))


func move_horizontal(direction: Vector3, speed: float, delta: float, acceleration: float = 30.0) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(direction * speed, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Aplica el avance real de la animación, frenando antes de atravesar al jugador
## y estirándolo si está lejos para que el ataque llegue.
func apply_root_motion(stop_distance: float = -1.0) -> void:
	if stop_distance < 0.0:
		stop_distance = strike_distance
	var motion := root_motion_velocity
	if target:
		var dir := direction_to_target()
		var forward: float = motion.dot(dir)
		var dist: float = distance_to_target()
		if forward > 0.0:
			if dist <= stop_distance:
				motion -= dir * forward
			elif dist > 2.6:
				motion += dir * forward * 0.4
	velocity.x = motion.x
	velocity.z = motion.z


func lock_point() -> Vector3:
	return _lock_point.global_position


func state_name() -> StringName:
	return state_machine.current.name


func is_dead() -> bool:
	return state_name() == &"Dead"


func can_be_deathblowed() -> bool:
	return state_name() == &"Broken"


# --- Combate ---------------------------------------------------------------------

func receive_hit(hit: HitData) -> int:
	var state: StringName = state_name()
	if state == &"Dead" or state == &"Broken" or evading:
		return HitData.Result.IGNORED

	var to_attacker: Vector3 = hit.attacker.global_position - global_position
	to_attacker.y = 0.0
	to_attacker = to_attacker.normalized()
	var contact: Vector3 = global_position + Vector3.UP * 1.3 + to_attacker * 0.55
	var facing_attacker: bool = get_facing().dot(to_attacker) > 0.0
	# Desprevenido no se cubre; el golpe lo pone en alerta.
	var unaware: bool = not alerted
	alert()

	# Fuera de sus ataques, bloquea todo lo que tenga de frente.
	# La patada rompe la guardia: queda expuesto sin bloquear.
	# Aturdido (humo) o retrocediendo: no puede bloquear.
	var can_guard: bool = can_block and not unaware and state != &"Attack" and state != &"Recoil" and state != &"Dazed" and facing_attacker
	if hit.guard_break and can_guard:
		posture.add(hit.posture_damage)
		Sfx.play(&"block", contact, -4.0)
		CombatFX.hitstop(0.05)
		CombatFX.shake(0.2)
		push = -to_attacker * 3.0
		blocks_in_a_row = 0
		if not posture.is_broken:
			state_machine.transition_to(&"Recoil")
		return HitData.Result.HIT

	if can_guard and hit.ranged:
		# Virote bloqueado con la espada: chispa y un poco de postura, sin reacción grande.
		posture.add(hit.posture_damage)
		Sfx.play(&"block", contact, -6.0)
		CombatFX.sparks(contact, 6, 3.0)
		return HitData.Result.BLOCKED

	if can_guard:
		posture.add(hit.posture_damage)
		Sfx.play(&"block", contact)
		CombatFX.sparks(contact, 10, 4.0)
		CombatFX.hitstop(0.035)
		body.play_reaction(&"block_impact", 0.25, 0.0, 1.5)
		body.flinch(to_attacker, 0.35)
		push = -to_attacker * 1.2
		blocks_in_a_row += 1
		mind.on_attack_blocked()
		if blocks_in_a_row >= mind.blocks_before_counter(blocks_before_counter) and not posture.is_broken:
			blocks_in_a_row = 0
			state_machine.transition_to(&"Attack", {"pattern": &"counter"})
		return HitData.Result.BLOCKED

	# Golpe directo (atacando, retrocediendo o de espaldas).
	health.take_damage(hit.damage)
	Voice.say(&"soldier", &"hurt", lock_point())
	var exposed: bool = state == &"Recoil" or state == &"Dazed"
	posture.add(hit.posture_damage * (1.0 if exposed else 0.5))
	Sfx.play(&"bolt_hit" if hit.ranged else &"hit", contact)
	CombatFX.blood(contact)
	CombatFX.hitstop(0.05)
	body.flinch(to_attacker, 0.8)
	# El virote interrumpe el ataque que estaba preparando o lanzando.
	if hit.interrupts and state == &"Attack" and not posture.is_broken:
		state_machine.transition_to(&"Recoil")
	return HitData.Result.HIT


## Explosión de pólvora: daña aunque esté en guardia, sube mucho la postura y lo desequilibra
## (interrumpe cualquier ataque).
func receive_blast(origin: Vector3, damage: float, posture_damage: float) -> void:
	var state: StringName = state_name()
	if state == &"Dead" or state == &"Broken":
		return
	var away: Vector3 = global_position - origin
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -get_facing()
	alert()
	health.take_damage(damage)
	posture.add(posture_damage)
	Voice.say(&"soldier", &"hurt", lock_point())
	CombatFX.blood(global_position + Vector3.UP * 1.2)
	body.flinch(-away, 1.2)
	push = away * 5.0
	blocks_in_a_row = 0
	if not posture.is_broken and not is_dead() and state_name() != &"Broken":
		state_machine.transition_to(&"Recoil")


## Bomba de humo: tose y queda aturdido un momento (ni ataca ni bloquea).
func receive_smoke() -> void:
	var state: StringName = state_name()
	if state == &"Dead" or state == &"Broken":
		return
	blocks_in_a_row = 0
	alert()
	state_machine.transition_to(&"Dazed")


func receive_deathblow(_attacker: Node3D) -> void:
	var at: Vector3 = global_position + Vector3.UP * 1.2
	Sfx.play(&"deathblow", at)
	CombatFX.sparks(at, 24, 7.0)
	CombatFX.blood(at)
	CombatFX.blood(at)
	CombatFX.hitstop(0.14)
	CombatFX.shake(0.6)
	health.current = 0.0
	health.changed.emit(0.0, health.max_health)
	state_machine.transition_to(&"Dead")


func set_vulnerable(enabled: bool) -> void:
	hurtbox.set_deferred("monitorable", enabled)
	_body_collision.set_deferred("disabled", not enabled)


func respawn() -> void:
	global_transform = _spawn
	velocity = Vector3.ZERO
	reset_physics_interpolation()
	model.rotation = Vector3.ZERO
	body.stop_action(0.1)
	health.heal(health.max_health)
	posture.reset()
	blocks_in_a_row = 0
	has_spoken_to_target = false
	alerted = not starts_unaware
	awareness = 0.0
	_lost_time = 0.0
	set_vulnerable(true)


## Pisotón: el jugador salta sobre él y se impulsa en su cabeza/hombros. Daña la postura;
## si estaba haciendo un barrido, lo interrumpe.
func receive_stomp(attacker: Node3D) -> void:
	if is_dead() or state_name() == &"Broken":
		return
	var at: Vector3 = global_position + Vector3.UP * 1.7
	Sfx.play(&"block", at, -2.0)
	CombatFX.hitstop(0.06)
	CombatFX.shake(0.25)
	var to_attacker: Vector3 = attacker.global_position - global_position
	to_attacker.y = 0.0
	body.flinch(to_attacker.normalized(), 1.0)
	alert()
	var attack := state_machine.current as EnemyAttackState
	var interrupted: bool = attack != null and attack.is_sweeping()
	posture.add(STOMP_POSTURE)
	blocks_in_a_row = 0
	if interrupted and not posture.is_broken:
		state_machine.transition_to(&"Recoil")


func _on_hit_landed(result: int, _hurtbox: Hurtbox) -> void:
	var attack := state_machine.current as EnemyAttackState
	if result == HitData.Result.HIT:
		mind.on_player_hit()
	if result == HitData.Result.DEFLECTED and attack:
		attack.on_deflected()
	elif result == HitData.Result.COUNTERED and attack:
		attack.on_countered()


func _on_posture_broken() -> void:
	if not is_dead():
		state_machine.transition_to(&"Broken")


func _on_health_depleted() -> void:
	if not is_dead():
		state_machine.transition_to(&"Broken")


# --- Sigilo ----------------------------------------------------------------------

## Te descubre: entra en combate y avisa a los compañeros cercanos.
func alert() -> void:
	if alerted or is_dead():
		return
	alerted = true
	awareness = 1.0
	_lost_time = 0.0
	_alarm_in = -1.0
	if target:
		last_known = target.global_position
	_show_mark("!", Color(1.0, 0.2, 0.15), 1.2)
	for node in get_tree().get_nodes_in_group("enemies"):
		var other := node as Enemy
		if other and other != self and not other.alerted and not other.is_dead() \
				and other.global_position.distance_to(global_position) <= ALARM_RADIUS:
			other.hear_alarm(0.4)
	var state: StringName = state_name()
	if state == &"Patrol" or state == &"Suspicious" or state == &"Idle":
		state_machine.transition_to(&"Chase")


## Un compañero dio la alarma: se pone en alerta tras un instante (lo que tarda en reaccionar).
func hear_alarm(delay: float) -> void:
	if not alerted and _alarm_in < 0.0:
		_alarm_in = delay


## Te pierde mucho rato: deja el combate, va a mirar dónde te vio y luego vuelve a su ronda.
func calm_down() -> void:
	alerted = false
	awareness = 0.5
	_calm_timer = 0.0
	_lost_time = 0.0
	Squad.end_turn(self)
	state_machine.transition_to(&"Suspicious", {"at": last_known})


## ¿Se le puede dar un golpe mortal por sorpresa? Desprevenido y con el jugador a su espalda o costado.
func can_be_stealth_killed(by: Player) -> bool:
	if alerted or is_dead() or state_name() == &"Broken":
		return false
	var to: Vector3 = by.global_position - global_position
	to.y = 0.0
	if to.length() > STEALTH_KILL_RANGE:
		return false
	return get_facing().dot(to.normalized()) < 0.3


## Ronda: los puntos de patrulla, o su puesto si no tiene.
func patrol_route() -> PackedVector3Array:
	return patrol_points if not patrol_points.is_empty() else PackedVector3Array([_spawn.origin])


## Hacia dónde mira en su puesto (para volver a esa orientación).
func post_facing() -> Vector3:
	return post_direction


func _update_awareness(delta: float) -> void:
	if not starts_unaware or is_dead():
		return
	if alerted:
		if has_target():
			_lost_time = 0.0
			last_known = target.global_position
		else:
			_lost_time += delta
			var state: StringName = state_name()
			if _lost_time >= LOSE_TIME and (state == &"Idle" or state == &"Chase" or state == &"Circle"):
				calm_down()
		return
	if _alarm_in >= 0.0:
		_alarm_in -= delta
		if _alarm_in < 0.0:
			alert()
			return
	var sight: float = _sight_gain()
	var hearing: float = _hearing_gain()
	if sight + hearing > 0.0:
		var before: float = awareness
		awareness += (sight + hearing) * delta
		if sight <= 0.0 and distance_to_target() > HEARING_CLOSE:
			awareness = minf(awareness, maxf(before, HEARING_MAX))
		_calm_timer = 0.0
	else:
		_calm_timer += delta
		if _calm_timer >= CALM_DELAY:
			awareness -= CALM_RATE * delta
	awareness = clampf(awareness, 0.0, 1.0)
	if awareness >= 1.0:
		alert()
	elif awareness >= SUSPICIOUS_AT and state_name() == &"Patrol":
		state_machine.transition_to(&"Suspicious", {"at": last_known})


## Sospecha por segundo por lo que ve ahora (cono de visión, distancia, obstáculos, agachado).
func _sight_gain() -> float:
	if target == null or target.is_dead():
		return 0.0
	var to: Vector3 = target.global_position - global_position
	to.y = 0.0
	var dist: float = to.length()
	if dist > VIEW_RANGE or dist < 0.01 or get_facing().angle_to(to / dist) > VIEW_HALF_ANGLE or not _can_see_target():
		return 0.0
	last_known = target.global_position
	var closeness: float = 1.0 - dist / VIEW_RANGE
	return SIGHT_RATE * (0.35 + 1.65 * closeness) * (CROUCH_SIGHT if target.crouching else 1.0)


## Sospecha por segundo por lo que oye ahora (dentro del radio de ruido del jugador).
func _hearing_gain() -> float:
	if target == null or target.is_dead():
		return 0.0
	var noise: float = target.noise_radius()
	var dist: float = distance_to_target()
	if noise <= 0.0 or dist > noise:
		return 0.0
	last_known = target.global_position
	return HEAR_BASE + HEAR_RATE * (1.0 - dist / noise)


## Línea de vista desde sus ojos al pecho del jugador (agachado, más bajo: se esconde tras muros bajos).
func _can_see_target() -> bool:
	var eyes: Vector3 = global_position + Vector3.UP * 1.6
	var chest: Vector3 = target.global_position + Vector3.UP * (0.7 if target.crouching else 1.3)
	var query := PhysicsRayQueryParameters3D.create(eyes, chest, 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


# --- Signo de sospecha / alerta sobre la cabeza ---

func _build_mark() -> void:
	_mark = Label3D.new()
	_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mark.no_depth_test = true
	_mark.fixed_size = true
	_mark.pixel_size = 0.0018
	_mark.font_size = 64
	_mark.outline_size = 16
	_mark.position = Vector3.UP * 2.35
	_mark.visible = false
	add_child(_mark)


func _show_mark(text: String, color: Color, seconds: float) -> void:
	_mark.text = text
	_mark.modulate = color
	_mark.visible = true
	_mark_timer = seconds


func _update_mark(delta: float) -> void:
	if not starts_unaware:
		return
	if _mark_timer > 0.0:
		_mark_timer -= delta
		if _mark_timer <= 0.0:
			_mark.visible = false
		return
	# "?" amarillo que se llena con la sospecha.
	var showing: bool = not alerted and not is_dead() and awareness > 0.05
	_mark.visible = showing
	if showing:
		_mark.text = "?"
		_mark.modulate = Color(1.0, 0.85, 0.2, clampf(0.35 + awareness, 0.0, 1.0))


# --- Esquiva (tipos ágiles como el bandido) ----------------------------------------

## Ve EMPEZAR tu ataque (lo mismo que vería un rival real) y, según su probabilidad, se aparta de un salto
## tras un instante de reacción. Decide una vez por ataque.
func _watch_player_attack(delta: float) -> void:
	if _evade_in >= 0.0:
		_evade_in -= delta
		if _evade_in < 0.0 and _can_evade_now():
			state_machine.transition_to(&"Evade")
		return
	if target == null or evade_chance <= 0.0:
		return
	var attacking: bool = target.state_machine.current.name == &"Attack"
	if attacking and not _saw_player_attack and _can_evade_now() and distance_to_target() <= EVADE_RANGE \
			and randf() < evade_chance:
		_evade_in = EVADE_REACTION
	_saw_player_attack = attacking


func _can_evade_now() -> bool:
	var state: StringName = state_name()
	return alerted and (state == &"Idle" or state == &"Circle" or state == &"Chase")


## ¿Está demasiado cerca el jugador para su gusto (lancero, arquero)?
func too_close() -> bool:
	return keep_away_range > 0.0 and distance_to_target() < keep_away_range


## ¿Hay línea de tiro limpia hasta el jugador? (para disparar)
func has_clear_shot() -> bool:
	return _can_see_target()
