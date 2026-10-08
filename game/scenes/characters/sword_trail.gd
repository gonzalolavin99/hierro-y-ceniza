class_name SwordTrail
extends MeshInstance3D
## Estela del filo: una cinta que une las últimas posiciones de la base y la punta de la espada
## y se desvanece. Solo es un rastro de aire cortado, sin brillo "mágico".

@export var lifetime: float = 0.12
@export var color: Color = Color(1.0, 0.97, 0.9, 0.35)

var base_node: Node3D
var tip_node: Node3D
var emitting: bool = false:
	set(value):
		emitting = value
		if not value:
			_fading = true

var _points: Array[Dictionary] = []  # {base, tip, time}
var _fading: bool = false
var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	material_override = mat
	global_transform = Transform3D.IDENTITY


func _process(_delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if emitting and base_node and tip_node:
		_points.append({"base": base_node.global_position, "tip": tip_node.global_position, "time": now})
	while not _points.is_empty() and now - float(_points[0]["time"]) > lifetime:
		_points.pop_front()
	_mesh.clear_surfaces()
	if _points.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for p in _points:
		var age: float = clampf((now - float(p["time"])) / lifetime, 0.0, 1.0)
		var c := Color(color.r, color.g, color.b, color.a * (1.0 - age))
		_mesh.surface_set_color(c)
		_mesh.surface_add_vertex(p["base"])
		_mesh.surface_set_color(c)
		_mesh.surface_add_vertex(p["tip"])
	_mesh.surface_end()
