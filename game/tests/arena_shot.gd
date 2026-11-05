extends Node
## Herramienta: capturas de la arena de Varga (vista general, entrada y duelo con su barra). Con ventana.
## Godot --path game res://tests/arena_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	var arena := get_tree().get_first_node_in_group("arenas") as VargaArena
	DebugOverlay.visible = false
	await get_tree().create_timer(0.5).timeout
	var cam := Camera3D.new()
	add_child(cam)
	cam.make_current()
	cam.global_position = arena.global_position + Vector3(-24.0, 14.0, 18.0)
	cam.look_at(arena.global_position + Vector3(2.0, 0.0, 0.0))
	await _shot(out, "a1")
	cam.global_position = arena.global_position + Vector3(-29.0, 2.0, 1.5)
	cam.look_at(arena.global_position + Vector3(0.0, 1.5, 0.0))
	await _shot(out, "a2")
	cam.queue_free()
	player.global_position = arena.global_position + Vector3(-10.0, 0.0, 0.0)
	player.reset_physics_interpolation()
	player.lock_target = arena.varga
	await get_tree().create_timer(3.0).timeout
	await _shot(out, "a3")
	get_tree().quit()


func _shot(out: String, name: String) -> void:
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(out.path_join(name + ".png"))
