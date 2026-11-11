extends Node
## Prueba automática: tras el último golpe de un patrón, el enemigo baja el arma ANTES de que su clip llegue al
## tajo siguiente (aviso del jugador: tras el combo de dos golpes parecía que iba a dar un tercero). Y Kael
## corta su ataque con la guardia en cualquier momento (también en el impacto) y DESVÍA el golpe que llega.
## Ejecutar: Godot --headless --path game res://tests/combo_settle_test.tscn

var _player: Player
var _enemy: Enemy
var _failures: int = 0


func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
		if node != _enemy:
			(node as Node3D).global_position += Vector3(0, 0, 200)
	_player.health.max_health = 9999.0
	_player.health.heal(9999.0)
	await _wait(0.4)
	for pattern in [&"double", &"thrust_combo", &"single"]:
		await _settle(pattern)
	await _deflect_from_attack()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


## Kael lejos (los tajos no le llegan); se mira el clip del enemigo tras su último golpe.
func _settle(pattern: StringName) -> void:
	_place(8.0)
	var swings: Array = EnemyAttackState.PATTERNS[pattern]
	var last: Dictionary = swings[-1]
	var strikes: Array = EnemyAttackState.CLIP_STRIKES.get(last["anim"], [])
	var next_strike: float = INF
	for at in strikes:
		if at > last["impact"]:
			next_strike = minf(next_strike, at)
	_enemy.state_machine.transition_to(&"Attack", {"pattern": pattern, "delay": 0.0})
	var state := _enemy.state_machine.current as EnemyAttackState
	var deepest: float = 0.0
	var settled: bool = false
	while _enemy.state_machine.current == state:
		if _enemy.body.action_weight() > 0.5 and _enemy.body.action_name() == last["anim"]:
			deepest = maxf(deepest, _enemy.body.action_time())
		settled = settled or state.is_settled()
		await get_tree().physics_frame
	if is_inf(next_strike):
		_check("%s: su clip no tiene otro tajo (nada que cortar)" % pattern, not settled)
	else:
		_check("%s: baja el arma antes del tajo siguiente del clip (llega a %.2f s; el tajo empieza en %.2f s)" % [pattern, deepest, next_strike],
			settled and deepest < next_strike)
	await _wait(1.0)


## Kael ataca; el soldado lanza un tajo; Kael pulsa LB a mitad de su propio golpe: corta y desvía.
func _deflect_from_attack() -> void:
	_place(1.6)
	_enemy.target = _player
	_player.lock_target = _enemy
	_enemy.state_machine.transition_to(&"Attack", {"pattern": &"single", "delay": 0.0})
	var hit_in: float = EnemyAttackState.PATTERNS[&"single"][0]["windup"]
	await _wait(hit_in - 0.35)
	_player.state_machine.transition_to(&"Attack", {"move": &"heavy"})
	await _wait(0.2)
	var posture_before: float = _enemy.posture.current
	Input.parse_input_event(_action("block", true))
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check("LB corta el golpe pesado de Kael a medio camino", _player.state_machine.current.name == &"Block")
	await _wait(0.4)
	Input.parse_input_event(_action("block", false))
	_check("…y desvía el tajo que llegaba (la postura del soldado sube: %.0f → %.0f)" % [posture_before, _enemy.posture.current],
		_enemy.posture.current > posture_before and _player.health.ratio() == 1.0)


func _place(distance: float) -> void:
	_enemy.state_machine.transition_to(&"Idle", {"wait": 1000.0})
	_player.state_machine.transition_to(&"Ground")
	_enemy.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(0, 0, distance)
	_player.reset_physics_interpolation()
	_enemy.face_direction(Vector3.BACK, 100.0)
	_enemy.posture.reset()


func _action(name: StringName, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	return event


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
