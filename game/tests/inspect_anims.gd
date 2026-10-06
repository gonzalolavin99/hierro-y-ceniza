extends SceneTree
## Inspecciona las animaciones de Mixamo: duración y desplazamiento de la cadera.

func _init() -> void:
	var dir := DirAccess.open("res://assets/animations/mixamo")
	var files := Array(dir.get_files()).filter(func(f: String) -> bool: return f.ends_with(".fbx"))
	files.sort()
	for f in files:
		var scene: Node = (load("res://assets/animations/mixamo/" + f) as PackedScene).instantiate()
		var ap := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap == null:
			print(f, ": sin AnimationPlayer")
			scene.free()
			continue
		for anim_name in ap.get_animation_list():
			var anim := ap.get_animation(anim_name)
			var hips := -1
			for i in anim.get_track_count():
				var p := str(anim.track_get_path(i))
				if p.ends_with("Hips") and anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
					hips = i
			var info := ""
			if hips >= 0:
				var a: Vector3 = anim.position_track_interpolate(hips, 0.0)
				var b: Vector3 = anim.position_track_interpolate(hips, anim.length)
				var miny := INF
				var maxy := -INF
				var tt := 0.0
				while tt <= anim.length:
					var v: Vector3 = anim.position_track_interpolate(hips, tt)
					miny = min(miny, v.y); maxy = max(maxy, v.y)
					tt += 0.05
				info = "desplaz=(%.2f, %.2f, %.2f) y[%.2f..%.2f] path=%s" % [b.x - a.x, b.y - a.y, b.z - a.z, miny, maxy, anim.track_get_path(hips)]
			print("%-22s %-14s %.2fs pistas=%d %s" % [f, anim_name, anim.length, anim.get_track_count(), info])
		scene.free()
	quit()
