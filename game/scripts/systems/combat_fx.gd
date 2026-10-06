extends Node
## Efectos del combate: congelado breve del impacto (hitstop), chispas y temblor de cámara.
## Las chispas son físicas (metal contra metal), nada de efectos "mágicos".

signal camera_shake_requested(strength: float)

const SPARK_COLOR: Color = Color(1.0, 0.75, 0.3)
const BLOOD_COLOR: Color = Color(0.35, 0.03, 0.02)

## 0 = sin sangre (solo chispas), 1 = mínima estilo Sekiro.
var blood_level: int = 1

var _hitstop_until: int = 0
var _spark_material: StandardMaterial3D
var _blood_material: StandardMaterial3D
var _particle_mesh: BoxMesh


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_spark_material = _make_material(SPARK_COLOR, true)
	_blood_material = _make_material(BLOOD_COLOR, false)
	_particle_mesh = BoxMesh.new()
	_particle_mesh.size = Vector3(0.03, 0.03, 0.12)


## Congela el juego un instante para dar peso al impacto.
func hitstop(duration: float) -> void:
	_hitstop_until = maxi(_hitstop_until, Time.get_ticks_msec() + int(duration * 1000.0))
	Engine.time_scale = 0.03


func _process(_delta: float) -> void:
	# Se mide en tiempo real (no afectado por la cámara lenta) para no quedarse congelado.
	if Engine.time_scale < 1.0 and Time.get_ticks_msec() >= _hitstop_until:
		Engine.time_scale = 1.0


func shake(strength: float) -> void:
	camera_shake_requested.emit(strength)


func sparks(at: Vector3, amount: int = 18, speed: float = 6.0) -> void:
	_burst(at, amount, speed, _spark_material, 0.25, 9.8)


func blood(at: Vector3) -> void:
	if blood_level <= 0:
		return
	_burst(at, 6, 2.5, _blood_material, 0.35, 14.0)


func _burst(at: Vector3, amount: int, speed: float, material: Material, lifetime: float, gravity: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.mesh = _particle_mesh
	p.material_override = material
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3.DOWN * gravity
	p.particle_flag_align_y = true
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	get_tree().current_scene.add_child(p)
	p.global_position = at
	p.emitting = true
	p.finished.connect(p.queue_free)


func _make_material(color: Color, emissive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 3.0
	return m
