class_name Health
extends Node
## Vida de un personaje (jugador o enemigo).

signal changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0

var current: float


func _ready() -> void:
	current = max_health


func take_damage(amount: float) -> void:
	if current <= 0.0:
		return
	current = maxf(current - amount, 0.0)
	changed.emit(current, max_health)
	if current <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	current = minf(current + amount, max_health)
	changed.emit(current, max_health)


func ratio() -> float:
	return current / max_health
