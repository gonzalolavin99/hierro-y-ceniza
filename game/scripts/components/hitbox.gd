class_name Hitbox
extends Area3D
## Zona que DA golpes (el arma). Solo está activa durante el instante del tajo.
## Cada activación golpea como mucho una vez a cada objetivo.

signal hit_landed(result: int, hurtbox: Hurtbox)

var _hit: HitData
var _already_hit: Array[Hurtbox] = []


func _ready() -> void:
	monitoring = false
	monitorable = false


func activate(hit: HitData) -> void:
	_hit = hit
	_already_hit.clear()
	monitoring = true


func deactivate() -> void:
	monitoring = false
	_hit = null


func is_active() -> bool:
	return _hit != null


func _physics_process(_delta: float) -> void:
	if _hit == null:
		return
	for area in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or hurtbox in _already_hit or hurtbox.target == _hit.attacker:
			continue
		_already_hit.append(hurtbox)
		var result: int = hurtbox.receive(_hit)
		hit_landed.emit(result, hurtbox)
		if _hit == null:  # El receptor pudo cancelar el ataque (p. ej. desvío)
			return
