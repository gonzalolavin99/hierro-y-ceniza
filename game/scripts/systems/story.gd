extends Node
## La historia: en qué acto va el relato y qué narraciones del anciano ya sonaron (cada una, una sola vez
## por partida). Las frases están en VoiceLines (narrador, eventos "story_*"); el guion en docs/11_GUION.md.
## Uso: Story.narrate(&"story_prologue") · Story.death_event() · Story.act = 2

## Acto del relato (1–4). Cambia las frases del anciano al morir.
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


## Evento de voz del anciano al morir Kael, según el acto.
func death_event() -> StringName:
	return &"player_death" if act <= 1 else StringName("player_death_%d" % act)


## Partida nueva: acto 1 y ninguna narración oída.
func reset() -> void:
	act = 1
	_heard.clear()


func to_dict() -> Dictionary:
	return {"act": act, "heard": _heard.keys().map(func(e: StringName) -> String: return String(e))}


func from_dict(data: Dictionary) -> void:
	reset()
	act = int(data.get("act", 1))
	for event in data.get("heard", []):
		_heard[StringName(event)] = true
