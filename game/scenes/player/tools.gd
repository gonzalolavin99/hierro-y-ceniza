class_name PlayerTools
extends RefCounted
## Armas secundarias de Kael (LT): cuál está equipada y cuántos usos le quedan.
## Son mecánicas (ballesta, humo, pólvora): nada sobrenatural (ver docs/04_GUIA_DE_CONTENIDO.md).

signal changed

## Orden al cambiar con la cruceta.
const ORDER: Array[StringName] = [&"crossbow", &"smoke", &"powder"]
## name: nombre en pantalla · max: usos al rellenar · windup: segundos hasta que sale el disparo o
## la bomba · recovery: segundos tras soltarla hasta poder moverse.
const DATA: Dictionary = {
	&"crossbow": {"name": "Ballesta de muñeca", "max": 10, "windup": 0.14, "recovery": 0.3},
	&"smoke": {"name": "Bomba de humo", "max": 3, "windup": 0.22, "recovery": 0.35},
	&"powder": {"name": "Bomba de pólvora", "max": 3, "windup": 0.3, "recovery": 0.4},
}

var current: StringName = &"crossbow"
var ammo: Dictionary = {}


func _init() -> void:
	refill()


## Rellena todos los usos (al reaparecer; en el futuro, al descansar en el campamento).
func refill() -> void:
	for tool: StringName in ORDER:
		ammo[tool] = DATA[tool]["max"]
	changed.emit()


func select(tool: StringName) -> void:
	current = tool
	changed.emit()


## Cambia a la siguiente (1) o anterior (-1) arma.
func cycle(direction: int) -> void:
	var index: int = ORDER.find(current)
	select(ORDER[posmod(index + direction, ORDER.size())])


func can_use() -> bool:
	return ammo[current] > 0


func consume() -> void:
	ammo[current] = maxi(ammo[current] - 1, 0)
	changed.emit()


func display_name() -> String:
	return DATA[current]["name"]
