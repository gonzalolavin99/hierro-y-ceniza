extends Node
## Prueba automática de los consejos y bromas de Frank (FrankAdvisor): vendarse con un enemigo cerca, quedarse
## sin vendas, morir y reaparecer (ánimo y pistas por enemigo), guardia rota, zonas, conciencia tras un golpe
## mortal, rato quieto, campamento, y que en los momentos serios no bromea. Sin Frank en el hombro, calla.
## Ejecutar: Godot --headless --path game res://tests/frank_tips_test.tscn

const TEST_PATH: String = "user://save_frank_tips_test.json"

var _player: Player
var _frank: Frank
var _advisor: FrankAdvisor
var _soldier: Enemy
var _failures: int = 0
var _spoken: Array[String] = []
var _subtitles: Array[String] = []


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player") as Player
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	_soldier = get_tree().get_first_node_in_group("enemies") as Enemy
	Voice.spoken.connect(func(speaker: StringName, event: StringName, _id: String) -> void: _spoken.append("%s/%s" % [speaker, event]))
	Voice.subtitle.connect(func(text: String, who: String, _s: float) -> void: _subtitles.append("%s: %s" % [who, text]))
	await _wait(0.5)
	Story.mark_heard(&"story_prologue")
	Story.mark_heard(Frank.STORY_MET)
	Story.changed.emit()
	await _wait(0.2)
	Voice.always_speak = true
	await _run()
	Voice.always_speak = false
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	_frank = _player.frank
	_advisor = _frank.advisor
	_check("Frank va en el hombro y tiene quien decide qué dice", _frank.mode == Frank.Mode.PERCHED and _advisor != null)
	_advisor.idle_long_after = 1e9

	# 1. Vendarse con un soldado alerta al lado: se tapa la cara.
	_soldier.aggro_range = 12.0
	_soldier.global_position = _player.global_position + Vector3(0.0, 0.0, 4.0)
	_soldier.reset_physics_interpolation()
	var waited: float = 0.0
	while not _soldier.has_target() and waited < 3.0:
		await _wait(0.1)
		waited += 0.1
	_quiet()
	_player.state_machine.transition_to(&"Heal")
	await _wait(0.2)
	_check("Vendarse con un enemigo cerca: «¿Ahora? ¿En serio?» y se tapa la cara",
		_spoken.has("frank/heal_danger") and _frank.pose == Frank.Pose.COVER_EYES)
	_soldier.aggro_range = 0.0
	_soldier.state_machine.transition_to(&"Idle", {"wait": 100.0})
	_soldier.global_position = _player.global_position + Vector3(0.0, 0.0, 40.0)
	_soldier.reset_physics_interpolation()
	await _wait(2.5)
	_check("El gesto se le pasa solo", _frank.pose == Frank.Pose.IDLE)

	# 2. Último vendaje: avisa de dónde conseguir más.
	_quiet()
	_player.bandages = 1
	_player.state_machine.transition_to(&"Heal")
	await _wait(3.6)
	_check("Sin vendas: «En un campamento te dan más»", _spoken.has("frank/bandages_out"))
	_player.bandages = _player.max_bandages

	# 3. Qué dice al reaparecer: ánimo, y desde la segunda vez pistas del enemigo (sin regalar la respuesta).
	_check("1.ª muerte: ánimo", _advisor.respawn_event("Lancero", 1) == &"death_first")
	_check("2.ª con el lancero: pista del lancero", _advisor.respawn_event("Lancero", 2) == &"hint_spear")
	_check("3.ª: ánimo otra vez", _advisor.respawn_event("Lancero", 3) == &"death_again")
	_check("4.ª: pista general de los ataques rojos", _advisor.respawn_event("Lancero", 4) == &"hint_danger")
	_check("2.ª con Varga: pista de Varga", _advisor.respawn_event("Capitana Varga", 2) == &"hint_varga")
	_check("Enemigo sin pista propia: ánimo", _advisor.respawn_event("Nadie", 2) == &"death_again")
	_quiet()
	_player.engaged_enemy = _soldier
	_player.state_machine.transition_to(&"Dead")
	await _wait(1.0)
	_check("Al morir Kael, Frank se tapa los ojos", _frank.pose == Frank.Pose.COVER_EYES)
	waited = 0.0
	while not _spoken.has("frank/death_first") and waited < 14.0:
		await _wait(0.1)
		waited += 0.1
	_check("Al reaparecer, lo anima (%.1f s)" % waited, _spoken.has("frank/death_first"))
	_check("Cuenta quién lo venció", int(_advisor.deaths_by.get(_soldier.display_name, 0)) == 1)
	_quiet()
	_player.engaged_enemy = _soldier
	_player.state_machine.transition_to(&"Dead")
	waited = 0.0
	while not _spoken.has("frank/hint_soldier") and waited < 14.0:
		await _wait(0.1)
		waited += 0.1
	_check("2.ª muerte con el soldado: pista del soldado", _spoken.has("frank/hint_soldier"))
	_check("Las pistas llevan subtítulo", _subtitles.any(func(s: String) -> bool: return s.contains("Se cansan antes que tú") or s.contains("tambalea")))

	# 4. Le rompen la guardia: "¡Respira, grandullón!" y se agarra.
	_quiet()
	_player.posture.broken.emit()
	await _wait(0.2)
	_check("Guardia rota: chilla y se agarra", _spoken.has("frank/stagger") and _frank.pose == Frank.Pose.CLING)
	_player.state_machine.transition_to(&"Ground")

	# 5. Zonas: después del anciano, su comentario.
	_quiet()
	Voice.say(&"narrator", &"story_pass_forest")
	await _wait(Voice.last_seconds + 1.0)
	_check("En el bosque, tras el anciano: «¡Árboles!»", _spoken.has("frank/zone_forest"))

	# 6. La conciencia: tras un golpe mortal (a veces).
	_quiet()
	Voice.say(&"kael", &"deathblow", _player.global_position)
	await _wait(2.0)
	_check("Tras un golpe mortal, la conciencia de Kael, cabizbajo", _spoken.has("frank/kill") and _frank.pose == Frank.Pose.SAD)

	# 7. Campamento: la primera vez, siempre.
	_quiet()
	Story._heard.erase(FrankAdvisor.REST_FIRST)
	_advisor._on_state_changed(&"Rest")
	await _wait(2.0)
	_check("Primer descanso: «Fuego, comida y nadie persiguiéndonos»", _spoken.has("frank/rest_first") and Story.heard(FrankAdvisor.REST_FIRST))

	# 8. Rato quieto: una broma.
	_quiet()
	_player.state_machine.transition_to(&"Ground")
	_advisor.idle_long_after = 1.0
	await _wait(1.6)
	_check("Quieto un rato: «¿Nos quedamos a vivir aquí?»", _spoken.has("frank/idle_long"))
	_advisor.idle_long_after = 1e9

	# 9. Momentos serios: tras morir Varga, cabizbajo y sin bromas (las pistas, sí).
	_quiet()
	Voice.say(&"varga", &"death", _player.global_position)
	await _wait(0.2)
	_check("Tras la muerte de Varga, cabizbajo y callado", _frank.pose == Frank.Pose.SAD and _advisor.is_quiet())
	var heals: int = _spoken.count("frank/heal")
	_quiet()
	_player.state_machine.transition_to(&"Heal")
	await _wait(0.3)
	_check("En un momento serio no bromea al vendarse", _spoken.count("frank/heal") == heals)
	await _wait(1.5)

	# 10. Sin Frank en el hombro (aún en la red), no dice nada.
	Story.reset()
	await _wait(0.3)
	var before: int = _spoken.filter(func(s: String) -> bool: return s.begins_with("frank/") and not s.ends_with("trapped")).size()
	_player.posture.broken.emit()
	_player.state_machine.transition_to(&"Heal")
	await _wait(0.5)
	var after: int = _spoken.filter(func(s: String) -> bool: return s.begins_with("frank/") and not s.ends_with("trapped")).size()
	_check("Si Frank no va con Kael, no comenta nada", after == before)


## Calla a todos y olvida pausas (cada caso empieza limpio).
func _quiet() -> void:
	Voice.reset()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
