class_name FootGroundingModifier
extends SkeletonModifier3D
## Ajusta suavemente los tobillos al suelo después de reproducir la animación.

## Altura natural del tobillo sobre el suelo en este modelo (medida con tests/feet_probe.tscn).
@export var ankle_clearance: float = 0.107
@export var max_correction: float = 0.3
@export var ray_up: float = 0.5
@export var ray_down: float = 0.6
## Cuánto puede bajar la cadera para que el pie de abajo llegue al suelo en una pendiente.
@export var max_hips_drop: float = 0.25
## Suavizado del ajuste de cadera (evita temblores).
@export var hips_smoothing: float = 14.0
@export_flags_3d_physics var floor_collision_mask: int = 1

const LEG_NAMES: Array[Array] = [
	["mixamorig_LeftUpLeg", "mixamorig_LeftLeg", "mixamorig_LeftFoot"],
	["mixamorig_RightUpLeg", "mixamorig_RightLeg", "mixamorig_RightFoot"],
]

var _legs: Array[PackedInt32Array] = []
var _hips: int = -1
var _hips_offset: float = 0.0
var grounded_legs_last_frame: int = 0


func _ready() -> void:
	_cache_legs()


func _cache_legs() -> void:
	_legs.clear()
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null:
		return
	_hips = skeleton.find_bone("mixamorig_Hips")
	for names: Array in LEG_NAMES:
		var indices := PackedInt32Array([
			skeleton.find_bone(String(names[0])),
			skeleton.find_bone(String(names[1])),
			skeleton.find_bone(String(names[2])),
		])
		if indices[0] >= 0 and indices[1] >= 0 and indices[2] >= 0:
			_legs.append(indices)


## Técnica estándar de apoyo de pies:
## 1. Para cada pie, cuánto lo levanta la animación sobre su suelo plano ("lift").
## 2. Dónde está el suelo real bajo ese pie (rayo).
## 3. Objetivo = suelo real + altura natural del tobillo + lift (el pie levantado sigue levantado).
## 4. Si un pie tiene que bajar, se baja la cadera esa cantidad (suavizado) para que llegue.
## 5. IK de dos huesos para colocar cada tobillo en su objetivo.
func _process_modification_with_delta(delta: float) -> void:
	grounded_legs_last_frame = 0
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null or _legs.is_empty() or _hips < 0 or not is_inside_tree():
		return
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var xf: Transform3D = skeleton.global_transform
	var up_world: Vector3 = xf.basis.y.normalized()
	var targets: Array = []
	var lowest: float = 0.0
	for leg: PackedInt32Array in _legs:
		var foot_pose: Transform3D = skeleton.get_bone_global_pose(leg[2])
		var lift: float = maxf(foot_pose.origin.y - ankle_clearance, 0.0)
		var foot_world: Vector3 = xf * foot_pose.origin
		var query := PhysicsRayQueryParameters3D.create(foot_world + Vector3.UP * ray_up, foot_world - Vector3.UP * ray_down, floor_collision_mask)
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			targets.append(null)
			continue
		var target_world: Vector3 = hit["position"] + Vector3.UP * (ankle_clearance + lift)
		var correction: float = (target_world - foot_world).dot(up_world)
		if absf(correction) > max_correction:
			targets.append(null)
			continue
		targets.append(target_world)
		lowest = minf(lowest, correction)
	# Bajar la cadera lo que necesite el pie más bajo (nunca subirla).
	var wanted: float = maxf(lowest, -max_hips_drop)
	_hips_offset = lerpf(_hips_offset, wanted, 1.0 - exp(-hips_smoothing * delta))
	if absf(_hips_offset) > 0.0005:
		var hips_pose: Transform3D = skeleton.get_bone_global_pose(_hips)
		hips_pose.origin.y += _hips_offset
		skeleton.set_bone_global_pose(_hips, hips_pose)
	for i in _legs.size():
		if targets[i] == null:
			continue
		var leg: PackedInt32Array = _legs[i]
		var target_skeleton: Vector3 = xf.affine_inverse() * (targets[i] as Vector3)
		_solve_leg(skeleton, leg[0], leg[1], leg[2], target_skeleton)
		grounded_legs_last_frame += 1


func _solve_leg(skeleton: Skeleton3D, upper: int, lower: int, foot: int, target: Vector3) -> void:
	var upper_pose: Transform3D = skeleton.get_bone_global_pose(upper)
	var lower_pose: Transform3D = skeleton.get_bone_global_pose(lower)
	var foot_pose: Transform3D = skeleton.get_bone_global_pose(foot)
	var hip: Vector3 = upper_pose.origin
	var knee: Vector3 = lower_pose.origin
	var ankle: Vector3 = foot_pose.origin
	var upper_length: float = hip.distance_to(knee)
	var lower_length: float = knee.distance_to(ankle)
	if upper_length < 0.001 or lower_length < 0.001:
		return
	var to_target: Vector3 = target - hip
	var distance: float = clampf(to_target.length(), absf(upper_length - lower_length) + 0.001, upper_length + lower_length - 0.0005)
	var direction: Vector3 = to_target.normalized()
	var old_direction: Vector3 = (ankle - hip).normalized()
	var bend: Vector3 = (knee - hip) - old_direction * (knee - hip).dot(old_direction)
	if bend.length() < 0.0001:
		bend = skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_Hips")).basis.z
	var pole: Vector3 = bend - direction * bend.dot(direction)
	pole = pole.normalized() if pole.length() > 0.0001 else bend.normalized()
	var along: float = (upper_length * upper_length - lower_length * lower_length + distance * distance) / (2.0 * distance)
	var height: float = sqrt(maxf(upper_length * upper_length - along * along, 0.0))
	var new_knee: Vector3 = hip + direction * along + pole * height
	var upper_rotation: Basis = _frame_rotation(knee - hip, bend, new_knee - hip, pole) * upper_pose.basis
	var lower_rotation: Basis = _frame_rotation(ankle - knee, bend, target - new_knee, pole) * lower_pose.basis
	skeleton.set_bone_global_pose(upper, Transform3D(upper_rotation, hip))
	skeleton.set_bone_global_pose(lower, Transform3D(lower_rotation, new_knee))
	skeleton.set_bone_global_pose(foot, Transform3D(foot_pose.basis, target))


func _frame_rotation(dir_a: Vector3, plane_a: Vector3, dir_b: Vector3, plane_b: Vector3) -> Basis:
	return _frame(dir_b, plane_b) * _frame(dir_a, plane_a).inverse()


func _frame(direction: Vector3, plane: Vector3) -> Basis:
	var x: Vector3 = direction.normalized()
	var y: Vector3 = (plane - x * plane.dot(x)).normalized()
	return Basis(x, y, x.cross(y)).orthonormalized()