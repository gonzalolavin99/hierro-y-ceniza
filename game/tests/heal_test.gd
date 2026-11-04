extends Node
## Prueba automática de la curación con vendajes: cura una parte de la vida, gasta un vendaje, deja
## expuesto (quieto y sin guardia), un golpe a tiempo la interrumpe sin gastar el vendaje, sin vendajes no
## hace nada, se reponen al reaparecer, y los enemigos castigan curarse cerca de ellos.
## Ejecutar: Godot --headless --path game res://tests/heal_test.tscn

var _player: Player
var _enemy: Enemy
var _failures: int = 0


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	for node in get_tree().get_nodes_in_group("enemies"):
		var other := node as Enemy
		other.aggro_range = 0.0
		if other != _enemy:
			other.global_position += Vector3(0.0, 0.0, -90.0)
			other.reset_physics_interpolation()
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	_enemy.global_position = Vector3(0.0, 0.0, -40.0)
	_enemy.reset_physics_interpolation()
	await _place()

	# 1. Empieza con sus vendajes y el HUD los muestra.
	_check("Empieza con %d vendajes" % _player.bandages, _player.bandages == _player.max_bandages and _player.max_bandages >= 2)
	_check("El HUD muestra los vendajes (\"%s\")" % _hud_text(), _hud_text().contains("%d" % _player.bandages))

	# 2. Curarse: tras vendarse, recupera parte de la vida y gasta un vendaje.
	_player.health.take_damage(60.0)
	var before: float = _player.health.current
	await _tap("heal")
	await _wait(0.1)
	_check("Pulsar curar empieza a vendarse (%s)" % _player.state_machine.current.name, _player.state_machine.current.name == &"Heal")
	Input.action_press("move_forward")
	await _wait(0.4)
	var speed: float = Vector2(_player.velocity.x, _player.velocity.z).length()
	Input.action_release("move_forward")
	_check("Mientras se venda no se mueve (%.1f m/s)" % speed, speed < 0.2)
	await _wait(1.3)
	var gained: float = _player.health.current - before
	_check("Cura una buena parte de la vida (+%.0f)" % gained, gained >= _player.health.max_health * 0.4)
	_check("Gasta un vendaje (quedan %d)" % _player.bandages, _player.bandages == _player.max_bandages - 1)
	_check("Al terminar vuelve a estar libre (%s)" % _player.state_machine.current.name, _player.state_machine.current.name == &"Ground")

	# 3. Un golpe mientras se venda lo interrumpe: no cura, pero no pierde el vendaje.
	await _place()
	_player.health.take_damage(60.0)
	var left: int = _player.bandages
	await _tap("heal")
	await _wait(0.2)
	var hit := HitData.create(_enemy, 20.0, 10.0, 0.0)
	_check("Vendándose no puede cubrirse: el golpe entra", _player.receive_hit(hit) == HitData.Result.HIT)
	await _wait(1.5)
	_check("El golpe interrumpe la cura (vida %.0f)" % _player.health.current, _player.health.current <= _player.health.max_health - 60.0)
	_check("…y no gasta el vendaje (quedan %d)" % _player.bandages, _player.bandages == left)

	# 4. Sin vendajes no hace nada.
	await _place()
	_player.bandages = 0
	_player.health.take_damage(30.0)
	var hurt: float = _player.health.current
	await _tap("heal")
	await _wait(1.6)
	_check("Sin vendajes no se cura (vida %.0f)" % _player.health.current, _player.health.current == hurt and _player.state_machine.current.name != &"Heal")

	# 5. Al reaparecer se reponen.
	_player.respawn()
	await _wait(0.1)
	_check("Al reaparecer recupera los vendajes (%d)" % _player.bandages, _player.bandages == _player.max_bandages)

	# 6. Castigo: un enemigo cerca que te ve curarte se lanza a por ti.
	await _place()
	_enemy.mind.predictable = false
	_enemy.aggro_range = 12.0
	_enemy.global_position = Vector3(0.0, 0.0, -4.5)
	_enemy.model.rotation.y = 0.0
	_enemy.reset_physics_interpolation()
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	Squad.reset()
	await _wait(0.3)
	_player.health.take_damage(50.0)
	var states: Array[StringName] = []
	var record := func(s: StringName) -> void: states.append(s)
	_enemy.state_machine.state_changed.connect(record)
	await _tap("heal")
	await _wait(0.6)
	_enemy.state_machine.state_changed.disconnect(record)
	_check("Te ve curarte y se lanza a castigarte %s" % str(states), &"Attack" in states)
	await _wait(2.0)

	# 7. En modo predecible (otras pruebas) no castiga.
	await _place()
	_enemy.mind.predictable = true
	_enemy.global_position = Vector3(0.0, 0.0, -4.5)
	_enemy.reset_physics_interpolation()
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.3)
	_player.health.take_damage(50.0)
	await _tap("heal")
	await _wait(0.6)
	_check("En modo predecible no castiga (%s)" % _enemy.state_name(), _enemy.state_name() == &"Idle")


## Jugador en el origen, quieto y con la vida llena.
func _place() -> void:
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	_player.model.rotation.y = 0.0
	_player.reset_physics_interpolation()
	_player.health.heal(_player.health.max_health)
	_player.posture.reset()
	await _wait(0.3)


func _hud_text() -> String:
	var hud: Node = get_tree().get_first_node_in_group("hud")
	return hud.call("bandage_text") if hud else ""


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
