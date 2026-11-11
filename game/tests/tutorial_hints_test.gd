extends Node
## Prueba automática de los avisos que solo salen las primeras veces (TutorialHints): cada ataque rojo
## explica qué hacer las 3 primeras veces y luego calla; al romper la postura de un enemigo cercano, "golpe
## mortal"; la primera vez que Kael está herido, "cúrate"; lo ya aprendido se guarda en Story.
## Ejecutar: Godot --headless --path game res://tests/tutorial_hints_test.tscn

var _player: Player
var _enemy: Enemy
var _hints: TutorialHints
var _failures: int = 0


func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	await _wait(0.5)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	_hints = (get_tree().get_first_node_in_group("hud") as Node).get("hints") as TutorialHints
	_check("El HUD tiene los avisos del tutorial", _hints != null)
	if _hints:
		await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	_enemy.aggro_range = 0.0
	_enemy.global_position = _player.global_position + Vector3(0.0, 0.0, -3.0)
	await _wait(0.2)

	# 1. Barrido rojo: 3 veces se explica, la 4.ª no.
	var count: int = 0
	for i in 4:
		_hints.last_id = &""
		_enemy.danger_warned.emit(HitData.Kind.SWEEP)
		if _hints.last_id == &"sweep":
			count += 1
	_check("El barrido se explica 3 veces y luego calla (%d)" % count, count == 3)
	_check("…el texto dice qué hacer (%s)" % _hints.text, "SALTA" in _hints.text)
	_check("…y queda aprendido en la partida", Story.heard(&"hint_sweep"))

	# 2. Cada ataque rojo tiene su aviso.
	_enemy.danger_warned.emit(HitData.Kind.THRUST)
	_check("La estocada tiene su aviso (%s)" % _hints.text, _hints.last_id == &"thrust" and "HACIA" in _hints.text)
	_enemy.danger_warned.emit(HitData.Kind.GRAB)
	_check("El agarre tiene su aviso", _hints.last_id == &"grab")

	# 3. Un enemigo lejano no da avisos.
	_hints.last_id = &""
	_enemy.global_position = _player.global_position + Vector3(0.0, 0.0, -30.0)
	await _wait(0.1)
	_enemy.danger_warned.emit(HitData.Kind.THRUST)
	_check("Un ataque rojo lejos de Kael no avisa", _hints.last_id == &"")

	# 4. Postura rota cerca: golpe mortal.
	_enemy.global_position = _player.global_position + Vector3(0.0, 0.0, -2.5)
	await _wait(0.1)
	_enemy.posture.add(_enemy.posture.max_posture * 2.0)
	await _wait(0.1)
	_check("Al romper la postura de un enemigo cercano: golpe mortal (%s)" % _hints.text, _hints.last_id == &"deathblow")

	# 5. Herido por primera vez: cúrate (una sola vez).
	_hints.last_id = &""
	_player.health.take_damage(_player.health.max_health * 0.4)
	_check("Herido por primera vez: cúrate (%s)" % _hints.text, _hints.last_id == &"heal")
	_hints.last_id = &""
	_player.health.take_damage(5.0)
	_check("…y solo una vez", _hints.last_id == &"")

	# 5b. Desprevenido y con Kael a su espalda a distancia de remate: marca roja ◆ y aviso (una vez por ocasión).
	await get_tree().create_timer(3.5, true, true).timeout  # Que se rehaga de la postura rota.
	var hud: Node = get_tree().get_first_node_in_group("hud")
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	_enemy.alerted = false
	await _wait(0.2)
	_player.global_position = _enemy.global_position - _enemy.get_facing() * 1.8
	_player.reset_physics_interpolation()
	_hints.last_id = &""
	await _wait(0.2)
	_check("Por la espalda y sin que te vea: la marca roja de golpe mortal sale sobre él", hud.get_node("DeathblowMark").visible)
	_check("…con su aviso (%s)" % _hints.text, _hints.last_id == &"stealth" and "espalda" in _hints.text)
	var times: int = int(_hints.shown.get(&"stealth", 0))
	await _wait(0.3)
	_check("…una vez por ocasión, no en cada fotograma (%d)" % int(_hints.shown.get(&"stealth", 0)), int(_hints.shown.get(&"stealth", 0)) == times)
	_player.global_position = _enemy.global_position - _enemy.get_facing() * 4.0
	_player.reset_physics_interpolation()
	await _wait(0.2)
	_check("Demasiado lejos: sin marca", not hud.get_node("DeathblowMark").visible)

	# 6. En una partida nueva vuelve a salir; lo aprendido viaja con la partida guardada.
	var saved: Dictionary = Story.to_dict()
	Story.reset()
	_check("Partida nueva: el barrido vuelve a explicarse", _hints.pending(&"sweep"))
	Story.from_dict(saved)
	_check("Partida cargada: lo aprendido sigue aprendido", not _hints.pending(&"sweep") and not _hints.pending(&"heal"))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
