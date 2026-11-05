extends Node
## Campamentos: el fundido a negro al descansar o reaparecer, y "reiniciar el mundo" (todos los enemigos
## vuelven vivos a su puesto, se borran flechas y turnos de ataque).
## Uso: Camps.fade_to(1.0, 0.6) · Camps.reset_world()

const FADE_LAYER: int = 60

var _layer: CanvasLayer
var _black: ColorRect
var _caption: Label
var _tween: Tween
## Menú para subir atributos (se abre al descansar).
var level_menu: LevelMenu
## Menú de pausa (Start / Esc).
var pause_menu: PauseMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = FADE_LAYER
	add_child(_layer)
	_black = ColorRect.new()
	_black.color = Color(0.02, 0.015, 0.01, 0.0)
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_black)
	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 34)
	_caption.add_theme_color_override("font_color", Color(0.95, 0.82, 0.6))
	_caption.modulate.a = 0.0
	_black.add_child(_caption)
	level_menu = LevelMenu.new()
	add_child(level_menu)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)


## Oscurece (1) o aclara (0) la pantalla en `seconds`, con un texto opcional en el centro.
func fade_to(alpha: float, seconds: float, caption: String = "") -> void:
	if _tween:
		_tween.kill()
	if caption != "":
		_caption.text = caption
	_tween = create_tween().set_parallel()
	_tween.tween_property(_black, "color:a", alpha, seconds)
	_tween.tween_property(_caption, "modulate:a", alpha if (caption != "" or alpha < _caption.modulate.a) else _caption.modulate.a, seconds)


func fade_alpha() -> float:
	return _black.color.a


## Todos los enemigos vuelven vivos y tranquilos a su puesto; sin flechas en el aire ni turnos pendientes.
func reset_world() -> void:
	for node in get_tree().get_nodes_in_group("enemy_projectiles"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).reset_to_post()
	Squad.reset()
	get_tree().call_group("arenas", "reset_arena")
