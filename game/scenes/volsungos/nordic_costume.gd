class_name NordicCostume
extends Node3D
## Original modular costume inspired by the Volsungos renders. Not a reconstructed scan.
## Each piece is placed in skeleton rest space and follows a real bone afterwards.
## Does not write bone poses, animation timing, weapon transforms or collision shapes.

const CLOTH_SHADER = preload("res://scenes/volsungos/woven_cloth.gdshader")
var attachments: Array[BoneAttachment3D] = []
var _skeleton: Skeleton3D
var _cape: ShaderMaterial


func dress(skeleton: Skeleton3D, hero: bool, accent: Color, archer: bool = false) -> void:
	if _skeleton != null:
		return
	_skeleton = skeleton
	var required := ["Hips", "Spine2", "Head", "LeftArm", "RightArm", "LeftForeArm", "RightForeArm", "LeftLeg", "RightLeg"]
	for bone: String in required:
		if skeleton.find_bone("mixamorig_" + bone) < 0:
			push_warning("NordicCostume: missing bone %s; keeping original body" % bone)
			return
	var cloth := material(Color("283a48") if hero else accent.darkened(0.15), 0.96)
	var leather := material(Color("35291f"), 0.86)
	var iron := material(Color("555b60"), 0.47, 0.72)
	var brass := material(Color("827052"), 0.45, 0.65)
	var fur := material(Color("353531"), 1.0)
	var hips := _rest("Hips")
	var chest := _rest("Spine2")
	var head := _rest("Head")
	var height := maxf(head.y + 0.22, 1.0)
	var unit := height / 1.82
	var center := Vector3(hips.x, lerpf(hips.y, chest.y, 0.57), hips.z)
	var torso_height := maxf(chest.y - hips.y, 0.25) + 0.1 * unit
	_piece("Spine2", "WoolTunic", _cone(0.235 * unit, 0.27 * unit, torso_height), center, cloth, Vector3(1, 1, 0.62))
	_piece("Hips", "TunicSkirt", _cone(0.25 * unit, 0.31 * unit, 0.29 * unit), hips + Vector3(0, -0.11, 0) * unit, cloth, Vector3(1, 1, 0.62))
	_piece("Hips", "LeatherBelt", _cone(0.258 * unit, 0.258 * unit, 0.065 * unit), hips + Vector3(0, 0.055, 0) * unit, leather, Vector3(1, 1, 0.65))
	_piece("Hips", "BeltClasp", _box(Vector3(0.075, 0.065, 0.015) * unit), hips + Vector3(0, 0.055, 0.18) * unit, brass)
	for side: String in ["Left", "Right"]:
		var shoulder := _rest(side + "Arm")
		_piece(side + "Arm", side + "Shoulder", _sphere(0.16 * unit), shoulder, fur, Vector3(1.05, 0.58, 0.95))
		var elbow := _rest(side + "ForeArm")
		var hand_index := skeleton.find_bone("mixamorig_" + side + "Hand")
		if hand_index >= 0:
			var hand := _rest(side + "Hand")
			_segment(side + "ForeArm", side + "Bracer", elbow.lerp(hand, 0.25), elbow.lerp(hand, 0.88), 0.065 * unit, leather)
		var knee := _rest(side + "Leg")
		var foot_index := skeleton.find_bone("mixamorig_" + side + "Foot")
		if foot_index >= 0:
			var foot := _rest(side + "Foot")
			_segment(side + "Leg", side + "Boot", knee.lerp(foot, 0.25), foot, 0.095 * unit, leather)
	if not hero:
		_piece("Head", "Hood" if archer else "Helmet", _sphere(0.135 * unit), head + Vector3(0, 0.1, 0) * unit, cloth if archer else iron, Vector3(1, 1.05, 1))
		if not archer:
			_piece("Head", "NoseGuard", _box(Vector3(0.028, 0.15, 0.025) * unit), head + Vector3(0, 0.04, 0.132) * unit, iron)
	# Short, light cape: no long cloth crossing knees, feet or weapon hitboxes.
	_cape = ShaderMaterial.new()
	_cape.shader = CLOTH_SHADER
	_cape.set_shader_parameter("cloth_color", Color("222b31") if hero else accent.darkened(0.35))
	var cape := PlaneMesh.new()
	cape.orientation = PlaneMesh.FACE_Z
	cape.size = Vector2(0.57, 0.64) * unit
	cape.subdivide_width = 6
	cape.subdivide_depth = 10
	_piece("Spine2", "ShortCape", cape, chest + Vector3(0, -0.24, -0.205) * unit, _cape)
	_piece("Spine2", "CapeClasp", _sphere(0.035 * unit), chest + Vector3(0.17, 0.015, 0.15) * unit, brass, Vector3(1, 1, 0.3))


func _exit_tree() -> void:
	# Attachments live under the skeleton, not this helper. Remove them on costume replacement.
	for attachment in attachments:
		if is_instance_valid(attachment) and not attachment.is_queued_for_deletion():
			attachment.queue_free()
	attachments.clear()


func _rest(bone: String) -> Vector3:
	return _skeleton.get_bone_global_rest(_skeleton.find_bone("mixamorig_" + bone)).origin


func _piece(bone: String, label: String, mesh: Mesh, at: Vector3, mat: Material, size: Vector3 = Vector3.ONE, basis: Basis = Basis.IDENTITY) -> void:
	var index := _skeleton.find_bone("mixamorig_" + bone)
	var attachment := BoneAttachment3D.new()
	attachment.name = "Volsungos_" + label
	attachment.bone_name = _skeleton.get_bone_name(index)
	_skeleton.add_child(attachment)
	attachments.append(attachment)
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = mat
	# A rest-space transform handles rigs whose arm bones use different local axes.
	instance.transform = _skeleton.get_bone_global_rest(index).affine_inverse() * Transform3D(basis.scaled_local(size), at)
	attachment.add_child(instance)


func _segment(bone: String, label: String, from: Vector3, to: Vector3, radius: float, mat: Material) -> void:
	var direction := (to - from).normalized()
	var axis := Vector3.UP.cross(direction)
	var basis := Basis.IDENTITY
	if axis.length_squared() > 0.00001:
		basis = Basis(axis.normalized(), Vector3.UP.angle_to(direction))
	elif direction.y < 0:
		basis = Basis(Vector3.RIGHT, PI)
	_piece(bone, label, _cone(radius * 0.9, radius, from.distance_to(to)), (from + to) * 0.5, mat, Vector3.ONE, basis)


static func material(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


static func _cone(top: float, bottom: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 12
	return mesh


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 12
	mesh.rings = 6
	return mesh
