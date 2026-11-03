extends SceneTree
## Mide a qué velocidad "pisa" cada animación de locomoción: mientras un pie está apoyado, se mueve
## hacia atrás respecto a la cadera a la misma velocidad a la que el cuerpo debería avanzar.
## Si el juego mueve al personaje a otra velocidad, los pies patinan.
## Ejecutar: Godot --headless --path game --script res://tests/measure_locomotion.gd

const ANIMS: Array[String] = ["walk_fwd", "walk_back", "walk_left", "walk_right", "run_fwd", "run_back", "run_left", "run_right"]


func _init() -> void:
	var bot: Node3D = (load("res://assets/animations/mixamo/y_bot.fbx") as PackedScene).instantiate()
	var sk := bot.get_node("Skeleton3D") as Skeleton3D
	# Escala del esqueleto (los FBX de Mixamo pueden venir en centímetros).
	var scale: float = (sk.global_transform.basis.get_scale().y if sk.is_inside_tree() else sk.transform.basis.get_scale().y)
	var tool := AnimPolish.new(sk)
	var lib: AnimationLibrary = load("res://assets/animations/mixamo_library.res")
	for anim_name in ANIMS:
		var anim: Animation = lib.get_animation(anim_name)
		var dt: float = 1.0 / 120.0
		var sum := Vector2.ZERO
		var count: int = 0
		var prev_support: String = ""
		var prev_pos := Vector3.ZERO
		var min_h: float = INF
		# Primera pasada: altura mínima del tobillo (pie plantado).
		var t: float = 0.0
		while t < anim.length:
			var g0: Dictionary = tool._globals(tool._locals(anim, t))
			min_h = minf(min_h, minf(g0["LeftFoot"].origin.y, g0["RightFoot"].origin.y) * scale)
			t += dt
		t = 0.0
		while t < anim.length:
			var g: Dictionary = tool._globals(tool._locals(anim, t))
			var a: Vector3 = g["LeftFoot"].origin * scale
			var b: Vector3 = g["RightFoot"].origin * scale
			var support: String = "L" if a.y < b.y else "R"
			var pos: Vector3 = a if support == "L" else b
			# Solo cuenta mientras el pie está plantado de verdad (a menos de 3 cm de su punto más bajo).
			if pos.y > min_h + 0.03:
				support = ""
			if support != "" and support == prev_support:
				var d: Vector3 = (pos - prev_pos) / dt
				sum += Vector2(d.x, d.z)
				count += 1
			prev_support = support
			prev_pos = pos
			t += dt
		# El pie apoyado va hacia atrás: el cuerpo avanza en sentido contrario. El modelo mira hacia +Z.
		var v: Vector2 = -sum / maxf(count, 1)
		print("%-11s %.2fs  tobillo mín %.3f  pisada: lateral %+.2f  adelante %+.2f  (%.2f m/s)" % [anim_name, anim.length, min_h, v.x, v.y, v.length()])
	bot.free()
	quit()
