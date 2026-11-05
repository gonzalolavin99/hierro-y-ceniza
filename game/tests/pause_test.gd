extends Node
## Prueba automática del menú de pausa: Start / Esc lo abre y congela el juego; Continuar (o Start / B otra
## vez) lo cierra; Controles muestra la lista de botones; Empezar de nuevo pide confirmación y borra la
## partida; con el menú de atributos abierto, Esc no abre la pausa.
## Ejecutar: Godot --headless --path game res://tests/pause_test.tscn

const TEST_PATH: String = "user://save_pause_test.json"

var _player: Player
var _menu: PauseMenu
var _failures: int = 0


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	_menu = Camps.pause_menu
	_menu.reload_on_restart = false
	await _run()
	get_tree().paused = false
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	await _wait(0.4)
	# 1. Start / Esc abre el menú y congela el juego.
	await _press("pause")
	_check("Start / Esc abre el menú de pausa", _menu.is_open())
	_check("…y congela el juego", get_tree().paused)
	_check("Empieza señalando Continuar (%s)" % _menu.focused_option(), _menu.focused_option() == &"continue")
	var before: Vector3 = _player.global_position
	Input.action_press("move_forward")
	await _wait(0.4)
	Input.action_release("move_forward")
	_check("Con la pausa, Kael no se mueve", _player.global_position.distance_to(before) < 0.01)

	# 2. Continuar lo cierra y el juego sigue.
	await _press("ui_accept")
	await _wait(0.3)
	_check("Continuar cierra el menú", not _menu.is_open())
	_check("…y el juego sigue", not get_tree().paused)

	# 2b. Con el mando de verdad: A en "Continuar" reanuda, y B cierra el menú.
	await _press_pad(JOY_BUTTON_START)
	_check("Start del mando abre el menú", _menu.is_open())
	await _press_pad(JOY_BUTTON_A)
	await _wait(0.3)
	_check("A del mando en Continuar reanuda el juego", not _menu.is_open() and not get_tree().paused)
	await _press_pad(JOY_BUTTON_START)
	await _press_pad(JOY_BUTTON_B)
	await _wait(0.3)
	_check("B del mando cierra el menú", not _menu.is_open() and not get_tree().paused)

	# 3. Start otra vez también cierra; B / Esc también.
	await _press("pause")
	await _press("pause")
	await _wait(0.3)
	_check("Start con el menú abierto lo cierra", not _menu.is_open() and not get_tree().paused)
	await _press("pause")
	await _press("ui_cancel")
	await _wait(0.3)
	_check("B / Esc con el menú abierto lo cierra", not _menu.is_open() and not get_tree().paused)

	# 4. Controles: muestra la lista y B vuelve al menú.
	await _press("pause")
	await _press("ui_down")
	_check("Abajo baja a Controles (%s)" % _menu.focused_option(), _menu.focused_option() == &"controls")
	await _press("ui_accept")
	_check("Controles muestra la lista de botones", _menu.showing() == &"controls" and _menu.controls_text().contains("Vendarse"))
	await _press("ui_cancel")
	_check("B vuelve al menú (%s)" % _menu.showing(), _menu.showing() == &"main" and _menu.is_open())

	# 5. Empezar de nuevo: pide confirmación; "No" no borra nada.
	_player.xp = 500
	_player.raise_attribute(&"vigor")
	_check("Hay una partida guardada", SaveGame.exists())
	_check("Al volver queda señalado Controles (%s)" % _menu.focused_option(), _menu.focused_option() == &"controls")
	await _press("ui_down")
	_check("Abajo llega a Empezar de nuevo (%s)" % _menu.focused_option(), _menu.focused_option() == &"restart")
	await _press("ui_accept")
	_check("Pide confirmación (%s)" % _menu.showing(), _menu.showing() == &"confirm")
	_check("…señalando \"No\" por seguridad (%s)" % _menu.focused_option(), _menu.focused_option() == &"no")
	await _press("ui_accept")
	_check("\"No\" vuelve al menú sin borrar", _menu.showing() == &"main" and SaveGame.exists())

	# 6. "Sí" borra la partida y empieza de nuevo.
	await _press("ui_accept")
	await _press("ui_right")
	if _menu.focused_option() != &"yes":
		await _press("ui_down")
	_check("Se puede elegir \"Sí\" (%s)" % _menu.focused_option(), _menu.focused_option() == &"yes")
	await _press("ui_accept")
	await _wait(0.3)
	_check("\"Sí\" borra la partida guardada", not SaveGame.exists())
	_check("…cierra el menú y quita la pausa", not _menu.is_open() and not get_tree().paused)
	_check("…y pide reiniciar el nivel", _menu.restart_count == 1)

	# 7. Con el menú de atributos abierto, Esc no abre la pausa (cierra el de atributos).
	Camps.level_menu.open(_player)
	await _press("pause")
	_check("Con el menú de atributos abierto no se abre la pausa", not _menu.is_open())
	Camps.level_menu.close()


func _press(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().process_frame
	await get_tree().process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await get_tree().process_frame
	await get_tree().process_frame


func _press_pad(button: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
		await get_tree().process_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
