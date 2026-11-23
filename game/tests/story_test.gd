extends Node
## Prueba automática de la historia: el anciano narra al entrar en zonas (una sola vez), al descansar por
## primera vez, cambia sus frases de muerte según el acto, y todo eso se guarda con la partida. Además revisa la
## lista única de marcas (StoryMarks): sin repetidas, con sus nombres de siempre y que el guardado no pierde ninguna.
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

	# 7. La lista única de marcas (StoryMarks).
	var unknown: Array[String] = []
	for text: String in Story.to_dict().get("heard", []):
		if not StoryMarks.is_known(StringName(text)):
			unknown.append(text)
	_check("Todo lo marcado en esta prueba está en la lista %s" % str(unknown), unknown.is_empty())
	var unique: Dictionary = {}
	for mark in StoryMarks.FIXED:
		unique[mark] = true
	_check("Las marcas fijas no se repiten", unique.size() == StoryMarks.FIXED.size())
	var expected: Array[StringName] = [&"scene_prologue", &"scene_varga", &"boss_varga", &"vow_stop", &"vow_end",
		&"frank_met", &"frank_freed", &"frank_rest_first", &"deserter_surrendered", &"deserter_spared", &"deserter_killed"]
	var renamed: Array[String] = []
	for mark in expected:
		if not mark in StoryMarks.FIXED:
			renamed.append(String(mark))
	_check("Las marcas fijas tienen sus nombres de siempre %s" % str(renamed),
		expected.size() == StoryMarks.FIXED.size() and renamed.is_empty())
	var clash: Array[String] = []
	for mark in StoryMarks.FIXED:
		for prefix in StoryMarks.PREFIXES:
			if String(mark).begins_with(prefix):
				clash.append(String(mark))
	_check("Ninguna marca fija empieza con un prefijo dinámico %s" % str(clash), clash.is_empty())
	_check("Las funciones arman los nombres de siempre",
		StoryMarks.gate(&"village_shortcut") == &"gate_village_shortcut"
		and StoryMarks.cache(&"x") == &"cache_x"
		and StoryMarks.hint(&"sweep") == &"hint_sweep"
		and StoryMarks.villager(&"sweeper") == &"villager_sweeper"
		and StoryMarks.villager_vow(&"child") == &"villager_child_vow"
		and StoryMarks.vow(&"stop") == StoryMarks.VOW_STOP
		and StoryMarks.vow(&"end") == StoryMarks.VOW_END)
	_check("Una marca mal escrita no es de la lista", not StoryMarks.is_known(&"boss_varg") and not StoryMarks.is_known(&"gate_"))
	Story.reset()
	var sample: Array[StringName] = [&"hint_sweep", &"villager_sweeper", &"gate_village_shortcut", &"cache_x", &"story_pass_village"]
	var all_marks: Array[StringName] = []
	all_marks.append_array(StoryMarks.FIXED)
	all_marks.append_array(sample)
	for mark in all_marks:
		Story.mark_heard(mark)
	SaveGame.save(_player)
	var data: Dictionary = SaveGame.read().get("story", {})
	Story.reset()
	Story.from_dict(data)
	var missing: Array[String] = []
	for mark in all_marks:
		if not Story.heard(mark):
			missing.append(String(mark))
	_check("Guardar y cargar devuelve todas las marcas (faltan: %s)" % str(missing), missing.is_empty())
	Story.reset()


func _teleport(at: Vector3) -> void:
	_player.global_position = at
	_player.reset_physics_interpolation()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
