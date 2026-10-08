extends SceneTree
func _init() -> void:
	for d in ["forward", "backward", "left", "right"]:
		var s: Node = (load("res://assets/animations/mixamo/dodge_%s.fbx" % d) as PackedScene).instantiate()
		var a: Animation = (s.get_node("AnimationPlayer") as AnimationPlayer).get_animation("mixamo_com")
		var tr := a.find_track(NodePath("Skeleton3D:mixamorig_Hips"), Animation.TYPE_POSITION_3D)
		var p0: Vector3 = a.position_track_interpolate(tr, 0.0)
		var line := ""
		var t := 0.0
		while t <= a.length + 0.001:
			var p: Vector3 = a.position_track_interpolate(tr, t)
			line += " %.1f:%.2f" % [t, Vector2(p.x - p0.x, p.z - p0.z).length()]
			t += 0.1
		print(d, line)
		s.free()
	quit()
