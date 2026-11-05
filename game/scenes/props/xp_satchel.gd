class_name XpSatchel
extends Node3D
## Morral caído: al morir, Kael pierde su experiencia y esta queda aquí, en su morral, donde cayó. Si vuelve
## y pasa junto a él, la recupera. Si muere otra vez antes, este morral se pierde. Se ve de lejos por un
## jirón de tela roja atado a una estaca. Se construye en código.

## Distancia a la que se recoge al pasar.
const PICKUP_RANGE: float = 1.3

var amount: int = 0
var _cloth_pivot: Node3D
var _label: Label3D
var _time: float = 0.0


static func spawn(parent: Node, at: Vector3, xp_amount: int) -> XpSatchel:
	var bag := XpSatchel.new()
	bag.amount = xp_amount
	parent.add_child(bag)
	bag.global_position = at
	return bag


func _ready() -> void:
	add_to_group("xp_satchels")
	_build()


func _physics_process(delta: float) -> void:
	_time += delta
	_cloth_pivot.rotation.y = 0.35 * sin(_time * 3.1) + 0.15 * sin(_time * 7.3)
	_cloth_pivot.rotation.x = 0.12 * sin(_time * 5.2)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.is_dead():
		_label.visible = false
		return
	var d: Vector3 = player.global_position - global_position
	var flat: float = Vector2(d.x, d.z).length()
	_label.visible = flat < 8.0
	if flat <= PICKUP_RANGE and absf(d.y) < 1.6:
		queue_free()  # antes de avisar: así el guardado ya no lo cuenta
		player.recover_xp(amount, global_position)


func _build() -> void:
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color(0.36, 0.22, 0.12)
	leather.roughness = 0.85
	var bag := MeshInstance3D.new()
	var body := SphereMesh.new()
	body.radius = 0.22
	body.height = 0.32
	body.radial_segments = 10
	body.rings = 6
	bag.mesh = body
	bag.material_override = leather
	bag.position = Vector3(0.0, 0.15, 0.0)
	bag.scale = Vector3(1.2, 1.0, 0.9)
	add_child(bag)
	var flap := MeshInstance3D.new()
	var flap_mesh := BoxMesh.new()
	flap_mesh.size = Vector3(0.4, 0.04, 0.24)
	flap.mesh = flap_mesh
	flap.material_override = leather
	flap.position = Vector3(0.0, 0.29, 0.03)
	flap.rotation.x = deg_to_rad(-12.0)
	add_child(flap)
	# Estaca clavada con un jirón de tela roja: se ve de lejos.
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.3, 0.2, 0.12)
	var stake := MeshInstance3D.new()
	var stake_mesh := CylinderMesh.new()
	stake_mesh.top_radius = 0.025
	stake_mesh.bottom_radius = 0.035
	stake_mesh.height = 1.5
	stake.mesh = stake_mesh
	stake.material_override = wood
	stake.position = Vector3(0.32, 0.75, -0.1)
	add_child(stake)
	var cloth := MeshInstance3D.new()
	var cloth_mesh := BoxMesh.new()
	cloth_mesh.size = Vector3(0.5, 0.18, 0.01)
	cloth.mesh = cloth_mesh
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.75, 0.1, 0.08)
	red.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloth.material_override = red
	# El jirón cuelga de un pivote en la punta de la estaca; el pivote es lo que se agita.
	_cloth_pivot = Node3D.new()
	_cloth_pivot.position = Vector3(0.32, 1.38, -0.1)
	add_child(_cloth_pivot)
	cloth.position = Vector3(0.25, 0.0, 0.0)
	_cloth_pivot.add_child(cloth)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.fixed_size = true
	_label.pixel_size = 0.001
	_label.font_size = 26
	_label.outline_size = 8
	_label.modulate = Color(1.0, 0.85, 0.6)
	_label.text = "Tu morral  ·  %d de experiencia" % amount
	_label.position = Vector3(0.0, 1.0, 0.0)
	_label.visible = false
	add_child(_label)
