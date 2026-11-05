extends Node
## La historia: en qué acto va el relato y qué narraciones del anciano ya sonaron (cada una, una sola vez
## por partida). Las frases están en VoiceLines (narrador, eventos "story_*"); el guion en docs/11_GUION.md.
## Uso: Story.narrate(&"story_prologue") · Story.death_event() · Story.act = 2

## Acto del relato (1–4). Cambia las frases del anciano al morir.
## Avisa cuando cambia la partida entera (nueva o cargada), para que el mundo se recoloque (Frank, la red…).
signal changed

var act: int = 1:
	set(value):
		act = clampi(value, 1, 4)
var _heard: Dictionary = {}  # evento -> true


## Hace hablar al anciano si esa narración aún no sonó. Devuelve true si habló.
func narrate(event: StringName) -> bool:
	if _heard.has(event):
		return false
	if not Voice.say(&"narrator", event):
		return false
	_heard[event] = true
	return true


func heard(event: StringName) -> bool:
	return _heard.has(event)


## Marca una narración o escena como ya vista (sin hacer hablar a nadie).
func mark_heard(event: StringName) -> void:
	_heard[event] = true


## ¿Toca la escena del prólogo? Solo en la partida real (la escena principal) y si aún no se vio.
func should_play_prologue() -> bool:
	var scene: Node = get_tree().current_scene
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	return scene != null and scene.scene_file_path == main and not heard(&"scene_prologue")


## Al aparecer Kael: si es una partida nueva, empieza con la escena del prólogo.
func start_if_new() -> void:
	if should_play_prologue():
		play_prologue()


## Pone la escena del prólogo (el juego queda en pausa hasta que termine o se salte).
func play_prologue() -> PrologueScene:
	# Su primera frase es la del prólogo: que la zona del inicio no la repita.
	mark_heard(&"story_prologue")
	get_tree().paused = true
	var scene := PrologueScene.new()
	get_tree().root.add_child(scene)
	scene.finished.connect(_on_prologue_finished)
	return scene


func _on_prologue_finished() -> void:
	mark_heard(&"scene_prologue")
	get_tree().paused = false
	SaveGame.save(get_tree().get_first_node_in_group("player") as Player)


## Evento de voz del anciano al morir Kael, según el acto.
func death_event() -> StringName:
	return &"player_death" if act <= 1 else StringName("player_death_%d" % act)


## Partida nueva: acto 1 y ninguna narración oída.
func reset() -> void:
	act = 1
	_heard.clear()
	changed.emit()


func to_dict() -> Dictionary:
	return {"act": act, "heard": _heard.keys().map(func(e: StringName) -> String: return String(e))}


func from_dict(data: Dictionary) -> void:
	reset()
	act = int(data.get("act", 1))
	for event in data.get("heard", []):
		_heard[StringName(event)] = true
	changed.emit()
