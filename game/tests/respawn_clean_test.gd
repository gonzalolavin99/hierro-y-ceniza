extends Node
## Prueba automática de "morir en mal momento": tras morir en cada situación delicada, al reaparecer no queda
## nada colgado (Kael de pie y sin agachar, sin objetivo fijado, sin proyectiles en el aire —de Kael ni de los
## enemigos—, sin fruta de Frank, sin pausa; el duelo con Varga reiniciado: rastrillo arriba, sin barra ni música).
## Ejecutar: Godot --headless --path game res://tests/respawn_clean_test.tscn

var _player: Player
var _arena: VargaArena
var _failures: int = 0


func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	await _wait(0.5)
	_player = get_tree().get_first_node_in_group("player") as Player
	_arena = get_tree().get_first_node_in_group("arenas") as VargaArena
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	# 1. Morir agachado y con un enemigo fijado.
	_player.crouching = true
	_player.lock_target = get_tree().get_first_node_in_group("enemies") as Enemy
	await _die()
	_check_clean("agachado y con un objetivo fijado")
	_check("…ya no está agachado", not _player.crouching)

	# 2. Morir en el aire.
	_player.global_position += Vector3(0.0, 6.0, 0.0)
	_player.reset_physics_interpolation()
	await _wait(0.1)
	await _die()
	_check_clean("en el aire")

	# 3. Morir con proyectiles en vuelo: un virote y una bomba de Kael, una flecha enemiga y una fruta de Frank.
	var from: Vector3 = _player.global_position + Vector3(0.0, 1.5, 0.0)
	var far: Vector3 = from + Vector3(0.0, 8.0, -60.0)
	Bolt.spawn(get_tree().current_scene, from, Vector3(0.0, 0.3, -1.0).normalized(), _player)
	Bomb.throw(get_tree().current_scene, from, far, 3.0, Bomb.Kind.SMOKE, _player)
	Arrow.spawn(get_tree().current_scene, from + Vector3(0.0, 4.0, -40.0), far, _player)
	FrankFruit.launch(get_tree().current_scene, from, far, 0.0)
	await get_tree().physics_frame
	await _die()
	_check_clean("con proyectiles en el aire")

	# 4. Morir en pleno duelo con Varga.
	if _arena:
		_player.global_position = _arena.global_position + Vector3(-6.0, 0.2, 0.0)
		_player.reset_physics_interpolation()
		_arena.start_fight()
		await _wait(0.5)
		var started: bool = _arena.is_active()
		await _die()
		_check_clean("en pleno duelo")
		_check("…el duelo se reinicia (empezó: %s; rastrillo cerrado: %s; música: %d)" % [started, _arena.gate_closed(), _arena.music_track()],
				started and not _arena.is_active() and not _arena.gate_closed() and _arena.music_track() < 0)


func _die() -> void:
	_player.health.take_damage(_player.health.max_health * 3.0)
	_player.state_machine.transition_to(&"Dead")
	await _wait(5.0)


func _check_clean(when: String) -> void:
	var left: Array[String] = []
	if _player.state_machine.current.name != &"Ground":
		left.append("estado %s" % _player.state_machine.current.name)
	if not _player.is_on_floor():
		left.append("en el aire")
	if _player.lock_target != null:
		left.append("objetivo fijado")
	if not is_equal_approx(_player.health.current, _player.health.max_health):
		left.append("vida sin llenar")
	if get_tree().paused:
		left.append("pausa")
	for group: String in ["projectiles", "enemy_projectiles"]:
		var n: int = get_tree().get_nodes_in_group(group).filter(func(p: Node) -> bool: return not p.is_queued_for_deletion()).size()
		if n > 0:
			left.append("%d en %s" % [n, group])
	var fruits: int = 0
	for node in get_tree().current_scene.find_children("*", "FrankFruit", true, false):
		if not node.is_queued_for_deletion():
			fruits += 1
	if fruits > 0:
		left.append("%d frutas" % fruits)
	_check("Morir %s: al reaparecer no queda nada colgado %s" % [when, left], left.is_empty())


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
