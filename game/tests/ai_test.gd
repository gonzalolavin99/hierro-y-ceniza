extends Node
## Prueba automática de la IA que lee al jugador (EnemyMind): adapta su estrategia a los hábitos
## observables del jugador, sin hacer trampas (decide al empezar cada ataque, no leyendo botones).
## Ejecutar: Godot --headless --path game res://tests/ai_test.tscn

var _player: Player
var _enemy: Enemy
var _failures: int = 0
var _deflects: int = 0


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	await _wait(0.3)
	var mind := EnemyMind.new()
	mind.rng.seed = 7

	# 1. Desvíos seguidos: empieza a retrasar golpes; si le das, lo olvida.
	_check("De partida casi no retrasa (%.2f)" % mind.delay_chance(), mind.delay_chance() <= 0.15)
	for i in 3:
		mind.on_player_deflect()
	_check("Tras 3 desvíos seguidos retrasa a menudo (%.2f)" % mind.delay_chance(), mind.delay_chance() >= 0.5)
	for i in 3:
		mind.on_player_deflect()
	_check("Con 6 desvíos, a veces amaga (%.2f)" % mind.feint_chance(), mind.feint_chance() > 0.0)
	mind.on_player_hit()
	_check("Si le acierta un golpe, vuelve a lo normal (%.2f)" % mind.delay_chance(), mind.delay_chance() <= 0.15)

	# 2. Abuso del paso rápido: prefiere estocadas.
	var calm := EnemyMind.new()
	calm.rng.seed = 11
	var base_thrusts: int = _count_patterns(calm, [&"thrust", &"slash_thrust", &"thrust_combo"], 2.2)
	var dodger := EnemyMind.new()
	dodger.rng.seed = 11
	for i in 3:
		dodger.on_player_dash()
	_check("Detecta el abuso del paso rápido", dodger.is_dash_abusing())
	var dodger_thrusts: int = _count_patterns(dodger, [&"thrust", &"slash_thrust", &"thrust_combo"], 2.2)
	_check("Contra quien esquiva siempre, más estocadas (%d → %d de 300)" % [base_thrusts, dodger_thrusts], dodger_thrusts > base_thrusts * 1.6)
	dodger.observe_time(5.0)
	_check("El abuso se olvida si pasa un rato sin esquivar", not dodger.is_dash_abusing())

	# 3. Quedarse cubierto mucho rato: barridos y agarres (no se bloquean).
	var turtle := EnemyMind.new()
	turtle.rng.seed = 5
	turtle.observe_guard(true, 2.5)
	_check("Detecta que el jugador se queda cubierto", turtle.is_turtling())
	var unblockable: int = _count_patterns(turtle, [&"sweep", &"grab"], 1.6)
	_check("Contra la guardia eterna, mayoría de barridos/agarres (%d de 300)" % unblockable, unblockable > 150)
	turtle.observe_guard(false, 0.1)
	_check("Al bajar la guardia lo olvida", not turtle.is_turtling())

	# 4. Atacar sin parar contra su guardia: contraataca antes.
	var mind2 := EnemyMind.new()
	_check("Normalmente contraataca tras 3 bloqueos", mind2.blocks_before_counter(3) == 3)
	for i in 6:
		mind2.on_attack_blocked()
	_check("Contra un ataque sin pausa, tras 2", mind2.blocks_before_counter(3) == 2)

	# 5. Golpe retrasado en el juego: el desvío "de siempre" llega antes de tiempo; esperando, funciona.
	await _reset()
	_enemy.state_machine.transition_to(&"Attack", {"pattern": &"single", "delay": 0.45})
	var attack := _enemy.state_machine.current as EnemyAttackState
	var normal_windup: float = attack._swings[0]["windup"]
	await _wait(normal_windup - 0.1)  # El jugador desvía al ritmo de un golpe normal…
	await _tap("block")
	await _wait(0.9)
	_check("Golpe retrasado: el desvío al ritmo normal falla (vida %.0f)" % _player.health.current, _player.health.current < _player.health.max_health)
	await _reset()
	_deflects = 0
	# (Una función anónima copia las variables locales: el contador tiene que ser de la prueba.)
	var count := func() -> void: _deflects += 1
	_player.deflected.connect(count)
	_enemy.state_machine.transition_to(&"Attack", {"pattern": &"single", "delay": 0.45})
	await _wait(normal_windup + 0.45 - 0.1)  # …quien espera al golpe de verdad, desvía.
	await _tap("block")
	await _wait(0.5)
	_player.deflected.disconnect(count)
	_check("Golpe retrasado: esperando, se desvía", _deflects == 1)

	# 6. Sin trampas: el retraso se decide al empezar y no cambia aunque el jugador pulse la guardia.
	await _reset()
	_enemy.mind.rng.seed = 3
	for i in 6:
		_enemy.mind.on_player_deflect()
	_enemy.state_machine.transition_to(&"Attack", {"pattern": &"single"})
	attack = _enemy.state_machine.current as EnemyAttackState
	var decided: float = attack.current_delay()
	await _wait(0.2)
	await _tap("block")
	await _wait(0.1)
	_check("El retraso decidido al empezar no cambia al pulsar guardia (%.2f)" % decided, attack.current_delay() == decided)
	await _wait(1.5)

	# 7. Amago: prepara el golpe y no lo suelta.
	await _reset()
	_enemy.state_machine.transition_to(&"Attack", {"pattern": &"single", "delay": 0.4, "feint": true})
	await _wait(1.6)
	_check("Amago: no golpea", _player.health.current == _player.health.max_health)
	_check("Amago: vuelve a la guardia", _enemy.state_name() != &"Attack")


func _count_patterns(mind: EnemyMind, wanted: Array, distance: float) -> int:
	var n: int = 0
	for i in 300:
		if mind.pick_pattern(distance) in wanted:
			n += 1
	return n


func _reset() -> void:
	_enemy.aggro_range = 0.0
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.4)
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	_player.model.rotation.y = 0.0
	_enemy.global_position = Vector3(0.0, 0.0, -2.0)
	_enemy.model.rotation.y = PI
	_player.reset_physics_interpolation()
	_enemy.reset_physics_interpolation()
	_player.health.heal(_player.health.max_health)
	_player.posture.reset()
	_enemy.posture.reset()
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.6)


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
