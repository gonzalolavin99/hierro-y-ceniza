extends Node
## Prueba automática del paso 3 de Frank: avisa (arquero apuntando, enemigo por la espalda, enemigo que
## sospecha) señalando hacia el peligro; encuentra escondites (los señala, brillan, se recogen con Y); y abre
## el pestillo de la despensa de los cazadores desde dentro. Sin Frank, la puerta sigue cerrada.
## Ejecutar: Godot --headless --path game res://tests/frank_finds_test.tscn

const TEST_PATH: String = "user://save_frank_finds_test.json"

var _player: Player
var _frank: Frank
var _failures: int = 0
var _spoken: Array[String] = []


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player") as Player
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
		(node as Enemy).state_machine.transition_to(&"Idle", {"wait": 1000.0})
	Voice.spoken.connect(func(speaker: StringName, event: StringName, _id: String) -> void: _spoken.append("%s/%s" % [speaker, event]))
	await _wait(0.5)
	Story.mark_heard(&"story_prologue")
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
	_check("Frank va en el hombro", _frank.mode == Frank.Mode.PERCHED)
	var archer: Enemy = _enemy_named("Arquero")
	var soldier: Enemy = _enemy_named("Soldado de práctica")
	var forward: Vector3 = -_player.camera_rig.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	# 1. Un arquero tensa el arco contra Kael: "¡El del arco!" y lo señala.
	_put(archer, _player.global_position + forward * 10.0 + forward.cross(Vector3.UP) * 6.0)
	archer.target = _player
	_quiet()
	archer.state_machine.transition_to(&"Shoot")
	await _wait(0.4)
	var to_archer: Vector3 = (archer.lock_point() - _frank.head_position()).normalized()
	_check("Arquero apuntando: Frank chilla «¡El del arco!»", _spoken.has("frank/warn_archer"))
	_check("…y lo señala", _frank.pose == Frank.Pose.POINT and _frank.point_direction.dot(to_archer) > 0.9)
	var turned: Vector3 = -_frank.global_basis.z
	_check("…girándose en el hombro hacia él", Vector2(turned.x, turned.z).normalized().dot(Vector2(to_archer.x, to_archer.z).normalized()) > 0.8)
	archer.state_machine.transition_to(&"Idle", {"wait": 1000.0})
	_put(archer, _player.global_position + Vector3(60.0, 0.0, 60.0))
	await _wait(2.0)
	_check("Deja de señalar al rato", _frank.pose == Frank.Pose.IDLE)

	# 2. Un enemigo se lanza a por Kael: delante no avisa; por la espalda, sí.
	_put(soldier, _player.global_position + forward * 6.0)
	_quiet()
	soldier.state_machine.transition_to(&"Chase")
	await _wait(0.2)
	_check("Enemigo de frente: no hace falta avisar", not _spoken.has("frank/warn_behind"))
	soldier.state_machine.transition_to(&"Idle", {"wait": 1000.0})
	_put(soldier, _player.global_position - forward * 6.0)
	_check("El ángulo lo pone a la espalda", _frank.advisor.is_behind(soldier))
	_quiet()
	soldier.state_machine.transition_to(&"Chase")
	await _wait(0.2)
	_check("Por la espalda: «¡Detrás de ti!» y lo señala", _spoken.has("frank/warn_behind") and _frank.pose == Frank.Pose.POINT)
	soldier.state_machine.transition_to(&"Idle", {"wait": 1000.0})

	# 3. Uno sospecha: lo dice bajito.
	_quiet()
	soldier.state_machine.transition_to(&"Suspicious", {"at": _player.global_position})
	await _wait(0.2)
	_check("Un enemigo sospecha: «Shh… Ese ha oído algo.»", _spoken.has("frank/warn_suspicious"))
	soldier.state_machine.transition_to(&"Idle", {"wait": 1000.0})
	_put(soldier, _player.global_position + Vector3(-60.0, 0.0, 60.0))

	# 4. Escondite detrás del bloque: Frank lo señala, brilla, y se recoge con Y.
	var cache: HiddenCache = _cache(&"behind_block")
	_check("El escondite está en el nivel, sin encontrar", cache != null and not cache.revealed and not cache.is_taken())
	_teleport(cache.global_position + Vector3(0.0, 0.0, 9.5))
	await _wait(0.3)
	_check("Lejos (9,5 m), Frank aún no lo huele", not cache.revealed)
	_quiet()
	_teleport(cache.global_position + Vector3(0.0, 0.0, 6.0))
	await _wait(0.3)
	_check("Cerca: «¡Eh! Ahí hay algo.» y lo señala", _spoken.has("frank/find_item") and _frank.pose == Frank.Pose.POINT)
	_check("El escondite brilla", cache.revealed)
	var xp_before: int = _player.xp
	_teleport(cache.global_position + Vector3(0.8, 0.0, 0.8))
	await _wait(0.3)
	_check("Junto al escondite se puede recoger", cache.can_pick(_player))
	_quiet()
	await _tap("interact")
	await _wait(0.3)
	_check("Recogido: +%d de experiencia" % (_player.xp - xp_before), _player.xp - xp_before == cache.reward_xp and cache.is_taken() and not cache.visible)
	_check("Frank presume: «¡La mitad es mía!»", _spoken.has("frank/found_item"))

	# 5. La despensa: cerrada por dentro; Frank abre el pestillo.
	var gate: LatchedGate = get_tree().get_first_node_in_group("latched_gates") as LatchedGate
	_check("La despensa está cerrada", gate != null and not gate.is_open())
	_quiet()
	_teleport(gate.outside_point())
	await _wait(0.4)
	_check("Frank se ofrece: «Cerrado por dentro… Déjame a mí.»", _spoken.has("frank/gate_locked"))
	_check("Aviso «Y  Que Frank abra el pestillo»", gate.can_open(_player) and gate._prompt.visible and gate._prompt.text.begins_with("Y"))
	_check("La puerta cierra el paso", _blocked(gate.outside_point(), gate.global_position))
	_quiet()
	await _tap("interact")
	await _wait(0.3)
	_check("Frank se baja del hombro", _frank.mode != Frank.Mode.PERCHED)
	var waited: float = 0.0
	var went_high: bool = false
	while not (gate.is_open() and _frank.mode == Frank.Mode.PERCHED) and waited < 8.0:
		if _frank.global_position.y > 2.8:
			went_high = true
		await _wait(0.1)
		waited += 0.1
	_check("Salta por encima del muro", went_high)
	_check("Abre la puerta y vuelve al hombro (%.1f s)" % waited, gate.is_open() and _frank.mode == Frank.Mode.PERCHED)
	_check("Chilla al ir y al volver", _spoken.has("frank/gate_go") and _spoken.has("frank/gate_done"))
	await _wait(1.0)
	_check("Ahora se puede pasar", not _blocked(gate.outside_point(), gate.global_position))

	# 6. Dentro: la nota de los cazadores. Frank no bromea.
	var note: HiddenCache = _cache(&"poacher_note")
	_quiet()
	_teleport(note.global_position + Vector3(0.6, 0.0, 0.0))
	await _wait(0.4)
	note.pick(_player)
	await _wait(0.2)
	_check("Dentro, la Nota de los cazadores (objeto clave)", _player.key_items.has(&"poacher_note") and ItemLore.ITEMS.has(&"poacher_note"))
	_check("Frank, triste: «…Esa jaula era para mí.»", _spoken.has("frank/poacher_note") and _frank.pose == Frank.Pose.SAD)

	# 7. Guardado: al cargar, la puerta sigue abierta y los escondites, vacíos.
	var saved: Dictionary = Story.to_dict()
	Story.reset()
	await _wait(0.3)
	_check("Partida nueva: puerta cerrada, escondites llenos", not gate.is_open() and cache.visible and not cache.is_taken())
	_teleport(gate.outside_point())
	await _wait(0.3)
	_check("Sin Frank: «Cerrado por dentro» y no se puede abrir", not gate.can_open(_player) and gate._prompt.text == "Cerrado por dentro")
	Story.from_dict(saved)
	await _wait(0.3)
	_check("Al cargar: puerta abierta y escondites vacíos", gate.is_open() and cache.is_taken() and not cache.visible)


## ¿Hay algo sólido entre dos puntos (a media altura)?
func _blocked(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from + Vector3.UP, to + Vector3.UP)
	query.exclude = [_player.get_rid()]
	return not get_viewport().world_3d.direct_space_state.intersect_ray(query).is_empty()


func _enemy_named(display: String) -> Enemy:
	for node in get_tree().get_nodes_in_group("enemies"):
		if (node as Enemy).display_name == display:
			return node as Enemy
	return null


func _cache(id: StringName) -> HiddenCache:
	for node in get_tree().get_nodes_in_group("hidden_caches"):
		if (node as HiddenCache).cache_id == id:
			return node as HiddenCache
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
