extends Node
## Herramienta: capturas de cada plano de la escena del prólogo. Con ventana (dura lo que la escena).
## Godot --path game res://tests/prologue_shot.tscn -- <carpeta>

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	await get_tree().create_timer(0.3).timeout
	var scene: PrologueScene = Story.play_prologue()
	var last: StringName = &""
	var since: float = 0.0
	var index: int = 0
	var count: int = 0
	while not scene.is_done() and count < 500:
		await get_tree().create_timer(0.25, true).timeout
		count += 1
		if scene.shot != last:
			last = scene.shot
			since = 0.0
		since += 0.25
		if is_equal_approx(since, 1.75):
			index += 1
			await _shot(out, "pro_%02d_%s" % [index, last])
	await get_tree().create_timer(1.6, true).timeout
	await _shot(out, "pro_after")
	get_tree().quit()


func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(out.path_join(name + ".png"))
