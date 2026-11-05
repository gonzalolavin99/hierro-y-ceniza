extends Node
## Prueba automática de la historia: el anciano narra al entrar en zonas (una sola vez), al descansar por
## primera vez, cambia sus frases de muerte según el acto, y todo eso se guarda con la partida.
## Ejecutar: Godot --headless --path game res://tests/story_test.tscn

const TEST_PATH: String = "user://save_story_test.json"

var _player: Player
var _failures: int = 0
var _spoken: Array[StringName] = []


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	Voice.spoken.connect(func(speaker: StringName, event: StringName, _id: String) -> void:
		if speaker == &"narrator":
			_spoken.append(event))
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await _run()
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	# 1. Datos: cada zona del nivel usa una narración que existe; todas las de historia tienen subtítulo.
	var narrator: Dictionary = VoiceLines.LINES[&"narrator"]
	var bad: Array[String] = []
	for node in get_tree().get_nodes_in_group("narration_zones"):
		var zone := node as NarrationZone
		if not narrator.has(zone.event):
			bad.append(String(zone.event))
	_check("Las zonas del nivel usan narraciones que existen %s" % str(bad), bad.is_empty())
	var story_events: int = 0
	for event: StringName in narrator:
		if String(event).begins_with("story_"):
			story_events += 1
	_check("Hay narraciones para zonas, jefes y finales (%d)" % story_events, story_events >= 18)
	for act in [2, 3, 4]:
		_check("Hay frases de muerte del acto %d" % act, narrator.has(StringName("player_death_%d" % act)))

	# 2. Kael empieza dentro de la zona del prólogo: el anciano lo narra una vez.
	await _wait(0.6)
	_check("Al empezar suena el prólogo (%s)" % str(_spoken), &"story_prologue" in _spoken and Story.heard(&"story_prologue"))
	_check("El prólogo deja el relato en el acto 1", Story.act == 1)
	_check("Una narración ya oída no se repite", not Story.narrate(&"story_prologue"))

	# 3. Entrar en otra zona la narra.
	_teleport(Vector3(32.0, 0.0, 15.0))
	await _wait(0.6)
	_check("Al entrar en la zona del grupo suena la aldea (%s)" % str(_spoken), Story.heard(&"story_pass_village"))
	var count: int = _spoken.count(&"story_pass_village")
	_teleport(Vector3(0.0, 0.0, 8.0))
	await _wait(0.4)
	_teleport(Vector3(32.0, 0.0, 15.0))
	await _wait(0.6)
	_check("Volver a entrar no la repite", _spoken.count(&"story_pass_village") == count)

	# 4. Las frases de muerte cambian con el acto.
	_check("Acto 1: muerte normal", Story.death_event() == &"player_death")
	Story.act = 3
	_check("Acto 3: frases del acto 3", Story.death_event() == &"player_death_3")
	Story.act = 9
	_check("El acto no pasa de 4", Story.act == 4)
	Story.act = 1

	# 5. Primer descanso: narración del campamento.
	var fire := get_tree().get_first_node_in_group("campfires") as Campfire
	fire.rest(_player)
	_check("Al descansar por primera vez habla el anciano", Story.heard(&"story_camp_first"))

	# 6. Se guarda y se carga con la partida.
	Story.act = 2
	SaveGame.save(_player)
	var saved: Dictionary = SaveGame.read().get("story", {})
	_check("La partida guarda el acto (%s)" % str(saved), int(saved.get("act", 0)) == 2)
	_check("…y lo ya narrado", "story_pass_village" in saved.get("heard", []))
	Story.reset()
	_check("Partida nueva: nada narrado", not Story.heard(&"story_pass_village") and Story.act == 1)
	Story.from_dict(saved)
	_check("Al cargar vuelve todo", Story.heard(&"story_pass_village") and Story.heard(&"story_camp_first") and Story.act == 2)


func _teleport(at: Vector3) -> void:
	_player.global_position = at
	_player.reset_physics_interpolation()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
