extends Node
## Herramienta: secuencia de capturas de la voltereta (desde quieto y corriendo), vista de lado. Con ventana.
## Godot --path game res://tests/roll_shot.tscn -- <carpeta>

var _out: String
var _cam: Camera3D
var _player: Player


func _ready() -> void:
	_out = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player") as Player
	for e in get_tree().get_nodes_in_group("enemies"):
		(e as Enemy).aggro_range = 0.0
	DebugOverlay.visible = false
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.make_current()
	await get_tree().create_timer(0.5).timeout
	# 1. Desde quieto
	_player.global_position = Vector3(-24, 0, -6)
	_player.reset_physics_interpolation()
	_cam.global_position = Vector3(-18.5, 1.3, -3.5)
	_cam.look_at(Vector3(-24, 0.7, -3.5))
	await get_tree().create_timer(0.4).timeout
	Input.action_press("move_forward")
	await get_tree().physics_frame
	Input.action_press("dodge")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("dodge")
	for i in 6:
		await get_tree().create_timer(0.12).timeout
		await _shot("r%d" % i)
	Input.action_release("move_forward")
	# 2. Corriendo
	await get_tree().create_timer(0.6).timeout
	_player.global_position = Vector3(-24, 0, -14)
	_player.reset_physics_interpolation()
	Input.action_press("move_forward")
	Input.action_press("dodge")
	await get_tree().create_timer(1.0).timeout
	Input.action_release("dodge")
	for i in 4:
		await get_tree().physics_frame
	Input.action_press("dodge")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("dodge")
	var at: Vector3 = _player.global_position
	_cam.global_position = at + Vector3(6.0, 1.3, 2.0)
	_cam.look_at(at + Vector3(0, 0.7, 2.0))
	for i in 6:
		await get_tree().create_timer(0.1).timeout
		await _shot("s%d" % i)
	Input.action_release("move_forward")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(480, 270)
	img.save_png(_out.path_join(name + ".png"))
