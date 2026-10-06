class_name Hurtbox
extends Area3D
## Zona que RECIBE golpes. Pasa el golpe a su dueño, que decide qué ocurre
## (recibir daño, bloquear, desviar…) implementando `receive_hit(hit: HitData) -> int`.

@export var target: Node3D


func _ready() -> void:
	monitoring = false
	monitorable = true
	if target == null:
		target = owner as Node3D


func receive(hit: HitData) -> int:
	return target.receive_hit(hit)
