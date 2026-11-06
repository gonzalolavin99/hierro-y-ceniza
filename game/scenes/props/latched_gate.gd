class_name LatchedGate
extends Node3D
## Despensa con la puerta atrancada por dentro (un atajo en pequeño, guion §12: "abre pestillos desde el otro
## lado"). Kael no puede entrar: los muros son altos y la puerta no cede. Con Frank en el hombro, junto a la
## puerta: "Y  Que Frank abra el pestillo": Frank salta al muro, se cuela dentro, quita el pestillo, la puerta
## se abre y vuelve al hombro. Queda abierta para siempre (Story "gate_<id>"). Sin Frank: "Cerrado por dentro".
## La puerta está en el lado -Z. Se construye en código (muros con colisión).

const SIZE: Vector3 = Vector3(3.6, 3.0, 3.6)
const DOOR_WIDTH: float = 1.1
const DOOR_HEIGHT: float = 2.1
const WALL: float = 0.2
const USE_RANGE: float = 2.4
## Distancia a la que Frank comenta que está cerrado.
const NOTICE_RANGE: float = 6.0

@export var gate_id: StringName = &"gate"

var _player: Player
var _hinge: Node3D
var _door: AnimatableBody3D
var _prompt: Label3D
var _busy: bool = false
var _noticed: bool = false


func _ready() -> void:
	add_to_group("latched_gates")
	_build()
	Story.changed.connect(_sync)
	_sync.call_deferred()


func story_flag() -> StringName:
	return StringName("gate_%s" % gate_id)


func is_open() -> bool:
	return Story.heard(story_flag())


func _sync() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	_busy = false
	_noticed = false
	_hinge.rotation.y = deg_to_rad(-100.0) if is_open() else 0.0


## Punto delante de la puerta, por fuera.
func outside_point() -> Vector3:
	return global_transform * Vector3(0.0, 0.0, -SIZE.z * 0.5 - 0.9)


func frank_ready() -> bool:
	return _player != null and _player.frank != null and _player.frank.mode == Frank.Mode.PERCHED


func near_door(player: Player) -> bool:
	if player == null:
		return false
	var local: Vector3 = global_transform.affine_inverse() * player.global_position
	return local.z < -SIZE.z * 0.5 and Vector2(local.x, local.z + SIZE.z * 0.5).length() <= USE_RANGE


func can_open(player: Player) -> bool:
	return not is_open() and not _busy and near_door(player) and frank_ready() \
		and player.state_machine.current.name == &"Ground"


func _process(_delta: float) -> void:
	if _player == null or is_open() or _busy:
		_prompt.visible = false
		return
	var near: bool = near_door(_player)
	_prompt.visible = near
	if near:
		_prompt.text = "Y  Que Frank abra el pestillo" if frank_ready() else "Cerrado por dentro"
	# Frank se ofrece la primera vez que se acercan.
	if not _noticed and frank_ready() and _player.frank.advisor.can_talk() 			and _player.global_position.distance_to(outside_point()) <= NOTICE_RANGE:
		_noticed = _player.frank.say(&"gate_locked")  # Si estaba hablando, lo intenta otra vez luego.
	if near and can_open(_player) and Input.is_action_just_pressed("interact"):
		frank_opens()


## Frank salta el muro, quita el pestillo y vuelve al hombro.
func frank_opens() -> void:
	if not frank_ready() or is_open() or _busy:
		return
	_busy = true
	_prompt.visible = false
	var frank: Frank = _player.frank
	frank.say(&"gate_go")
	var wall_top := Transform3D(global_basis, global_transform * Vector3(0.6, SIZE.y + 0.02, -SIZE.z * 0.5))
	frank.hop(func() -> Transform3D: return wall_top, 0.6, 1.0, Frank.Mode.GROUND)
	await get_tree().create_timer(0.9, false).timeout
	var inside: Vector3 = global_transform * Vector3(0.35, 0.0, -SIZE.z * 0.5 + 0.5)
	frank.hop_to_ground(inside, global_basis * Vector3.FORWARD, 0.5, 0.3)
	await get_tree().create_timer(0.9, false).timeout
	Sfx.play(&"block", global_transform * Vector3(0.4, 1.1, -SIZE.z * 0.5), -6.0)  # El pestillo.
	Story.mark_heard(story_flag())
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hinge, "rotation:y", deg_to_rad(-100.0), 0.9)
	await get_tree().create_timer(0.5, false).timeout
	frank.say(&"gate_done")
	await get_tree().create_timer(0.8, false).timeout
	frank.hop_to_shoulder(0.7)
	await frank.perched
	_busy = false
	SaveGame.save(_player)


func _build() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.42, 0.36, 0.3)
	stone.roughness = 1.0
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.36, 0.25, 0.15)
	wood.roughness = 0.95
	var walls := StaticBody3D.new()
	walls.name = "Walls"
	add_child(walls)
	var half: Vector3 = SIZE * 0.5
	# Atrás, izquierda y derecha.
	_wall(walls, Vector3(0.0, half.y, half.z), Vector3(SIZE.x, SIZE.y, WALL), stone)
	_wall(walls, Vector3(-half.x, half.y, 0.0), Vector3(WALL, SIZE.y, SIZE.z), stone)
	_wall(walls, Vector3(half.x, half.y, 0.0), Vector3(WALL, SIZE.y, SIZE.z), stone)
	# Delante, con el hueco de la puerta.
	var side: float = (SIZE.x - DOOR_WIDTH) * 0.5
	_wall(walls, Vector3(-half.x + side * 0.5, half.y, -half.z), Vector3(side, SIZE.y, WALL), stone)
	_wall(walls, Vector3(half.x - side * 0.5, half.y, -half.z), Vector3(side, SIZE.y, WALL), stone)
	_wall(walls, Vector3(0.0, DOOR_HEIGHT + (SIZE.y - DOOR_HEIGHT) * 0.5, -half.z),
		Vector3(DOOR_WIDTH, SIZE.y - DOOR_HEIGHT, WALL), stone)
	# Puerta: gira sobre la bisagra de la izquierda, hacia dentro.
	_hinge = Node3D.new()
	_hinge.name = "Hinge"
	_hinge.position = Vector3(-DOOR_WIDTH * 0.5, 0.0, -half.z)
	add_child(_hinge)
	_door = AnimatableBody3D.new()
	_door.name = "Door"
	_door.sync_to_physics = false  # La mueve la bisagra (su padre): que la colisión la siga tal cual.
	_hinge.add_child(_door)
	_wall(_door, Vector3(DOOR_WIDTH * 0.5, DOOR_HEIGHT * 0.5, 0.0), Vector3(DOOR_WIDTH - 0.04, DOOR_HEIGHT, 0.08), wood)
	for y in [0.4, 1.7]:  # Travesaños.
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(DOOR_WIDTH - 0.1, 0.1, 0.04)
		box.material = wood
		bar.mesh = box
		bar.position = Vector3(DOOR_WIDTH * 0.5, y, -0.06)
		_door.add_child(bar)
	# Letrero pintado a mano.
	var sign := Label3D.new()
	sign.text = "NO TOCAR"
	sign.font_size = 40
	sign.pixel_size = 0.006
	sign.modulate = Color(0.85, 0.8, 0.7)
	sign.position = Vector3(DOOR_WIDTH * 0.5, 1.25, -0.05)
	sign.rotation.y = PI
	_door.add_child(sign)
	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.fixed_size = true
	_prompt.pixel_size = 0.0012
	_prompt.font_size = 28
	_prompt.outline_size = 8
	_prompt.modulate = Color(1.0, 0.92, 0.75)
	_prompt.position = Vector3(0.0, 1.6, -half.z - 0.4)
	_prompt.visible = false
	add_child(_prompt)


func _wall(body: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = material
	mesh.mesh = box
	mesh.position = at
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position = at
	body.add_child(shape)
