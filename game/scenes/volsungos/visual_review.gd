extends Node3D
## Self-contained art review, reachable from the main menu even without Mixamo installed.
const Actor = preload("res://scenes/volsungos/review_actor.gd")
const Props = preload("res://scenes/volsungos/nordic_props.gd")
const Cinema = preload("res://scenes/volsungos/forge_cinema.gd")
var actors: Array[VolsungosReviewActor] = []
var camera: Camera3D
var yaw: float = 0.0
var distance: float = 6.0
var dragging: bool = false
var _ui: Control
var _cinema: Control
var _motion_button: Button
var _motion: int = 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("131a20")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("c0c8d5")
	world.environment.ambient_light_energy = 0.32
	world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment.fog_enabled = true
	world.environment.fog_light_color = Color("3c444d")
	world.environment.fog_density = 0.012
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -25, 0)
	sun.light_color = Color("dce2ee")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(sun)
	var scenery := Props.new()
	add_child(scenery)
	scenery.hall()
	for i in 2:
		var actor := Actor.new()
		actor.hero = i == 0
		actor.position.x = -0.85 if i == 0 else 0.85
		actor.phase = i * 0.8
		add_child(actor)
		actors.append(actor)
	camera = Camera3D.new()
	camera.fov = 42
	add_child(camera)
	camera.make_current()
	_update_camera()
	_build_ui()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 112
	_ui.add_child(top)
	var titles := VBoxContainer.new()
	top.add_child(titles)
	var title := Label.new()
	title.text = "HIERRO Y CENIZA  /  LOS VOLSUNGOS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("d8bd8c"))
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Estudio de vestuario y ambiente · modelos provisionales"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles.add_child(subtitle)
	var hint := Label.new()
	hint.text = "Arrastra sobre la escena para girar · Rueda: acercar · Esc / B: volver"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles.add_child(hint)
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -310
	_ui.add_child(bottom)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	bottom.add_child(content)
	var references := HBoxContainer.new()
	references.alignment = BoxContainer.ALIGNMENT_CENTER
	references.add_theme_constant_override("separation", 18)
	content.add_child(references)
	for entry in [["sigurd", "Sigurd · referencia"], ["siggeir", "Siggeir · referencia"], ["signy", "Signy · referencia"], ["hall", "Salón · referencia"]]:
		var card := VBoxContainer.new()
		references.add_child(card)
		var texture := TextureRect.new()
		var render_path: String = "res://assets/volsungos/%s.jpg" % entry[0]
		if ResourceLoader.exists(render_path):
			texture.texture = load(render_path)
		texture.custom_minimum_size = Vector2(150, 170)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.add_child(texture)
		var caption := Label.new()
		caption.text = entry[1]
		if texture.texture == null:
			caption.text += "\nSin imagen local"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(caption)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	content.add_child(actions)
	_motion_button = _button("Movimiento: reposo", _cycle_motion, actions)
	_button("Ver la forja", _show_forge, actions)
	_button("Volver al menú", _back, actions)
	_motion_button.grab_focus()


func _button(text: String, action: Callable, parent: Node) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(200, 48)
	result.pressed.connect(action)
	parent.add_child(result)
	return result


func _cycle_motion() -> void:
	_motion = (_motion + 1) % 3
	for actor in actors:
		actor.motion = _motion
	_motion_button.text = "Movimiento: " + ["reposo", "marcha", "guardia"][ _motion ]


func _show_forge() -> void:
	if is_instance_valid(_cinema):
		return
	_ui.hide()
	_cinema = Cinema.new()
	_ui.get_parent().add_child(_cinema)
	_cinema.closed.connect(func() -> void:
		_ui.show()
		_motion_button.grab_focus()
		_cinema = null)


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_cinema):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(3.8, distance - 0.4)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(9, distance + 0.4)
		_update_camera()
	elif event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * 0.006
		_update_camera()


func _input(event: InputEvent) -> void:
	# Release even if the pointer finishes over a UI panel.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false


func _update_camera() -> void:
	camera.position = Vector3(sin(yaw) * distance, 2.5, cos(yaw) * distance)
	camera.look_at(Vector3(0, 0.65, 0))


func _back() -> void:
	if ResourceLoader.exists("res://scenes/ui/main_menu.tscn"):
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		get_tree().quit()
