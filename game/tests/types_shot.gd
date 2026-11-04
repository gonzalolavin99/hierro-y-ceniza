extends Node
## Herramienta: capturas de cerca del lancero y del arquero (armas, guardia, disparo), con ventana.
## Godot --path game res://tests/types_shot.tscn -- <carpeta>

var _out: String
var _player: Player
var _cam: Camera3D


func _ready() -> void:
	_out = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player")
	_cam = Camera3D.new()
	_cam.fov = 50.0
	add_child(_cam)
	var spear: Enemy = _find("Lancero")
	var archer: Enemy = _find("Arquero")
	for e: Enemy in [spear, archer]:
		e.mind.predictable = true
		e.state_machine.transition_to(&"Idle", {"wait": 100.0})
	# Lancero: el jugador delante; cámara de lado para ver la lanza entera.
	_player.global_position = spear.global_position + Vector3(0.0, 0.0, -3.0)
	_player.reset_physics_interpolation()
	await _wait(0.8)
	_look(spear, Vector3(4.0, 1.6, 0.5))
	await _shot("t1_lancero")
	spear.state_machine.transition_to(&"Attack", {"pattern": &"spear_thrust"})
	await _wait(0.5)
	await _shot("t2_lancero_estocada")
	spear.aggro_range = 0.0
	# Arquero: el jugador a 8 m; cámara delante-izquierda del arquero.
	_player.global_position = archer.global_position + Vector3(0.0, 0.0, -8.0)
	_player.reset_physics_interpolation()
	await _wait(0.8)
	_look(archer, Vector3(-2.2, 1.7, -2.6))
	await _shot("t3_arquero")
	archer.state_machine.transition_to(&"Shoot")
	await _wait(0.6)
	await _shot("t4_arquero_tensa")
	await _wait(0.6)
	await _shot("t5_arquero_apunta")
	await _wait(0.45)
	await _shot("t6_flecha")
	get_tree().quit()


func _look(enemy: Enemy, offset: Vector3) -> void:
	_cam.look_at_from_position(enemy.global_position + offset, enemy.global_position + Vector3.UP * 1.2)
	_cam.make_current()


func _find(display: String) -> Enemy:
	for node in get_tree().get_nodes_in_group("enemies"):
		if (node as Enemy).display_name == display:
			return node
	return null


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(_out.path_join(label + ".png"))


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout
