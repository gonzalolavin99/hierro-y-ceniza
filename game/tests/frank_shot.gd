extends Node
## Herramienta: capturas de Frank (en la red, cada plano de la escena y en el hombro de Kael). Con ventana.
## Godot --path game res://tests/frank_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	var snare := get_tree().get_first_node_in_group("frank_snare") as FrankSnare
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await get_tree().create_timer(0.5).timeout
	Story.mark_heard(&"story_prologue")
	# 1. La red, desde donde se acerca Kael.
	var cam := Camera3D.new()
	add_child(cam)
	cam.global_position = snare.kael_spot() + Vector3.UP * 1.7 + (snare.kael_spot() - snare.global_position).normalized() * 1.5
	cam.look_at(snare.bag_position())
	cam.make_current()
	await get_tree().create_timer(0.5).timeout
	await _shot(out, "fr_01_net")
	cam.global_position = snare.bag_position() + (snare.kael_spot() - snare.global_position).normalized() * 0.7 + Vector3.UP * 0.05
	cam.look_at(snare.bag_position() + Vector3.DOWN * 0.05)
	await get_tree().create_timer(0.3).timeout
	await _shot(out, "fr_02_net_close")
	cam.queue_free()
	player.global_position = snare.kael_spot()
	player.reset_physics_interpolation()
	await get_tree().create_timer(0.3).timeout
	var scene: FrankMeet = snare.free_frank()
	var last: StringName = &""
	var since: float = 0.0
	var index: int = 2
	while scene and is_instance_valid(scene) and not scene.is_done():
		await get_tree().create_timer(0.25).timeout
		if scene.shot != last:
			last = scene.shot
			since = 0.0
		since += 0.25
		if is_equal_approx(since, 1.0):
			index += 1
			await _shot(out, "fr_%02d_%s" % [index, last])
	await get_tree().create_timer(1.5).timeout
	await _shot(out, "fr_20_gameplay")
	# En el hombro, visto de cerca de frente y desde atrás.
	var c2 := Camera3D.new()
	add_child(c2)
	var fw: Vector3 = -player.model.global_basis.z
	var left: Vector3 = Vector3.UP.cross(fw).normalized()
	var at: Vector3 = player.frank.global_position
	c2.global_position = at + fw * 1.0 + left * 0.5 + Vector3.UP * 0.1
	c2.look_at(at + Vector3.UP * 0.12)
	c2.make_current()
	await get_tree().create_timer(0.3).timeout
	await _shot(out, "fr_21_shoulder_front")
	c2.global_position = at - fw * 1.2 + left * 0.6 + Vector3.UP * 0.3
	c2.look_at(at + Vector3.UP * 0.1)
	await get_tree().create_timer(0.3).timeout
	await _shot(out, "fr_22_shoulder_back")
	get_tree().quit()


func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(640, 360)
	img.save_png(out.path_join(name + ".png"))
