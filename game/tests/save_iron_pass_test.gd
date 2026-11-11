extends Node
## Prueba automática del guardado EN EL NIVEL REAL (el Paso de Hierro): lo que se consigue allí (portón del
## atajo, puerta de la aldea, despensa, escondite, Varga vencida, la Ráfaga, la elección del prólogo, el último
## campamento) sigue igual tras "cerrar y volver a abrir el juego". Usa un archivo de prueba aparte.
## Ejecutar: Godot --headless --path game res://tests/save_iron_pass_test.tscn

const TEST_PATH: String = "user://save_iron_pass_save_test.json"

var _level: Node
var _player: Player
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
	_check("Partida nueva: el atajo cerrado y solo el Torbellino", not _gate(&"fortress_shortcut").is_open() and _player.arts.unlocked == [PlayerArts.STARTING])

	# Lo que se consigue en el nivel.
	for id: StringName in [&"fortress_shortcut", &"village_shortcut", &"poacher_store"]:
		Story.mark_heard(_gate(id).story_flag())
	var cache: HiddenCache = _cache(&"forest_back")
	cache.pick(_player)
	Story.mark_heard(&"boss_varga")
	Story.mark_heard(&"vow_stop")
	_player.arts.unlock(&"art_flurry")
	_player.arts.equip(&"art_flurry")
	_player.key_items.append(&"varga_banner")
	var forest_fire: Campfire = _forest_fire()
	_player.set_spawn(forest_fire.rest_position(), 90.0)
	var xp: int = _player.xp
	SaveGame.save(_player)
	_check("Se guardó la partida", SaveGame.exists())

	# "Cerrar y volver a abrir".
	await _load_level()
	_check("El portón del atajo sigue abierto", _gate(&"fortress_shortcut").is_open())
	_check("…la puerta de la aldea, sin la tranca", _gate(&"village_shortcut").is_open())
	_check("…la despensa de los cazadores, abierta", _gate(&"poacher_store").is_open())
	_check("…el escondite, ya recogido", _cache(&"forest_back").is_taken())
	_check("…y la experiencia que dio (%d)" % _player.xp, _player.xp == xp)
	_check("Varga sigue vencida", Story.heard(&"boss_varga") and not _varga_alive())
	_check("La Ráfaga sigue aprendida y equipada (%s)" % str(_player.arts.unlocked), &"art_flurry" in _player.arts.unlocked and _player.arts.equipped == &"art_flurry")
	_check("El estandarte de Varga sigue en el morral", &"varga_banner" in _player.key_items)
	_check("La elección del prólogo se recuerda", Story.heard(&"vow_stop"))
	var at: float = _player.global_position.distance_to(_forest_fire().rest_position())
	_check("Kael aparece en la fogata del bosque (a %.1f m)" % at, at < 1.0)
	_check("El archivo dice qué nivel es (%s)" % str(SaveGame.read().get("level")), str(SaveGame.read().get("level")) == "save_iron_pass_test")


func _gate(id: StringName) -> LatchedGate:
	for node in get_tree().get_nodes_in_group("latched_gates"):
		if (node as LatchedGate).gate_id == id:
			return node
	return null


func _cache(id: StringName) -> HiddenCache:
	for node in get_tree().get_nodes_in_group("hidden_caches"):
		if (node as HiddenCache).cache_id == id:
			return node
	return null


func _forest_fire() -> Campfire:
	var best: Campfire
	for node in get_tree().get_nodes_in_group("campfires"):
		var fire := node as Campfire
		if best == null or fire.global_position.z < best.global_position.z:
			best = fire
	return best


func _varga_alive() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy.boss and not enemy.is_dead():
			return true
	return false


## Carga el nivel (como al abrir el juego), quitando el anterior.
func _load_level() -> void:
	if _level:
		_level.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	_level = load("res://scenes/levels/iron_pass.tscn").instantiate()
	add_child(_level)
	_player = get_tree().get_first_node_in_group("player") as Player
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await get_tree().create_timer(0.6, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
