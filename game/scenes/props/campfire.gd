class_name Campfire
extends Node3D
## Campamento: fogata con tienda. Junto a ella Kael puede descansar (Y / E): recupera vida, vendajes y
## herramientas, los enemigos vuelven a su puesto y este pasa a ser su punto de reaparición.
## No se puede descansar con enemigos alerta cerca. Todo se construye en código (piezas sencillas).

## Distancia a la fogata para poder descansar.
const REST_RANGE: float = 2.6
## Distancia a la que aparece el aviso.
const PROMPT_RANGE: float = 3.4
## Un enemigo que te tiene en la mira a esta distancia o menos impide descansar.
const THREAT_RANGE: float = 20.0
## Dónde se sienta Kael (respecto a la fogata).
const REST_OFFSET: Vector3 = Vector3(1.5, 0.0, 0.0)

@export var camp_name: String = "Campamento"

var _light: OmniLight3D
var _flames: Array[MeshInstance3D] = []
var _prompt: Label3D
var _crackle: AudioStreamPlayer3D
var _time: float = 0.0


func _ready() -> void:
	add_to_group("campfires")
	_build_fire()
	_build_tent()
	_build_prompt()
	_build_sound()


func _process(delta: float) -> void:
	_time += delta
	# Llama viva: la luz y las lenguas de fuego titilan sin ritmo fijo.
	var flicker: float = 0.75 + 0.15 * sin(_time * 11.0) + 0.1 * sin(_time * 23.7 + 1.3)
	_light.light_energy = 2.2 * flicker
	for i in _flames.size():
		var f: MeshInstance3D = _flames[i]
		var s: float = 1.0 + 0.18 * sin(_time * (9.0 + i * 3.1) + i * 2.0)
		f.scale = Vector3(1.0, s, 1.0)
	_update_prompt()


# --- Lógica --------------------------------------------------------------------------

func rest_position() -> Vector3:
	return global_position + global_basis * REST_OFFSET


## Ángulo (grados) para que Kael mire a la fogata desde su sitio.
func rest_facing_degrees() -> float:
	var to_fire: Vector3 = global_position - rest_position()
	return rad_to_deg(atan2(-to_fire.x, -to_fire.z))


func in_range(player: Player, distance: float = REST_RANGE) -> bool:
	var d: Vector3 = player.global_position - global_position
	return Vector2(d.x, d.z).length() <= distance and absf(d.y) < 1.5


func threatened() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.has_target() \
				and enemy.global_position.distance_to(global_position) <= THREAT_RANGE:
			return true
	return false


func can_rest(player: Player) -> bool:
	return in_range(player) and not threatened() and not player.is_dead()


## Mitad del descanso (pantalla en negro): repone a Kael, reinicia el mundo y fija la reaparición aquí.
func rest(player: Player) -> void:
	player.restore()
	player.set_spawn(rest_position(), rest_facing_degrees())
	Camps.reset_world()


# --- Aviso ---------------------------------------------------------------------------

func _update_prompt() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var near: bool = player != null and in_range(player, PROMPT_RANGE) and not player.is_dead() \
			and player.state_machine.current.name != &"Rest"
	_prompt.visible = near
	if near:
		_prompt.text = "Hay enemigos cerca" if threatened() else "Y  Descansar"
		_prompt.modulate = Color(1.0, 0.55, 0.45) if threatened() else Color(1.0, 0.92, 0.75)


func prompt_visible() -> bool:
	return _prompt.visible


func prompt_text() -> String:
	return _prompt.text


# --- Construcción --------------------------------------------------------------------

func _build_fire() -> void:
	var stone_mat := _mat(Color(0.36, 0.34, 0.32), 0.95)
	for i in 9:
		var a: float = TAU * i / 9.0
		var stone := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.16 + 0.03 * sin(i * 2.3)
		mesh.height = mesh.radius * 1.3
		mesh.radial_segments = 8
		mesh.rings = 4
		stone.mesh = mesh
		stone.material_override = stone_mat
		stone.position = Vector3(cos(a) * 0.55, 0.07, sin(a) * 0.55)
		add_child(stone)
	var log_mat := _mat(Color(0.28, 0.17, 0.09), 0.9)
	for i in 4:
		var log_piece := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.06
		mesh.bottom_radius = 0.07
		mesh.height = 0.8
		mesh.radial_segments = 7
		log_piece.mesh = mesh
		log_piece.material_override = log_mat
		log_piece.rotation = Vector3(deg_to_rad(62.0), TAU * i / 4.0 + 0.4, 0.0)
		log_piece.position = Vector3(0.0, 0.2, 0.0)
		add_child(log_piece)
	var ember_mat := StandardMaterial3D.new()
	ember_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_mat.albedo_color = Color(1.0, 0.35, 0.08)
	var embers := MeshInstance3D.new()
	var bed := CylinderMesh.new()
	bed.top_radius = 0.38
	bed.bottom_radius = 0.42
	bed.height = 0.05
	embers.mesh = bed
	embers.material_override = ember_mat
	embers.position.y = 0.03
	add_child(embers)
	# Lenguas de fuego: conos sin sombra, de naranja a amarillo.
	var colors: Array[Color] = [Color(1.0, 0.42, 0.08), Color(1.0, 0.6, 0.15), Color(1.0, 0.82, 0.35)]
	for i in 3:
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.22 - i * 0.05
		cone.height = 0.75 - i * 0.15
		cone.radial_segments = 8
		flame.mesh = cone
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = colors[i]
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.85
		flame.material_override = mat
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flame.position = Vector3(0.04 * (i - 1), 0.1 + cone.height * 0.5, 0.03 * (1 - i))
		add_child(flame)
		_flames.append(flame)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.62, 0.3)
	_light.omni_range = 8.0
	_light.position.y = 0.9
	_light.shadow_enabled = false
	add_child(_light)
	# No se puede atravesar la fogata.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.65
	cyl.height = 0.6
	shape.shape = cyl
	shape.position.y = 0.3
	body.add_child(shape)
	add_child(body)


func _build_tent() -> void:
	# Tienda de lona a un lado, detrás de la fogata (respecto al sitio de descanso).
	var tent := Node3D.new()
	tent.position = Vector3(-2.2, 0.0, -0.6)
	tent.rotation.y = deg_to_rad(80.0)
	add_child(tent)
	var canvas := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(2.0, 1.5, 2.4)
	canvas.mesh = prism
	canvas.material_override = _mat(Color(0.55, 0.48, 0.36), 1.0)
	canvas.position.y = 0.75
	tent.add_child(canvas)
	var pole_mat := _mat(Color(0.3, 0.2, 0.12), 0.9)
	for z in [-1.25, 1.25]:
		var pole := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.03
		mesh.bottom_radius = 0.03
		mesh.height = 1.7
		pole.mesh = mesh
		pole.material_override = pole_mat
		pole.position = Vector3(0.0, 0.85, z)
		tent.add_child(pole)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 1.4, 2.4)
	shape.shape = box
	shape.position.y = 0.7
	body.add_child(shape)
	tent.add_child(body)
	# Petate (manta enrollada) junto al sitio de descanso.
	var roll := MeshInstance3D.new()
	var roll_mesh := CapsuleMesh.new()
	roll_mesh.radius = 0.13
	roll_mesh.height = 0.9
	roll.mesh = roll_mesh
	roll.material_override = _mat(Color(0.42, 0.24, 0.18), 1.0)
	roll.rotation = Vector3(0.0, deg_to_rad(30.0), deg_to_rad(90.0))
	roll.position = Vector3(-1.0, 0.13, 1.1)
	add_child(roll)


func _build_prompt() -> void:
	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.fixed_size = true
	_prompt.pixel_size = 0.0012
	_prompt.font_size = 28
	_prompt.outline_size = 8
	_prompt.position = Vector3(0.0, 1.5, 0.0)
	_prompt.visible = false
	add_child(_prompt)


func _build_sound() -> void:
	var path: String = "res://assets/audio/sfx/fire_1.wav"
	if not ResourceLoader.exists(path):
		return
	var stream := (load(path) as AudioStreamWAV).duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_crackle = AudioStreamPlayer3D.new()
	_crackle.stream = stream
	_crackle.volume_db = -8.0
	_crackle.unit_size = 3.0
	_crackle.max_distance = 22.0
	_crackle.position.y = 0.4
	_crackle.autoplay = true
	add_child(_crackle)


func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat
