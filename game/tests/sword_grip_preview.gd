extends Node3D
## Herramienta: muestra el maniquí con 3 hojas de colores (X rojo, Y verde, Z azul) en la mano
## para decidir la orientación de la espada.

func _ready() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.27, 0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	add_child(env)
	var bot: Node3D = (load("res://assets/animations/mixamo/y_bot.fbx") as PackedScene).instantiate()
	add_child(bot)
	var sk := bot.get_node("Skeleton3D") as Skeleton3D
	var att := BoneAttachment3D.new()
	att.bone_name = "mixamorig_RightHand"
	sk.add_child(att)
	for axis in 3:
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		var size := Vector3(0.03, 0.03, 0.03)
		size[axis] = 1.0
		box.size = size
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = [Color.RED, Color.GREEN, Color.BLUE][axis]
		box.material = mat
		m.mesh = box
		var off := Vector3.ZERO
		off[axis] = 0.5
		m.position = off
		att.add_child(m)
	var ap := bot.get_node("AnimationPlayer") as AnimationPlayer
	ap.add_animation_library("m", load("res://assets/animations/mixamo_library.res"))
	var cam := Camera3D.new()
	add_child(cam)
	get_window().size = Vector2i(600, 600)
	for pose in [["idle", 0.5], ["block_hold", 0.3], ["slash_a", 0.53], ["run_fwd", 0.2]]:
		ap.play("m/" + pose[0])
		ap.seek(pose[1], true)
		ap.pause()
		for view in [["front", Vector3(-1.2, 1.5, 2.6)], ["side", Vector3(2.8, 1.5, 0.4)]]:
			cam.look_at_from_position(view[1], Vector3(0, 1.1, 0))
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s_%s.png" % [pose[0], view[0]]))
	get_tree().quit()
