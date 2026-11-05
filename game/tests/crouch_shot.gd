extends Node
## Herramienta: capturas de Kael agachado (quieto y caminando), vistas de lado. Con ventana.
## Godot --path game res://tests/crouch_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	for e in get_tree().get_nodes_in_group("enemies"):
		(e as Enemy).aggro_range = 0.0
	await get_tree().create_timer(0.5).timeout
	player.global_position = Vector3(-20, 0, 0)
	player.reset_physics_interpolation()
	var cam := Camera3D.new()
	add_child(cam)
	cam.make_current()
	Input.action_press("crouch")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("crouch")
	await get_tree().create_timer(0.8).timeout
	cam.global_position = player.global_position + Vector3(4.0, 1.2, 0.0)
	cam.look_at(player.global_position + Vector3.UP * 0.8)
	await _shot(out, "c1")
	Input.action_press("move_forward")
	await get_tree().create_timer(0.9).timeout
	for name in ["c2", "c3"]:
		cam.global_position = player.global_position + Vector3(4.0, 1.2, 0.0)
		cam.look_at(player.global_position + Vector3.UP * 0.8)
		await _shot(out, name)
		await get_tree().create_timer(0.27).timeout
	Input.action_release("move_forward")
	get_tree().quit()


func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(out.path_join(name + ".png"))
