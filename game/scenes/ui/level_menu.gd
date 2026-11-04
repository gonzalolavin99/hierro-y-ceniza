class_name LevelMenu
extends CanvasLayer
## Menú del campamento para subir atributos gastando experiencia. Se abre al descansar.
## Arriba / abajo elige, A / Intro sube un punto, B / Esc cierra y Kael se levanta.
## Lo crea el autoload Camps (siempre existe, oculto). Se construye en código.

signal closed

const ROW_COLOR: Color = Color(0.92, 0.88, 0.8)
const CANT_COLOR: Color = Color(0.6, 0.55, 0.5)

var _player: Player
var _root: Control
var _header: Label
var _rows: Dictionary[StringName, Button] = {}
var _description: Label
var _open: bool = false


func _ready() -> void:
	add_to_group("level_menu")
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func open(player: Player) -> void:
	_player = player
	_open = true
	_root.visible = true
	_refresh()
	_rows[Attributes.ORDER[0]].grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	var focused: Control = _root.get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	closed.emit()


func is_open() -> bool:
	return _open


func header_text() -> String:
	return _header.text


func focused_attribute() -> StringName:
	for key in _rows:
		if _rows[key].has_focus():
			return key
	return &""


func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _on_row_pressed(attribute: StringName) -> void:
	if not _open or _player == null:
		return
	if _player.raise_attribute(attribute):
		Sfx.play(&"pickup", _player.global_position + Vector3.UP * 1.0, -2.0, 0.0)
	else:
		Sfx.play(&"block", _player.global_position + Vector3.UP * 1.3, -18.0)
	_refresh()


func _on_row_focused(attribute: StringName) -> void:
	_description.text = Attributes.DESCRIPTIONS[attribute]


func _refresh() -> void:
	var attrs: Attributes = _player.attributes
	_header.text = "Nivel %d     Experiencia %d     Siguiente punto: %d" % [attrs.level(), _player.xp, attrs.next_cost()]
	for key in _rows:
		var value: int = attrs.get_value(key)
		var bonus: String = "máximo" if value >= Attributes.MAX_VALUE else attrs.next_bonus_text(key)
		_rows[key].text = "%-10s %2d      (%s)" % [Attributes.NAMES[key], value, bonus]
		var color: Color = ROW_COLOR if attrs.can_raise(key, _player.xp) else CANT_COLOR
		_rows[key].add_theme_color_override("font_color", color)
		_rows[key].add_theme_color_override("font_focus_color", color.lightened(0.2))
		_rows[key].add_theme_color_override("font_hover_color", color)
	var focused: StringName = focused_attribute()
	_on_row_focused(focused if focused != &"" else Attributes.ORDER[0])


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.035, 0.88)
	style.border_color = Color(0.55, 0.4, 0.25, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(110, 320)
	panel.custom_minimum_size = Vector2(760, 0)
	_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := _label("Campamento — Subir atributos", 34, Color(0.95, 0.82, 0.6))
	box.add_child(title)
	_header = _label("", 22, ROW_COLOR)
	box.add_child(_header)
	box.add_child(HSeparator.new())
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0, 0, 0, 0)
	flat.set_content_margin_all(6)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.55, 0.38, 0.2, 0.45)
	focus.set_corner_radius_all(4)
	focus.set_content_margin_all(6)
	for key in Attributes.ORDER:
		var row := Button.new()
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_font_size_override("font_size", 28)
		row.add_theme_stylebox_override("normal", flat)
		row.add_theme_stylebox_override("hover", flat)
		row.add_theme_stylebox_override("pressed", focus)
		row.add_theme_stylebox_override("focus", focus)
		row.pressed.connect(_on_row_pressed.bind(key))
		row.focus_entered.connect(_on_row_focused.bind(key))
		box.add_child(row)
		_rows[key] = row
	box.add_child(HSeparator.new())
	_description = _label("", 22, Color(0.85, 0.78, 0.65))
	box.add_child(_description)
	box.add_child(_label("A / Intro: subir un punto     ·     B / Esc: levantarse", 20, CANT_COLOR))


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
