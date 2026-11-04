extends Node
## Herramienta: capturas de la experiencia (HUD con "+N") y del morral caído (con ventana).
## Godot --path game res://tests/xp_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	var enemy := get_tree().get_first_node_in_group("enemies") as Enemy
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await get_tree().create_timer(0.5).timeout
	enemy.receive_deathblow(player)
	await _shot(out, "x1", 0.4)
	var bag_at: Vector3 = player.global_position + Vector3(3.0, 0.0, -2.0)
	XpSatchel.spawn(get_tree().current_scene, bag_at, 40)
	var cam := Camera3D.new()
	cam.fov = 50.0
	add_child(cam)
	cam.look_at_from_position(bag_at + Vector3(2.0, 1.4, 2.4), bag_at + Vector3.UP * 0.5)
	cam.make_current()
	player.global_position = bag_at + Vector3(-1.5, 0.0, 2.5)
	player.reset_physics_interpolation()
	await _shot(out, "x2", 0.6)
	get_tree().quit()


func _shot(out: String, name: String, after: float) -> void:
	await get_tree().create_timer(after).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(out.path_join(name + ".png"))
