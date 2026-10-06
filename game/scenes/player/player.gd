class_name Player
extends CharacterBody3D
## Kael, el protagonista. Este script guarda los parámetros y las utilidades de movimiento;
## qué hace en cada momento lo deciden los estados (carpeta states/).

@export_group("Movimiento")
@export var run_speed: float = 5.5
@export var sprint_speed: float = 8.0
@export var ground_acceleration: float = 45.0
@export var ground_deceleration: float = 60.0
@export var air_acceleration: float = 12.0
## Qué tan rápido gira el personaje hacia donde se mueve.
@export var turn_speed: float = 14.0

@export_group("Salto")
@export var jump_height: float = 1.5
@export var gravity: float = 24.0
## Multiplicador de gravedad al caer (caída más pesada, como Sekiro).
@export var fall_gravity_multiplier: float = 1.5
## Tiempo de gracia para saltar justo después de salir de una cornisa.
@export var coyote_time: float = 0.12
## Si pulsas saltar un poco antes de tocar el suelo, el salto se guarda este tiempo.
@export var jump_buffer_time: float = 0.12

@export_group("Paso rápido")
@export var dash_distance: float = 3.6
@export var dash_duration: float = 0.28
## Segundos de invulnerabilidad desde el inicio del paso.
@export var dash_invulnerable_time: float = 0.2
@export var dash_cooldown: float = 0.15

@export_group("Aturdimiento")
@export var stagger_duration: float = 1.2

@onready var model: Node3D = $Model
@onready var camera_rig: CameraRig = $CameraRig
@onready var health: Health = $Health
@onready var posture: Posture = $Posture
@onready var state_machine: StateMachine = $StateMachine

var invulnerable: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_cooldown_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")
	state_machine.setup(self)
	posture.broken.connect(_on_posture_broken)


func _physics_process(delta: float) -> void:
	coyote_timer = coyote_time if is_on_floor() else maxf(coyote_timer - delta, 0.0)
	jump_buffer_timer = jump_buffer_time if Input.is_action_just_pressed("jump") else maxf(jump_buffer_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)

	state_machine.physics_update(delta)
	move_and_slide()

	DebugOverlay.watch("Estado", state_machine.current.name)
	DebugOverlay.watch("Velocidad", "%.1f m/s" % Vector2(velocity.x, velocity.z).length())
	DebugOverlay.watch("Invulnerable", "SÍ" if invulnerable else "no")


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


func jump_velocity() -> float:
	return sqrt(2.0 * gravity * jump_height)


## ¿Se puede saltar ahora? (en el suelo o recién salido de él, y con salto guardado)
func wants_jump() -> bool:
	return jump_buffer_timer > 0.0 and coyote_timer > 0.0


func do_jump() -> void:
	velocity.y = jump_velocity()
	jump_buffer_timer = 0.0
	coyote_timer = 0.0


func _on_posture_broken() -> void:
	state_machine.transition_to(&"Stagger")
