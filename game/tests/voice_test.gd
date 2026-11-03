extends Node
## Prueba automática del sistema de voces: quién dice qué y cuándo, sin saturar, con subtítulos,
## sin fallar si aún no existe el audio y respetando la guía de contenido.
## Ejecutar: Godot --headless --path game res://tests/voice_test.tscn

## Palabras que la guía de contenido (docs/04) no permite en ningún texto del juego.
const BANNED: Array[String] = ["soul", "spirit", "demon", "devil", "magic", "spell", "witch", "curse", "god", "ghost",
	"undead", "hell", "heaven", "pray", "alma", "espíritu", "demonio", "diablo", "magia", "hechiz", "bruj",
	"maldi", "dios", "fantasma", "infierno", "cielo", "reza"]

var _player: Player
var _enemy: Enemy
var _failures: int = 0
var _spoken: Array = []
var _subtitles: Array[String] = []


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	Voice.always_speak = true  # Sin azar: cada evento habla si su pausa lo permite.
	Voice.spoken.connect(func(speaker: StringName, event: StringName, _id: String) -> void: _spoken.append([speaker, event]))
	Voice.subtitle.connect(func(text: String, _who: String, _secs: float) -> void: _subtitles.append(text))
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	await _wait(0.3)

	# 1. Datos: cada evento tiene líneas con id; las frases tienen texto en inglés y subtítulo en español.
	var lines_ok: bool = true
	var phrases: int = 0
	for speaker: StringName in VoiceLines.LINES:
		for event: StringName in VoiceLines.LINES[speaker]:
			var data: Dictionary = VoiceLines.LINES[speaker][event]
			for line: Dictionary in data["lines"]:
				lines_ok = lines_ok and line.has("id") and (line.has("effort") or (line.has("en") and line.has("es")))
				if line.has("es"):
					phrases += 1
	_check("Todas las líneas tienen id y texto o descripción de esfuerzo", lines_ok)
	_check("Hay frases con subtítulo (%d)" % phrases, phrases >= 5)

	# 2. Guía de contenido: ninguna palabra prohibida en los textos de voz.
	var found: Array[String] = []
	for speaker: StringName in VoiceLines.LINES:
		for event: StringName in VoiceLines.LINES[speaker]:
			for line: Dictionary in VoiceLines.LINES[speaker][event]["lines"]:
				var text: String = (line.get("en", "") + " " + line.get("es", "") + " " + line.get("effort", "")).to_lower()
				for word in BANNED:
					if (" " + text).contains(" " + word):
						found.append("%s: %s" % [line["id"], word])
	_check("Sin palabras prohibidas por la guía %s" % str(found), found.is_empty())

	# 3. Pausa entre repeticiones: el mismo evento no se repite enseguida.
	Voice.reset()
	var first: bool = Voice.say(&"kael", &"hurt", _player.global_position)
	var again: bool = Voice.say(&"kael", &"hurt", _player.global_position)
	_check("La primera vez habla", first)
	_check("Repetido al instante, calla (no satura)", not again)
	await _wait(VoiceLines.LINES[&"kael"][&"hurt"]["cooldown"] + 0.1)
	_check("Pasada la pausa, vuelve a hablar", Voice.say(&"kael", &"hurt", _player.global_position))

	# 4. Sin archivo de audio no falla, y las frases muestran su subtítulo igualmente.
	Voice.reset()
	_subtitles.clear()
	_check("Una frase sin audio no falla", Voice.say(&"soldier", &"spot", _enemy.global_position))
	_check("Muestra el subtítulo en español (%s)" % str(_subtitles), _subtitles.size() == 1 and not _subtitles[0].is_empty())
	await get_tree().process_frame
	var hud_text: String = _hud_subtitle()
	_check("El HUD muestra el subtítulo (\"%s\")" % hud_text, hud_text == _subtitles[0])

	# 5. Los personajes hablan en el juego.
	Voice.reset()
	_spoken.clear()
	_enemy.state_machine.transition_to(&"Attack", {"pattern": &"sweep"})
	await _wait(0.1)
	_check("El soldado grita antes de un ataque peligroso", [&"soldier", &"danger"] in _spoken)
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	_spoken.clear()
	_player.state_machine.transition_to(&"Attack", {"move": &"heavy"})
	await _wait(0.1)
	_check("Kael hace un esfuerzo con el golpe pesado", [&"kael", &"heavy"] in _spoken)
	await _wait(1.6)

	# 6. Al morir el jugador, el narrador lo corrige: "No… no fue así."
	Voice.reset()
	_subtitles.clear()
	_spoken.clear()
	_player.health.take_damage(10000.0)
	_player.state_machine.transition_to(&"Dead")
	await _wait(2.5)
	_check("Kael muere con un quejido", [&"kael", &"death"] in _spoken)
	_check("El narrador habla al morir (%s)" % str(_subtitles), [&"narrator", &"player_death"] in _spoken and not _subtitles.is_empty())


func _hud_subtitle() -> String:
	var hud: Node = get_tree().get_first_node_in_group("hud")
	return hud.call("subtitle_text") if hud else ""


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
