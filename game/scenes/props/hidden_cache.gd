class_name HiddenCache
extends Node3D
## Escondite: un hatillo de tela y una cesta medio tapados, en un rincón que no se ve a simple vista.
## Frank lo huele: al acercarse Kael (FIND_RANGE) lo señala y chilla, y el escondite brilla un poco.
## Junto a él: "Y  Recoger" da experiencia y, si tiene, un objeto clave (ItemLore). Queda apuntado en Story
## ("cache_<id>") y no vuelve a aparecer. Se construye en código.

## Distancia a la que Frank lo encuentra.
const FIND_RANGE: float = 8.0
const PICKUP_RANGE: float = 1.7

@export var cache_id: StringName = &"cache"
@export var reward_xp: int = 100
## Objeto clave que contiene (vacío = solo experiencia).
@export var reward_item: StringName = &""

## Frank ya lo señaló (brilla).
var revealed: bool = false
var _player: Player
var _prompt: Label3D
var _glint: OmniLight3D
var _visual: Node3D
var _time: float = 0.0


func _ready() -> void:
	add_to_group("hidden_caches")
	_build()
	Story.changed.connect(_sync)
	_sync.call_deferred()


func story_flag() -> StringName:
	return StringName("cache_%s" % cache_id)


func is_taken() -> bool:
	return Story.heard(story_flag())


func _sync() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	revealed = false
	visible = not is_taken()


## Frank lo ha encontrado: brilla para que se vea.
func reveal() -> void:
	revealed = true


func can_pick(player: Player) -> bool:
	if is_taken() or player == null:
		return false
	var d: Vector3 = player.global_position - global_position
	return Vector2(d.x, d.z).length() <= PICKUP_RANGE and absf(d.y) < 1.5 \
		and player.state_machine.current.name == &"Ground"


func _process(delta: float) -> void:
	_time += delta
	_glint.visible = revealed and visible
	_glint.light_energy = 0.6 + 0.3 * sin(_time * 4.0)
	if not visible:
		_prompt.visible = false
		return
	_prompt.visible = can_pick(_player)
	if _prompt.visible and Input.is_action_just_pressed("interact"):
		pick(_player)


## Kael lo recoge.
func pick(player: Player) -> void:
	if is_taken():
		return
	Story.mark_heard(story_flag())
	visible = false
	_prompt.visible = false
	Sfx.play(&"pickup", global_position + Vector3.UP * 0.3)
	if reward_xp > 0:
		player.gain_xp(reward_xp)
	if reward_item != &"" and not player.key_items.has(reward_item):
		player.key_items.append(reward_item)
	_show_reward_text()
	if player.frank and player.frank.mode == Frank.Mode.PERCHED:
		# La nota de los cazadores le toca de cerca: no hay broma.
		player.frank.say(&"poacher_note" if reward_item == &"poacher_note" else &"found_item")
		if reward_item == &"poacher_note":
			player.frank.gesture(Frank.Pose.SAD, 4.0)
	SaveGame.save(player)


func _show_reward_text() -> void:
	var parts: PackedStringArray = []
	if reward_item != &"":
		parts.append(ItemLore.ITEMS.get(reward_item, {}).get("name", String(reward_item)))
	if reward_xp > 0:
		parts.append("+%d experiencia" % reward_xp)
	var label := Label3D.new()
	label.text = "\n".join(parts)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0012
	label.font_size = 30
	label.outline_size = 8
	label.modulate = Color(1.0, 0.92, 0.7)
	get_parent().add_child(label)
	label.global_position = global_position + Vector3.UP * 1.0
	var tween := label.create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y + 0.8, 2.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.2).set_delay(1.0)
	tween.tween_callback(label.queue_free)


func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.45, 0.38, 0.3)
	cloth.roughness = 1.0
	var wicker := StandardMaterial3D.new()
	wicker.albedo_color = Color(0.52, 0.4, 0.22)
	wicker.roughness = 1.0
	# Hatillo atado.
	var bundle := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.3
	sphere.material = cloth
	bundle.mesh = sphere
	bundle.position = Vector3(0.0, 0.15, 0.0)
	_visual.add_child(bundle)
	var knot := MeshInstance3D.new()
	var knot_mesh := SphereMesh.new()
	knot_mesh.radius = 0.06
	knot_mesh.height = 0.1
	knot_mesh.material = cloth
	knot.mesh = knot_mesh
	knot.position = Vector3(0.0, 0.31, 0.0)
	_visual.add_child(knot)
	# Cesta al lado.
	var basket := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.17
	cylinder.bottom_radius = 0.13
	cylinder.height = 0.22
	cylinder.material = wicker
	basket.mesh = cylinder
	basket.position = Vector3(0.32, 0.11, 0.05)
	_visual.add_child(basket)
	_glint = OmniLight3D.new()
	_glint.light_color = Color(1.0, 0.85, 0.55)
	_glint.omni_range = 1.4
	_glint.position = Vector3(0.1, 0.5, 0.0)
	_glint.visible = false
	add_child(_glint)
	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.fixed_size = true
	_prompt.pixel_size = 0.0012
	_prompt.font_size = 28
	_prompt.outline_size = 8
	_prompt.text = "Y  Recoger"
	_prompt.modulate = Color(1.0, 0.92, 0.75)
	_prompt.position = Vector3(0.0, 0.8, 0.0)
	_prompt.visible = false
	add_child(_prompt)
