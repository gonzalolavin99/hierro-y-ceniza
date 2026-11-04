extends Node
## Herramienta: capturas de Kael vendándose (con ventana).
## Godot --path game res://tests/heal_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	var cam := Camera3D.new()
	cam.fov = 45.0
	add_child(cam)
	player.health.take_damage(50.0)
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await get_tree().create_timer(0.8).timeout
	cam.look_at_from_position(player.global_position + Vector3(1.6, 1.6, -2.4), player.global_position + Vector3.UP * 1.1)
	cam.make_current()
	Input.action_press("heal"); await get_tree().create_timer(0.05).timeout; Input.action_release("heal")
	for i in 3:
		await get_tree().create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.resize(960, 540)
		img.save_png(out.path_join("h%d.png" % (i + 1)))
	get_tree().quit()
