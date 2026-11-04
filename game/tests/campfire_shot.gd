extends Node
## Herramienta: capturas del campamento y de Kael descansando (con ventana).
## Godot --path game res://tests/campfire_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	var fire := get_tree().get_first_node_in_group("campfires") as Campfire
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	var cam := Camera3D.new()
	cam.fov = 50.0
	add_child(cam)
	await get_tree().create_timer(0.5).timeout
	cam.look_at_from_position(fire.global_position + Vector3(3.5, 2.2, 4.0), fire.global_position + Vector3.UP * 0.5)
	cam.make_current()
	player.global_position = fire.rest_position() + Vector3(0.6, 0.0, 0.6)
	player.reset_physics_interpolation()
	await _shot(out, "c1", 0.6)
	Input.action_press("interact"); await get_tree().create_timer(0.05).timeout; Input.action_release("interact")
	await _shot(out, "c2", 0.45)
	await _shot(out, "c3", 0.8)
	await _shot(out, "c4", 2.5)
	get_tree().quit()


func _shot(out: String, name: String, after: float) -> void:
	await get_tree().create_timer(after).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(out.path_join(name + ".png"))
