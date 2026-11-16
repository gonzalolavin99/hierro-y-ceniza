class_name MainMenu
extends Control
## Menú principal (Hito 9, paso 6a: lo mínimo para dar el `.exe` a probar). Título, versión y:
## Continuar (si hay partida guardada) · Partida nueva (si ya hay una, pide confirmación: se borra) · Salir.
## Con mando (cruceta/stick y A) o teclado (flechas e Intro). Se construye en código.

const BG_COLOR := Color("1c1e21")
const TITLE_COLOR := Color(0.95, 0.82, 0.6)
const TEXT_COLOR := Color(0.92, 0.88, 0.8)
const DIM_COLOR := Color(0.6, 0.55, 0.5)

## Para las pruebas: no cambiar de escena ni cerrar el juego al elegir (se mira `chosen`).
var dry_run: bool = false
## Lo último que se eligió: &"continue", &"new", &"quit".
var chosen: StringName = &""

var _buttons: Dictionary[StringName, Button] = {}
var _main: VBoxContainer
var _confirm: VBoxContainer
var _music: AudioStreamPlayer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = false
	_build()
	_show_main()


func has_save() -> bool:
	return FileAccess.file_exists(SaveGame.path) or FileAccess.file_exists(SaveGame.backup_path())


func press(id: StringName) -> void:
	match id:
		&"continue":
			_start(false)
		&"new":
			if has_save():
				_main.visible = false
				_confirm.visible = true
				_buttons[&"no"].grab_focus()
			else:
				_start(true)
		&"yes":
			if not dry_run and not _combat_ready():
				_show_missing_assets()
				return
			SaveGame.erase()
			_start(true)
		&"no":
			_show_main()
		&"quit":
			chosen = &"quit"
			if not dry_run:
				get_tree().quit()
		&"volsungos":
			chosen = &"volsungos"
			if not dry_run:
				get_tree().change_scene_to_file("res://scenes/volsungos/visual_review.tscn")


func _start(new_game: bool) -> void:
	chosen = &"new" if new_game else &"continue"
	if dry_run:
		return
	if not _combat_ready():
		_show_missing_assets()
		return
	Camps.fade_to(1.0, 0.0)
	get_tree().change_scene_to_file(GameInfo.GAME_SCENE)
	Camps.fade_to(0.0, 0.8)


func _combat_ready() -> bool:
	return ResourceLoader.exists("res://assets/animations/mixamo/y_bot.fbx") and ResourceLoader.exists("res://assets/animations/mixamo_library.res")


func _show_missing_assets() -> void:
	var notice := AcceptDialog.new()
	notice.title = "Instalación de los personajes"
	notice.dialog_text = "Faltan el modelo y las animaciones originales de Mixamo.\nConsulta docs/06_ARQUITECTURA_TECNICA.md para instalarlos.\nPuedes abrir el taller Los Volsungos sin esos archivos."
	add_child(notice)
	notice.confirmed.connect(notice.queue_free)
	notice.canceled.connect(notice.queue_free)
	notice.popup_centered()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _confirm.visible:
		get_viewport().set_input_as_handled()
		_show_main()


func _show_main() -> void:
	_confirm.visible = false
	_main.visible = true
	_buttons[&"continue"].visible = has_save()
	(_buttons[&"continue"] if has_save() else _buttons[&"new"]).grab_focus()


# --- Construcción --------------------------------------------------------------------

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art := TextureRect.new()
	if ResourceLoader.exists("res://assets/volsungos/hall.jpg"):
		art.texture = load("res://assets/volsungos/hall.jpg")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(art)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.04, 0.05, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	# Un resplandor cálido abajo: la fogata del narrador.
	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	glow.offset_top = -380.0
	var gradient := Gradient.new()
	gradient.set_color(0, Color(StylePalette.EMBER, 0.0))
	gradient.set_color(1, Color(StylePalette.EMBER, 0.16))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	var glow_rect := TextureRect.new()
	glow_rect.texture = tex
	glow_rect.stretch_mode = TextureRect.STRETCH_SCALE
	glow_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0, 0, 0, 0)
	glow.add_child(glow_rect)
	add_child(glow)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	column.add_child(_label(GameInfo.TITLE, 84, TITLE_COLOR))
	column.add_child(_label("Una leyenda del Paso de Hierro", 26, DIM_COLOR))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 40)
	column.add_child(gap)

	_main = VBoxContainer.new()
	_main.add_theme_constant_override("separation", 10)
	column.add_child(_main)
	for entry in [[&"continue", "Continuar"], [&"new", "Partida nueva"], [&"volsungos", "Los Volsungos · taller 3D"], [&"quit", "Salir"]]:
		_main.add_child(_button(entry[0], entry[1]))

	_confirm = VBoxContainer.new()
	_confirm.add_theme_constant_override("separation", 10)
	column.add_child(_confirm)
	var warning := _label("Ya hay una partida guardada.\nSi empiezas una nueva, se borrará. No se puede deshacer.", 24, TEXT_COLOR)
	_confirm.add_child(warning)
	_confirm.add_child(_button(&"no", "No, volver"))
	_confirm.add_child(_button(&"yes", "Sí, borrar y empezar de nuevo"))

	var hint := _label("A / Intro: elegir", 20, DIM_COLOR)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -70.0
	hint.offset_bottom = -40.0
	add_child(hint)
	var version := _label("Versión %s" % GameInfo.VERSION, 18, DIM_COLOR)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -300.0
	version.offset_top = -50.0
	version.offset_right = -30.0
	version.offset_bottom = -20.0
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)

	_music = AudioStreamPlayer.new()
	_music.bus = AudioMix.MUSIC
	_music.stream = Ambience._loop("res://assets/audio/music/pass_explore.wav")
	_music.volume_db = -14.0
	_music.autoplay = true
	add_child(_music)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(id: StringName, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.custom_minimum_size = Vector2(460, 54)
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", DIM_COLOR)
	button.add_theme_color_override("font_focus_color", TITLE_COLOR)
	button.add_theme_color_override("font_hover_color", TITLE_COLOR)
	button.pressed.connect(press.bind(id))
	button.mouse_entered.connect(button.grab_focus)
	_buttons[id] = button
	return button
