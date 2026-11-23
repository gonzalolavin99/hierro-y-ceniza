class_name AudioMix
extends RefCounted
## Canales de mezcla del sonido (revisión del estudio, audio): cada sonido va a su canal, y así se puede subir o
## bajar cada uno aparte (las opciones del paso 6 los usarán) y la música baja sola cuando alguien habla.
## Los canales están en game/default_bus_layout.tres (Godot los carga al arrancar).
## - Musica: la música (duelo, prólogo, exploración).
## - Voz: lo que se habla (personajes, narrador, chillidos de Frank).
## - Efectos: golpes, pasos, armas, fuego cercano.
## - Ambiente: los sonidos de fondo (viento, río, pájaros lejanos, la hoguera de la ropa de la aldea).

const MUSIC: StringName = &"Musica"
const VOICE: StringName = &"Voz"
const SFX: StringName = &"Efectos"
const AMBIENT: StringName = &"Ambiente"
const ALL: Array[StringName] = [MUSIC, VOICE, SFX, AMBIENT]
## Cuánto bajan la música y el ambiente mientras alguien habla (para que se entienda la voz).
const DUCK_DB: float = -6.0


static func bus_index(bus: StringName) -> int:
	return AudioServer.get_bus_index(bus)


static func volume(bus: StringName) -> float:
	var i: int = bus_index(bus)
	return AudioServer.get_bus_volume_db(i) if i >= 0 else 0.0
