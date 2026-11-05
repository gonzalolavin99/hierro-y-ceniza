class_name PauseMenu
extends CanvasLayer
## Menú de pausa (Start / Esc): congela el juego. Continuar · Inventario (objetos y sus descripciones,
## ItemLore) · Controles · Empezar de nuevo (pide
## confirmación y borra la partida guardada) · Salir. Start o B / Esc vuelve atrás o cierra.
## Lo crea el autoload Camps (siempre existe, oculto). Se construye en código.

const TEXT_COLOR: Color = Color(0.92, 0.88, 0.8)
const DIM_COLOR: Color = Color(0.6, 0.55, 0.5)
const TITLE_COLOR: Color = Color(0.95, 0.82, 0.6)
## Lista de controles (mando · teclado · qué hace).
const CONTROLS: Array = [
	["Stick izq. / WASD", "Moverse"],
	["Stick der. / Flechas", "Cámara"],
	["A / Espacio", "Saltar (en el aire junto al enemigo: pisotón)"],
	["B / Shift", "Con dirección: rodar · Sin dirección: paso atrás · Mantener: correr"],
	["RB / J", "Ataque (×3 combo) · al enemigo expuesto: golpe mortal"],
	["RT / L", "Golpe pesado"],
	["LB / K", "Mantener: guardia · Tocar a tiempo: desviar"],
	["LB+RB / K+J", "Técnica equipada"],
	["Y / F", "Patada: rompe la guardia"],
	["Y / E junto a la fogata", "Descansar y subir atributos"],
	["X / R", "Vendarse (cura; quieto y sin guardia)"],
	["LT / Q", "Arma secundaria"],
	["Cruceta ← → / 1, 2", "Cambiar de arma secundaria"],
	["Cruceta ↑ / 3", "Cambiar de técnica"],
	["L3 / C", "Agacharse (sigilo)"],
	["R3 / Tab", "Fijar objetivo"],
	["Start / Esc", "Pausa"],
]

## Para las pruebas: si es false, "Empezar de nuevo" no recarga la escena (solo cuenta la petición).
var reload_on_restart: bool = true
var restart_count: int = 0

var _root: Control
var _pages: Dictionary[StringName, Control] = {}
var _buttons: Dictionary[StringName, Button] = {}
var _controls_label: Label
var _item_list: VBoxContainer
var _item_buttons: Dictionary[StringName, Button] = {}
var _item_name: Label
var _item_kind: Label
var _item_text: Label
var _page: StringName = &""
var _open: bool = false


func _ready() -> void:
	add_to_group("pause_menu")
	layer = 58
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func is_open() -> bool:
	return _open


func showing() -> StringName:
	return _page


func focused_option() -> StringName:
	for key in _buttons:
		if _buttons[key].has_focus():
			return key
	return &""


## Objeto señalado en el inventario (o &"" si no hay).
func focused_item() -> StringName:
	for id in _item_buttons:
		if _item_buttons[id].has_focus():
			return id
	return &""


## Objetos que muestra ahora el inventario, en orden.
func inventory_items() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_item_buttons.keys())
	return result


## Texto de la descripción que se ve ahora (nombre, tipo y descripción).
func item_description() -> String:
	return "%s
%s
%s" % [_item_name.text, _item_kind.text, _item_text.text]


func controls_text() -> String:
	return _controls_label.text


func open() -> void:
	_open = true
	_root.visible = true
	get_tree().paused = true
	_show(&"main")


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	_page = &""
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	# Se quita la pausa un instante después: así el botón que cerró el menú (A) no hace saltar a Kael.
	get_tree().create_timer(0.08, true, false, true).timeout.connect(_unpause)


func _unpause() -> void:
	if not _open:
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		if event.is_action_pressed("pause") and not Camps.level_menu.is_open():
			get_viewport().set_input_as_handled()
			open()
		return
	# Esc es a la vez "pausa" y "volver": primero vuelve atrás; en el menú principal, cierra.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _page == &"main":
			close()
		else:
			_show(&"main", {&"controls": &"controls", &"inventory": &"inventory"}.get(_page, &"restart"))
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _show(page: StringName, focus: StringName = &"") -> void:
	if page == &"inventory":
		_fill_inventory()
	_page = page
	for key in _pages:
		_pages[key].visible = key == page
	var first: StringName = focus
	if first == &"":
		first = {&"main": &"continue", &"controls": &"back", &"confirm": &"no", &"inventory": &"inv_back"}[page]
	if page == &"inventory" and not _item_buttons.is_empty():
		_item_buttons[_item_buttons.keys()[0]].grab_focus()
		return
	_buttons[first].grab_focus()


func _on_option(option: StringName) -> void:
	match option:
		&"continue":
			close()
		&"inventory":
			_show(&"inventory")
		&"inv_back":
			_show(&"main", &"inventory")
		&"controls":
			_show(&"controls")
		&"back":
			_show(&"main", &"controls")
		&"restart":
			_show(&"confirm")
		&"no":
			_show(&"main", &"restart")
		&"yes":
			_restart()
		&"quit":
			get_tree().quit()


func _restart() -> void:
	SaveGame.erase()
	restart_count += 1
	close()
	if reload_on_restart:
		get_tree().paused = false
		Camps.fade_to(0.0, 0.0)
		get_tree().reload_current_scene()


# --- Construcción --------------------------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)

	var main := _panel(Vector2(560, 0))
	main.add_child(_label("Pausa", 40, TITLE_COLOR))
	main.add_child(HSeparator.new())
	for entry in [[&"continue", "Continuar"], [&"inventory", "Inventario"], [&"controls", "Controles"], [&"restart", "Empezar de nuevo"], [&"quit", "Salir del juego"]]:
		main.add_child(_button(entry[0], entry[1]))
	main.add_child(HSeparator.new())
	main.add_child(_label("A / Intro: elegir     ·     B / Esc: volver", 20, DIM_COLOR))
	_pages[&"main"] = main.get_meta("page")

	var controls := _panel(Vector2(1100, 0))
	controls.add_child(_label("Controles  (mando / teclado)", 34, TITLE_COLOR))
	controls.add_child(HSeparator.new())
	var lines: PackedStringArray = []
	for row in CONTROLS:
		lines.append("%s  —  %s" % [row[0], row[1]])
	_controls_label = _label("\n".join(lines), 22, TEXT_COLOR)
	controls.add_child(_controls_label)
	controls.add_child(HSeparator.new())
	controls.add_child(_button(&"back", "Volver"))
	_pages[&"controls"] = controls.get_meta("page")

	var inventory := _panel(Vector2(1180, 0))
	inventory.add_child(_label("Inventario", 34, TITLE_COLOR))
	inventory.add_child(HSeparator.new())
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	inventory.add_child(columns)
	_item_list = VBoxContainer.new()
	_item_list.custom_minimum_size = Vector2(400, 0)
	_item_list.add_theme_constant_override("separation", 2)
	columns.add_child(_item_list)
	var details := VBoxContainer.new()
	details.custom_minimum_size = Vector2(640, 0)
	details.add_theme_constant_override("separation", 10)
	columns.add_child(details)
	_item_name = _label("", 32, TITLE_COLOR)
	details.add_child(_item_name)
	_item_kind = _label("", 20, DIM_COLOR)
	details.add_child(_item_kind)
	_item_text = _label("", 23, TEXT_COLOR)
	_item_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_item_text.custom_minimum_size = Vector2(640, 0)
	details.add_child(_item_text)
	inventory.add_child(HSeparator.new())
	inventory.add_child(_button(&"inv_back", "Volver"))
	_pages[&"inventory"] = inventory.get_meta("page")

	var confirm := _panel(Vector2(760, 0))
	confirm.add_child(_label("¿Empezar de nuevo?", 36, TITLE_COLOR))
	var warning := _label("Se borrará tu partida: atributos, experiencia, morral y campamento.\nNo se puede deshacer.", 22, TEXT_COLOR)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm.add_child(warning)
	confirm.add_child(HSeparator.new())
	confirm.add_child(_button(&"no", "No, volver"))
	confirm.add_child(_button(&"yes", "Sí, borrar y empezar de nuevo"))
	_pages[&"confirm"] = confirm.get_meta("page")


## Rehace la lista del inventario con lo que lleva Kael ahora.
func _fill_inventory() -> void:
	for child in _item_list.get_children():
		_item_list.remove_child(child)
		child.queue_free()
	_item_buttons.clear()
	_describe(&"")
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	for id: StringName in ItemLore.owned(player):
		var count: String = ItemLore.count_text(player, id)
		var text: String = ItemLore.ITEMS[id]["name"] + ("   " + count if count != "" else "")
		var button := _button(&"", text)
		button.add_theme_font_size_override("font_size", 23)
		button.focus_entered.connect(_describe.bind(id))
		_item_list.add_child(button)
		_item_buttons[id] = button
	# Bajar desde el último objeto lleva a "Volver"; subir desde "Volver", al último objeto.
	var last: Button = _item_buttons[_item_buttons.keys()[-1]]
	last.focus_neighbor_bottom = _buttons[&"inv_back"].get_path()
	_buttons[&"inv_back"].focus_neighbor_top = last.get_path()


func _describe(id: StringName) -> void:
	if id == &"":
		_item_name.text = ""
		_item_kind.text = ""
		_item_text.text = ""
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	var count: String = ItemLore.count_text(player, id) if player else ""
	_item_name.text = ItemLore.ITEMS[id]["name"]
	_item_kind.text = ItemLore.ITEMS[id]["kind"] + ("   ·   lleva " + count if count != "" else "")
	_item_text.text = ItemLore.ITEMS[id]["text"]


## Panel centrado; devuelve la caja donde van los elementos.
func _panel(min_size: Vector2) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.035, 0.94)
	style.border_color = Color(0.55, 0.4, 0.25, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = min_size
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	# La página es el CenterContainer (box → panel → center).
	box.set_meta("page", center)
	return box


func _button(key: StringName, text: String) -> Button:
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0, 0, 0, 0)
	flat.set_content_margin_all(8)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.55, 0.38, 0.2, 0.45)
	focus.set_corner_radius_all(4)
	focus.set_content_margin_all(8)
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.85))
	button.add_theme_color_override("font_hover_color", TEXT_COLOR)
	button.add_theme_stylebox_override("normal", flat)
	button.add_theme_stylebox_override("hover", flat)
	button.add_theme_stylebox_override("pressed", focus)
	button.add_theme_stylebox_override("focus", focus)
	if key != &"":  # Los objetos del inventario no son opciones del menú.
		button.pressed.connect(_on_option.bind(key))
		_buttons[key] = button
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
