class_name WeaponPose
extends Node3D
## Mueve el arma entre posturas (reposo, guardia, tajos) mientras no tengamos animaciones reales.
## Este nodo es el "hombro": el arma cuelga de él apuntando hacia -Z.

# Rotación (x = subir/bajar la punta, y = + izquierda / - derecha, z = girar el filo).
const POSES: Dictionary[StringName, Vector3] = {
	&"idle": Vector3(-0.55, -0.35, 0.0),
	&"block": Vector3(0.15, 1.45, -0.25),
	&"windup_right": Vector3(0.75, -1.7, 0.0),
	&"end_left": Vector3(-0.35, 1.25, 0.0),
	&"windup_left": Vector3(0.6, 1.5, 0.0),
	&"end_right": Vector3(-0.35, -1.35, 0.0),
	&"windup_high": Vector3(1.5, -0.2, 0.0),
	&"end_low": Vector3(-1.0, -0.1, 0.0),
	&"thrust": Vector3(-0.05, -0.05, 0.0),
}

@export var glint_path: NodePath

var _tween: Tween
var _glint: Node3D


func _ready() -> void:
	rotation = POSES[&"idle"]
	if not glint_path.is_empty():
		_glint = get_node(glint_path)
		_glint.visible = false


## Ir a una postura en `duration` segundos.
func go(pose: StringName, duration: float, ease_type: Tween.EaseType = Tween.EASE_OUT) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ease(ease_type).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "rotation", POSES[pose], maxf(duration, 0.01))


## Ir rápido a una postura y volver a otra (rebote del arma al desviar o bloquear).
func bounce(pose_a: StringName, pose_b: StringName, duration_a: float, duration_b: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "rotation", POSES[pose_a], duration_a)
	_tween.tween_property(self, "rotation", POSES[pose_b], duration_b)


## Destello en el filo antes de atacar (aviso visual, como en Sekiro).
func glint() -> void:
	if _glint == null:
		return
	_glint.visible = true
	_glint.scale = Vector3.ONE * 0.2
	var t := create_tween()
	t.tween_property(_glint, "scale", Vector3.ONE * 1.4, 0.08)
	t.tween_property(_glint, "scale", Vector3.ONE * 0.1, 0.14)
	t.tween_callback(func() -> void: _glint.visible = false)
