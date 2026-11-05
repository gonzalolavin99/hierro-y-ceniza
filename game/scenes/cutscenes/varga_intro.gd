class_name VargaIntro
extends CanvasLayer
## Escena antes del duelo con Varga (solo la primera vez): en el propio patio, con bandas negras de cine.
## Varga está junto a la ropa de los enfermos que arde; se gira, habla con Kael y desenvaina.
## Kael y Varga quedan en el estado "Scripted" mientras dura. Mantener A 1 s la salta.
## Al terminar emite `finished` y devuelve la cámara y los controles.

signal finished

const HOLD_TO_SKIP: float = 1.0
const BAR_HEIGHT: float = 90.0

var _arena: Node3D
var _player: Player
var _varga: Enemy
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
## Plano actual (para pruebas): wide, varga, kael, walk, draw.
var shot: StringName = &""


func setup(arena: Node3D, player: Player, varga: Enemy) -> void:
	_arena = arena
	_player = player
	_varga = varga


func _ready() -> void:
	add_to_group("cutscene")
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	Voice.subtitle.connect(_on_subtitle)
	_previous_camera = get_viewport().get_camera_3d()
	_camera = Camera3D.new()
	_camera.fov = 48.0
	_arena.add_child(_camera)
	_camera.make_current()
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud:
		_hud_was_visible = hud.visible
		hud.visible = false
	_overlay_was_visible = DebugOverlay.visible
	DebugOverlay.visible = false
	_player.state_machine.transition_to(&"Scripted")
	_varga.state_machine.transition_to(&"Scripted")
	_run()


func is_done() -> bool:
	return _done


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


func _run() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(_top, "offset_bottom", BAR_HEIGHT, 0.6)
	tween.tween_property(_bottom, "offset_top", -BAR_HEIGHT, 0.6)
	# 1. Plano abierto desde detrás de Kael: Varga, de espaldas, junto al fuego de la ropa.
	shot = &"wide"
	var kael_at: Vector3 = _player.global_position
	var varga_at: Vector3 = _varga.global_position
	var across: Vector3 = (varga_at - kael_at).normalized()
	_face(_varga, across)  # Mira hacia el fuego (de espaldas a Kael).
	_place(kael_at - across * 2.6 + Vector3.UP * 1.9 + across.cross(Vector3.UP) * 0.9, varga_at + Vector3.UP * 1.2)
	_push(kael_at - across * 1.8 + Vector3.UP * 1.8 + across.cross(Vector3.UP) * 0.8, 7.0)
	if not await _line(&"narrator", &"story_varga_before", 0.3):
		return
	# 2. Se gira hacia Kael y habla (primer plano).
	_face(_varga, -across)
	await _wait(0.6)
	shot = &"varga"
	_close_up(_varga.body, 1.6, 1.5)
	if not await _line(&"varga", &"intro_1"):
		return
	shot = &"kael"
	_close_up(_player.body, 1.6, 1.4)
	if not await _line(&"kael_scene", &"varga_1"):
		return
	# 3. Avanza hacia él mientras le contesta (plano de lado).
	shot = &"walk"
	var side: Vector3 = across.cross(Vector3.UP)
	var gap: float = kael_at.distance_to(varga_at)
	var mid: Vector3 = (kael_at + varga_at) * 0.5 + across * 1.5  # Algo más cerca de ella, que avanza.
	_place(mid + side * maxf(gap * 0.75, 6.0) + Vector3.UP * 1.8, mid + Vector3.UP * 1.0)
	(_varga.state_machine.current as EnemyScripted).walk_velocity = -across * 1.1
	if not await _line(&"varga", &"intro_2"):
		return
	(_varga.state_machine.current as EnemyScripted).walk_velocity = Vector3.ZERO
	shot = &"kael"
	_close_up(_player.body, 1.6, 1.3)
	if not await _line(&"kael_scene", &"varga_2"):
		return
	# 4. Desenvaina: "Entonces ven."
	shot = &"draw"
	_varga.body.play_action(&"draw", 0.0, 1.0, 0.15)
	var head: Vector3 = _varga.global_position + Vector3.UP * 1.5
	_place(head - across * 3.4 + side * 1.2 + Vector3.DOWN * 0.5, head)
	_push(head - across * 2.8 + side * 1.0 + Vector3.DOWN * 0.45, 4.0)
	if not await _line(&"varga", &"intro_3"):
		return
	_finish()


## Dice una línea y espera a que termine (más `pause`). Devuelve false si se saltó la escena.
func _line(speaker: StringName, event: StringName, pause: float = 0.5) -> bool:
	if _done:
		return false
	Voice.say(speaker, event, _varga.lock_point() if speaker == &"varga" else Vector3.ZERO)
	await _wait(Voice.last_seconds + pause)
	return not _done


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func _face(enemy: Enemy, direction: Vector3) -> void:
	direction.y = 0.0
	enemy.model.global_rotation.y = atan2(-direction.x, -direction.z)


func _place(at: Vector3, look: Vector3) -> void:
	if _cam_tween:
		_cam_tween.kill()
	_camera.global_position = at
	_camera.look_at(look)


func _push(to: Vector3, seconds: float) -> void:
	var target := Transform3D(_camera.global_basis, to)
	_cam_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(_camera, "global_transform", target, seconds)


func _close_up(body: Mannequin, height: float, distance: float) -> void:
	var head: Vector3 = body.global_position + Vector3.UP * height
	var front: Vector3 = -body.global_basis.z
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
	_varga.body.stop_action(0.2)
	_player.state_machine.transition_to(&"Ground")
	_varga.state_machine.transition_to(&"Idle", {"wait": 0.4})
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
