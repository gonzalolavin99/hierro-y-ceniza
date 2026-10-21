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
## Tiempo que tarda la cámara en pasar del modo libre al modo fijado (y al revés).
@export var lock_blend_time: float = 0.4
## Al fijar, la cámara se aparta a la derecha del jugador para que no tape al enemigo (metros).
@export var lock_side_offset: float = 1.2
## Al fijar, el centro de la cámara se adelanta hacia el enemigo (fracción de la distancia).
@export var lock_focus_bias: float = 0.3
## En peleas cercanas la cámara se aleja un poco y mira algo más desde arriba.
@export var close_range: float = 3.0
@export var close_extra_length: float = 0.3
@export var close_extra_pitch_degrees: float = -6.0

@onready var _pitch: Node3D = $Pitch
@onready var _arm: SpringArm3D = $Pitch/SpringArm3D
@onready var camera: Camera3D = $Pitch/SpringArm3D/Camera3D

var _target: Player
var _recentering: bool = false
var _shake: float = 0.0
## 0 = cámara libre, 1 = totalmente fijada. Sube y baja poco a poco para suavizar la transición.
var _lock_amount: float = 0.0
var _lock_offset: Vector3 = Vector3.ZERO
var _lock_dir: Vector3 = Vector3.FORWARD
var _lock_forward: float = 0.0
var _clip_scale: float = 1.0
var _base_length: float
var _close_pitch: float = 0.0
var _last_lock_target: Enemy
var _last_desired_yaw: float = 0.0


func _ready() -> void:
	_target = get_parent() as Player
	top_level = true
	global_position = _target.global_position + Vector3.UP * height
	_arm.add_excluded_object(_target.get_rid())
	_pitch.rotation.x = deg_to_rad(-12.0)
	_base_length = _arm.spring_length
	CombatFX.camera_shake_requested.connect(func(strength: float) -> void: _shake = maxf(_shake, strength))


func _process(delta: float) -> void:
	# Seguir la posición interpolada para que se vea fluido a más de 60 FPS.
	var target_pos: Vector3 = _target.get_global_transform_interpolated().origin + Vector3.UP * height
	_update_lock_amount(delta)
	_update_lock_offset(target_pos, delta)
	global_position = global_position.lerp(target_pos + _lock_offset, 1.0 - exp(-follow_speed * delta))

	if _target.lock_target:
		_follow_lock_target(delta)
	else:
		_last_lock_target = null
		_free_look(delta)
	_apply_shake(delta)


func _update_lock_amount(delta: float) -> void:
	var goal: float = 1.0 if _target.lock_target else 0.0
	_lock_amount = move_toward(_lock_amount, goal, delta / lock_blend_time)


## Mezcla suave en forma de S: arranca y termina despacio.
func _eased_lock() -> float:
	return smoothstep(0.0, 1.0, _lock_amount)


## Calcula cuánto se aparta la cámara al fijar. Se suavizan las cantidades (no la flecha), y la
## dirección se recalcula en cada fotograma: así, al rodear al enemigo, la cámara no se queda atrás.
func _update_lock_offset(pivot: Vector3, delta: float) -> void:
	var closeness: float = 0.0
	var forward: float = 0.0
	var lock: Enemy = _target.lock_target
	if lock:
		var to: Vector3 = lock.global_position - _target.global_position
		to.y = 0.0
		var dist: float = to.length()
		if dist > 0.01:
			_lock_dir = to / dist
		closeness = clampf(1.0 - (dist - 1.0) / (close_range - 1.0), 0.0, 1.0)
		# Adelantarse hacia el enemigo, pero sin acercarse a menos de 1,6 m de él (giros bruscos).
		forward = clampf(dist * lock_focus_bias, 0.0, maxf(dist - 1.6, 0.0))
	var weight: float = 1.0 - exp(-follow_speed * delta)
	_lock_forward = lerpf(_lock_forward, forward, weight)
	var right := Vector3(-_lock_dir.z, 0.0, _lock_dir.x)
	var offset: Vector3 = (_lock_dir * _lock_forward + right * lock_side_offset) * _eased_lock()
	_clip_scale = lerpf(_clip_scale, _clip_fraction(pivot, offset), weight)
	_lock_offset = offset * _clip_scale
	var close: float = closeness * _eased_lock()
	_arm.spring_length = lerpf(_arm.spring_length, _base_length + close_extra_length * close, 1.0 - exp(-6.0 * delta))
	_close_pitch = deg_to_rad(close_extra_pitch_degrees) * close


## Qué parte del desplazamiento cabe sin meterse en una pared (1 = todo), para no atravesarla.
func _clip_fraction(pivot: Vector3, offset: Vector3) -> float:
	var length: float = offset.length()
	if length < 0.01:
		return 1.0
	var query := PhysicsRayQueryParameters3D.create(pivot, pivot + offset * 1.25, 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return 1.0
	return clampf((pivot.distance_to(hit.position) / 1.25 - 0.25) / length, 0.0, 1.0)


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
	var desired_pitch: float = clampf(atan2(to.y, flat) + deg_to_rad(lock_on_pitch_degrees) + _close_pitch, deg_to_rad(-45.0), deg_to_rad(15.0))
	# Anticipación: acompañar el giro que ya está ocurriendo (p. ej. al rodear al enemigo) para no
	# quedarse atrás; el suavizado solo corrige lo que falte.
	if _target.lock_target == _last_lock_target:
		rotation.y += angle_difference(_last_desired_yaw, desired_yaw) * _eased_lock()
	_last_lock_target = _target.lock_target
	_last_desired_yaw = desired_yaw
	# Al empezar a fijar, la cámara acelera poco a poco en vez de girar de golpe.
	var weight: float = (1.0 - exp(-lock_on_speed * delta)) * lerpf(0.08, 1.0, _eased_lock())
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
