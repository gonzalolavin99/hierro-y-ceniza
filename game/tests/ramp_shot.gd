extends Node
func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	var p: Player = get_tree().get_first_node_in_group("player")
	p.global_position = Vector3(-12.0, 1.5, -6.0)
	p.model.rotation.y = 0.0
	p.camera_rig.rotation.y = deg_to_rad(-80)
	p.reset_physics_interpolation()
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/rampa_quieto.png")
	Input.action_press("move_forward")
	await get_tree().create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/rampa_caminando.png")
	get_tree().quit()
