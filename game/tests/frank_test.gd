extends Node
## Prueba automática de Frank, el tití: empieza atrapado en la red; al acercarse pide ayuda; con Y sale la
## escena de la red y acaba en el hombro de Kael (y lo sigue); si Kael pasa de largo, se suelta solo y lo
## alcanza ofendido; la partida guardada lo recuerda; saltar la escena lo deja igual en el hombro.
## Ejecutar: Godot --headless --path game res://tests/frank_test.tscn

const TEST_PATH: String = "user://save_frank_test.json"

var _player: Player
var _snare: FrankSnare
var _frank: Frank
var _failures: int = 0
var _spoken: Array[String] = []
var _subtitles: Array[String] = []


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player") as Player
	_snare = get_tree().get_first_node_in_group("frank_snare") as FrankSnare
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	Voice.spoken.connect(func(speaker: StringName, event: StringName, _id: String) -> void: _spoken.append("%s/%s" % [speaker, event]))
	Voice.subtitle.connect(func(text: String, who: String, _s: float) -> void: _subtitles.append("%s: %s" % [who, text]))
	await _wait(0.5)
	# El prólogo no cuenta aquí: se da por visto.
	for scene in get_tree().get_nodes_in_group("cutscene"):
		scene.queue_free()
	get_tree().paused = false
	await _wait(0.3)
	await _run()
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	_frank = _player.frank
	_check("La red está en el nivel y Frank existe", _snare != null and _frank != null)
	_check("Al empezar, Frank está atrapado en la red", _frank.mode == Frank.Mode.TRAPPED and _frank.visible)
	_check("Frank está dentro de la red", _frank.global_position.distance_to(_snare.bag_position()) < 0.4)
	Story.mark_heard(&"story_prologue")
	Voice.reset()
	var curls: int = _count_curls(_frank)
	_check("Tiene el pelo lleno de rulos (%d)" % curls, curls >= 15)
	var size: AABB = _bounds(_frank)
	var head_top: float = _frank.head_position().y - _frank.global_position.y
	_check("Es pequeñito (cabeza a %.2f m; con la cola colgando, %.2f m)" % [head_top, size.size.y], head_top > 0.15 and head_top < 0.32 and size.size.y < 0.8)

	# 1. Kael se acerca: Frank pide ayuda (con subtítulo de lo que Kael entiende).
	_teleport(_snare.global_position + (_player.global_position - _snare.global_position).normalized() * 8.0)
	await _wait(0.6)
	_check("Al acercarse, Frank chilla pidiendo ayuda", _spoken.has("frank/trapped"))
	_check("El subtítulo es de Frank y va entre «»", _subtitles.any(func(s: String) -> bool: return s.begins_with("Frank: «")))
	_check("Lejos aún no se puede soltar", not _snare.can_free(_player))
	_teleport(_snare.kael_spot())
	await _wait(0.3)
	_check("Junto a la red se puede soltar (aviso «Y  Soltar al tití»)", _snare.can_free(_player))

	# 2. Y: la escena de la red.
	await _tap("interact")
	await _wait(0.2)
	var scene: FrankMeet = _snare.scene
	_check("Con Y empieza la escena de la red", scene != null and get_tree().get_node_count_in_group("cutscene") == 1)
	_check("Kael no se mueve durante la escena", _player.state_machine.current.name == &"Scripted")
	var shots: Array[StringName] = []
	var landed_on_ground: bool = false
	var elapsed: float = 0.0
	while is_instance_valid(scene) and not scene.is_done() and elapsed < 60.0:
		if not shots.has(scene.shot):
			shots.append(scene.shot)
		if _frank.mode == Frank.Mode.GROUND:
			landed_on_ground = true
		await _wait(0.1)
		elapsed += 0.1
	_check("La escena terminó (%.0f s)" % elapsed, elapsed < 60.0)
	_check("Tiene todos sus planos %s" % str(shots), shots == [&"cut", &"frank", &"kael", &"curls", &"two", &"hop", &"end"])
	_check("La red cae y Frank cae al suelo", _snare.is_cut() and landed_on_ground)
	for event in ["frank/meet_1", "kael_scene/frank_1", "frank/meet_2", "narrator/story_frank_meet", "frank/meet_3", "kael_scene/frank_2"]:
		_check("Se dice %s" % event, _spoken.has(event))
	_check("Frank se queja de sus rulos", _subtitles.any(func(s: String) -> bool: return s.contains("rulos")))
	await _wait(0.3)
	_check("Acaba en el hombro de Kael", _frank.mode == Frank.Mode.PERCHED)
	_check("Kael vuelve a moverse", _player.state_machine.current.name == &"Ground")
	_check("La partida recuerda que lo soltó", Story.heard(Frank.STORY_MET) and Story.heard(Frank.STORY_FREED))
	_check_on_shoulder("tras la escena")

	# 3. Lo sigue a todas partes.
	_teleport(_player.global_position + Vector3(6.0, 0.0, -4.0))
	await _wait(0.2)
	_check_on_shoulder("tras moverse")
	_player.model.rotation.y += 2.0
	await _wait(0.2)
	_check_on_shoulder("tras girarse")
	var before: int = _spoken.count("frank/scared")
	Voice.always_speak = true
	_player.health.take_damage(10.0)
	await _wait(0.2)
	Voice.always_speak = false
	_check("Si a Kael le pegan, Frank se asusta", _spoken.count("frank/scared") > before)

	# 4. La partida guardada: al cargar, Frank sigue en el hombro y la red, cortada.
	var saved: Dictionary = Story.to_dict()
	Story.reset()
	await _wait(0.2)
	_check("Partida nueva: Frank vuelve a la red", _frank.mode == Frank.Mode.TRAPPED and not _snare.is_cut())
	Story.from_dict(saved)
	await _wait(0.2)
	_check("Al cargar: Frank en el hombro y la red cortada", _frank.mode == Frank.Mode.PERCHED and _snare.is_cut())

	# 5. Si Kael pasa de largo: se suelta solo, lo alcanza y se le sube, ofendido.
	Story.reset()
	await _wait(0.2)
	_teleport(_snare.global_position + Vector3(6.0, 0.0, -3.0))
	await _wait(0.4)
	_teleport(_snare.global_position + Vector3(32.0, 0.0, -3.0))
	await _wait(0.3)
	_check("Al alejarse, Frank se suelta y corre tras Kael", _frank.mode == Frank.Mode.RUNNING or _frank.mode == Frank.Mode.HOPPING)
	_check("La red cae", _snare.is_cut())
	var waited: float = 0.0
	while _frank.mode != Frank.Mode.PERCHED and waited < 6.0:
		await _wait(0.1)
		waited += 0.1
	_check("Lo alcanza y se le sube al hombro (%.1f s)" % waited, _frank.mode == Frank.Mode.PERCHED)
	await _wait(0.4)
	_check("Se queja, ofendido", _spoken.has("frank/offended"))
	_check("Lo conoció, pero Kael no lo soltó", Story.heard(Frank.STORY_MET) and not Story.heard(Frank.STORY_FREED))
	await _wait(6.5)
	_check("El anciano lo recuerda («Pasé de largo»)", _spoken.has("narrator/story_frank_left"))
	_check_on_shoulder("tras alcanzarlo")

	# 6. Saltar la escena (mantener A): Frank acaba igual en el hombro.
	Story.reset()
	await _wait(0.2)
	_teleport(_snare.kael_spot())
	await _wait(0.2)
	var skipped: FrankMeet = _snare.free_frank()
	await _wait(1.0)
	Input.action_press("ui_accept")
	await _wait(1.3)
	Input.action_release("ui_accept")
	await _wait(0.6)
	_check("Mantener A salta la escena", not is_instance_valid(skipped) or skipped.is_done())
	_check("Saltada: Frank en el hombro y la red cortada", _frank.mode == Frank.Mode.PERCHED and _snare.is_cut() and Story.heard(Frank.STORY_FREED))
	_check("Saltada: Kael vuelve a moverse y no quedan escenas", _player.state_machine.current.name == &"Ground" and get_tree().get_node_count_in_group("cutscene") == 0)


func _check_on_shoulder(when: String) -> void:
	var left: Vector3 = _player.body.bone_attachment("mixamorig_LeftArm").global_position
	var gap: float = _frank.global_position.distance_to(left)
	var high: float = _frank.global_position.y - _player.global_position.y
	_check("Frank va sobre el hombro izquierdo %s (a %.2f m del hombro, a %.2f m del suelo)" % [when, gap, high], gap < 0.2 and high > 1.2 and high < 1.7)


func _count_curls(node: Node) -> int:
	var count: int = 0
	for child in node.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is TorusMesh:
			count += 1
		count += _count_curls(child)
	return count


func _bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		var m := mesh as MeshInstance3D
		var b: AABB = m.global_transform * m.get_aabb()
		if first:
			box = b
			first = false
		else:
			box = box.merge(b)
	return box


## Pulsa y suelta un botón como lo haría el mando (el juego lo ve en el fotograma siguiente).
func _tap(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().process_frame
	await get_tree().process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _teleport(at: Vector3) -> void:
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = Vector3(at.x, _player.global_position.y, at.z)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
