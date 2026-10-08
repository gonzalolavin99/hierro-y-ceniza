extends Node3D
## Herramienta: original (izquierda) vs retocada (derecha) en los mismos instantes.
## Godot --path game res://tests/polish_preview.tscn -- <carpeta> <archivo_fbx> <nombre_en_biblioteca> <t1,t2,...>
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0]
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.27, 0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 40, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var fl := MeshInstance3D.new()
	fl.mesh = PlaneMesh.new()
	(fl.mesh as PlaneMesh).size = Vector2(12, 12)
	add_child(fl)
	var bots: Array[AnimationPlayer] = []
	for i in 2:
		var bot: Node3D = (load("res://assets/animations/mixamo/y_bot.fbx") as PackedScene).instantiate()
		add_child(bot)
		bot.position.x = -0.9 if i == 0 else 0.9
		var ap := bot.get_node("AnimationPlayer") as AnimationPlayer
		var lib := AnimationLibrary.new()
		if i == 0:
			var s: Node = (load("res://assets/animations/mixamo/%s.fbx" % a[1]) as PackedScene).instantiate()
			var anim: Animation = (s.get_node("AnimationPlayer") as AnimationPlayer).get_animation("mixamo_com").duplicate(true)
			s.free()
			var hips := anim.find_track(NodePath("Skeleton3D:mixamorig_Hips"), Animation.TYPE_POSITION_3D)
			var first: Vector3 = anim.track_get_key_value(hips, 0)
			for k in anim.track_get_key_count(hips):
				var v: Vector3 = anim.track_get_key_value(hips, k)
				anim.track_set_key_value(hips, k, Vector3(first.x, v.y, first.z))
			lib.add_animation("x", anim)
		else:
			var polished: AnimationLibrary = load("res://assets/animations/mixamo_library.res")
			lib.add_animation("x", polished.get_animation(a[2]))
		ap.add_animation_library("p", lib)
		ap.play("p/x")
		ap.pause()
		bots.append(ap)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 45
	get_window().size = Vector2i(900, 600)
	for ts in a[3].split(","):
		var t := float(ts)
		for ap in bots:
			ap.seek(t, true)
		for view in [["frente", Vector3(0, 1.3, 4.2)], ["lado", Vector3(4.5, 1.3, 0.3)]]:
			cam.look_at_from_position(view[1], Vector3(0, 0.95, 0))
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join("%s_%s_%s.png" % [a[2], ts, view[0]]))
	get_tree().quit()
