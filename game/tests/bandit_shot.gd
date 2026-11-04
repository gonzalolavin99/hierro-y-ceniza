extends Node
## Herramienta: capturas del bandido (esquiva y embestida), con ventana.
## Godot --path game res://tests/bandit_shot.tscn -- <carpeta>

var _out: String
var _player: Player
var _bandit: Enemy


func _ready() -> void:
	_out = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player")
	for node in get_tree().get_nodes_in_group("enemies"):
		if (node as Enemy).display_name == "Bandido":
			_bandit = node
	_bandit.evade_chance = 1.0
	_bandit.mind.predictable = true
	_player.global_position = _bandit.global_position + Vector3(0.0, 0.0, -2.0)
	_player.model.rotation.y = PI
	_player.camera_rig.rotation.y = PI
	_player.reset_physics_interpolation()
	_bandit.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.8)
	Input.action_press("lock_on"); await _wait(0.05); Input.action_release("lock_on")
	await _wait(0.4)
	await _shot("b1_frente")
	Input.action_press("attack"); await _wait(0.05); Input.action_release("attack")
	await _wait(0.2)
	await _shot("b2_esquiva")
	await _wait(0.25)
	await _shot("b3_esquiva_fin")
	_bandit.state_machine.transition_to(&"Attack", {"pattern": &"lunge"})
	await _wait(0.4)
	await _shot("b4_embestida")
	get_tree().quit()


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540)
	img.save_png(_out.path_join(label + ".png"))


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout
