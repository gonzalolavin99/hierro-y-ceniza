extends Node
## Prueba automática de la pose de "aguantar la espada" (versión retrasada fija de cada ataque, HOLDS): mientras
## el enemigo aguanta, la punta del arma casi no se mueve (< 5 cm) y está ARRIBA (por encima del hombro), para
## que el jugador aprenda a leer esa pose; al soltarla, el golpe llega como siempre.
## Ejecutar: Godot --headless --path game res://tests/hold_pose_test.tscn

const MAX_DRIFT: float = 0.05

var _player: Player
var _enemy: Enemy
var _failures: int = 0


func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	await _wait(0.5)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	_player.invulnerable = true
	for pattern: StringName in [&"single", &"double", &"thrust_combo", &"slash_thrust"]:
		await _measure(pattern)
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _measure(pattern: StringName) -> void:
	_enemy.aggro_range = 0.0
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	_enemy.global_position = _player.global_position + Vector3(0.0, 0.0, -2.0)
	_enemy.model.rotation.y = PI
	_enemy.reset_physics_interpolation()
	await _wait(0.6)
	_enemy.state_machine.transition_to(&"Attack", {"pattern": pattern, "hold": true})
	var attack := _enemy.state_machine.current as EnemyAttackState
	var start: Vector3 = Vector3.INF
	var drift: float = 0.0
	var above: bool = true
	var frames: int = 0
	var shoulder_y: float = _enemy.global_position.y + 1.45
	while _enemy.state_machine.current == attack and frames < 400:
		await get_tree().physics_frame
		frames += 1
		if attack._holding:
			# Respecto al cuerpo (puede girarse hacia Kael mientras aguanta: eso no cuenta como mover la espada).
			var tip: Vector3 = _enemy.body.global_transform.affine_inverse() * _enemy.body.weapon_tip()
			if start == Vector3.INF:
				start = tip
			drift = maxf(drift, tip.distance_to(start))
			above = above and _enemy.body.weapon_tip().y > shoulder_y
	var held: bool = start != Vector3.INF
	_check("%s: aguanta (%s)" % [pattern, "sí" if held else "no"], held)
	_check("%s: la punta casi quieta mientras aguanta (%.1f cm < %.0f)" % [pattern, drift * 100.0, MAX_DRIFT * 100.0], held and drift < MAX_DRIFT)
	_check("%s: la espada arriba (por encima del hombro)" % pattern, held and above)
	await _wait(0.5)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
