extends Node
## Prueba automática del repertorio: cada movimiento debe conectar con el soldado y terminar bien.
## Ejecutar: Godot --headless --path game res://tests/moveset_test.tscn

var _player: Player
var _enemy: Enemy
var _failures: int = 0


func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player")
	_enemy = get_tree().get_first_node_in_group("enemies")
	_enemy.set_physics_process(false)  # Quieto, en guardia: solo recibe
	await _wait(0.3)
	for move in PlayerMoves.MOVES:
		await _try(move)
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _try(move: StringName) -> void:
	_enemy.respawn()
	_enemy.state_machine.transition_to(&"Idle", {"wait": 99.0})
	_enemy.global_position = Vector3(0, 0, 17)
	_enemy.model.rotation.y = 0.0  # mira hacia -Z (hacia el jugador)
	var air: bool = PlayerMoves.MOVES[move].get("air", false)
	_player.global_position = Vector3(0, 1.4 if air else 0.0, 15.3)
	_player.velocity = Vector3.ZERO
	_player.model.rotation.y = PI  # mira hacia +Z (hacia el soldado)
	_player.reset_physics_interpolation()
	_player.lock_target = _enemy
	_player.state_machine.transition_to(&"Ground")
	await _wait(0.4)
	var posture0: float = _enemy.posture.current
	var health0: float = _enemy.health.current
	_player.state_machine.transition_to(&"Attack", {"move": move})
	await _wait(2.2)
	var affected: bool = _enemy.posture.current > posture0 or _enemy.health.current < health0 or _enemy.state_name() != &"Idle"
	_check("%-14s conecta (postura %.0f→%.0f, vida %.0f→%.0f, %s)" % [move, posture0, _enemy.posture.current, health0, _enemy.health.current, _enemy.state_name()], affected)
	_check("%-14s termina (%s)" % [move, _player.state_machine.current.name], _player.state_machine.current.name in [&"Ground", &"Air"])
	if move == &"kick":
		_check("la patada rompe la guardia", _enemy.state_name() == &"Recoil" or _enemy.state_name() == &"Idle" and _enemy.posture.current > posture0)


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
