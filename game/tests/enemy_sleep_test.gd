extends Node
## Prueba automática de los enemigos que "duermen" (Cimientos): en el Paso de Hierro, los enemigos tranquilos a
## más de 40 m de Kael no piensan ni se animan; al acercarse Kael despiertan y siguen igual (pueden verle y
## pelear). El patio de pruebas no duerme a nadie.
## Ejecutar: Godot --headless --path game res://tests/enemy_sleep_test.tscn

var _failures: int = 0


func _ready() -> void:
	var level: Node = load("res://scenes/levels/iron_pass.tscn").instantiate()
	add_child(level)
	await _wait(1.0)
	var player := get_tree().get_first_node_in_group("player") as Player
	var enemies: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		enemies.append(node as Enemy)
	var far: Array[Enemy] = enemies.filter(func(e: Enemy) -> bool: return e.global_position.distance_to(player.global_position) > Squad.SLEEP_DISTANCE + 2.0)
	var near: Array[Enemy] = enemies.filter(func(e: Enemy) -> bool: return e.global_position.distance_to(player.global_position) < Squad.SLEEP_DISTANCE - 2.0)
	var sleeping: int = far.filter(func(e: Enemy) -> bool: return e.asleep).size()
	_check("Al inicio duermen los enemigos lejanos (%d de %d)" % [sleeping, far.size()], far.size() > 10 and sleeping == far.size() - far.filter(func(e: Enemy) -> bool: return e.boss).size())
	_check("…y los cercanos están despiertos", near.all(func(e: Enemy) -> bool: return not e.asleep))
	_check("Un jefe nunca duerme", enemies.filter(func(e: Enemy) -> bool: return e.boss).all(func(e: Enemy) -> bool: return not e.asleep))

	# Kael llega a la aldea: los soldados de la aldea despiertan y siguen en su sitio.
	var soldier: Enemy
	for e in enemies:
		if e.global_position.distance_to(Vector3(9, 0, 55)) < 1.0:
			soldier = e
	var post: Vector3 = soldier.global_position
	player.set_spawn(Vector3(9.0, 0.0, 64.0), 180.0)
	player.respawn()
	await _wait(0.6)
	_check("Al acercarse Kael, el soldado de la aldea despierta", not soldier.asleep)
	_check("…cerca de su puesto, sin saltos raros (%.2f m)" % soldier.global_position.distance_to(post), soldier.global_position.distance_to(post) < 3.0)
	var states: Array[StringName] = []
	for i in 30:
		await _wait(0.1)
		if not soldier.state_name() in states:
			states.append(soldier.state_name())
	_check("…y le ve y va a por él (%s)" % [states], soldier.alerted and states.any(func(s: StringName) -> bool: return s in [&"Chase", &"Attack", &"Circle", &"Block"]))

	# Fuera del Paso de Hierro nadie duerme.
	level.queue_free()
	await _wait(0.2)
	_check("Al salir del Paso, dormir se apaga", Squad.sleep_distance == 0.0)
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
