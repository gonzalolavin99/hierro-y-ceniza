extends Node3D
## Herramienta: genera una tira de 8 capturas por animación para revisarlas.
## Ejecutar (con ventana): Godot --path game res://tests/anim_preview.tscn -- <carpeta_salida> [anim1,anim2,...]

const FRAMES: int = 8
const SIZE: int = 260

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://anim_preview"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var only: PackedStringArray = args[1].split(",") if args.size() > 1 else PackedStringArray()

	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.27, 0.3)
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	(floor_mesh.mesh as PlaneMesh).size = Vector2(10, 10)
	add_child(floor_mesh)

	var bot: Node3D = (load("res://assets/animations/mixamo/y_bot.fbx") as PackedScene).instantiate()
	add_child(bot)
	var ap := bot.get_node("AnimationPlayer") as AnimationPlayer
	var lib := AnimationLibrary.new()
	var dir := DirAccess.open("res://assets/animations/mixamo")
	for f in dir.get_files():
		if not f.ends_with(".fbx") or f == "y_bot.fbx":
			continue
		var key := f.get_basename()
		if not only.is_empty() and not only.has(key):
			continue
		var s: Node = (load("res://assets/animations/mixamo/" + f) as PackedScene).instantiate()
		lib.add_animation(key, (s.get_node("AnimationPlayer") as AnimationPlayer).get_animation("mixamo_com").duplicate())
		s.free()
	ap.add_animation_library("p", lib)

	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 50
	get_window().size = Vector2i(SIZE * 2, SIZE * 2)

	var names := Array(lib.get_animation_list())
	names.sort()
	for n in names:
		var anim := lib.get_animation(n)
		var sheet := Image.create(SIZE * FRAMES, SIZE, false, Image.FORMAT_RGB8)
		ap.play("p/" + n)
		ap.pause()
		for i in FRAMES:
			var t: float = anim.length * float(i) / float(FRAMES - 1)
			ap.seek(t, true)
			var hips: Vector3 = bot.get_node("Skeleton3D").get_bone_global_pose(0).origin
			# Vista 3/4 desde el frente-derecha del personaje (que mira hacia +Z)
			cam.look_at_from_position(Vector3(hips.x - 2.6, 1.7, hips.z + 3.6), Vector3(hips.x, 1.0, hips.z))
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.resize(SIZE, SIZE)
			img.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(img, Rect2i(0, 0, SIZE, SIZE), Vector2i(i * SIZE, 0))
		sheet.save_png(out_dir.path_join(n + ".png"))
		print("ok ", n, " (%.2fs)" % anim.length)
	get_tree().quit()
