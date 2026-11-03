class_name SmokeCloud
extends Node3D
## Nube de humo espeso (bomba de humo). Los enemigos que están dentro al formarse tosen y quedan
## aturdidos. Humo físico gris, nada de efectos "mágicos".

const RADIUS: float = 3.5
const DURATION: float = 5.0
## Durante este tiempo, quien esté dentro (o entre) queda aturdido.
const STUN_WINDOW: float = 0.6

var _age: float = 0.0
var _affected: Array[Enemy] = []
var _particles: CPUParticles3D


static func create(parent: Node, at: Vector3) -> SmokeCloud:
	var cloud := SmokeCloud.new()
	parent.add_child(cloud)
	cloud.global_position = at
	return cloud


func _ready() -> void:
	add_to_group("projectiles")
	Sfx.play(&"smoke", global_position)
	var p := CPUParticles3D.new()
	p.amount = 45
	p.lifetime = 2.6
	p.one_shot = false
	p.explosiveness = 0.35
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 1.2
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 2.2
	p.gravity = Vector3(0.0, 0.25, 0.0)
	p.damping_min = 1.0
	p.damping_max = 1.6
	p.scale_amount_min = 2.4
	p.scale_amount_max = 4.2
	p.angle_min = 0.0
	p.angle_max = 360.0
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 1.3))
	p.scale_amount_curve = curve
	# Bocanadas: cuadrados que miran siempre a la cámara con una textura redonda difuminada.
	var puff := QuadMesh.new()
	puff.size = Vector2(1.0, 1.0)
	var soft := Gradient.new()
	soft.set_color(0, Color(1, 1, 1, 1))
	soft.set_color(1, Color(1, 1, 1, 0))
	soft.add_point(0.45, Color(1, 1, 1, 0.55))
	var texture := GradientTexture2D.new()
	texture.gradient = soft
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = Color(0.68, 0.66, 0.63, 0.7)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.billboard_keep_scale = true
	material.disable_receive_shadows = true
	puff.material = material
	p.mesh = puff
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.9))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = fade
	add_child(p)
	p.position.y = 0.6
	p.emitting = true
	_particles = p


func _physics_process(delta: float) -> void:
	_age += delta
	# Deja de soltar humo a tiempo para que las últimas bocanadas se disipen antes de desaparecer.
	if _age > DURATION - _particles.lifetime:
		_particles.emitting = false
	if _age > DURATION:
		queue_free()
		return
	if _age > STUN_WINDOW:
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy in _affected and enemy.global_position.distance_to(global_position) <= RADIUS:
			_affected.append(enemy)
			enemy.receive_smoke()
