class_name CameraRig
extends Node3D
## Cámara en tercera persona controlada con el stick derecho.
## Sigue al jugador suavemente y se acerca sola si hay una pared detrás (SpringArm3D).
## R3 sin objetivo: recoloca la cámara detrás del personaje.

@export var sensitivity: Vector2 = Vector2(3.2, 2.2)
@export var invert_y: bool = false
@export var height: float = 1.55
@export var follow_speed: float = 14.0
@export_range(-89.0, 0.0) var pitch_min_degrees: float = -60.0
@export_range(0.0, 89.0) var pitch_max_degrees: float = 35.0
@export var recenter_speed: float = 10.0

@onready var _pitch: Node3D = $Pitch
@onready var _arm: SpringArm3D = $Pitch/SpringArm3D

var _target: Player
var _recentering: bool = false


func _ready() -> void:
	_target = get_parent() as Player
	top_level = true
	global_position = _target.global_position + Vector3.UP * height
	_arm.add_excluded_object(_target.get_rid())
	_pitch.rotation.x = deg_to_rad(-12.0)


func _process(delta: float) -> void:
	# Seguir la posición interpolada para que se vea fluido a más de 60 FPS.
	var target_pos: Vector3 = _target.get_global_transform_interpolated().origin + Vector3.UP * height
	global_position = global_position.lerp(target_pos, 1.0 - exp(-follow_speed * delta))

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

	if Input.is_action_just_pressed("lock_on"):
		_recentering = true
	if _recentering:
		var behind: float = _target.model.global_rotation.y
		rotation.y = lerp_angle(rotation.y, behind, 1.0 - exp(-recenter_speed * delta))
		_pitch.rotation.x = lerpf(_pitch.rotation.x, deg_to_rad(-12.0), 1.0 - exp(-recenter_speed * delta))
		if absf(angle_difference(rotation.y, behind)) < 0.01:
			_recentering = false


func get_yaw() -> float:
	return rotation.y
