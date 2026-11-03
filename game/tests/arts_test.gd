extends Node
## Prueba automática de las técnicas (LB + RB): técnica equipada, desbloqueo, cambio con la cruceta
## y el efecto de cada técnica.
## Ejecutar: Godot --headless --path game res://tests/arts_test.tscn
## Con ventana y una carpeta guarda capturas: Godot --path game res://tests/arts_test.tscn -- <carpeta>

var _player: Player
var _enemy: Enemy
var _failures: int = 0
var _shots_dir: String = ""


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	if not OS.get_cmdline_user_args().is_empty():
		_shots_dir = OS.get_cmdline_user_args()[0]
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	await _wait(0.3)
	await _tap("lock_on")
	var arts: PlayerArts = _player.arts

	# 1. Desbloqueo: de partida solo el Torbellino.
	arts.reset_unlocked()
	_check("De partida, equipado el Torbellino", arts.equipped == &"art_whirlwind")
	_check("De partida solo hay una técnica", arts.unlocked.size() == 1)
	await _tap("art_next")
	_check("Sin otras desbloqueadas, la cruceta no cambia", arts.equipped == &"art_whirlwind")
	arts.unlock(&"art_hammer")
	await _tap("art_next")
	_check("Desbloqueado el Golpe de Martillo, la cruceta lo equipa", arts.equipped == &"art_hammer")
	arts.unlock(&"art_flurry")
	await _tap("art_next")
	_check("Cruceta otra vez: Ráfaga", arts.equipped == &"art_flurry")
	await _tap("art_next")
	_check("Y vuelve al Torbellino", arts.equipped == &"art_whirlwind")
	arts.unlock(&"art_flurry")
	_check("Desbloquear dos veces no duplica", arts.unlocked.size() == 3)

	# 2. LB + RB usa la técnica equipada.
	await _reset(2.2)
	arts.equip(&"art_hammer")
	await _art()
	_check("LB + RB ejecuta la técnica equipada (%s)" % _current_move(), _current_move() == &"art_hammer")

	# 3. Golpe de Martillo: salta y acorta distancia; mucha postura aunque bloquee.
	await _reset(4.0)
	arts.equip(&"art_hammer")
	var start: Vector3 = _player.global_position
	await _art()
	await _wait(0.6)
	await _shot("martillo")
	await _until_ground(2.5)
	var advanced: float = start.distance_to(_player.global_position)
	_check("Martillo: avanza hacia el soldado (%.1f m)" % advanced, advanced > 1.2)
	_check("Martillo: rompe mucha postura en guardia (%.0f)" % _enemy.posture.current, _enemy.posture.current >= 35.0)

	# 4. Ráfaga: tres tajos; contra un soldado expuesto, mucho daño a la vida.
	await _reset(2.0)
	arts.equip(&"art_flurry")
	_enemy.state_machine.transition_to(&"Dazed")
	await _art()
	await _wait(0.9)
	await _shot("rafaga")
	await _until_ground(3.5)
	var lost: float = _enemy.health.max_health - _enemy.health.current
	_check("Ráfaga: tres tajos con mucho daño (%.0f de vida)" % lost, lost >= 35.0)

	# 5. La Ráfaga es arriesgada: tarda en poder cancelarse con la guardia.
	await _reset(2.2)
	arts.equip(&"art_flurry")
	await _art()
	await _wait(0.8)
	Input.action_press("block")
	await _wait(0.1)
	_check("Ráfaga: a medio combo no se cancela con la guardia", _current_move() == &"art_flurry")
	Input.action_release("block")
	await _until_ground(3.5)


# --- Ayudas ---------------------------------------------------------------------

func _art() -> void:
	Input.action_press("block")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await _tap("attack")
	Input.action_release("block")
	await get_tree().physics_frame


func _current_move() -> StringName:
	var state: Node = _player.state_machine.current
	return state.get("_name") if state.name == &"Attack" else &""


func _until_ground(seconds: float) -> void:
	for i in int(seconds * 60.0):
		if _player.state_machine.current.name == &"Ground":
			return
		await get_tree().physics_frame


func _reset(dist: float) -> void:
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	_enemy.aggro_range = 0.0
	await _wait(0.4)
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	_player.model.rotation.y = 0.0
	_enemy.global_position = Vector3(0.0, 0.0, -dist)
	_enemy.model.rotation.y = PI
	_player.reset_physics_interpolation()
	_enemy.reset_physics_interpolation()
	_player.health.heal(_player.health.max_health)
	_player.posture.reset()
	_enemy.health.heal(_enemy.health.max_health)
	_enemy.posture.reset()
	_enemy.blocks_in_a_row = 0
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.4)


func _shot(label: String) -> void:
	if _shots_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.resize(800, 450)
	img.save_png(_shots_dir.path_join(label + ".png"))


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
