class_name NordicProps
extends Node3D
## Reusable scenery. Decorative only; existing navigation and collision remain authoritative.
var _wood := NordicCostume.material(Color("473225"))
var _iron := NordicCostume.material(Color("353a3e"), 0.55, 0.7)
var _stone := NordicCostume.material(Color("55514b"))


func bench(at: Vector3, angle: float = 0.0) -> void:
	var group := Node3D.new()
	add_child(group)
	group.position = at
	group.rotation.y = angle
	box(group, Vector3(0, 0.48, 0), Vector3(1.8, 0.12, 0.36), _wood)
	for x: float in [-0.67, 0.67]:
		box(group, Vector3(x, 0.23, 0), Vector3(0.13, 0.46, 0.3), _wood)


func banner(at: Vector3, accent: Color) -> void:
	box(self, at + Vector3(0, 1.35, 0), Vector3(0.1, 2.7, 0.1), _wood)
	box(self, at + Vector3(0, 2.57, 0), Vector3(1.12, 0.08, 0.08), _wood)
	var cloth := PlaneMesh.new()
	cloth.orientation = PlaneMesh.FACE_Z
	cloth.size = Vector2(0.9, 1.4)
	cloth.subdivide_width = 6
	cloth.subdivide_depth = 12
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/volsungos/woven_cloth.gdshader")
	mat.set_shader_parameter("cloth_color", accent)
	var instance := MeshInstance3D.new()
	instance.mesh = cloth
	instance.material_override = mat
	instance.position = at + Vector3(0, 1.8, 0.07)
	add_child(instance)


func brazier(at: Vector3, particles: bool = true) -> void:
	var bowl := MeshInstance3D.new()
	bowl.mesh = NordicCostume._cone(0.32, 0.16, 0.18)
	bowl.material_override = _iron
	bowl.position = at + Vector3(0, 0.72, 0)
	add_child(bowl)
	for angle: float in [0, TAU / 3, 2 * TAU / 3]:
		box(self, at + Vector3(cos(angle) * 0.16, 0.32, sin(angle) * 0.16), Vector3(0.05, 0.64, 0.05), _iron)
	var coal := NordicCostume.material(Color("bc6025"))
	coal.emission_enabled = true
	coal.emission = Color("ed8738")
	coal.emission_energy_multiplier = 0.8
	box(self, at + Vector3(0, 0.8, 0), Vector3(0.4, 0.045, 0.4), coal)
	var light := OmniLight3D.new()
	light.position = at + Vector3(0, 1.15, 0)
	light.light_color = Color("ffc58b")
	light.light_energy = 0.8
	light.omni_range = 5
	light.shadow_enabled = false
	add_child(light)
	if particles:
		var sparks := CPUParticles3D.new()
		sparks.position = at + Vector3(0, 0.86, 0)
		sparks.amount = 18
		sparks.lifetime = 1.6
		sparks.mesh = NordicCostume._sphere(0.012)
		sparks.material_override = coal
		sparks.direction = Vector3.UP
		sparks.spread = 20
		sparks.gravity = Vector3(0, 0.2, 0)
		sparks.initial_velocity_min = 0.3
		sparks.initial_velocity_max = 0.8
		sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		sparks.emission_sphere_radius = 0.13
		add_child(sparks)


func dress_village() -> void:
	# At the edges of the nine-metre-wide road, outside its navigable corridor.
	bench(Vector3(-4.7, 0, 56), PI / 2)
	bench(Vector3(4.7, 0, 48), PI / 2)
	banner(Vector3(-4.7, 0, 72), Color("6b3028"))
	banner(Vector3(4.7, 0, 72), Color("6b3028"))
	brazier(Vector3(-4.7, 0, 64))
	brazier(Vector3(4.7, 0, 36))


func hall() -> void:
	box(self, Vector3(0, -0.13, 0), Vector3(13, 0.25, 17), _stone)
	for x: float in [-5.7, 5.7]:
		for z: float in [-6, -3, 0, 3, 6]:
			box(self, Vector3(x, 2, z), Vector3(0.28, 4, 0.28), _wood)
		box(self, Vector3(x, 3.9, 0), Vector3(0.35, 0.3, 15), _wood)
		for z: float in [-4, 0, 4]:
			bench(Vector3(x * 0.72, 0, z), PI / 2)
	for z: float in [-6, -3, 0, 3, 6]:
		box(self, Vector3(0, 4, z), Vector3(11.7, 0.25, 0.25), _wood)
	box(self, Vector3(0, 1.7, -7.4), Vector3(12, 3.4, 0.25), _wood)
	banner(Vector3(-3.5, 0, -5.7), Color("6b3028"))
	banner(Vector3(3.5, 0, -5.7), Color("283a48"))
	brazier(Vector3(-3, 0, -2))
	brazier(Vector3(3, 0, -2))


static func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = NordicCostume._box(size)
	instance.material_override = mat
	instance.position = at
	parent.add_child(instance)
	return instance
