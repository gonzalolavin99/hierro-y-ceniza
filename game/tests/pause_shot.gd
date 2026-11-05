extends Node
## Herramienta: capturas del menú de pausa (principal, inventario, controles y confirmación), con ventana.
## Godot --path game res://tests/pause_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	Camps.pause_menu.reload_on_restart = false
	await get_tree().create_timer(0.5).timeout
	Camps.pause_menu.open()
	await _shot(out, "p1")
	Camps.pause_menu.call("_show", &"inventory")
	await _shot(out, "p_inv")
	Camps.pause_menu.call("_show", &"controls")
	await _shot(out, "p2")
	Camps.pause_menu.call("_show", &"confirm")
	await _shot(out, "p3")
	get_tree().paused = false
	get_tree().quit()


func _shot(out: String, name: String) -> void:
	await get_tree().create_timer(0.3, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(out.path_join(name + ".png"))
