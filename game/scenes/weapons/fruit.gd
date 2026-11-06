class_name FrankFruit
extends Node3D
## Fruta que lanza Frank: vuela en arco hasta `target` y avisa al llegar (`landed`). Luego queda en el suelo un
## rato y desaparece. Sin colisiones: el efecto lo decide FrankThrow al llegar. Se construye en código.

signal landed(at: Vector3)

const LINGER: float = 4.0

var _from: Vector3
var _to: Vector3
var _height: float = 1.2
var _time: float = 0.6
var _elapsed: float = 0.0
var _flying: bool = true
var _ground_y: float = 0.0
## Si tiene objetivo, la fruta lo persigue en el vuelo (el enemigo se mueve): acaba justo en él.
var _follow: Node3D


static func launch(parent: Node, from: Vector3, to: Vector3, ground_y: float, follow: Node3D = null) -> FrankFruit:
	var fruit := FrankFruit.new()
	fruit._follow = follow
	fruit._from = from
	fruit._to = to
	fruit._ground_y = ground_y
	fruit._time = clampf(from.distance_to(to) / 13.0, 0.35, 0.9)
	fruit._height = clampf(from.distance_to(to) * 0.12, 0.5, 1.6)
	parent.add_child(fruit)
	fruit.global_position = from
	return fruit


func flight_time() -> float:
	return _time


func _ready() -> void:
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.93, 0.5, 0.12)
	skin.roughness = 0.6
	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.065
	sphere.height = 0.12
	sphere.material = skin
	body.mesh = sphere
	add_child(body)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.25, 0.5, 0.18)
	var leaf := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.05, 0.008, 0.025)
	box.material = leaf_mat
	leaf.mesh = box
	leaf.position = Vector3(0.02, 0.065, 0.0)
	leaf.rotation.z = 0.4
	add_child(leaf)


func _process(delta: float) -> void:
	_elapsed += delta
	if _flying:
		var t: float = clampf(_elapsed / _time, 0.0, 1.0)
		if _follow and is_instance_valid(_follow):
			_to = _follow.global_position
		global_position = _from.lerp(_to, t) + Vector3.UP * sin(t * PI) * _height
		rotation += Vector3(9.0, 4.0, 0.0) * delta
		if t >= 1.0:
			_flying = false
			_elapsed = 0.0
			Sfx.play(&"hit", global_position, -14.0, 0.2)
			landed.emit(global_position)
		return
	# Cae al suelo (si dio en una cabeza) y se queda un rato.
	global_position.y = maxf(_ground_y + 0.06, global_position.y - delta * 6.0)
	if _elapsed >= LINGER:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.4)
		tween.tween_callback(queue_free)
		set_process(false)
