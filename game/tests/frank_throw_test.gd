extends Node
## Prueba automática del paso 4 de Frank: con la cruz abajo lanza una fruta. A un enemigo desprevenido lo
## distrae (va a mirar donde cayó y le da la espalda a Kael: golpe por la espalda); en plena pelea lo aturde
## un momento; a una jefa, casi nada. Recarga lenta, aviso en pantalla y, sin Frank, nada.
## Ejecutar: Godot --headless --path game res://tests/frank_throw_test.tscn

const TEST_PATH: String = "user://save_frank_throw_test.json"

var _player: Player
var _frank: Frank
var _thrower: FrankThrow
var _hud: Node
var _failures: int = 0
var _spoken: Array[String] = []


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player") as Player
	_hud = get_tree().get_first_node_in_group("hud")
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
		(node as Enemy).state_machine.transition_to(&"Idle", {"wait": 1000.0})
	Voice.spoken.connect(func(speaker: StringName, event: StringName, _id: String) -> void: _spoken.append("%s/%s" % [speaker, event]))
	await _wait(0.5)
	# El anciano manda sobre todos: que no hable en medio de la prueba al pasar por las zonas.
	for event in [&"story_prologue", &"story_pass_village", &"story_pass_forest", &"story_pass_fortress"]:
		Story.mark_heard(event)
	Story.mark_heard(Frank.STORY_MET)
	Story.changed.emit()
	await _wait(0.3)
	Voice.always_speak = true
	await _run()
	Voice.always_speak = false
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	_frank = _player.frank
	_frank.chat_gap = 0.0  # Sin pausa entre comentarios: cada caso lo provoca la prueba.
	_thrower = _frank.thrower
	_check("Frank en el hombro, con fruta lista", _frank.mode == Frank.Mode.PERCHED and _thrower.is_ready())
	_check("En pantalla: «↓  Fruta de Frank»", _hud.frank_text() == "↓  Fruta de Frank")
	_check("Hay botón (cruz abajo / G)", InputMap.has_action("frank_throw"))

	# 1. Sin nadie delante: no gasta la fruta.
	_teleport(Vector3(0.0, 0.0, -40.0))
	_aim_at(Vector3(0.0, 0.0, -80.0))
	await _wait(0.2)
	_quiet()
	await _tap("frank_throw")
	await _wait(0.2)
	_check("Sin nadie a tiro: «¿A quién se la tiro?» y no gasta", _spoken.has("frank/throw_nobody") and _thrower.is_ready())

	# 2. Enemigo desprevenido: la fruta cae detrás de él; va a mirar y le da la espalda a Kael.
	var sentry: Enemy = null
	for node in get_tree().get_nodes_in_group("enemies"):
		if (node as Enemy).starts_unaware and not (node as Enemy).alerted:
			sentry = node as Enemy
			break
	_check("Hay un centinela desprevenido en el escenario", sentry != null)
	sentry.state_machine.transition_to(&"Idle", {"wait": 1000.0})
	var facing: Vector3 = sentry.get_facing()
	var side: Vector3 = facing.cross(Vector3.UP).normalized()
	_teleport(sentry.global_position + side * 9.0 - facing * 2.0)
	_aim_at(sentry.global_position)
	await _wait(0.2)
	_quiet()
	await _tap("frank_throw")
	await _wait(0.1)
	_check("Lanza la fruta (chillido y gesto)", _thrower.last_fruit != null and _spoken.has("frank/throw_go") and not _thrower.is_ready())
	_check("Recarga: «↓  Fruta de Frank  (40 s)»", _hud.frank_text().contains("(4"))
	await _wait(_thrower.last_fruit.flight_time() + 0.2)
	_check("El centinela va a mirar donde cayó (sospecha, sin descubrir a Kael)", sentry.state_name() == &"Suspicious" and not sentry.alerted)
	await _wait(1.0)
	var to_kael: Vector3 = _player.global_position - sentry.global_position
	to_kael.y = 0.0
	_check("Le da la espalda a Kael", sentry.get_facing().dot(to_kael.normalized()) < 0.3)
	_check("Frank susurra: «Ya mira para otro lado. ¡Ahora!»", _spoken.has("frank/throw_distract"))
	_teleport(sentry.global_position - sentry.get_facing() * 1.2)
	await get_tree().physics_frame
	_check("Kael puede rematarlo por la espalda", sentry.can_be_stealth_killed(_player))
	_quiet()
	await _tap("frank_throw")
	await _wait(0.2)
	_check("Recargando: «Espera, que busco otra fruta» y no lanza", _spoken.has("frank/throw_wait") and _thrower.cooldown_left > 30.0)
	sentry.state_machine.transition_to(&"Idle", {"wait": 1000.0})

	# 3. En plena pelea: en la cara, aturdido un momento.
	var soldier: Enemy = _enemy_named("Soldado de práctica")
	_check("El soldado de práctica está alerta", soldier.alerted)
	_teleport(Vector3(20.0, 0.0, 30.0))
	_put(soldier, Vector3(20.0, 0.0, 36.0))
	_aim_at(soldier.global_position)
	_thrower.cooldown_left = 0.0
	await _wait(0.2)
	_quiet()
	var got: Enemy = _thrower.try_throw()
	_check("Apunta al que tiene delante", got == soldier)
	# Mientras vuela, el soldado se aparta: la fruta tiene que darle igual en la cabeza.
	_put(soldier, soldier.global_position + Vector3(1.5, 0.0, 0.0))
	var head: Node3D = soldier.body.bone_attachment("mixamorig_Head")
	var fruit: FrankFruit = _thrower.last_fruit
	var closest: float = 100.0
	var flown: float = 0.0
	while is_instance_valid(fruit) and fruit._flying and flown < 2.0:
		closest = minf(closest, fruit.global_position.distance_to(head.global_position))
		await get_tree().process_frame
		flown += get_process_delta_time()
	if is_instance_valid(fruit):
		closest = minf(closest, fruit.global_position.distance_to(head.global_position))
	_check("La fruta le da en la cabeza aunque se mueva (a %.2f m)" % closest, closest < 0.15)
	await _wait(0.1)
	_check("En plena pelea: aturdido", soldier.state_name() == &"Dazed")
	await _wait(0.4)
	_check("Frank: «¡En toda la cara!»", _spoken.has("frank/throw_hit"))
	await _wait(1.4)
	_check("Se le pasa enseguida (≈1,4 s)", soldier.state_name() != &"Dazed")
	_put(soldier, Vector3(-60.0, 0.0, 60.0))

	# 4. Una jefa: casi nada.
	var varga: Enemy = _enemy_named("Capitana Varga")
	# Fuera de su patio (si no, empieza su escena).
	varga.state_machine.transition_to(&"Idle", {"wait": 1000.0})
	_put(varga, Vector3(20.0, 0.0, 36.0))
	_teleport(Vector3(20.0, 0.0, 28.0))
	_aim_at(varga.global_position)
	_thrower.cooldown_left = 0.0
	await _wait(0.2)
	_quiet()
	var state_before: StringName = varga.state_name()
	got = _thrower.try_throw()
	await _wait(_thrower.last_fruit.flight_time() + 0.6)
	_check("A la jefa: ni aturdida ni distraída", got == varga and varga.state_name() != &"Dazed" and varga.state_name() != &"Suspicious")
	_check("Frank: «Ni la ha despeinado.»", _spoken.has("frank/throw_boss"))
	print("    (Varga estaba en %s)" % state_before)

	# 5. Sin Frank (en la red): ni botón ni aviso.
	Story.reset()
	await _wait(0.3)
	_thrower.cooldown_left = 0.0
	_check("Sin Frank no lanza nada", _thrower.try_throw() == null)
	_check("Sin Frank, el aviso no se ve", _hud.frank_text() == "")


func _aim_at(at: Vector3) -> void:
	var to: Vector3 = at - _player.global_position
	_player.camera_rig.global_rotation.y = atan2(-to.x, -to.z)
	_player.model.global_rotation.y = atan2(-to.x, -to.z)


func _enemy_named(display: String) -> Enemy:
	for node in get_tree().get_nodes_in_group("enemies"):
		if (node as Enemy).display_name == display:
			return node as Enemy
	return null


func _put(enemy: Enemy, at: Vector3) -> void:
	enemy.global_position = Vector3(at.x, enemy.global_position.y, at.z)
	enemy.velocity = Vector3.ZERO
	enemy.reset_physics_interpolation()


func _quiet() -> void:
	Voice.reset()
	_spoken.clear()


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
