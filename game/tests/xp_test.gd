extends Node
## Prueba automática de la experiencia: los enemigos la dan al morir, el HUD la muestra, al morir Kael la
## pierde y queda en su morral donde cayó; volviendo a por él la recupera. Si muere otra vez antes, el
## morral viejo se pierde. Descansar no borra el morral.
## Ejecutar: Godot --headless --path game res://tests/xp_test.tscn

var _player: Player
var _enemy: Enemy
var _fire: Campfire
var _failures: int = 0


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	_fire = get_tree().get_first_node_in_group("campfires") as Campfire
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	await _wait(0.3)
	# 1. Empieza sin experiencia y el HUD lo muestra.
	_check("Empieza con 0 de experiencia (%d)" % _player.xp, _player.xp == 0)
	_check("El HUD la muestra (\"%s\")" % _hud_text(), _hud_text().contains("Experiencia") and _hud_text().contains("0"))

	# 2. Matar a un enemigo da su experiencia.
	_check("Cada enemigo da experiencia (%d)" % _enemy.xp_reward, _enemy.xp_reward > 0)
	_enemy.receive_deathblow(_player)
	await _wait(0.3)
	var reward: int = _enemy.xp_reward
	_check("Al matarlo gana su experiencia (%d)" % _player.xp, _player.xp == reward)
	_check("El HUD se actualiza (\"%s\")" % _hud_text(), _hud_text().contains(str(reward)))
	_check("Tipos distintos dan distinta experiencia (%s)" % str(_rewards()), _rewards().size() >= 2)

	# 3. Morir: la pierde y queda en el morral donde cayó.
	var fell_at: Vector3 = _fire.global_position + Vector3(12.0, 0.0, -5.0)
	await _place(fell_at)
	await _die()
	_check("Tras morir no lleva experiencia (%d)" % _player.xp, _player.xp == 0)
	var bags: Array = _satchels()
	_check("Queda un morral (%d)" % bags.size(), bags.size() == 1)
	if bags.size() != 1:
		return
	var bag: XpSatchel = bags[0]
	_check("…con lo que llevaba (%d)" % bag.amount, bag.amount == reward)
	_check("…donde cayó (a %.1f m)" % _flat(bag.global_position, fell_at), _flat(bag.global_position, fell_at) < 1.0)

	# 4. Descansar no borra el morral.
	await _place(_fire.rest_position())
	await _tap("interact")
	await _wait(3.0)
	Camps.level_menu.close()  # el menú de atributos se abre al descansar
	await _wait(1.0)
	_check("Descansar no borra el morral (%d)" % _satchels().size(), _satchels().size() == 1)

	# 5. Volver a por él: la recupera y el morral desaparece.
	await _place(bag.global_position + Vector3(3.0, 0.0, 0.0))
	_check("A 3 m no la recoge todavía (%d)" % _player.xp, _player.xp == 0)
	await _place(bag.global_position + Vector3(0.5, 0.0, 0.0))
	await _wait(0.3)
	_check("Al pasar por el morral recupera la experiencia (%d)" % _player.xp, _player.xp == reward)
	_check("…y el morral desaparece (%d)" % _satchels().size(), _satchels().size() == 0)

	# 6. Morir dos veces: el primer morral se pierde, solo queda el último.
	await _place(fell_at)
	await _die()
	_player.gain_xp(25)
	var second_at: Vector3 = _fire.global_position + Vector3(-6.0, 0.0, -10.0)
	await _place(second_at)
	await _die()
	bags = _satchels()
	_check("Morir otra vez deja un solo morral (%d)" % bags.size(), bags.size() == 1)
	if bags.size() == 1:
		var last: XpSatchel = bags[0]
		_check("…el último, con solo lo nuevo (%d)" % last.amount, last.amount == 25 and _flat(last.global_position, second_at) < 1.0)

	# 7. Morir sin experiencia no deja morral (y borra el anterior).
	await _place(fell_at)
	await _die()
	_check("Morir sin experiencia no deja morral (%d)" % _satchels().size(), _satchels().size() == 0)


func _rewards() -> Dictionary:
	var found: Dictionary = {}
	for node in get_tree().get_nodes_in_group("enemies"):
		found[(node as Enemy).xp_reward] = true
	return found


func _satchels() -> Array:
	return get_tree().get_nodes_in_group("xp_satchels").filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())


func _die() -> void:
	_player.health.take_damage(_player.health.max_health * 2.0)
	_player.state_machine.transition_to(&"Dead")
	await _wait(4.6)


func _hud_text() -> String:
	var hud: Node = get_tree().get_first_node_in_group("hud")
	return hud.call("xp_text") if hud else ""


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
