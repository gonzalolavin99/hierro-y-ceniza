class_name Player
extends CharacterBody3D
## Kael, el protagonista. Este script guarda los parámetros y las utilidades;
## qué hace en cada momento lo deciden los estados (carpeta states/).

signal deflected

@export_group("Movimiento")
@export var run_speed: float = 5.5
@export var sprint_speed: float = 8.0
## Velocidad con un enemigo fijado (camina de lado mirándolo).
@export var lock_on_speed: float = 4.6
@export var block_move_speed: float = 2.2
@export var ground_acceleration: float = 45.0
@export var ground_deceleration: float = 60.0
@export var air_acceleration: float = 12.0
## Qué tan rápido gira el personaje hacia donde se mueve.
@export var turn_speed: float = 14.0
## Orientación inicial (0 = mirando hacia -Z, 180 = hacia +Z).
@export var start_facing_degrees: float = 0.0

@export_group("Salto")
@export var jump_height: float = 1.5
@export var gravity: float = 24.0
## Multiplicador de gravedad al caer (caída más pesada, como Sekiro).
@export var fall_gravity_multiplier: float = 1.5
## Tiempo de gracia para saltar justo después de salir de una cornisa.
@export var coyote_time: float = 0.12
## Si pulsas un botón un poco antes de poder actuar, la orden se guarda este tiempo.
@export var input_buffer_time: float = 0.15

@export_group("Paso rápido")
@export var dash_distance: float = 3.6
@export var dash_duration: float = 0.28
## Segundos de invulnerabilidad desde el inicio del paso.
@export var dash_invulnerable_time: float = 0.2
@export var dash_cooldown: float = 0.15

@export_group("Guardia y desvío")
## Ventana de desvío (segundos tras pulsar LB).
@export var deflect_window: float = 0.18
## Ventana reducida si se pulsa LB repetidamente (castiga el "spam", como Sekiro).
@export var deflect_window_spam: float = 0.08
@export var spam_threshold: float = 0.35
## La postura se recupera más rápido con la guardia alta.
@export var block_posture_regen: float = 2.5

@export_group("Fijar objetivo")
@export var lock_range: float = 18.0

@export_group("Aturdimiento")
@export var stagger_duration: float = 1.2
@export var hitstun_duration: float = 0.35

@onready var model: Node3D = $Model
@onready var body: Mannequin = $Model/Mannequin
@onready var hitbox: Hitbox = $Model/Hitbox
@onready var camera_rig: CameraRig = $CameraRig
@onready var health: Health = $Health
@onready var posture: Posture = $Posture
@onready var state_machine: StateMachine = $StateMachine

var invulnerable: bool = false
## Velocidad que "pide" la animación actual (su paso real), recalculada cada frame.
var root_motion_velocity: Vector3 = Vector3.ZERO
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var attack_buffer_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var deflect_timer: float = 0.0
var lock_target: Enemy
## Último enemigo con el que hubo contacto (para mostrar sus barras).
var engaged_enemy: Enemy

var _last_block_press: float = -10.0
var _spawn_position: Vector3
var _stick_flicked: bool = false


func _ready() -> void:
	add_to_group("player")
	model.rotation.y = deg_to_rad(start_facing_degrees)
	camera_rig.rotation.y = model.rotation.y
	_spawn_position = global_position
	state_machine.setup(self)
	posture.broken.connect(_on_posture_broken)


func _physics_process(delta: float) -> void:
	coyote_timer = coyote_time if is_on_floor() else maxf(coyote_timer - delta, 0.0)
	jump_buffer_timer = input_buffer_time if Input.is_action_just_pressed("jump") else maxf(jump_buffer_timer - delta, 0.0)
	attack_buffer_timer = input_buffer_time if Input.is_action_just_pressed("attack") else maxf(attack_buffer_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	deflect_timer = maxf(deflect_timer - delta, 0.0)
	if Input.is_action_just_pressed("block"):
		_on_block_pressed()

	_update_lock_on()
	root_motion_velocity = body.consume_root_motion() / maxf(delta, 0.0001)
	state_machine.physics_update(delta)
	move_and_slide()
	body.update_locomotion(velocity, get_facing(), run_speed)

	DebugOverlay.watch("Estado", state_machine.current.name)
	DebugOverlay.watch("Velocidad", "%.1f m/s" % Vector2(velocity.x, velocity.z).length())
	DebugOverlay.watch("Objetivo", lock_target.display_name if lock_target else "—")


# --- Movimiento -------------------------------------------------------------

## Dirección de movimiento en el mundo según el stick y hacia dónde mira la cámara.
func get_move_direction() -> Vector3:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var yaw: float = camera_rig.get_yaw()
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)


## Hacia dónde mira el personaje (en el plano horizontal).
func get_facing() -> Vector3:
	return -model.global_basis.z


func apply_gravity(delta: float) -> void:
	var multiplier: float = fall_gravity_multiplier if velocity.y < 0.0 else 1.0
	velocity.y -= gravity * multiplier * delta


## Acelera la velocidad horizontal hacia `direction * speed`.
func move_horizontal(direction: Vector3, speed: float, acceleration: float, delta: float) -> void:
	var target := direction * speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = acceleration if direction.length_squared() > 0.0 else ground_deceleration
	horizontal = horizontal.move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Gira el modelo suavemente hacia una dirección.
func face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	var target_yaw: float = atan2(-direction.x, -direction.z)
	model.rotation.y = lerp_angle(model.rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))


## Aplica el avance real de la animación, frenando antes de atravesar al objetivo
## (y estirándolo un poco si está lejos, para que el golpe llegue: "magnetismo" de ataque).
func apply_root_motion(target: Node3D, stop_distance: float = 1.25) -> void:
	var motion := root_motion_velocity
	if target:
		var to := target.global_position - global_position
		to.y = 0.0
		var dist: float = to.length()
		var dir: Vector3 = to / maxf(dist, 0.001)
		var forward: float = motion.dot(dir)
		if forward > 0.0:
			if dist <= stop_distance:
				motion -= dir * forward
			elif dist > 2.5:
				motion += dir * forward * 0.35
	velocity.x = motion.x
	velocity.z = motion.z


## Gira al instante hacia una dirección.
func snap_facing(direction: Vector3) -> void:
	if direction.length_squared() > 0.001:
		model.rotation.y = atan2(-direction.x, -direction.z)


## Dirección horizontal hacia el objetivo fijado (o Vector3.ZERO).
func direction_to_lock_target() -> Vector3:
	if lock_target == null:
		return Vector3.ZERO
	var to := lock_target.global_position - global_position
	to.y = 0.0
	return to.normalized()


## Hacia dónde orientar un ataque: el objetivo fijado, si no el stick, si no el frente.
func attack_direction() -> Vector3:
	if lock_target:
		return direction_to_lock_target()
	var input_dir := get_move_direction()
	return input_dir.normalized() if input_dir.length_squared() > 0.04 else get_facing()


func jump_velocity() -> float:
	return sqrt(2.0 * gravity * jump_height)


## ¿Se puede saltar ahora? (en el suelo o recién salido de él, y con salto guardado)
func wants_jump() -> bool:
	return jump_buffer_timer > 0.0 and coyote_timer > 0.0


func do_jump() -> void:
	velocity.y = jump_velocity()
	jump_buffer_timer = 0.0
	coyote_timer = 0.0


func wants_attack() -> bool:
	return attack_buffer_timer > 0.0


func consume_attack() -> void:
	attack_buffer_timer = 0.0


# --- Combate ----------------------------------------------------------------

## Si hay un enemigo expuesto cerca, inicia el golpe mortal. Devuelve true si lo hizo.
func try_deathblow() -> bool:
	var best: Enemy = null
	var best_dist: float = 3.5
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.can_be_deathblowed():
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if enemy == lock_target:
			dist -= 1.0  # Preferir el fijado
		if dist < best_dist:
			best_dist = dist
			best = enemy
	if best == null:
		return false
	consume_attack()
	state_machine.transition_to(&"Deathblow", {"target": best})
	return true


func is_dead() -> bool:
	return state_machine.current.name == &"Dead"


## Lo llama el Hurtbox cuando un arma enemiga nos alcanza.
func receive_hit(hit: HitData) -> int:
	if is_dead() or invulnerable:
		return HitData.Result.IGNORED
	var attacker_enemy := hit.attacker as Enemy
	if attacker_enemy:
		engaged_enemy = attacker_enemy

	var to_attacker := hit.attacker.global_position - global_position
	to_attacker.y = 0.0
	to_attacker = to_attacker.normalized()
	var contact: Vector3 = global_position + Vector3.UP * 1.3 + to_attacker * 0.55
	var facing_attacker: bool = get_facing().dot(to_attacker) > 0.2
	var guarding: bool = state_machine.current.name == &"Block"

	if guarding and facing_attacker and deflect_timer > 0.0:
		# ¡Desvío! Sin daño, casi sin postura propia; el atacante la sufre.
		posture.add(hit.posture_damage * 0.25)
		Sfx.play(&"deflect", contact)
		CombatFX.sparks(contact, 30, 9.0)
		CombatFX.hitstop(0.09)
		CombatFX.shake(0.25)
		body.play_reaction(&"block_impact", 0.22, 0.05, 1.8)
		deflected.emit()
		return HitData.Result.DEFLECTED

	if guarding and facing_attacker:
		# Bloqueo: sin daño a la vida, pero la postura sube.
		posture.add(hit.posture_damage)
		Sfx.play(&"block", contact)
		CombatFX.sparks(contact, 10, 4.0)
		CombatFX.hitstop(0.04)
		CombatFX.shake(0.12)
		velocity += -to_attacker * 2.5
		body.play_reaction(&"block_impact", 0.3, 0.0, 1.4)
		return HitData.Result.BLOCKED

	health.take_damage(hit.damage)
	posture.add(hit.posture_damage * 0.5)
	Sfx.play(&"hit", contact)
	CombatFX.blood(contact)
	CombatFX.hitstop(0.06)
	CombatFX.shake(0.4)
	if health.current <= 0.0:
		state_machine.transition_to(&"Dead")
	elif state_machine.current.name != &"Stagger":
		state_machine.transition_to(&"Hitstun", {"from": to_attacker})
	return HitData.Result.HIT


func respawn() -> void:
	global_position = _spawn_position
	velocity = Vector3.ZERO
	reset_physics_interpolation()
	model.rotation = Vector3(0.0, deg_to_rad(start_facing_degrees), 0.0)
	body.stop_action(0.1)
	health.heal(health.max_health)
	posture.reset()
	lock_target = null
	camera_rig.recenter()


func _on_block_pressed() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	deflect_timer = deflect_window_spam if now - _last_block_press < spam_threshold else deflect_window
	_last_block_press = now


func _on_posture_broken() -> void:
	Sfx.play(&"posture_break", global_position + Vector3.UP * 1.2)
	if not is_dead():
		state_machine.transition_to(&"Stagger")


# --- Fijar objetivo -----------------------------------------------------------

func _update_lock_on() -> void:
	if lock_target and (lock_target.is_dead() or global_position.distance_to(lock_target.global_position) > lock_range * 1.3):
		lock_target = null

	if Input.is_action_just_pressed("lock_on"):
		if lock_target:
			lock_target = null
		else:
			lock_target = _find_lock_target(0)
			if lock_target == null:
				camera_rig.recenter()

	# Con objetivo fijado, mover el stick derecho a un lado cambia de objetivo.
	if lock_target:
		var stick_x: float = Input.get_axis("cam_left", "cam_right")
		if absf(stick_x) > 0.75 and not _stick_flicked:
			_stick_flicked = true
			var next := _find_lock_target(1 if stick_x > 0.0 else -1)
			if next:
				lock_target = next
		elif absf(stick_x) < 0.3:
			_stick_flicked = false
	if lock_target:
		engaged_enemy = lock_target


## Busca el mejor enemigo para fijar. side: 0 = el más centrado, -1/1 = hacia la izquierda/derecha.
func _find_lock_target(side: int) -> Enemy:
	var cam: Camera3D = camera_rig.camera
	var cam_forward: Vector3 = -cam.global_basis.z
	var best: Enemy = null
	var best_score: float = INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead() or enemy == lock_target:
			continue
		var to: Vector3 = enemy.lock_point() - cam.global_position
		if global_position.distance_to(enemy.global_position) > lock_range:
			continue
		var angle: float = cam_forward.angle_to(to)
		var lateral: float = cam.global_basis.x.dot(to.normalized())
		if side == 0 and angle > deg_to_rad(70.0):
			continue
		if side != 0 and signf(lateral) != float(side):
			continue
		if not _has_line_of_sight(enemy):
			continue
		var score: float = (absf(lateral) if side != 0 else angle) * 10.0 + to.length() * 0.2
		if score < best_score:
			best_score = score
			best = enemy
	return best


func _has_line_of_sight(enemy: Enemy) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.5, enemy.lock_point(), 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
