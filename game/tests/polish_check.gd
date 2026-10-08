extends SceneTree
## Verifica el taller de animación (AnimPolish).
func _init() -> void:
	var bot: Node = (load("res://assets/animations/mixamo/y_bot.fbx") as PackedScene).instantiate()
	var sk := bot.get_node("Skeleton3D") as Skeleton3D
	var tool := AnimPolish.new(sk)
	for file in ["idle", "slash", "x_one_hand_combo"]:
		var src: Node = (load("res://assets/animations/mixamo/%s.fbx" % file) as PackedScene).instantiate()
		var orig: Animation = (src.get_node("AnimationPlayer") as AnimationPlayer).get_animation("mixamo_com")
		for cfg in [{}, {"hips_drop": 0.06}, {"cut_emphasis": {"impacts": [0.53], "hips": 12.0, "spine": 10.0}}]:
			var a: Animation = orig.duplicate(true)
			var rep := tool.polish(a, cfg.duplicate(true))
			var d := {"Hips": 0.0, "LeftLeg": 0.0, "LeftFoot": 0.0, "RightHand": 0.0}
			var t := 0.0
			while t < orig.length:
				var g0 := tool._globals(tool._locals(orig, t))
				var g1 := tool._globals(tool._locals(a, t))
				for b in d:
					d[b] = maxf(d[b], g0[b].origin.distance_to(g1[b].origin))
				t += 0.05
			print("%-18s %-55s pies_err=%.4f  desvío: cadera=%.3f rodilla=%.3f pie=%.4f mano=%.3f" % [file, JSON.stringify(cfg), rep["pies_error_max"], d["Hips"], d["LeftLeg"], d["LeftFoot"], d["RightHand"]])
		src.free()
	bot.free()
	quit()
