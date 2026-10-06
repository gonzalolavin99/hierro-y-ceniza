extends SceneTree
func _init() -> void:
	var s: Node = (load("res://assets/animations/mixamo/y_bot.fbx") as PackedScene).instantiate()
	_p(s, 0)
	var sk := s.find_child("Skeleton3D", true, false) as Skeleton3D
	print("huesos: ", sk.get_bone_count())
	for i in sk.get_bone_count():
		if sk.get_bone_name(i).contains("Hand") and not sk.get_bone_name(i).contains("Thumb") and not sk.get_bone_name(i).contains("Index") and not sk.get_bone_name(i).contains("Middle") and not sk.get_bone_name(i).contains("Ring") and not sk.get_bone_name(i).contains("Pinky"):
			print(i, " ", sk.get_bone_name(i), " ", sk.get_bone_global_rest(i).origin)
	var aabb := AABB()
	for m in s.find_children("*", "MeshInstance3D", true, false):
		print("malla: ", m.name, " ", (m as MeshInstance3D).get_aabb())
	s.free()
	quit()
func _p(n: Node, d: int) -> void:
	if d < 4:
		print("  ".repeat(d), n.name, " (", n.get_class(), ")")
		for c in n.get_children(): _p(c, d + 1)
