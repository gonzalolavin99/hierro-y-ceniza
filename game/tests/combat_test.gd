extends Node
## Prueba automática del combate contra el soldado de práctica.
## Ejecutar: Godot --headless --path game res://tests/combat_test.tscn

var _player: Player
var _enemy: Enemy
var _failures: int = 0
var _deflects: int = 0


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	_player.deflected.connect(func() -> void: _deflects += 1)
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	await _wait(0.3)

	# 1. Fijar objetivo con R3
	await _tap("lock_on")
	_check("R3 fija al soldado", _player.lock_target == _enemy)

	# 2. El soldado se acerca
	var t: float = 0.0
	while _player.global_position.distance_to(_enemy.global_position) > 2.6 and t < 6.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
	_check("El soldado se acerca (%.1f m)" % _player.global_position.distance_to(_enemy.global_position), t < 6.0)

	# 3. Guardia alta y desvío en el último instante de cada preparación enemiga
	Input.action_press("block")
	t = 0.0
	while _deflects < 2 and t < 15.0 and not _player.is_dead():
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var attack := _enemy.state_machine.current as EnemyAttackState
		if attack and attack._phase == EnemyAttackState.Phase.WINDUP:
			var remaining: float = attack._swings[attack._index]["windup"] - attack._timer
			var key: String = "%d-%d" % [attack.get_instance_id(), attack._index]
			if remaining <= 0.06 and _last_key != key:
				_last_key = key
				Input.action_release("block")
				await get_tree().physics_frame
				Input.action_press("block")
	Input.action_release("block")
	_check("Desvía ataques reales (%d desvíos, vida %.0f)" % [_deflects, _player.health.current], _deflects >= 2)
	_check("El desvío sube la postura enemiga (%.0f)" % _enemy.posture.current, _enemy.posture.current > 20.0 or _enemy.state_name() == &"Broken")

	# 4. Atacar: el soldado bloquea (sube su postura) o recibe daño
	await _wait(0.4)
	var posture_before: float = _enemy.posture.current
	var health_before: float = _enemy.health.current
	for i in 3:
		await _tap("attack")
		await _wait(0.25)
	await _wait(0.3)
	_check("Los ataques afectan al soldado (postura %.0f→%.0f, vida %.0f→%.0f)" % [posture_before, _enemy.posture.current, health_before, _enemy.health.current],
		_enemy.posture.current > posture_before or _enemy.health.current < health_before or _enemy.state_name() == &"Broken")

	# 5. Romper postura → golpe mortal
	if _enemy.state_name() != &"Broken":
		_enemy.posture.add(1000.0)
	await get_tree().physics_frame
	_check("Postura rota = expuesto", _enemy.can_be_deathblowed())
	await _tap("attack")
	_check("RB inicia el golpe mortal (%s)" % _player.state_machine.current.name, _player.state_machine.current.name == &"Deathblow")
	await _wait(0.8)
	_check("El soldado muere", _enemy.is_dead())
	_check("Se suelta la fijación", _player.lock_target == null)

	# 6. Muerte del jugador y reaparición
	await _wait(0.3)
	_player.receive_hit(HitData.create(_enemy, 1000.0, 0.0))
	_check("El jugador muere", _player.is_dead())
	await _wait(2.8)
	_check("Reaparece con vida completa", not _player.is_dead() and _player.health.current == _player.health.max_health)

	# 7. El soldado reaparece (solo en pruebas)
	await _wait(3.0)
	_check("El soldado reaparece", not _enemy.is_dead() and _enemy.health.current == _enemy.health.max_health)


var _last_key: String = ""


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
