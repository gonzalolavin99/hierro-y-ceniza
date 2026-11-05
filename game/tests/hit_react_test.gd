extends Node
## Prueba automática de las reacciones a los golpes: Kael reacciona según la fuerza (ligero, medio, fuerte)
## y la dirección (por la espalda no se gira); los enemigos, fuera de sus ataques, retroceden al recibir.
## Ejecutar: Godot --headless --path game res://tests/hit_react_test.tscn

var _player: Player
var _enemy: Enemy
var _failures: int = 0


func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	_player.health.max_health = 9999.0
	await _wait(0.4)
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	# Fuerza de cada golpe.
	_check("Un cuchillo es un golpe ligero", PlayerHitstun.strength_of(11.0, false) == PlayerHitstun.Strength.LIGHT)
	_check("Un tajo de soldado es medio", PlayerHitstun.strength_of(20.0, false) == PlayerHitstun.Strength.MEDIUM)
	_check("Un ataque peligroso es fuerte", PlayerHitstun.strength_of(20.0, true) == PlayerHitstun.Strength.HEAVY)

	# Cuánto lo desplaza cada fuerza (de frente).
	var light: Array = await _hit_and_measure(11.0, false, Vector3.FORWARD)
	var medium: Array = await _hit_and_measure(22.0, false, Vector3.FORWARD)
	var heavy: Array = await _hit_and_measure(22.0, true, Vector3.FORWARD)
	_check("Ligero: retrocede poco (%.2f m)" % light[0], light[0] > 0.2 and light[0] < 0.9)
	_check("Medio: retrocede más (%.2f m)" % medium[0], medium[0] > light[0] + 0.15)
	_check("Fuerte: sale despedido (%.2f m)" % heavy[0], heavy[0] > medium[0] + 0.3)
	_check("Fuerte: los pies dejan el suelo (%.2f m)" % heavy[1], heavy[1] > 0.05)
	_check("Fuerte: tarda más en rehacerse (%.2f s > %.2f s)" % [heavy[2], light[2]], heavy[2] > light[2] + 0.25)

	# Por la espalda: no se gira.
	_reset_player()
	var facing: Vector3 = _player.get_facing()
	_hit_from(-facing, 22.0, false)
	await _wait(0.05)
	_check("Golpe por la espalda: no se gira (%.2f)" % _player.get_facing().dot(facing), _player.get_facing().dot(facing) > 0.9)
	await _wait(0.8)

	# Enemigo fuera de su ataque: retrocede al recibir.
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.3)
	var before: Vector3 = _enemy.global_position
	var hit := HitData.create(_player, 22.0, 10.0)
	_player.global_position = before - _enemy.get_facing() * 1.5  # Por la espalda: no lo bloquea.
	_player.reset_physics_interpolation()
	_enemy.receive_hit(hit)
	await _wait(0.5)
	var moved: float = Vector2(_enemy.global_position.x - before.x, _enemy.global_position.z - before.z).length()
	_check("El enemigo retrocede al recibir un golpe (%.2f m)" % moved, moved > 0.2)


## Golpea a Kael (desde `direction` respecto a él) y mide: [distancia recorrida, altura máxima, segundos de aturdimiento].
func _hit_and_measure(damage: float, heavy: bool, direction: Vector3) -> Array:
	_reset_player()
	await _wait(0.3)
	var start: Vector3 = _player.global_position
	_hit_from(direction, damage, heavy)
	var peak: float = 0.0
	var stun: float = 0.0
	for i in 90:
		await get_tree().physics_frame
		peak = maxf(peak, _player.global_position.y - start.y)
		if _player.state_machine.current.name == &"Hitstun":
			stun += 1.0 / Engine.physics_ticks_per_second
	await _wait(0.2)
	var flat := Vector2(_player.global_position.x - start.x, _player.global_position.z - start.z)
	return [flat.length(), peak, stun]


## Golpe al jugador desde un atacante colocado en `direction` (mundo) a 1,5 m.
func _hit_from(direction: Vector3, damage: float, heavy: bool) -> void:
	_enemy.global_position = _player.global_position + direction.normalized() * 1.5
	_enemy.reset_physics_interpolation()
	var hit := HitData.create(_enemy, damage, 10.0)
	hit.heavy = heavy
	_player.receive_hit(hit)


func _reset_player() -> void:
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = Vector3(-20.0, 0.0, -10.0)
	_player.velocity = Vector3.ZERO
	_player.model.rotation.y = 0.0
	_player.health.heal(9999.0)
	_player.posture.reset()
	_player.reset_physics_interpolation()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
