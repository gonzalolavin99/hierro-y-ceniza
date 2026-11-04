extends Node
## Herramienta: captura del menú de atributos tras descansar (con ventana).
## Godot --path game res://tests/level_menu_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	var fire := get_tree().get_first_node_in_group("campfires") as Campfire
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await get_tree().create_timer(0.5).timeout
	player.xp = 215
	player.global_position = fire.rest_position()
	player.reset_physics_interpolation()
	await get_tree().create_timer(0.3).timeout
	Input.action_press("interact"); await get_tree().create_timer(0.05).timeout; Input.action_release("interact")
	await get_tree().create_timer(4.0).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(out.path_join("m1.png"))
	get_tree().quit()
