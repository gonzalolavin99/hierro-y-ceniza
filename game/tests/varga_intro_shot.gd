extends Node
## Herramienta: capturas de cada plano de la escena antes del duelo con Varga. Con ventana.
## Godot --path game res://tests/varga_intro_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	var arena := get_tree().get_first_node_in_group("arenas") as VargaArena
	await get_tree().create_timer(0.5).timeout
	player.global_position = arena.global_position + Vector3(-11.0, 0.0, 0.0)
	player.reset_physics_interpolation()
	await get_tree().create_timer(0.6).timeout
	var intro: VargaIntro = arena.intro
	var last: StringName = &""
	var since: float = 0.0
	var index: int = 0
	while intro and is_instance_valid(intro) and not intro.is_done():
		await get_tree().create_timer(0.25).timeout
		if intro.shot != last:
			last = intro.shot
			since = 0.0
		since += 0.25
		if is_equal_approx(since, 1.5):
			index += 1
			await _shot(out, "vi_%02d_%s" % [index, last])
	await get_tree().create_timer(1.5).timeout
	await _shot(out, "vi_after")
	get_tree().quit()


func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(640, 360)
	img.save_png(out.path_join(name + ".png"))
