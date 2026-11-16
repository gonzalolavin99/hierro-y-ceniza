class_name VolsungosReviewActor
extends Node3D
## Original articulated study for the review room only. Not a production character,
## not motion capture from the footage, and never used in place of Mixamo in combat.
var skeleton: Skeleton3D
var costume: NordicCostume
var phase: float = 0.0
var motion: int = 0
var elapsed: float = 0.0
var hero: bool = true


func _ready() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)
	_bone("Hips", "", Vector3(0, 0.94, 0))
	_bone("Spine", "Hips", Vector3(0, 1.08, 0))
	_bone("Spine1", "Spine", Vector3(0, 1.24, 0))
	_bone("Spine2", "Spine1", Vector3(0, 1.4, 0))
	_bone("Neck", "Spine2", Vector3(0, 1.5, 0))
	_bone("Head", "Neck", Vector3(0, 1.6, 0))
	for side: String in ["Left", "Right"]:
		var sign_x := 1.0 if side == "Left" else -1.0
		_bone(side + "Shoulder", "Spine2", Vector3(sign_x * 0.12, 1.4, 0))
		_bone(side + "Arm", side + "Shoulder", Vector3(sign_x * 0.25, 1.4, 0))
		_bone(side + "ForeArm", side + "Arm", Vector3(sign_x * 0.32, 1.12, 0))
		_bone(side + "Hand", side + "ForeArm", Vector3(sign_x * 0.32, 0.88, 0.04))
		_bone(side + "UpLeg", "Hips", Vector3(sign_x * 0.12, 0.9, 0))
		_bone(side + "Leg", side + "UpLeg", Vector3(sign_x * 0.12, 0.5, 0))
		_bone(side + "Foot", side + "Leg", Vector3(sign_x * 0.12, 0.1, 0.03))
	var skin := NordicCostume.material(Color("b49a80"))
	var wool := NordicCostume.material(Color("283a48") if hero else Color("6b3028"))
	var dark := NordicCostume.material(Color("302b27"))
	_part("Neck", NordicCostume._cone(0.065, 0.075, 0.16), Vector3(0, 0.045, 0), skin)
	_part("Head", NordicCostume._sphere(0.115), Vector3(0, 0.07, 0), skin, Vector3(0.85, 1.2, 0.93))
	if hero:
		var hair := NordicCostume.material(Color("59432f"))
		_part("Head", NordicCostume._sphere(0.12), Vector3(0, 0.095, -0.035), hair, Vector3(0.9, 1.13, 0.7))
		_part("Head", NordicCostume._sphere(0.078), Vector3(0, -0.005, 0.065), hair, Vector3(0.8, 0.65, 0.42))
		for x: float in [-0.037, 0.037]:
			_part("Head", NordicCostume._box(Vector3(0.022, 0.009, 0.012)), Vector3(x, 0.095, 0.1), dark)
	for side: String in ["Left", "Right"]:
		_limb(side + "Arm", side + "ForeArm", 0.085, wool)
		_limb(side + "ForeArm", side + "Hand", 0.06, wool)
		_limb(side + "UpLeg", side + "Leg", 0.105, dark)
		_limb(side + "Leg", side + "Foot", 0.07, dark)
		_part(side + "Hand", NordicCostume._sphere(0.055), Vector3.ZERO, skin, Vector3(0.7, 1.3, 1))
		_part(side + "Foot", NordicCostume._box(Vector3(0.16, 0.13, 0.3)), Vector3(0, -0.025, 0.065), dark)
	var metal := NordicCostume.material(Color("8c979e"), 0.3, 0.85)
	_part("RightHand", NordicCostume._box(Vector3(0.045, 0.74, 0.025)), Vector3(0, 0.48, 0.08), metal)
	_part("RightHand", NordicCostume._box(Vector3(0.24, 0.035, 0.055)), Vector3(0, 0.12, 0.08), metal)
	costume = NordicCostume.new()
	add_child(costume)
	costume.dress(skeleton, hero, Color("6b3028"))


func _bone(label: String, parent_name: String, at: Vector3) -> void:
	var index := skeleton.get_bone_count()
	skeleton.add_bone("mixamorig_" + label)
	var local := at
	if not parent_name.is_empty():
		var parent_index := skeleton.find_bone("mixamorig_" + parent_name)
		skeleton.set_bone_parent(index, parent_index)
		local -= skeleton.get_bone_global_rest(parent_index).origin
	skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, local))
	skeleton.set_bone_pose_position(index, local)


func _part(bone: String, mesh: Mesh, at: Vector3, mat: Material, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var follow := BoneAttachment3D.new()
	follow.bone_name = "mixamorig_" + bone
	skeleton.add_child(follow)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = at
	instance.scale = size
	follow.add_child(instance)
	return instance


func _limb(from: String, to: String, radius: float, mat: Material) -> void:
	var a := skeleton.get_bone_global_rest(skeleton.find_bone("mixamorig_" + from)).origin
	var b := skeleton.get_bone_global_rest(skeleton.find_bone("mixamorig_" + to)).origin
	var diff := b - a
	var instance := _part(from, NordicCostume._cone(radius, radius * 0.8, diff.length()), diff * 0.5, mat)
	var axis := Vector3.UP.cross(diff.normalized())
	instance.basis = Basis(axis.normalized(), Vector3.UP.angle_to(diff)) if axis.length() > 0.001 else Basis(Vector3.RIGHT, PI)


func _process(delta: float) -> void:
	elapsed += delta
	var t := elapsed + phase
	skeleton.reset_bone_poses()
	_pose("Spine2", Vector3(0.02 * sin(t * 2), 0, 0))
	if motion == 1:
		for side: String in ["Left", "Right"]:
			var sign_x := 1.0 if side == "Left" else -1.0
			var stride := sin(t * 5) * sign_x
			_pose(side + "UpLeg", Vector3(stride * 0.45, 0, 0))
			_pose(side + "Leg", Vector3(maxf(-stride, 0) * 0.6, 0, 0))
			_pose(side + "Arm", Vector3(-stride * 0.25, 0, 0))
	elif motion == 2:
		var swing := sin(t * 2.8)
		_pose("Spine2", Vector3(0.05, swing * 0.3, 0))
		_pose("RightArm", Vector3(-0.5, swing * 0.35, -0.4))
		_pose("RightForeArm", Vector3(-0.8 + swing * 0.5, 0, 0))
		_pose("LeftArm", Vector3(-0.35, 0, 0.25))
		_pose("LeftForeArm", Vector3(-0.7, 0, 0))


func _pose(bone: String, angles: Vector3) -> void:
	skeleton.set_bone_pose_rotation(skeleton.find_bone("mixamorig_" + bone), Quaternion.from_euler(angles))
