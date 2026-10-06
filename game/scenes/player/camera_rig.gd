class_name CameraRig
extends Node3D
## Cámara en tercera persona controlada con el stick derecho.
## Sigue al jugador suavemente y se acerca sola si hay una pared detrás (SpringArm3D).
## Con un enemigo fijado (R3) la cámara lo mantiene encuadrado.

@export var sensitivity: Vector2 = Vector2(3.2, 2.2)
@export var invert_y: bool = false
@export var height: float = 1.55
@export var follow_speed: float = 14.0
@export_range(-89.0, 0.0) var pitch_min_degrees: float = -60.0
@export_range(0.0, 89.0) var pitch_max_degrees: float = 35.0
@export var recenter_speed: float = 10.0
@export var lock_on_speed: float = 9.0
## Inclinación de la cámara al fijar (negativo = mirar un poco hacia abajo).
@export var lock_on_pitch_degrees: float = -14.0

@onready var _pitch: Node3D = $Pitch
@onready var _arm: SpringArm3D = $Pitch/SpringArm3D
@onready var camera: Camera3D = $Pitch/SpringArm3D/Camera3D

var _target: Player
var _recentering: bool = false
var _shake: float = 0.0


func _ready() -> void:
	_target = get_parent() as Player
	top_level = true
	global_position = _target.global_position + Vector3.UP * height
	_arm.add_excluded_object(_target.get_rid())
	_pitch.rotation.x = deg_to_rad(-12.0)
	CombatFX.camera_shake_requested.connect(func(strength: float) -> void: _shake = maxf(_shake, strength))


func _process(delta: float) -> void:
	# Seguir la posición interpolada para que se vea fluido a más de 60 FPS.
	var target_pos: Vector3 = _target.get_global_transform_interpolated().origin + Vector3.UP * height
	global_position = global_position.lerp(target_pos, 1.0 - exp(-follow_speed * delta))

	if _target.lock_target:
		_follow_lock_target(delta)
	else:
		_free_look(delta)
	_apply_shake(delta)


func _free_look(delta: float) -> void:
	var look: Vector2 = Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	if look.length_squared() > 0.0:
		_recentering = false
	rotation.y -= look.x * sensitivity.x * delta
	var y_sign: float = 1.0 if invert_y else -1.0
	_pitch.rotation.x = clampf(
		_pitch.rotation.x + look.y * y_sign * sensitivity.y * delta,
		deg_to_rad(pitch_min_degrees),
		deg_to_rad(pitch_max_degrees)
	)

	if _recentering:
		var behind: float = _target.model.global_rotation.y
		var weight: float = 1.0 - exp(-recenter_speed * delta)
		rotation.y = lerp_angle(rotation.y, behind, weight)
		_pitch.rotation.x = lerpf(_pitch.rotation.x, deg_to_rad(-12.0), weight)
		if absf(angle_difference(rotation.y, behind)) < 0.01:
			_recentering = false


func _follow_lock_target(delta: float) -> void:
	_recentering = false
	var to: Vector3 = _target.lock_target.lock_point() - global_position
	var desired_yaw: float = atan2(-to.x, -to.z)
	var flat: float = Vector2(to.x, to.z).length()
	var desired_pitch: float = clampf(atan2(to.y, flat) + deg_to_rad(lock_on_pitch_degrees), deg_to_rad(-45.0), deg_to_rad(15.0))
	var weight: float = 1.0 - exp(-lock_on_speed * delta)
	rotation.y = lerp_angle(rotation.y, desired_yaw, weight)
	_pitch.rotation.x = lerpf(_pitch.rotation.x, desired_pitch, weight)


func _apply_shake(delta: float) -> void:
	_shake = maxf(_shake - delta * 2.5, 0.0)
	var amount: float = _shake * _shake * 0.25
	var t: float = Time.get_ticks_msec() * 0.05
	camera.h_offset = sin(t * 1.7) * amount
	camera.v_offset = cos(t * 2.3) * amount


## Coloca la cámara detrás del personaje (R3 sin enemigos cerca).
func recenter() -> void:
	_recentering = true


func get_yaw() -> float:
	return rotation.y
