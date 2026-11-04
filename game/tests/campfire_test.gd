extends Node
## Prueba automática del campamento: descansar junto a la fogata repone vida y vendajes, devuelve a
## todos los enemigos (vivos o muertos) a su puesto y lo convierte en el punto de reaparición. No se
## puede descansar con enemigos alerta cerca. Los enemigos muertos ya no reaparecen solos: solo al
## descansar o al morir Kael.
## Ejecutar: Godot --headless --path game res://tests/campfire_test.tscn

var _player: Player
var _fire: Campfire
var _enemy: Enemy
var _failures: int = 0


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_fire = get_tree().get_first_node_in_group("campfires") as Campfire
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	_check("Hay una fogata en el nivel", _fire != null)
	if _fire == null:
		return
	await _wait(0.3)

	# 1. Lejos de la fogata no se puede descansar ni se ve el aviso.
	await _place(_fire.global_position + Vector3(9.0, 0.0, 0.0))
	_check("Lejos de la fogata no se puede descansar", not _fire.can_rest(_player))
	_check("Lejos no se ve el aviso", not _fire.prompt_visible())

	# 2. Cerca, sin enemigos alerta: aviso visible y se puede descansar.
	await _place(_fire.rest_position())
	_check("Junto a la fogata se puede descansar", _fire.can_rest(_player))
	_check("Junto a la fogata se ve el aviso (\"%s\")" % _fire.prompt_text(), _fire.prompt_visible() and _fire.prompt_text().contains("Descansar"))

	# 3. Los enemigos muertos ya no reaparecen solos.
	var spawn: Vector3 = _enemy.global_position
	_enemy.receive_deathblow(_player)
	await _wait(7.0)
	_check("Un enemigo muerto sigue muerto con el tiempo (%s)" % _enemy.state_name(), _enemy.is_dead())

	# 4. Descansar: repone todo y devuelve a los enemigos.
	var other := _second_enemy()
	var other_spawn: Vector3 = other.global_position
	other.global_position += Vector3(6.0, 0.0, 3.0)
	other.reset_physics_interpolation()
	await _place(_fire.rest_position())
	_player.health.take_damage(70.0)
	_player.bandages = 1
	await _tap("interact")
	await _wait(0.2)
	_check("Pulsar Y junto a la fogata empieza a descansar (%s)" % _player.state_machine.current.name, _player.state_machine.current.name == &"Rest")
	await _wait(1.0)
	_check("La pantalla se oscurece al descansar (%.2f)" % Camps.fade_alpha(), Camps.fade_alpha() > 0.5)
	await _wait(3.0)
	Camps.level_menu.close()  # el menú de atributos se abre al descansar
	await _wait(1.0)
	_check("Al descansar recupera toda la vida (%.0f/%.0f)" % [_player.health.current, _player.health.max_health], is_equal_approx(_player.health.current, _player.health.max_health))
	_check("…y todos los vendajes (%d)" % _player.bandages, _player.bandages == _player.max_bandages)
	_check("El enemigo muerto vuelve a la vida (%s)" % _enemy.state_name(), not _enemy.is_dead())
	_check("…en su puesto (a %.1f m)" % _flat(_enemy.global_position, spawn), _flat(_enemy.global_position, spawn) < 0.5)
	_check("Un enemigo vivo y desplazado vuelve a su puesto (a %.1f m)" % _flat(other.global_position, other_spawn), _flat(other.global_position, other_spawn) < 0.5)
	_check("Al terminar se levanta (%s)" % _player.state_machine.current.name, _player.state_machine.current.name == &"Ground")
	_check("La pantalla vuelve a verse (%.2f)" % Camps.fade_alpha(), Camps.fade_alpha() < 0.05)

	# 5. Morir: reaparece junto a la fogata donde descansó, y los enemigos también vuelven.
	await _place(_fire.global_position + Vector3(14.0, 0.0, -6.0))
	_enemy.receive_deathblow(_player)
	await _wait(0.2)
	_player.health.take_damage(_player.health.max_health * 2.0)
	_player.state_machine.transition_to(&"Dead")
	await _wait(0.2)
	_check("Kael muere (%s)" % _player.state_machine.current.name, _player.state_machine.current.name == &"Dead")
	await _wait(4.8)
	var at_fire: float = _flat(_player.global_position, _fire.rest_position())
	_check("Reaparece junto a la fogata (a %.1f m)" % at_fire, at_fire < 1.0)
	_check("Tras morir, los enemigos también vuelven (%s)" % _enemy.state_name(), not _enemy.is_dead())
	_check("Tras reaparecer la pantalla se ve (%.2f)" % Camps.fade_alpha(), Camps.fade_alpha() < 0.05)

	# 6. Con un enemigo alerta cerca no se puede descansar (Y sigue siendo la patada).
	await _place(_fire.rest_position())
	_enemy.global_position = _fire.global_position + Vector3(0.0, 0.0, -7.0)
	_enemy.reset_physics_interpolation()
	_enemy.aggro_range = 12.0
	_enemy.alert()
	await _wait(0.6)
	_check("Con un enemigo alerta cerca no se puede descansar", not _fire.can_rest(_player))
	_check("…y el aviso lo dice (\"%s\")" % _fire.prompt_text(), _fire.prompt_text().contains("enemigos"))
	await _tap("interact")
	await _wait(0.1)
	_check("…así que Y no hace descansar (%s)" % _player.state_machine.current.name, _player.state_machine.current.name != &"Rest")


func _second_enemy() -> Enemy:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node != _enemy:
			return node as Enemy
	return null


## Jugador en un punto, quieto y con la vida llena.
func _place(at: Vector3) -> void:
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	_player.health.heal(_player.health.max_health)
	_player.posture.reset()
	await _wait(0.3)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


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
