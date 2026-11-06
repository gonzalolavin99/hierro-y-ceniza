extends Node
## Herramienta: capturas del paso 3 de Frank (señalando un escondite, la despensa cerrada, Frank en el
## muro, la puerta abierta). Con ventana. Godot --path game res://tests/frank_finds_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await get_tree().create_timer(0.4).timeout
	Story.mark_heard(&"story_prologue")
	Story.mark_heard(Frank.STORY_MET)
	Story.changed.emit()
	Voice.always_speak = true
	var cache: HiddenCache
	for node in get_tree().get_nodes_in_group("hidden_caches"):
		if (node as HiddenCache).cache_id == &"behind_block":
			cache = node
	var gate := get_tree().get_first_node_in_group("latched_gates") as LatchedGate
	# 1. Frank señala el escondite detrás del bloque.
	player.global_position = cache.global_position + Vector3(2.5, 0.0, 6.5)
	player.reset_physics_interpolation()
	await get_tree().create_timer(1.2).timeout
	await _shot(out, "ff_01_point_cache")
	var cam := Camera3D.new()
	add_child(cam)
	cam.global_position = cache.global_position + Vector3(1.6, 1.3, -1.6)
	cam.look_at(cache.global_position + Vector3.UP * 0.2)
	cam.make_current()
	await get_tree().create_timer(0.2).timeout
	await _shot(out, "ff_02_cache")
	cam.queue_free()
	# 2. La despensa cerrada, desde fuera.
	player.global_position = gate.outside_point() + (gate.outside_point() - gate.global_position).normalized() * 2.0
	player.reset_physics_interpolation()
	player.model.global_rotation.y = atan2(-(gate.global_position - player.global_position).x, -(gate.global_position - player.global_position).z)
	player.camera_rig.global_rotation.y = player.model.global_rotation.y
	await get_tree().create_timer(1.0).timeout
	await _shot(out, "ff_03_store_closed")
	player.global_position = gate.outside_point()
	player.reset_physics_interpolation()
	await get_tree().create_timer(0.3).timeout
	gate.frank_opens()
	await get_tree().create_timer(0.7).timeout
	await _shot(out, "ff_04_frank_wall")
	await get_tree().create_timer(2.6).timeout
	await _shot(out, "ff_05_open")
	get_tree().quit()


func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(640, 360)
	img.save_png(out.path_join(name + ".png"))
