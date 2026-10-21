class_name HitData
extends RefCounted
## Información de un golpe: cuánto daño hace y quién lo dio.

enum Result { HIT, BLOCKED, DEFLECTED, IGNORED, COUNTERED }
## Tipo de golpe. Los peligrosos (aviso rojo) no se pueden bloquear ni desviar:
## SWEEP (barrido) se salta, THRUST (estocada) se contrarresta pisando la hoja, GRAB (agarre) se esquiva.
enum Kind { NORMAL, SWEEP, THRUST, GRAB }

var damage: float = 10.0
var posture_damage: float = 10.0
## Postura que recibe el ATACANTE si su golpe es desviado.
var deflect_posture_damage: float = 20.0
var attacker: Node3D
## Rompe la guardia (patada): si el rival está bloqueando, queda expuesto.
var guard_break: bool = false
var kind: Kind = Kind.NORMAL


func is_perilous() -> bool:
	return kind != Kind.NORMAL


static func create(p_attacker: Node3D, p_damage: float, p_posture: float, p_deflect_posture: float = 20.0) -> HitData:
	var hit := HitData.new()
	hit.attacker = p_attacker
	hit.damage = p_damage
	hit.posture_damage = p_posture
	hit.deflect_posture_damage = p_deflect_posture
	return hit
