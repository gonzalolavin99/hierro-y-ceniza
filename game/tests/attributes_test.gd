extends Node
## Prueba automática de los atributos: se suben gastando experiencia (cada nivel cuesta más), cada uno
## mejora lo suyo (Vigor vida, Temple postura, Fuerza daño, Destreza daño a la postura), y el menú del
## campamento se abre al descansar, sube con A / Intro y se cierra con B / Esc.
## Ejecutar: Godot --headless --path game res://tests/attributes_test.tscn

var _player: Player
var _fire: Campfire
var _failures: int = 0


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_fire = get_tree().get_first_node_in_group("campfires") as Campfire
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	await _wait(0.3)
	var attrs: Attributes = _player.attributes
	# 1. Empieza en nivel 1 con todo en 1.
	_check("Empieza en nivel 1 (%d)" % attrs.level(), attrs.level() == 1)
	_check("Los cuatro atributos empiezan en 1", attrs.get_value(&"vigor") == 1 and attrs.get_value(&"temple") == 1 \
			and attrs.get_value(&"strength") == 1 and attrs.get_value(&"dexterity") == 1)
	var cost: int = attrs.next_cost()
	_check("Subir cuesta experiencia (%d)" % cost, cost > 0)

	# 2. Sin experiencia suficiente no sube.
	_player.xp = cost - 1
	_check("Sin experiencia suficiente no sube", not _player.raise_attribute(&"vigor") and attrs.get_value(&"vigor") == 1 and _player.xp == cost - 1)

	# 3. Vigor: más vida; gasta la experiencia y el siguiente nivel cuesta más.
	var health_before: float = _player.health.max_health
	_player.xp = cost + 500
	_check("Con experiencia suficiente sube Vigor", _player.raise_attribute(&"vigor") and attrs.get_value(&"vigor") == 2)
	_check("…gasta lo que costaba (%d)" % _player.xp, _player.xp == 500)
	_check("…más vida (%.0f → %.0f)" % [health_before, _player.health.max_health], _player.health.max_health > health_before)
	_check("…sube el nivel (%d)" % attrs.level(), attrs.level() == 2)
	_check("…y el siguiente cuesta más (%d → %d)" % [cost, attrs.next_cost()], attrs.next_cost() > cost)

	# 4. Temple: más postura.
	var posture_before: float = _player.posture.max_posture
	_player.raise_attribute(&"temple")
	_check("Temple da más postura (%.0f → %.0f)" % [posture_before, _player.posture.max_posture], _player.posture.max_posture > posture_before)

	# 5. Fuerza y Destreza: golpes más fuertes (daño y postura).
	var base := _player.make_hit(10.0, 10.0)
	_player.raise_attribute(&"strength")
	var stronger := _player.make_hit(10.0, 10.0)
	_check("Fuerza sube el daño (%.1f → %.1f)" % [base.damage, stronger.damage], stronger.damage > base.damage and is_equal_approx(stronger.posture_damage, base.posture_damage))
	_player.raise_attribute(&"dexterity")
	var nimbler := _player.make_hit(10.0, 10.0)
	_check("Destreza sube el daño a la postura (%.1f → %.1f)" % [base.posture_damage, nimbler.posture_damage], nimbler.posture_damage > base.posture_damage)

	# 6. Hay un tope por atributo.
	_player.xp = 999999
	for i in 30:
		_player.raise_attribute(&"vigor")
	_check("Vigor tiene tope (%d)" % attrs.get_value(&"vigor"), attrs.get_value(&"vigor") == Attributes.MAX_VALUE)
	_player.xp = 0

	# 7. Al morir y reaparecer conserva los atributos.
	var vigor: int = attrs.get_value(&"vigor")
	_player.health.take_damage(_player.health.max_health * 2.0)
	_player.state_machine.transition_to(&"Dead")
	await _wait(4.6)
	_check("Tras morir conserva los atributos y la vida máxima", attrs.get_value(&"vigor") == vigor and is_equal_approx(_player.health.current, _player.health.max_health))

	# 8. Menú del campamento: se abre al descansar, sube con A y se cierra con B.
	_player.xp = attrs.next_cost() + 10
	_player.global_position = _fire.rest_position()
	_player.reset_physics_interpolation()
	await _wait(0.3)
	await _tap("interact")
	await _wait(3.6)
	var menu: Node = get_tree().get_first_node_in_group("level_menu")
	_check("Tras descansar se abre el menú de atributos", menu != null and menu.call("is_open"))
	_check("El jugador sigue descansando mientras (%s)" % _player.state_machine.current.name, _player.state_machine.current.name == &"Rest")
	if menu == null:
		return
	_check("El menú muestra la experiencia (\"%s\")" % menu.call("header_text"), (menu.call("header_text") as String).contains(str(_player.xp)))
	var level_before: int = attrs.level()
	_check("Empieza señalando Vigor (%s)" % menu.call("focused_attribute"), menu.call("focused_attribute") == &"vigor")
	await _ui("ui_down")  # Vigor ya está al tope (paso 6): baja a Temple
	var first: StringName = menu.call("focused_attribute")
	var value_before: int = attrs.get_value(first)
	await _ui("ui_accept")
	_check("A / Intro sube el atributo elegido (%s %d → %d)" % [first, value_before, attrs.get_value(first)], attrs.get_value(first) == value_before + 1 and attrs.level() == level_before + 1)
	await _ui("ui_down")
	_check("Abajo cambia de atributo (%s)" % menu.call("focused_attribute"), menu.call("focused_attribute") != first)
	await _ui("ui_accept")
	_check("Sin experiencia suficiente, A no sube (nivel %d)" % attrs.level(), attrs.level() == level_before + 1)
	await _ui("ui_cancel")
	await _wait(0.8)
	_check("B / Esc cierra el menú", not menu.call("is_open"))
	_check("…y Kael se levanta (%s)" % _player.state_machine.current.name, _player.state_machine.current.name == &"Ground")


func _ui(action: StringName) -> void:
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
	await get_tree().process_frame
	await get_tree().process_frame


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
