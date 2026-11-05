class_name PrologueScene
extends CanvasLayer
## Escena del prólogo (guion, docs/11_GUION.md): la fogata del anciano → Kael entra en la sala del Regente,
## se arrodilla, recibe la orden y el pergamino con los nombres (primeros planos al hablar) → primer plano
## de la cinta de Lira → título → empieza el juego (~70 s).
## Tiene su propio mundo 3D (SubViewport con own_world_3d), así no toca el nivel. El juego queda en pausa
## mientras dura. Mantener A / Start / Esc 1 s la salta. Al terminar emite `finished`.
## Uso: Story.play_prologue() (al empezar una partida nueva).

signal finished

const HOLD_TO_SKIP: float = 1.0
const KAEL_COLOR: Color = Color(0.55, 0.15, 0.12)
const MANNEQUIN: PackedScene = preload("res://scenes/characters/mannequin.tscn")
## Dónde está cada decorado dentro del mundo de la escena.
const FIRE_AT: Vector3 = Vector3.ZERO
const HALL_AT: Vector3 = Vector3(200.0, 0.0, 0.0)
## Dónde se detiene Kael ante el estrado (z dentro de la sala).
const KAEL_STOP_Z: float = -2.2

var _viewport: SubViewport
var _world: Node3D
var _camera: Camera3D
var _black: ColorRect
var _title: Label
var _subtitle: Label
var _skip_label: Label
var _fire_light: OmniLight3D
var _kael: Mannequin
var _cam_tween: Tween
var _hold: float = 0.0
var _done: bool = false
var _time: float = 0.0
var _overlay_was_visible: bool = false
var _regent: Mannequin
var _scroll: MeshInstance3D
var _sub_tween: Tween
## Personajes caminando ahora → su velocidad (para su animación de pasos).
var _walkers: Dictionary = {}
var _follow_target: Node3D
var _follow_offset: Vector3
var _follow_look: Vector3
var _follow_smooth: float = 4.0
## Plano actual (para pruebas): fire, hall, regent, ribbon, title.
var shot: StringName = &""


func _ready() -> void:
	add_to_group("cutscene")
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_screen()
	_build_fire_set()
	_build_hall_set()
	Voice.subtitle.connect(_on_subtitle)
	# El panel de depuración (F3) no se ve durante la escena.
	_overlay_was_visible = DebugOverlay.visible
	DebugOverlay.visible = false
	_run()


func is_done() -> bool:
	return _done


func _process(delta: float) -> void:
	_time += delta
	if _fire_light:
		_fire_light.light_energy = 2.6 + sin(_time * 13.0) * 0.25 + sin(_time * 7.3) * 0.2
	for body: Mannequin in _walkers:
		body.update_locomotion(_walkers[body], -body.global_basis.z)
	if _follow_target:
		var want: Vector3 = _follow_target.global_position + _follow_offset
		_camera.global_position = _camera.global_position.lerp(want, 1.0 - exp(-_follow_smooth * delta))
		_camera.look_at(_follow_target.global_position + _follow_look)
	if _done:
		return
	if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("pause") or Input.is_action_pressed("jump"):
		_hold += delta
		_skip_label.text = "Mantén para saltar la escena  " + "■".repeat(int(_hold / HOLD_TO_SKIP * 10.0))
		_skip_label.modulate.a = 1.0
		if _hold >= HOLD_TO_SKIP:
			_finish()
	else:
		_hold = 0.0
		_skip_label.text = "Mantén A para saltar la escena"
		_skip_label.modulate.a = move_toward(_skip_label.modulate.a, 0.45, delta)


# --- Guion de la escena ----------------------------------------------------------------

func _run() -> void:
	# 1. La fogata: el anciano empieza a contar.
	shot = &"fire"
	_place_camera(FIRE_AT + Vector3(3.6, 1.3, 3.4), FIRE_AT + Vector3(0.0, 0.6, 0.0))
	_push_camera(FIRE_AT + Vector3(2.4, 1.0, 2.3), 13.0)
	await _fade(0.0, 2.0)
	if not await _line(&"narrator", &"story_prologue"):
		return
	if not await _line(&"narrator", &"story_prologue_order"):
		return
	# 2. La sala: Kael entra caminando por la alfombra hasta el estrado (cámara de lado, siguiéndolo).
	await _fade(1.0, 0.7)
	if _done:
		return
	shot = &"hall"
	_follow(_kael, Vector3(2.6, 1.1, 1.2), Vector3(0.0, 1.3, -1.5))
	var walk_time: float = _walk(_kael, HALL_AT + Vector3(0.0, 0.0, KAEL_STOP_Z), 1.25)
	await _fade(0.0, 0.9)
	Voice.say(&"narrator", &"story_prologue_summon")
	await _wait(maxf(walk_time, Voice.last_seconds + 0.4))
	if _done:
		return
	_kael.play_action(&"kneel", 0.0, 1.0, 0.35)
	# 3. Plano abierto desde detrás de Kael: la orden.
	_follow(null)
	_place_camera(HALL_AT + Vector3(1.1, 1.4, KAEL_STOP_Z + 2.6), HALL_AT + Vector3(0.0, 1.6, -6.0))
	_push_camera(HALL_AT + Vector3(0.8, 1.45, KAEL_STOP_Z + 1.9), 6.0)
	await _wait(0.8)
	if not await _line(&"regent", &"prologue_order"):
		return
	# 4. Primeros planos: Kael pregunta; el Regente baja del estrado mientras contesta.
	shot = &"kael"
	_close_up(_kael, 1.05, 1.15)
	if not await _line(&"kael_scene", &"prologue_who"):
		return
	shot = &"regent"
	_walk(_regent, HALL_AT + Vector3(0.0, 0.0, -4.0), 0.9)
	_follow(_regent, Vector3(-2.4, 0.3, 1.6), Vector3(0.0, 1.5, 0.0), 2.5)
	if not await _line(&"regent", &"prologue_rebels"):
		return
	_follow(null)
	_close_up(_regent, 1.6, 1.3)
	if not await _line(&"regent", &"prologue_sister"):
		return
	# 5. Los nombres: el Regente le tiende el pergamino; Kael se levanta y lo toma.
	_attach_scroll(_regent, "YBot/Skeleton3D/RightHand")
	_kael.stop_action(0.5)
	_place_camera(HALL_AT + Vector3(2.3, 1.5, -2.9), HALL_AT + Vector3(0.0, 1.3, -3.2))
	_push_camera(HALL_AT + Vector3(1.9, 1.45, -3.0), 6.0)
	if not await _line(&"regent", &"prologue_names"):
		return
	_attach_scroll(_kael, "YBot/Skeleton3D/LeftWrist")
	shot = &"kael"
	_close_up(_kael, 1.6, 1.45)
	if not await _line(&"kael_scene", &"prologue_answer"):
		return
	# 6. La cinta en la muñeca de Kael.
	shot = &"ribbon"
	var wrist: Vector3 = _wrist_position()
	_place_camera(wrist + Vector3(0.9, 0.4, 0.75), wrist)
	_push_camera(wrist + Vector3(0.6, 0.28, 0.5), 7.0, wrist)
	if not await _line(&"narrator", &"story_prologue_ribbon"):
		return
	if not await _line(&"narrator", &"story_prologue_end"):
		return
	# 7. Título.
	await _fade(1.0, 1.2)
	if _done:
		return
	shot = &"title"
	var tween := create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, 1.5)
	tween.tween_interval(2.0)
	tween.tween_property(_title, "modulate:a", 0.0, 1.2)
	await tween.finished
	_finish()


## Hace caminar a `body` hasta `to` a `speed` m/s, mirando hacia donde va (con su paso de caminar).
## Devuelve cuánto tarda.
func _walk(body: Mannequin, to: Vector3, speed: float) -> float:
	var from: Vector3 = body.global_position
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var seconds: float = maxf(flat.length() / speed, 0.1)
	if flat.length() > 0.01:
		body.rotation.y = atan2(-flat.x, -flat.z)
	_walkers[body] = flat / seconds
	var tween := create_tween()
	tween.tween_property(body, "global_position", to, seconds)
	tween.tween_callback(_stop_walking.bind(body))
	return seconds


func _stop_walking(body: Mannequin) -> void:
	_walkers.erase(body)
	body.update_locomotion(Vector3.ZERO, -body.global_basis.z)


## La cámara sigue a `target` desde `offset` (en el mundo), mirando a su `look` (relativo a él).
## Con `null`, deja de seguir.
func _follow(target: Node3D, offset: Vector3 = Vector3.ZERO, look: Vector3 = Vector3.ZERO, smooth: float = 4.0) -> void:
	if _cam_tween:
		_cam_tween.kill()
	_follow_target = target
	_follow_offset = offset
	_follow_look = look
	_follow_smooth = smooth
	if target:
		_camera.global_position = target.global_position + offset
		_camera.look_at(target.global_position + look)


## Primer plano de la cara de `body` (`height`: altura de la cabeza), desde delante y algo de lado.
func _close_up(body: Mannequin, height: float, distance: float) -> void:
	var head: Vector3 = body.global_position + Vector3.UP * height
	var front: Vector3 = -body.global_basis.z
	var side: Vector3 = front.cross(Vector3.UP)
	_place_camera(head + front * distance + side * distance * 0.35 + Vector3.UP * 0.05, head)
	_push_camera(head + front * distance * 0.8 + side * distance * 0.3 + Vector3.UP * 0.05, 6.0, head)


## El pergamino con los cinco nombres, en la mano (hueso) indicada de `body`.
func _attach_scroll(body: Mannequin, hand_path: String) -> void:
	var hand: Node3D = body.get_node_or_null(hand_path)
	if hand == null:
		return
	if _scroll == null:
		_scroll = MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.025
		mesh.bottom_radius = 0.025
		mesh.height = 0.32
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.86, 0.8, 0.64)
		mesh.material = mat
		_scroll.mesh = mesh
	if _scroll.get_parent():
		_scroll.get_parent().remove_child(_scroll)
	hand.add_child(_scroll)
	_scroll.position = Vector3(0.0, 0.08, 0.03)
	_scroll.rotation = Vector3(0.0, 0.0, PI * 0.5)


## Dice una línea y espera a que termine (más un respiro). Devuelve false si se saltó la escena.
func _line(speaker: StringName, event: StringName) -> bool:
	if _done:
		return false
	Voice.say(speaker, event)
	await _wait(Voice.last_seconds + 0.6)
	return not _done


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func _fade(alpha: float, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(_black, "color:a", alpha, seconds)
	await tween.finished


func _finish() -> void:
	if _done:
		return
	_done = true
	Voice.reset()
	DebugOverlay.visible = _overlay_was_visible
	get_tree().call_group("hud", "clear_subtitle")
	_subtitle.modulate.a = 0.0
	_skip_label.visible = false
	finished.emit()
	# Del negro al juego.
	_viewport.get_parent().visible = false
	_black.color.a = 1.0
	_title.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_black, "color:a", 0.0, 1.2)
	tween.tween_callback(queue_free)


# --- Cámara ----------------------------------------------------------------------------

func _place_camera(at: Vector3, look: Vector3) -> void:
	if _cam_tween:
		_cam_tween.kill()
	_camera.global_position = at
	_camera.look_at(look)


## Acercamiento lento de la cámara hasta `to` en `seconds` (mirando a donde miraba, o a `look`).
func _push_camera(to: Vector3, seconds: float, look: Variant = null) -> void:
	var start: Transform3D = _camera.global_transform
	var target := Transform3D(start.basis, to)
	if look is Vector3:
		target = target.looking_at(look)
	_cam_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(_camera, "global_transform", target, seconds)


func _wrist_position() -> Vector3:
	var ribbon: Node3D = _kael.find_child("Ribbon", true, false)
	return ribbon.global_position if ribbon else _kael.global_position + Vector3(0.0, 0.5, 0.3)


func _on_subtitle(text: String, speaker_name: String, seconds: float) -> void:
	if _done:
		return
	_subtitle.text = "%s:  %s" % [speaker_name, text]
	_subtitle.modulate.a = 1.0
	# Un solo desvanecido a la vez: si no, el de la frase anterior borraba la nueva a medias.
	if _sub_tween:
		_sub_tween.kill()
	_sub_tween = create_tween()
	_sub_tween.tween_interval(seconds)
	_sub_tween.tween_property(_subtitle, "modulate:a", 0.0, 0.4)


# --- Construcción ----------------------------------------------------------------------

func _build_screen() -> void:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	container.add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)
	_camera = Camera3D.new()
	_camera.fov = 50.0
	_world.add_child(_camera)
	_camera.make_current()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.012, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.22, 0.24)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.05, 0.05)
	env.fog_density = 0.03
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_world.add_child(world_env)

	_black = ColorRect.new()
	_black.color = Color(0.0, 0.0, 0.0, 1.0)
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	_title = Label.new()
	_title.text = "HIERRO Y CENIZA"
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 76)
	_title.add_theme_color_override("font_color", Color(0.93, 0.8, 0.58))
	_title.modulate.a = 0.0
	add_child(_title)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.add_theme_font_size_override("font_size", 30)
	_subtitle.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
	_subtitle.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_subtitle.add_theme_constant_override("outline_size", 8)
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle.offset_left = -700.0
	_subtitle.offset_right = 700.0
	_subtitle.offset_top = -150.0
	_subtitle.offset_bottom = -80.0
	_subtitle.modulate.a = 0.0
	add_child(_subtitle)
	_skip_label = Label.new()
	_skip_label.text = "Mantén A para saltar la escena"
	_skip_label.add_theme_font_size_override("font_size", 18)
	_skip_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.68))
	_skip_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_label.offset_left = -420.0
	_skip_label.offset_top = -50.0
	_skip_label.offset_right = -30.0
	_skip_label.offset_bottom = -20.0
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_label.modulate.a = 0.45
	add_child(_skip_label)


## Noche, campo abierto: la fogata, el anciano y el niño que escucha (de espaldas, sin cara).
func _build_fire_set() -> void:
	var ground := _box(FIRE_AT + Vector3(0.0, -0.05, 0.0), Vector3(30.0, 0.1, 30.0), Color(0.12, 0.09, 0.07))
	ground.name = "Ground"
	for i in 6:
		var angle: float = TAU * i / 6.0
		var stone := _box(FIRE_AT + Vector3(cos(angle) * 0.5, 0.06, sin(angle) * 0.5), Vector3(0.18, 0.12, 0.14), Color(0.3, 0.28, 0.26))
		stone.rotation.y = angle
	for i in 3:
		var log_mesh := _box(FIRE_AT + Vector3(0.0, 0.1, 0.0), Vector3(0.09, 0.09, 0.7), Color(0.22, 0.13, 0.07))
		log_mesh.rotation = Vector3(0.0, TAU * i / 3.0, 0.25)
	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.55, 0.15)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.45, 0.1)
	flame_mat.emission_energy_multiplier = 4.0
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 3:
		var cone := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = 0.16 - i * 0.03
		mesh.height = 0.5 - i * 0.08
		mesh.material = flame_mat
		cone.mesh = mesh
		cone.position = FIRE_AT + Vector3((i - 1) * 0.08, 0.3, (i % 2) * 0.06)
		_world.add_child(cone)
	_fire_light = OmniLight3D.new()
	_fire_light.light_color = Color(1.0, 0.58, 0.28)
	_fire_light.omni_range = 9.0
	_fire_light.light_energy = 2.6
	_fire_light.shadow_enabled = true
	_fire_light.position = FIRE_AT + Vector3(0.0, 0.7, 0.0)
	_world.add_child(_fire_light)
	# El anciano, sentado junto al fuego, mirándolo.
	var elder := _person(FIRE_AT + Vector3(1.1, 0.0, 0.5), FIRE_AT, Color(0.36, 0.33, 0.3), 1.0)
	elder.name = "Elder"
	# El niño, al otro lado, de espaldas a la cámara.
	var child := _person(FIRE_AT + Vector3(-1.0, 0.0, -0.7), FIRE_AT, Color(0.25, 0.3, 0.26), 0.62)
	child.name = "Child"


## La sala del Regente: piedra, columnas, estandartes lisos, luz fría de las ventanas.
func _build_hall_set() -> void:
	var stone := Color(0.33, 0.32, 0.31)
	_box(HALL_AT + Vector3(0.0, -0.1, -2.0), Vector3(10.0, 0.2, 26.0), Color(0.24, 0.23, 0.22))
	_box(HALL_AT + Vector3(-5.0, 3.5, -2.0), Vector3(0.4, 7.0, 26.0), stone)
	_box(HALL_AT + Vector3(5.0, 3.5, -2.0), Vector3(0.4, 7.0, 26.0), stone)
	_box(HALL_AT + Vector3(0.0, 3.5, -9.0), Vector3(10.0, 7.0, 0.4), stone)
	_box(HALL_AT + Vector3(0.0, 0.25, -6.0), Vector3(5.0, 0.5, 3.0), Color(0.28, 0.27, 0.26))  # estrado
	_box(HALL_AT + Vector3(0.0, 0.01, 0.0), Vector3(1.8, 0.02, 14.0), Color(0.42, 0.1, 0.09))  # alfombra
	for z in [-6.0, -2.0, 2.0, 6.0]:
		for x in [-3.6, 3.6]:
			_box(HALL_AT + Vector3(x, 3.5, z), Vector3(0.7, 7.0, 0.7), Color(0.38, 0.37, 0.35))
	for x in [-2.2, 2.2]:  # Estandartes lisos, sin símbolos.
		_box(HALL_AT + Vector3(x, 4.3, -8.75), Vector3(1.1, 3.6, 0.06), Color(0.45, 0.08, 0.08))
	for z in [-4.0, 0.0, 4.0]:  # Ventanas altas con luz fría.
		var window := _box(HALL_AT + Vector3(4.78, 4.6, z), Vector3(0.05, 2.4, 0.9), Color(0.7, 0.78, 0.9))
		var mat := window.material_override as StandardMaterial3D
		mat.emission_enabled = true
		mat.emission = Color(0.6, 0.7, 0.85)
		mat.emission_energy_multiplier = 2.0
		var beam := SpotLight3D.new()
		beam.light_color = Color(0.7, 0.78, 0.95)
		beam.light_energy = 3.0
		beam.spot_range = 12.0
		beam.spot_angle = 22.0
		beam.shadow_enabled = true
		beam.position = HALL_AT + Vector3(4.5, 5.0, z)
		_world.add_child(beam)
		beam.look_at(HALL_AT + Vector3(-1.0, 0.0, z + 0.5))
	var torch := OmniLight3D.new()
	torch.light_color = Color(1.0, 0.6, 0.3)
	torch.light_energy = 1.4
	torch.omni_range = 7.0
	torch.position = HALL_AT + Vector3(0.0, 3.0, -7.5)
	_world.add_child(torch)
	# El Regente en el estrado, dos guardias con lanza y Kael arrodillado ante él.
	_regent = _person(HALL_AT + Vector3(0.0, 0.5, -6.0), HALL_AT + Vector3(0.0, 0.5, 2.0), Color(0.16, 0.12, 0.2), 1.0, false)
	_regent.name = "Regent"
	for x in [-2.0, 2.0]:
		var guard := _person(HALL_AT + Vector3(x, 0.5, -6.6), HALL_AT + Vector3(x, 0.5, 2.0), Color(0.3, 0.1, 0.1), 1.0, false, Mannequin.Weapon.SPEAR)
		guard.name = "Guard"
	_kael = _person(HALL_AT + Vector3(0.0, 0.0, 7.0), HALL_AT + Vector3(0.0, 0.0, -6.0), KAEL_COLOR, 1.0, false, Mannequin.Weapon.SWORD, true)
	_kael.name = "Kael"


## Un maniquí quieto: arrodillado/sentado (`kneel`) o de pie, mirando hacia `look`.
func _person(at: Vector3, look: Vector3, color: Color, size: float, kneel: bool = true,
		weapon: Mannequin.Weapon = Mannequin.Weapon.NONE, ribbon: bool = false) -> Mannequin:
	var body := MANNEQUIN.instantiate() as Mannequin
	body.body_color = color
	body.weapon = weapon
	body.ribbon = ribbon
	_world.add_child(body)
	body.position = at
	body.scale = Vector3.ONE * size
	var to := look - at
	body.rotation.y = atan2(-to.x, -to.z)  # El maniquí mira hacia su -Z.
	if kneel:
		body.play_action(&"kneel", 0.0, 1.0, 0.0)
	return body


func _box(at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mesh_instance.material_override = mat
	mesh_instance.position = at
	_world.add_child(mesh_instance)
	return mesh_instance
