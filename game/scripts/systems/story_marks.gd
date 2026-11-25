class_name StoryMarks
extends RefCounted
## Lista única de las marcas de la historia que se guardan en `Story` (save.json → "story" → "heard").
## Los NOMBRES no se cambian nunca: están en las partidas guardadas de los probadores.
## Uso: Story.mark_heard(StoryMarks.BOSS_VARGA) · Story.heard(StoryMarks.gate(gate_id)). Prueba: story_test.

# Escenas ya vistas.
const SCENE_PROLOGUE: StringName = &"scene_prologue"
const SCENE_VARGA: StringName = &"scene_varga"
# Jefes vencidos.
const BOSS_VARGA: StringName = &"boss_varga"
# Promesa del prólogo (paso 4.6).
const VOW_STOP: StringName = &"vow_stop"
const VOW_END: StringName = &"vow_end"
# Frank.
const FRANK_MET: StringName = &"frank_met"
const FRANK_FREED: StringName = &"frank_freed"
const FRANK_REST_FIRST: StringName = &"frank_rest_first"
# El desertor (paso 4.3).
const DESERTER_SURRENDERED: StringName = &"deserter_surrendered"
const DESERTER_SPARED: StringName = &"deserter_spared"
const DESERTER_KILLED: StringName = &"deserter_killed"

## Todas las marcas fijas (al agregar una constante arriba, agregarla aquí).
const FIXED: Array[StringName] = [
	SCENE_PROLOGUE, SCENE_VARGA, BOSS_VARGA, VOW_STOP, VOW_END,
	FRANK_MET, FRANK_FREED, FRANK_REST_FIRST,
	DESERTER_SURRENDERED, DESERTER_SPARED, DESERTER_KILLED,
]

# Marcas que se arman con un id: prefijo + id.
const PREFIX_NARRATION: String = "story_"  # Narraciones del anciano (eventos del narrador en VoiceLines).
const PREFIX_HINT: String = "hint_"  # Carteles de ayuda aprendidos (tutorial_hints).
const PREFIX_VILLAGER: String = "villager_"  # Frase de un aldeano ya dicha (villager).
const PREFIX_GATE: String = "gate_"  # Puertas con pestillo abiertas (latched_gate).
const PREFIX_CACHE: String = "cache_"  # Escondites ya saqueados (hidden_cache).
const PREFIXES: Array[String] = [PREFIX_NARRATION, PREFIX_HINT, PREFIX_VILLAGER, PREFIX_GATE, PREFIX_CACHE]


static func hint(id: StringName) -> StringName:
	return StringName(PREFIX_HINT + String(id))


## Promesa elegida en el prólogo (&"stop" / &"end") → VOW_STOP / VOW_END.
static func vow(choice: StringName) -> StringName:
	return StringName("vow_" + String(choice))


static func villager(event: StringName) -> StringName:
	return StringName(PREFIX_VILLAGER + String(event))


## Frase extra de la promesa de un aldeano ya dicha: "villager_<evento>_vow".
static func villager_vow(event: StringName) -> StringName:
	return StringName(PREFIX_VILLAGER + String(event) + "_vow")


static func gate(id: StringName) -> StringName:
	return StringName(PREFIX_GATE + String(id))


static func cache(id: StringName) -> StringName:
	return StringName(PREFIX_CACHE + String(id))


## ¿Es una marca de la lista: fija, o con uno de los prefijos y un id detrás?
static func is_known(mark: StringName) -> bool:
	if mark in FIXED:
		return true
	var text := String(mark)
	for prefix in PREFIXES:
		if text.begins_with(prefix) and text.length() > prefix.length():
			return true
	return false
