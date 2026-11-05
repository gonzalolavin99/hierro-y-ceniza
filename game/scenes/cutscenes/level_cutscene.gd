class_name LevelCutscene
extends CanvasLayer
## Base de las escenas que pasan en el propio nivel (la de Varga, la de Frank…): bandas negras de cine,
## cámara propia, HUD oculto, subtítulos propios y "mantén A 1 s para saltarla". Kael queda en el estado
## "Scripted" mientras dura. Cada escena hereda de esta y escribe su guion en `_run()` y su final en `_end()`
## (que también se llama si se salta: tiene que dejarlo todo como al terminar).

signal finished

const HOLD_TO_SKIP: float = 1.0
const BAR_HEIGHT: float = 90.0

var _player: Player
var _camera: Camera3D
var _previous_camera: Camera3D
var _top: ColorRect
var _bottom: ColorRect
var _subtitle: Label
var _skip_label: Label
var _sub_tween: Tween
var _cam_tween: Tween
var _hold: float = 0.0
var _done: bool = false
var _hud_was_visible: bool = true
var _overlay_was_visible: bool = false
## Plano actual (para pruebas).
var shot: StringName = &""


func _ready() -> void:
	add_to_group("cutscene")
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	Voice.subtitle.connect(_on_subtitle)
	_previous_camera = get_viewport().get_camera_3d()
	_camera = Camera3D.new()
	_camera.fov = 48.0
	_player.get_parent().add_child(_camera)
	_camera.make_current()
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud:
		_hud_was_visible = hud.visible
		hud.visible = false
	_overlay_was_visible = DebugOverlay.visible
	DebugOverlay.visible = false
	_player.state_machine.transition_to(&"Scripted")
	_begin()
	var tween := create_tween().set_parallel()
	tween.tween_property(_top, "offset_bottom", BAR_HEIGHT, 0.6)
	tween.tween_property(_bottom, "offset_top", -BAR_HEIGHT, 0.6)
	_run()


func is_done() -> bool:
	return _done


## Antes de empezar (poner a los actores en su sitio y en "Scripted").
func _begin() -> void:
	pass


## El guion de la escena (con `await`). Al acabar debe llamar a `_finish()`.
func _run() -> void:
	_finish()


## Final de la escena (o al saltarla): devolver a los actores a su estado de juego.
func _end() -> void:
	pass


func _process(delta: float) -> void:
	if _done:
		return
	if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("jump"):
		_hold += delta
		_skip_label.text = "Mantén para saltar la escena  " + "■".repeat(int(_hold / HOLD_TO_SKIP * 10.0))
		if _hold >= HOLD_TO_SKIP:
			_finish()
	else:
		_hold = 0.0
		_skip_label.text = "Mantén A para saltar la escena"


## Dice una línea y espera a que termine (más `pause`). Devuelve false si se saltó la escena.
func _line(speaker: StringName, event: StringName, pause: float = 0.5, at: Vector3 = Vector3.ZERO) -> bool:
	if _done:
		return false
	Voice.say(speaker, event, at)
	await _wait(Voice.last_seconds + pause)
	return not _done


## Espera (en tiempo de juego). Devuelve false si se saltó la escena mientras tanto.
func _wait(seconds: float) -> bool:
	await get_tree().create_timer(seconds, true).timeout
	return not _done


func _place(at: Vector3, look: Vector3) -> void:
	if _cam_tween:
		_cam_tween.kill()
	_camera.global_position = at
	_camera.look_at(look)


func _push(to: Vector3, seconds: float) -> void:
	var target := Transform3D(_camera.global_basis, to)
	_cam_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(_camera, "global_transform", target, seconds)


## Primer plano de la cara de un personaje (que mira hacia -Z de `body`), a `height` del suelo.
func _close_up(body: Node3D, height: float, distance: float) -> void:
	var head: Vector3 = body.global_position + Vector3.UP * height
	var front: Vector3 = -body.global_basis.z
	front.y = 0.0
	front = front.normalized()
	var side: Vector3 = front.cross(Vector3.UP)
	_place(head + front * distance + side * distance * 0.35 + Vector3.UP * 0.05, head)
	_push(head + front * distance * 0.85 + side * distance * 0.3 + Vector3.UP * 0.05, 5.0)


func _finish() -> void:
	if _done:
		return
	_done = true
	Voice.reset()
	if _previous_camera and is_instance_valid(_previous_camera):
		_previous_camera.make_current()
	_camera.queue_free()
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = _hud_was_visible
	DebugOverlay.visible = _overlay_was_visible
	_player.state_machine.transition_to(&"Ground")
	_end()
	_subtitle.modulate.a = 0.0
	_skip_label.visible = false
	finished.emit()
	var tween := create_tween().set_parallel()
	tween.tween_property(_top, "offset_bottom", 0.0, 0.5)
	tween.tween_property(_bottom, "offset_top", 0.0, 0.5)
	tween.chain().tween_callback(queue_free)


func _on_subtitle(text: String, speaker_name: String, seconds: float) -> void:
	if _done:
		return
	_subtitle.text = "%s:  %s" % [speaker_name, text]
	_subtitle.modulate.a = 1.0
	if _sub_tween:
		_sub_tween.kill()
	_sub_tween = create_tween()
	_sub_tween.tween_interval(seconds)
	_sub_tween.tween_property(_subtitle, "modulate:a", 0.0, 0.4)


func _build() -> void:
	_top = ColorRect.new()
	_top.color = Color.BLACK
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top.offset_bottom = 0.0
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	_bottom = ColorRect.new()
	_bottom.color = Color.BLACK
	_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.offset_top = 0.0
	_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bottom)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.add_theme_font_size_override("font_size", 28)
	_subtitle.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle.offset_left = -700.0
	_subtitle.offset_right = 700.0
	_subtitle.offset_top = -80.0
	_subtitle.offset_bottom = -20.0
	_subtitle.modulate.a = 0.0
	add_child(_subtitle)
	_skip_label = Label.new()
	_skip_label.text = "Mantén A para saltar la escena"
	_skip_label.add_theme_font_size_override("font_size", 16)
	_skip_label.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6))
	_skip_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_skip_label.offset_left = -380.0
	_skip_label.offset_top = 30.0
	_skip_label.offset_right = -30.0
	_skip_label.offset_bottom = 60.0
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_skip_label)
