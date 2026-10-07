class_name Enemy
extends CharacterBody3D
## Enemigo humano base. Bloquea cuando no está atacando (como en Sekiro): la forma de vencerlo
## es presionar su postura con ataques y desvíos hasta romperla, y entonces dar el golpe mortal.

signal died

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

@onready var model: Node3D = $Model
@onready var body: Mannequin = $Model/Mannequin
@onready var hitbox: Hitbox = $Model/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: Health = $Health
@onready var posture: Posture = $Posture
@onready var state_machine: StateMachine = $StateMachine
@onready var _lock_point: Marker3D = $LockPoint
@onready var _body_collision: CollisionShape3D = $Collision

var target: Player
var blocks_in_a_row: int = 0
## Velocidad que "pide" la animación actual (su paso real).
var root_motion_velocity: Vector3 = Vector3.ZERO
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


func _physics_process(delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Player
	# Con poca vida, la postura se recupera más lento (como en Sekiro).
	posture.regen_multiplier = 0.25 + 0.75 * health.ratio()
	velocity.y -= gravity * delta
	root_motion_velocity = body.consume_root_motion() / maxf(delta, 0.0001)
	state_machine.physics_update(delta)
	move_and_slide()
	body.update_locomotion(velocity, get_facing(), walk_speed * 1.4)


# --- Utilidades para los estados ------------------------------------------------

func has_target() -> bool:
	return target != null and not target.is_dead() and distance_to_target() <= aggro_range


func distance_to_target() -> float:
	return global_position.distance_to(target.global_position) if target else INF


func direction_to_target() -> Vector3:
	var to: Vector3 = target.global_position - global_position
	to.y = 0.0
	return to.normalized()


func get_facing() -> Vector3:
	return -model.global_basis.z


func face_target(delta: float, speed_multiplier: float = 1.0) -> void:
	var dir: Vector3 = direction_to_target()
	if dir.length_squared() < 0.001:
		return
	var yaw: float = atan2(-dir.x, -dir.z)
	model.rotation.y = lerp_angle(model.rotation.y, yaw, 1.0 - exp(-turn_speed * speed_multiplier * delta))


func move_horizontal(direction: Vector3, speed: float, delta: float, acceleration: float = 30.0) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(direction * speed, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Aplica el avance real de la animación, frenando antes de atravesar al jugador
## y estirándolo si está lejos para que el ataque llegue.
func apply_root_motion(stop_distance: float = 1.3) -> void:
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
	if state == &"Dead" or state == &"Broken":
		return HitData.Result.IGNORED

	var to_attacker: Vector3 = hit.attacker.global_position - global_position
	to_attacker.y = 0.0
	to_attacker = to_attacker.normalized()
	var contact: Vector3 = global_position + Vector3.UP * 1.3 + to_attacker * 0.55
	var facing_attacker: bool = get_facing().dot(to_attacker) > 0.0

	# Fuera de sus ataques, bloquea todo lo que tenga de frente.
	if state != &"Attack" and state != &"Recoil" and facing_attacker:
		posture.add(hit.posture_damage)
		Sfx.play(&"block", contact)
		CombatFX.sparks(contact, 10, 4.0)
		CombatFX.hitstop(0.035)
		body.play_reaction(&"block_impact", 0.25, 0.0, 1.5)
		blocks_in_a_row += 1
		if blocks_in_a_row >= blocks_before_counter and not posture.is_broken:
			blocks_in_a_row = 0
			state_machine.transition_to(&"Attack", {"pattern": &"counter"})
		return HitData.Result.BLOCKED

	# Golpe directo (atacando, retrocediendo o de espaldas).
	health.take_damage(hit.damage)
	posture.add(hit.posture_damage * (1.0 if state == &"Recoil" else 0.5))
	Sfx.play(&"hit", contact)
	CombatFX.blood(contact)
	CombatFX.hitstop(0.05)
	return HitData.Result.HIT


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
	set_vulnerable(true)


func _on_hit_landed(result: int, _hurtbox: Hurtbox) -> void:
	var attack := state_machine.current as EnemyAttackState
	if result == HitData.Result.DEFLECTED and attack:
		attack.on_deflected()


func _on_posture_broken() -> void:
	if not is_dead():
		state_machine.transition_to(&"Broken")


func _on_health_depleted() -> void:
	if not is_dead():
		state_machine.transition_to(&"Broken")
