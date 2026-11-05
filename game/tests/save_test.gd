extends Node
## Prueba automática del guardado: se guarda solo al descansar, al subir atributos, al morir y al recoger
## el morral; al "volver a abrir el juego" (cargar el nivel de nuevo) Kael aparece en su último campamento
## con sus atributos, su experiencia y su morral. Un archivo roto no rompe el juego.
## Usa un archivo de prueba aparte: nunca toca la partida del jugador.
## Ejecutar: Godot --headless --path game res://tests/save_test.tscn

const TEST_PATH: String = "user://save_test.json"

var _level: Node
var _player: Player
var _fire: Campfire
var _failures: int = 0


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	await _load_level()
	await _run()
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	# 1. Sin partida guardada: empieza de cero.
	_check("Sin partida guardada no hay archivo", not SaveGame.exists())
	_check("Empieza de cero (nivel %d, exp %d)" % [_player.attributes.level(), _player.xp], _player.attributes.level() == 1 and _player.xp == 0)

	# 2. Descansar guarda: experiencia, atributos y campamento.
	_player.xp = 500
	_player.raise_attribute(&"vigor")
	_player.raise_attribute(&"strength")
	var xp_left: int = _player.xp
	_check("Subir un atributo guarda la partida", SaveGame.exists())
	await _rest()
	var data: Dictionary = SaveGame.read()
	_check("El archivo tiene la experiencia (%s)" % str(data.get("xp")), int(data.get("xp", -1)) == xp_left)
	_check("…los atributos (%s)" % str(data.get("attributes")), int(data.get("attributes", {}).get("vigor", 0)) == 2)
	_check("…y el campamento", data.has("spawn"))

	# 3. Morir guarda el morral (y la experiencia a 0): no se puede esquivar cerrando el juego.
	var fell_at: Vector3 = _fire.global_position + Vector3(12.0, 0.0, -5.0)
	_player.global_position = fell_at
	_player.reset_physics_interpolation()
	await _wait(0.3)
	_player.health.take_damage(_player.health.max_health * 2.0)
	_player.state_machine.transition_to(&"Dead")
	await _wait(0.5)
	data = SaveGame.read()
	_check("Al morir se guarda el morral (%s)" % str(data.get("satchel")), data.get("satchel", {}).get("amount", 0) == xp_left)
	_check("…y la experiencia a 0 (%s)" % str(data.get("xp")), int(data.get("xp", -1)) == 0)
	await _wait(4.5)

	# 4. "Cerrar y volver a abrir": se carga todo.
	await _load_level()
	var at_fire: float = _flat(_player.global_position, _fire.rest_position())
	_check("Al abrir aparece en su campamento (a %.1f m)" % at_fire, at_fire < 1.0)
	_check("…con sus atributos (Vigor %d, Fuerza %d)" % [_player.attributes.get_value(&"vigor"), _player.attributes.get_value(&"strength")],
			_player.attributes.get_value(&"vigor") == 2 and _player.attributes.get_value(&"strength") == 2)
	_check("…la vida máxima que le dan (%.0f)" % _player.health.max_health, _player.health.max_health > 100.0 and is_equal_approx(_player.health.current, _player.health.max_health))
	_check("…y su experiencia (%d)" % _player.xp, _player.xp == 0)
	var bags: Array = get_tree().get_nodes_in_group("xp_satchels")
	_check("Su morral sigue donde cayó (%d)" % bags.size(), bags.size() == 1 and _flat((bags[0] as Node3D).global_position, fell_at) < 1.0)
	_check("…con lo que llevaba", bags.size() == 1 and (bags[0] as XpSatchel).amount == xp_left)

	# 5. Recoger el morral guarda.
	if bags.size() == 1:
		_player.global_position = (bags[0] as Node3D).global_position
		_player.reset_physics_interpolation()
		await _wait(0.4)
		data = SaveGame.read()
		_check("Recoger el morral guarda (exp %s, morral %s)" % [str(data.get("xp")), str(data.has("satchel"))], int(data.get("xp", -1)) == xp_left and not data.has("satchel"))

	# 6. Un archivo roto no rompe el juego: empieza de cero.
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{esto no es json")
	file.close()
	await _load_level()
	_check("Con un archivo roto empieza de cero sin errores", _player.attributes.level() == 1 and _player.xp == 0)

	# 7. Fuera de las pruebas y del juego normal no guarda.
	SaveGame.erase()
	SaveGame.force_active = false
	_player.xp = 999
	_player.raise_attribute(&"temple")
	_check("Si no es la partida real, no guarda nada", not SaveGame.exists())
	SaveGame.force_active = true


func _rest() -> void:
	_player.global_position = _fire.rest_position()
	_player.reset_physics_interpolation()
	await _wait(0.3)
	Input.action_press("interact")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("interact")
	await _wait(3.0)
	Camps.level_menu.close()
	await _wait(1.0)


## Carga el nivel (como al abrir el juego), quitando el anterior.
func _load_level() -> void:
	if _level:
		_level.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	_level = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(_level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_fire = get_tree().get_first_node_in_group("campfires") as Campfire
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await _wait(0.4)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
