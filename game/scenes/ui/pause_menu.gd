class_name PauseMenu
extends CanvasLayer
## Menú de pausa (Start / Esc): congela el juego. Continuar · Controles · Empezar de nuevo (pide
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
	["B / Shift", "Tocar: paso rápido · Mantener: correr"],
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
			_show(&"main", &"controls" if _page == &"controls" else &"restart")
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _show(page: StringName, focus: StringName = &"") -> void:
	_page = page
	for key in _pages:
		_pages[key].visible = key == page
	var first: StringName = focus
	if first == &"":
		first = {&"main": &"continue", &"controls": &"back", &"confirm": &"no"}[page]
	_buttons[first].grab_focus()


func _on_option(option: StringName) -> void:
	match option:
		&"continue":
			close()
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
	for entry in [[&"continue", "Continuar"], [&"controls", "Controles"], [&"restart", "Empezar de nuevo"], [&"quit", "Salir del juego"]]:
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

	var confirm := _panel(Vector2(760, 0))
	confirm.add_child(_label("¿Empezar de nuevo?", 36, TITLE_COLOR))
	var warning := _label("Se borrará tu partida: atributos, experiencia, morral y campamento.\nNo se puede deshacer.", 22, TEXT_COLOR)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm.add_child(warning)
	confirm.add_child(HSeparator.new())
	confirm.add_child(_button(&"no", "No, volver"))
	confirm.add_child(_button(&"yes", "Sí, borrar y empezar de nuevo"))
	_pages[&"confirm"] = confirm.get_meta("page")


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
	button.pressed.connect(_on_option.bind(key))
	_buttons[key] = button
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
