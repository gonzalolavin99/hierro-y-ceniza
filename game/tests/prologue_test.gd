extends Node
## Prueba automática de la escena del prólogo: solo sale en partida nueva de la escena principal, pausa el
## juego, recorre sus planos (fogata, sala, primeros planos de Kael y del Regente, cinta, título), se puede saltar manteniendo A, no deja
## abrir el menú de pausa, y al terminar queda marcada como vista (y guardada).
## Ejecutar: Godot --headless --path game res://tests/prologue_test.tscn

const TEST_PATH: String = "user://save_prologue_test.json"

var _player: Player
var _failures: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player") as Player
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await _wait(0.4)
	await _run()
	Engine.time_scale = 1.0
	get_tree().paused = false
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	_check("En las pruebas no sale sola (no es la escena principal)", get_tree().get_node_count_in_group("cutscene") == 0 and not Story.should_play_prologue())
	_check("Kael lleva la cinta de Lira en la muñeca", _player.body.find_child("Ribbon", true, false) != null)

	# 1. Saltarla: pausa el juego; Start no abre el menú de pausa; mantener A 1 s la salta.
	var scene: PrologueScene = Story.play_prologue()
	await _wait(0.3)
	_check("Pausa el juego mientras dura", get_tree().paused)
	_check("Empieza en la fogata (%s)" % scene.shot, scene.shot == &"fire")
	_tap("pause")
	await _wait(0.2)
	_check("Start no abre el menú de pausa durante la escena", not Camps.pause_menu.is_open())
	Input.action_press("ui_accept")
	await _wait(0.5)
	_check("Un toque corto no la salta", not scene.is_done())
	await _wait(0.8)
	Input.action_release("ui_accept")
	_check("Mantener A la salta", scene.is_done())
	_check("…y el juego sigue", not get_tree().paused)
	_check("Queda vista (no se repite)", Story.heard(&"scene_prologue") and not Story.should_play_prologue())
	_check("La zona del inicio no repite la frase del prólogo", Story.heard(&"story_prologue"))
	_check("Se guarda al terminar", "scene_prologue" in SaveGame.read().get("story", {}).get("heard", []))
	await _wait(1.6)
	_check("La escena se quita del todo", get_tree().get_node_count_in_group("cutscene") == 0)

	# 2. Entera (a velocidad x4): pasa por todos los planos y termina sola.
	Story.reset()
	Engine.time_scale = 4.0
	scene = Story.play_prologue()
	var shots: Array[StringName] = []
	for i in 400:  # Hasta 40 s reales (la escena dura ~40 s a velocidad normal; aquí, ~10 s).
		await _wait(0.1)
		if not scene.shot in shots:
			shots.append(scene.shot)
		if scene.is_done():
			break
	Engine.time_scale = 1.0
	_check("Recorre los planos en orden %s" % str(shots), shots == [&"fire", &"hall", &"kael", &"regent", &"ribbon", &"title"])
	_check("Termina sola y devuelve el juego", scene.is_done() and not get_tree().paused)
	await _wait(1.6)


func _tap(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
