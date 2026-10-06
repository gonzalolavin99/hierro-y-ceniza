extends Node
## Herramienta: juega una pelea corta y guarda capturas (con ventana).
## Godot --path game res://tests/visual_check.tscn -- <carpeta>

var _out: String
var _player: Player
var _enemy: Enemy
var _n: int = 0

func _ready() -> void:
	_out = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player")
	_enemy = get_tree().get_first_node_in_group("enemies")
	await _wait(0.6)
	await _shot("01_inicio")
	Input.action_press("move_forward")
	await _wait(0.5)
	await _shot("02_corriendo")
	Input.action_release("move_forward")
	Input.action_press("lock_on"); await _wait(0.05); Input.action_release("lock_on")
	while _player.global_position.distance_to(_enemy.global_position) > 2.6:
		await get_tree().physics_frame
	await _shot("03_cerca")
	# Esperar preparación del enemigo
	for i in 400:
		await get_tree().physics_frame
		var a := _enemy.state_machine.current as EnemyAttackState
		if a and a._phase == EnemyAttackState.Phase.WINDUP and a._timer > 0.2:
			break
	await _shot("04_enemigo_prepara")
	Input.action_press("block")
	await _wait(0.4)
	await _shot("05_guardia")
	Input.action_release("block")
	await _wait(0.3)
	Input.action_press("attack"); await _wait(0.05); Input.action_release("attack")
	await _wait(0.12)
	await _shot("06_ataque")
	await _wait(0.5)
	_enemy.posture.add(1000)
	await _wait(0.8)
	await _shot("07_enemigo_roto")
	Input.action_press("attack"); await _wait(0.05); Input.action_release("attack")
	await _wait(0.2)
	await _shot("08_golpe_mortal")
	await _wait(1.2)
	await _shot("09_muerto")
	get_tree().quit()

func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(800, 450)
	img.save_png(_out.path_join(label + ".png"))

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout
