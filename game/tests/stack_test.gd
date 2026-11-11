extends Node
## Prueba automática: nadie se queda de pie sobre la cabeza de otro (aviso del jugador, 2026-11-11: en el duelo,
## Varga cayó encima de Kael y se quedó allí; él le pegaba y ella a él no). Un enemigo que cae sobre Kael
## resbala al suelo a su lado, y Kael tampoco se queda encima de un enemigo.
## Ejecutar: Godot --headless --path game res://tests/stack_test.tscn

var _player: Player
var _enemy: Enemy
var _failures: int = 0


func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	await _wait(0.5)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	_enemy.aggro_range = 0.0
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	_player.invulnerable = true

	# 1. Un enemigo cae justo encima de Kael (como Varga tras un salto).
	for offset: Vector3 in [Vector3.ZERO, Vector3(0.15, 0.0, 0.1)]:
		_enemy.global_position = _player.global_position + Vector3.UP * 2.2 + offset
		_enemy.velocity = Vector3.ZERO
		_enemy.reset_physics_interpolation()
		await _wait(1.2)
		var flat: float = Vector2(_enemy.global_position.x - _player.global_position.x, _enemy.global_position.z - _player.global_position.z).length()
		var high: float = _enemy.global_position.y - _player.global_position.y
		_check("Un enemigo que cae sobre Kael acaba en el suelo, a su lado (altura %.2f m, a %.2f m)" % [high, flat], high < 0.3 and flat > 0.5)
		_check("…y vuelve a chocar con él (no se queda atravesable)", _enemy.collision_mask & 2 != 0)

	# 2. Kael cae justo encima de un enemigo.
	_enemy.global_position = _player.global_position + Vector3(0.0, 0.0, -4.0)
	_enemy.reset_physics_interpolation()
	await _wait(0.5)
	_player.global_position = _enemy.global_position + Vector3.UP * 2.2
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	await _wait(1.2)
	var flat2: float = Vector2(_enemy.global_position.x - _player.global_position.x, _enemy.global_position.z - _player.global_position.z).length()
	_check("Kael no se queda de pie sobre un enemigo (altura %.2f m, a %.2f m)" % [_player.global_position.y - _enemy.global_position.y, flat2],
			_player.global_position.y - _enemy.global_position.y < 0.3 and flat2 > 0.5)
	_check("…y vuelve a chocar con los enemigos", _player.collision_mask & 4 != 0)
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
