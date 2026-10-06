class_name Posture
extends Node
## Postura al estilo Sekiro: sube al recibir o bloquear golpes y baja sola con el tiempo.
## Si se llena, la postura se rompe (el personaje queda expuesto).

signal changed(current: float, maximum: float)
signal broken

@export var max_posture: float = 100.0
## Puntos por segundo que se recuperan.
@export var regen_rate: float = 20.0
## Segundos sin recibir postura antes de empezar a recuperarse.
@export var regen_delay: float = 1.0

var current: float = 0.0
## Multiplica la recuperación (p. ej. más rápida con la guardia alta, más lenta con poca vida).
var regen_multiplier: float = 1.0
var is_broken: bool = false
var _since_hit: float = 0.0


func _physics_process(delta: float) -> void:
	_since_hit += delta
	if is_broken or current <= 0.0 or _since_hit < regen_delay:
		return
	current = maxf(current - regen_rate * regen_multiplier * delta, 0.0)
	changed.emit(current, max_posture)


func add(amount: float) -> void:
	if is_broken:
		return
	_since_hit = 0.0
	current = minf(current + amount, max_posture)
	changed.emit(current, max_posture)
	if current >= max_posture:
		is_broken = true
		broken.emit()


## Se llama al salir del aturdimiento.
func reset() -> void:
	is_broken = false
	current = 0.0
	changed.emit(current, max_posture)


func ratio() -> float:
	return current / max_posture
