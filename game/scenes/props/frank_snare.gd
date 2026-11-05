class_name FrankSnare
extends Node3D
## La red de los cazadores furtivos donde está atrapado Frank (guion §12), al principio del camino.
## Un poste con un brazo, una cuerda y la red colgando con Frank dentro. Al acercarse, Frank chilla
## pidiendo ayuda. Junto a la red: "Y  Soltar al tití" lanza la escena (FrankMeet).
## Si Kael pasa de largo (se aleja más de LEAVE_DISTANCE tras haberlo visto), Frank se suelta solo, lo
## alcanza corriendo y se le sube al hombro, ofendido. En los dos casos queda apuntado en Story.
## Todo se construye en código (piezas sencillas).

const SEEN_DISTANCE: float = 11.0
const LEAVE_DISTANCE: float = 26.0
const FREE_RANGE: float = 2.3
## Dónde cuelga la red (respecto al nodo) y a qué altura.
const BAG_AT: Vector3 = Vector3(0.0, 1.75, 0.0)
const BEAM_HEIGHT: float = 2.9
const BAG_RADIUS: float = 0.27
## Dónde se pone Kael para cortar la cuerda (respecto al nodo), mirando a la red.
const KAEL_SPOT: Vector3 = Vector3(0.0, 0.0, -1.15)

var scene: FrankMeet
var _player: Player
var _swing: Node3D
var _bag: Node3D
var _rope: MeshInstance3D
var _frank_seat: Node3D
var _prompt: Label3D
var _seen: bool = false
var _cut: bool = false
var _time: float = 0.0


func _ready() -> void:
	add_to_group("frank_snare")
	_build()
	Story.changed.connect(_sync)
	_sync.call_deferred()


func _sync() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	if Story.heard(Frank.STORY_MET):
		_show_cut()
	elif _player and _player.frank:
		_cut = false
		_seen = false
		_restore_bag()
		_player.frank.trap(_frank_seat)


func is_cut() -> bool:
	return _cut


func frank_trapped() -> bool:
	return _player != null and _player.frank != null and _player.frank.mode == Frank.Mode.TRAPPED


func kael_spot() -> Vector3:
	return global_transform * KAEL_SPOT


func bag_position() -> Vector3:
	return _bag.global_position


func can_free(player: Player) -> bool:
	if not frank_trapped() or scene != null:
		return false
	var d: Vector3 = player.global_position - global_position
	return Vector2(d.x, d.z).length() <= FREE_RANGE and player.state_machine.current.name == &"Ground"


func _process(delta: float) -> void:
	_time += delta
	if not _cut:
		var struggle: float = 0.05 if frank_trapped() else 0.0
		_swing.rotation = Vector3(sin(_time * 1.1) * 0.05, 0.0, sin(_time * 1.4) * 0.06 + sin(_time * 9.0) * struggle * 0.3)
	if _player == null or not frank_trapped() or scene != null:
		_prompt.visible = false
		return
	var distance: float = _player.global_position.distance_to(global_position)
	if distance <= SEEN_DISTANCE:
		_seen = true
		_player.frank.say(&"trapped")
	elif _seen and distance >= LEAVE_DISTANCE:
		frank_frees_himself()
		return
	_prompt.visible = can_free(_player)
	if _prompt.visible and Input.is_action_just_pressed("interact"):
		free_frank()


## Kael lo suelta: escena de la red.
func free_frank() -> FrankMeet:
	if not frank_trapped() or scene != null:
		return null
	_prompt.visible = false
	scene = FrankMeet.new()
	scene.setup(self, _player, _player.frank)
	scene.finished.connect(func() -> void: scene = null)
	add_child(scene)
	return scene


## Kael pasó de largo: Frank roe la red, cae, lo alcanza corriendo y se le sube al hombro, ofendido.
func frank_frees_himself() -> void:
	var frank: Frank = _player.frank
	Story.mark_heard(Frank.STORY_MET)
	# Aparece detrás de Kael (fuera de cámara) y llega corriendo.
	var behind: Vector3 = _player.global_position + _player.model.global_basis.z * 5.0
	frank.run_to_kael(behind)
	drop_bag()
	await frank.perched
	frank.say(&"offended")
	await get_tree().create_timer(Voice.last_seconds + 0.4, false).timeout
	frank.say(&"offended_2")
	await get_tree().create_timer(Voice.last_seconds + 0.6, false).timeout
	Story.narrate(&"story_frank_left")
	SaveGame.save(_player)


## Corta la cuerda: la red cae al suelo.
func drop_bag() -> void:
	if _cut:
		return
	_cut = true
	_prompt.visible = false
	Sfx.play(&"swing", _bag.global_position)
	var tween := create_tween().set_parallel()
	tween.tween_property(_bag, "position:y", -(BEAM_HEIGHT - BAG_RADIUS * 0.6), 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_bag, "scale", Vector3(1.1, 0.4, 1.1), 0.35).set_delay(0.3)
	tween.tween_property(_rope, "scale:y", 0.35, 0.2)
	tween.tween_property(_rope, "position:y", -_rope_length() * 0.35 * 0.5, 0.2)
	_swing.rotation = Vector3.ZERO


func _show_cut() -> void:
	_cut = true
	_swing.rotation = Vector3.ZERO
	_bag.position = Vector3(0.0, -(BEAM_HEIGHT - BAG_RADIUS * 0.6), 0.0)
	_bag.scale = Vector3(1.1, 0.4, 1.1)
	_rope.scale.y = 0.35
	_rope.position.y = -_rope_length() * 0.35 * 0.5
	_prompt.visible = false


func _restore_bag() -> void:
	_bag.position = Vector3(0.0, BAG_AT.y - BEAM_HEIGHT, 0.0)
	_bag.scale = Vector3.ONE
	_rope.scale.y = 1.0
	_rope.position.y = -_rope_length() * 0.5


func _rope_length() -> float:
	return BEAM_HEIGHT - BAG_AT.y - BAG_RADIUS * 1.1


# --- Construcción ---------------------------------------------------------------------------------

func _build() -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.33, 0.23, 0.14)
	wood.roughness = 0.95
	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.62, 0.53, 0.37)
	# Poste clavado a un lado y brazo que sale hasta encima de la red.
	var post_x: float = -1.15
	add_child(_box(Vector3(post_x, BEAM_HEIGHT * 0.5 + 0.1, 0.0), Vector3(0.16, BEAM_HEIGHT + 0.2, 0.16), wood))
	add_child(_box(Vector3(post_x * 0.5 + 0.1, BEAM_HEIGHT, 0.0), Vector3(absf(post_x) + 0.45, 0.12, 0.12), wood))
	add_child(_box(Vector3(post_x + 0.25, BEAM_HEIGHT - 0.25, 0.0), Vector3(0.08, 0.55, 0.08), wood, 45.0))  # Riostra.
	# Lo que dejaron los cazadores: una jaula vacía y una caja.
	add_child(_box(Vector3(-1.9, 0.25, 0.6), Vector3(0.6, 0.5, 0.5), wood, 12.0))
	_build_cage(Vector3(-1.7, 0.0, -0.5), wood)
	# Cuerda y red: cuelgan de un pivote en la punta del brazo (se mecen).
	_swing = Node3D.new()
	_swing.name = "Swing"
	_swing.position = Vector3(0.0, BEAM_HEIGHT, 0.0)
	add_child(_swing)
	var rope_length: float = _rope_length()
	var rope_mesh := CylinderMesh.new()
	rope_mesh.top_radius = 0.012
	rope_mesh.bottom_radius = 0.012
	rope_mesh.height = rope_length
	rope_mesh.material = rope_mat
	_rope = MeshInstance3D.new()
	_rope.mesh = rope_mesh
	_swing.add_child(_rope)
	_bag = Node3D.new()
	_bag.name = "Bag"
	_swing.add_child(_bag)
	var net := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = BAG_RADIUS
	sphere.height = BAG_RADIUS * 2.2
	sphere.material = _net_material()
	net.mesh = sphere
	_bag.add_child(net)
	var knot := MeshInstance3D.new()
	var knot_mesh := SphereMesh.new()
	knot_mesh.radius = 0.05
	knot_mesh.height = 0.09
	knot_mesh.material = rope_mat
	knot.mesh = knot_mesh
	knot.position = Vector3(0.0, BAG_RADIUS * 1.05, 0.0)
	_bag.add_child(knot)
	_frank_seat = Node3D.new()
	_frank_seat.name = "FrankSeat"
	_frank_seat.position = Vector3(0.0, -BAG_RADIUS * 0.8, 0.0)
	_bag.add_child(_frank_seat)
	_restore_bag()
	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.fixed_size = true
	_prompt.pixel_size = 0.0012
	_prompt.font_size = 28
	_prompt.outline_size = 8
	_prompt.text = "Y  Soltar al tití"
	_prompt.modulate = Color(1.0, 0.92, 0.75)
	_prompt.position = Vector3(0.0, 1.0, -0.4)
	_prompt.visible = false
	add_child(_prompt)


func _build_cage(at: Vector3, wood: StandardMaterial3D) -> void:
	var size: float = 0.5
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			add_child(_box(at + Vector3(x * size * 0.5, size * 0.5, z * size * 0.5), Vector3(0.04, size, 0.04), wood))
	for i in 5:
		var off: float = lerpf(-size * 0.5, size * 0.5, i / 4.0)
		add_child(_box(at + Vector3(off, size * 0.5, -size * 0.5), Vector3(0.02, size, 0.02), wood))
		add_child(_box(at + Vector3(off, size * 0.5, size * 0.5), Vector3(0.02, size, 0.02), wood))
	add_child(_box(at + Vector3(0.0, size, 0.0), Vector3(size + 0.06, 0.04, size + 0.06), wood))


## Malla de cuerda: una esfera con un material que solo deja ver líneas en rombo (lo demás, hueco).
func _net_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 rope_color = vec3(0.6, 0.5, 0.34);
uniform float cells = 16.0;
uniform float thickness = 0.065;
void fragment() {
	vec2 uv = UV * vec2(cells * 2.0, cells);
	float a = abs(fract(uv.x + uv.y) - 0.5);
	float b = abs(fract(uv.x - uv.y) - 0.5);
	if (min(a, b) > thickness) {
		discard;
	}
	ALBEDO = rope_color;
	ROUGHNESS = 1.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = shader
	return m


func _box(at: Vector3, size: Vector3, material: Material, tilt_degrees: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.rotation_degrees.z = tilt_degrees
	return part
