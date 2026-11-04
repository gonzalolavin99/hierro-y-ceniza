extends Node
## Herramienta: capturas del patio de sigilo (con ventana).
## Godot --path game res://tests/stealth_shot.tscn -- <carpeta>

var _out: String
var _player: Player


func _ready() -> void:
	_out = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player")
	_player.global_position = Vector3(-27.0, 0.0, 9.5)
	_player.model.rotation.y = deg_to_rad(35.0)
	_player.camera_rig.rotation.y = deg_to_rad(35.0)
	_player.reset_physics_interpolation()
	await _wait(1.0)
	await _shot("s1_entrada")
	Input.action_press("crouch"); await _wait(0.05); Input.action_release("crouch")
	await _wait(0.6)
	await _shot("s2_agachado")
	# De pie y a la vista del guardia: aparece la sospecha.
	Input.action_press("crouch"); await _wait(0.05); Input.action_release("crouch")
	_player.global_position = Vector3(-31.0, 0.0, 12.5)
	_player.model.rotation.y = deg_to_rad(138.0)
	_player.camera_rig.rotation.y = deg_to_rad(138.0)
	_player.reset_physics_interpolation()
	for node in get_tree().get_nodes_in_group("enemies"):
		if (node as Enemy).starts_unaware:
			(node as Enemy).awareness = 0.6
	await _wait(0.7)
	await _shot("s3_sospecha")
	get_tree().quit()


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(_out.path_join(label + ".png"))


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout
