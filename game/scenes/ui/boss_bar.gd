class_name BossBar
extends CanvasLayer
## Barra de jefe (arriba, al centro): nombre, vida, postura (crece desde el centro, como la del jugador)
## y un punto rojo por cada golpe mortal que le queda (como en Sekiro). Oculta hasta que empieza el duelo.

const WIDTH: float = 640.0
const RED: Color = Color(0.72, 0.12, 0.1)

var _boss: Enemy
var _root: Control
var _name: Label
var _health_fill: ColorRect
var _posture_fill: ColorRect
var _dots: HBoxContainer
var _tween: Tween


func _ready() -> void:
	layer = 5
	_build()
	_root.modulate.a = 0.0
	_root.visible = false


func _process(_delta: float) -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	_health_fill.anchor_right = _boss.health.ratio()
	var p: float = _boss.posture.ratio()
	_posture_fill.anchor_left = 0.5 - p * 0.5
	_posture_fill.anchor_right = 0.5 + p * 0.5
	_posture_fill.color = Color(1.0, 0.55, 0.15) if p > 0.75 else Color(0.95, 0.75, 0.3)
	for i in _dots.get_child_count():
		var dot := _dots.get_child(i) as ColorRect
		dot.color = RED if i < _boss.deathblows_left else Color(0.25, 0.22, 0.2)


func is_showing() -> bool:
	return _root.visible and _boss != null


## Puntos rojos que se ven ahora (golpes mortales que le faltan).
func dots_left() -> int:
	return _boss.deathblows_left if _boss else 0


func show_boss(boss: Enemy) -> void:
	_boss = boss
	_name.text = boss.display_name
	for child in _dots.get_children():
		child.queue_free()
	for i in boss.deathblows:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(16, 16)
		_dots.add_child(dot)
	_root.visible = true
	_fade(1.0, 0.8)


func hide_boss(delay: float = 0.0) -> void:
	_boss = null
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(delay)
	_tween.tween_property(_root, "modulate:a", 0.0, 0.6)
	_tween.tween_callback(func() -> void: _root.visible = false)


func _fade(alpha: float, seconds: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_root, "modulate:a", alpha, seconds)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_root.offset_left = -WIDTH * 0.5
	_root.offset_right = WIDTH * 0.5
	_root.offset_top = 28.0
	_root.offset_bottom = 110.0
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var row := HBoxContainer.new()
	row.position = Vector2(0, 0)
	row.size = Vector2(WIDTH, 30)
	row.add_theme_constant_override("separation", 10)
	_root.add_child(row)
	_dots = HBoxContainer.new()
	_dots.add_theme_constant_override("separation", 6)
	row.add_child(_dots)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 24)
	_name.add_theme_color_override("font_color", Color(0.95, 0.9, 0.82))
	_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_name.add_theme_constant_override("outline_size", 6)
	row.add_child(_name)
	_health_fill = _bar(Vector2(0, 36), 10.0, RED)
	_posture_fill = _bar(Vector2(0, 54), 8.0, Color(0.95, 0.75, 0.3))
	_posture_fill.anchor_left = 0.5
	_posture_fill.anchor_right = 0.5


## Barra con fondo oscuro; devuelve el relleno (se estira con anchor_right / anchor_left).
func _bar(at: Vector2, height: float, color: Color) -> ColorRect:
	var back := ColorRect.new()
	back.color = Color(0.05, 0.04, 0.04, 0.75)
	back.position = at
	back.size = Vector2(WIDTH, height)
	_root.add_child(back)
	var fill := ColorRect.new()
	fill.color = color
	fill.anchor_bottom = 1.0
	fill.anchor_right = 1.0
	back.add_child(fill)
	return fill
