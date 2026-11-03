class_name PlayerArts
extends RefCounted
## Técnicas de combate de Kael (LB + RB). Solo se lleva una equipada, como en Sekiro.
## Se desbloquean a lo largo del juego (maestros, hallazgos); el Torbellino viene de serie.

signal changed

## Orden al cambiar con la cruceta (arriba). Nombre en pantalla de cada técnica.
const ORDER: Array[StringName] = [&"art_whirlwind", &"art_hammer", &"art_flurry"]
const NAMES: Dictionary = {
	&"art_whirlwind": "Torbellino",
	&"art_hammer": "Golpe de Martillo",
	&"art_flurry": "Ráfaga",
}
const STARTING: StringName = &"art_whirlwind"

var equipped: StringName = STARTING
var unlocked: Array[StringName] = [STARTING]


## Vuelve al estado de partida: solo la técnica inicial.
func reset_unlocked() -> void:
	unlocked = [STARTING]
	equipped = STARTING
	changed.emit()


func unlock(art: StringName) -> void:
	if art in ORDER and not art in unlocked:
		unlocked.append(art)
		changed.emit()


func unlock_all() -> void:
	for art: StringName in ORDER:
		unlock(art)


func equip(art: StringName) -> void:
	if art in unlocked:
		equipped = art
		changed.emit()


## Equipa la siguiente técnica desbloqueada (en el orden de ORDER).
func cycle() -> void:
	var index: int = ORDER.find(equipped)
	for step in range(1, ORDER.size() + 1):
		var art: StringName = ORDER[(index + step) % ORDER.size()]
		if art in unlocked:
			equip(art)
			return


func display_name() -> String:
	return NAMES[equipped]
