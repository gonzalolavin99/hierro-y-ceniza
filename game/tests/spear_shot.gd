extends Node
## Herramienta: captura del lancero en plena estocada (para ver que la punta llega). Con ventana.
## Godot --path game res://tests/spear_shot.tscn -- <carpeta>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	var spear: Enemy = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.name == "Spearman":
			spear = e
		else:
			(e as Enemy).aggro_range = 0.0
	await get_tree().create_timer(0.5).timeout
	spear.state_machine.transition_to(&"Idle", {"wait": 100.0})
	player.global_position = Vector3(-12, 0, 30)
	player.model.rotation.y = 0.0
	spear.global_position = Vector3(-12, 0, 32.6)
	spear.model.rotation.y = 0.0
	player.reset_physics_interpolation()
	spear.reset_physics_interpolation()
	player.health.max_health = 9999.0
	player.health.heal(9999.0)
	var cam := Camera3D.new()
	add_child(cam)
	cam.global_position = Vector3(-7.5, 1.6, 31.3)
	cam.look_at(Vector3(-12, 1.1, 31.3))
	cam.make_current()
	await get_tree().create_timer(0.6).timeout
	spear.state_machine.transition_to(&"Attack", {"pattern": &"spear_thrust"})
	await get_tree().create_timer(0.3).timeout
	await _shot(out, "s1")
	await get_tree().create_timer(0.3).timeout
	await _shot(out, "s2")
	get_tree().quit()


func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(out.path_join(name + ".png"))
