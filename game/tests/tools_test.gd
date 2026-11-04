extends Node
## Prueba automática de las armas secundarias (LT): ballesta de muñeca, bomba de humo y bomba de pólvora.
## Ejecutar: Godot --headless --path game res://tests/tools_test.tscn
## Con ventana y una carpeta guarda capturas: Godot --path game res://tests/tools_test.tscn -- <carpeta>

var _player: Player
var _enemy: Enemy
var _failures: int = 0
var _shots_dir: String = ""


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	_enemy.mind.predictable = true  # Ritmo fijo: esta prueba no trata de la IA adaptativa (ver ai_test).
	if not OS.get_cmdline_user_args().is_empty():
		_shots_dir = OS.get_cmdline_user_args()[0]
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	await _wait(0.3)
	await _tap("lock_on")
	_check("R3 fija al soldado", _player.lock_target == _enemy)

	# 1. Munición inicial y cambio de arma con la cruceta.
	var tools: PlayerTools = _player.tools
	_check("Empieza con la ballesta", tools.current == &"crossbow")
	_check("Munición inicial 10 / 3 / 3", tools.ammo[&"crossbow"] == 10 and tools.ammo[&"smoke"] == 3 and tools.ammo[&"powder"] == 3)
	await _tap("item_next")
	_check("Cruceta derecha: humo", tools.current == &"smoke")
	await _tap("item_next")
	_check("Cruceta derecha: pólvora", tools.current == &"powder")
	await _tap("item_next")
	_check("Cruceta derecha: vuelve a la ballesta", tools.current == &"crossbow")
	await _tap("item_prev")
	_check("Cruceta izquierda: pólvora", tools.current == &"powder")
	tools.select(&"crossbow")

	# 2. Ballesta contra un soldado en guardia: la bloquea.
	await _reset(2.2)
	await _tap("item")
	_check("Disparar gasta un virote (%d)" % tools.ammo[&"crossbow"], tools.ammo[&"crossbow"] == 9)
	await _shot("ballesta")
	await _wait(0.6)
	_check("En guardia bloquea el virote (vida %.0f)" % _enemy.health.current, _enemy.health.current == _enemy.health.max_health)
	_check("El bloqueo le sube algo la postura (%.0f)" % _enemy.posture.current, _enemy.posture.current > 0.0)

	# 3. Ballesta mientras prepara un ataque: lo interrumpe.
	await _reset(2.2)
	_enemy.state_machine.transition_to(&"Attack", {"pattern": &"single"})
	await _wait(0.1)
	await _tap("item")
	var interrupted: bool = await _until_state(&"Recoil", 0.7)
	_check("Un virote durante su preparación lo interrumpe", interrupted)
	_check("El virote le hace daño (vida %.0f)" % _enemy.health.current, _enemy.health.current < _enemy.health.max_health)
	_check("El jugador no recibe el tajo interrumpido", _player.health.current == _player.health.max_health)

	# 4. Bomba de humo: el soldado queda aturdido, sin atacar ni bloquear.
	await _reset(2.2)
	tools.select(&"smoke")
	await _tap("item")
	_check("La bomba de humo gasta un uso", tools.ammo[&"smoke"] == 2)
	var dazed: bool = await _until_state(&"Dazed", 0.8)
	_check("El humo lo aturde", dazed)
	await _shot("humo")
	await _wait(0.6)
	await _shot("humo_2")
	await _wait(0.2)
	_check("Sigue aturdido un rato", _enemy.state_name() == &"Dazed")
	var health_before: float = _enemy.health.current
	await _tap("attack")
	await _wait(0.5)
	_check("Aturdido no bloquea: el tajo hace daño (%.0f → %.0f)" % [health_before, _enemy.health.current], _enemy.health.current < health_before)
	var recovered: bool = false
	for i in 180:
		if _enemy.state_name() != &"Dazed":
			recovered = true
			break
		await get_tree().physics_frame
	_check("Se le pasa el aturdimiento", recovered)
	_check("Mientras estuvo aturdido no atacó al jugador", _player.health.current == _player.health.max_health)

	# 5. Bomba de pólvora: atraviesa la guardia (daño y mucha postura).
	await _reset(5.0)
	# Sin "verlo", no se acerca: así se mide la explosión a 5 m (sigue bloqueando de frente).
	_enemy.aggro_range = 0.0
	tools.select(&"powder")
	await _tap("item")
	_check("La bomba de pólvora gasta un uso", tools.ammo[&"powder"] == 2)
	await _wait(0.45)
	await _shot("polvora")
	await _wait(0.4)
	await _shot("explosion")
	await _wait(0.8)
	_check("La explosión daña aunque esté en guardia (vida %.0f)" % _enemy.health.current, _enemy.health.current <= _enemy.health.max_health - 20.0)
	_check("La explosión daña mucho la postura (%.0f)" % _enemy.posture.current, _enemy.posture.current >= 25.0)
	_check("A 5 m la explosión no daña al jugador", _player.health.current == _player.health.max_health)
	_enemy.aggro_range = 12.0

	# 6. Bomba de pólvora durante su ataque: lo interrumpe.
	await _reset(4.0)
	_enemy.state_machine.transition_to(&"Attack", {"pattern": &"sweep"})
	await _tap("item")
	interrupted = await _until_state(&"Recoil", 1.5)
	_check("La explosión interrumpe su ataque", interrupted)

	# 7. Sin munición no pasa nada.
	await _reset(2.2)
	tools.select(&"crossbow")
	tools.ammo[&"crossbow"] = 0
	await _tap("item")
	await get_tree().physics_frame
	_check("Sin virotes no dispara (estado %s)" % _player.state_machine.current.name, _player.state_machine.current.name == &"Ground")
	_check("No aparece ningún virote", get_tree().get_nodes_in_group("projectiles").is_empty())

	# 8. Al reaparecer se rellena la munición.
	_player.respawn()
	_check("Al reaparecer se rellena (%d / %d / %d)" % [tools.ammo[&"crossbow"], tools.ammo[&"smoke"], tools.ammo[&"powder"]], tools.ammo[&"crossbow"] == 10 and tools.ammo[&"smoke"] == 3 and tools.ammo[&"powder"] == 3)


# --- Ayudas ---------------------------------------------------------------------

## Coloca al jugador en el origen y al soldado a `dist` metros delante, quieto en guardia.
func _reset(dist: float) -> void:
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.6)
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	_player.model.rotation.y = 0.0
	_enemy.global_position = Vector3(0.0, 0.0, -dist)
	_enemy.model.rotation.y = PI
	_player.reset_physics_interpolation()
	_enemy.reset_physics_interpolation()
	_player.health.heal(_player.health.max_health)
	_player.posture.reset()
	_enemy.health.heal(_enemy.health.max_health)
	_enemy.posture.reset()
	# Otra vez quieto tras recolocarlo (mientras tanto pudo empezar a perseguir o atacar).
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.4)


func _until_state(state: StringName, seconds: float) -> bool:
	for i in int(seconds * 60.0):
		if _enemy.state_name() == state:
			return true
		await get_tree().physics_frame
	return _enemy.state_name() == state


func _shot(label: String) -> void:
	if _shots_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.resize(800, 450)
	img.save_png(_shots_dir.path_join(label + ".png"))


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
