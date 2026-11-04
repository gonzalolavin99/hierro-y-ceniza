extends Node
## Prueba automática de los tipos de enemigo. Bandido: más frágil, rápido e impaciente que el
## soldado, usa solo su repertorio (tajos rápidos, ráfagas, embestida; sin estocadas), lee el inicio de
## tus ataques para apartarse de un salto (el soldado bloquea) y su embestida llega desde lejos.
## Lancero: más alcance, estocadas, guarda la distancia. Arquero: dispara flechas (se bloquean y
## desvían), retrocede si te acercas y no puede bloquear.
## Ejecutar: Godot --headless --path game res://tests/enemy_types_test.tscn

const SOLDIER: PackedScene = preload("res://scenes/enemies/training_soldier.tscn")
const BANDIT: PackedScene = preload("res://scenes/enemies/bandit.tscn")
const SPEARMAN: PackedScene = preload("res://scenes/enemies/spearman.tscn")
const ARCHER: PackedScene = preload("res://scenes/enemies/archer.tscn")
const THRUSTS: Array[StringName] = [&"thrust", &"slash_thrust", &"thrust_combo"]

var _player: Player
var _level: Node
var _failures: int = 0
var _deflects: int = 0


func _ready() -> void:
	_level = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(_level)
	_player = get_tree().get_first_node_in_group("player") as Player
	for node in get_tree().get_nodes_in_group("enemies"):
		var other := node as Enemy
		other.aggro_range = 0.0
		other.global_position += Vector3(0.0, 0.0, -90.0)
		other.reset_physics_interpolation()
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	var soldier := _spawn(SOLDIER, Vector3(8.0, 0.0, -2.0))
	var bandit := _spawn(BANDIT, Vector3(0.0, 0.0, -2.0))
	await _wait(0.3)

	# 1. Cifras: más frágil y más rápido que el soldado.
	_check("El bandido tiene menos vida (%.0f < %.0f)" % [bandit.health.max_health, soldier.health.max_health],
		bandit.health.max_health < soldier.health.max_health)
	_check("…y su postura se rompe antes (%.0f < %.0f)" % [bandit.posture.max_posture, soldier.posture.max_posture],
		bandit.posture.max_posture < soldier.posture.max_posture)
	_check("…pero se mueve más rápido (%.1f > %.1f)" % [bandit.walk_speed, soldier.walk_speed], bandit.walk_speed > soldier.walk_speed)
	_check("…y espera menos para atacar (%.2f s)" % bandit.idle_wait.y, bandit.idle_wait.y < soldier.idle_wait.y)
	_check("Cada uno tiene su nombre (%s / %s)" % [bandit.display_name, soldier.display_name], bandit.display_name != soldier.display_name)

	# 2. Repertorio: cada tipo elige solo sus ataques.
	var bandit_picks: Dictionary = {}
	var soldier_picks: Dictionary = {}
	for i in 400:
		bandit_picks[bandit.mind.pick_pattern(1.6)] = true
		soldier_picks[soldier.mind.pick_pattern(1.6)] = true
	var bandit_set: Array = bandit.moveset + bandit.danger_moveset
	_check("El bandido solo usa su repertorio %s" % str(bandit_picks.keys()), bandit_picks.keys().all(func(p: StringName) -> bool: return p in bandit_set))
	_check("El bandido no hace estocadas", bandit_picks.keys().all(func(p: StringName) -> bool: return not p in THRUSTS))
	_check("El bandido usa tajos rápidos y ráfagas", bandit_picks.has(&"quick") and bandit_picks.has(&"flurry"))
	_check("El soldado no usa los ataques del bandido", not soldier_picks.has(&"quick") and not soldier_picks.has(&"flurry"))

	# 3. Esquiva: el bandido ve venir tu ataque y se aparta de un salto (no le das).
	bandit.evade_chance = 1.0
	await _reset(bandit, 1.9)
	await _tap("attack")
	await _wait(0.25)
	_check("El bandido esquiva tu ataque (%s)" % bandit.state_name(), bandit.state_name() == &"Evade")
	await _wait(0.6)
	var dist: float = bandit.distance_to_target()
	_check("Se aparta fuera de tu alcance (%.1f m; tu tajo llega a ~2,2)" % dist, dist >= 2.3)
	_check("Tu tajo no le alcanza (vida %.0f)" % bandit.health.current, bandit.health.current == bandit.health.max_health)
	await _wait(1.2)

	# 4. El soldado no esquiva: bloquea.
	await _reset(soldier, 1.9)
	await _tap("attack")
	await _wait(0.6)
	_check("El soldado no esquiva, bloquea (%s, vida %.0f)" % [soldier.state_name(), soldier.health.current],
		soldier.state_name() != &"Evade" and soldier.health.current == soldier.health.max_health)
	soldier.aggro_range = 0.0
	soldier.global_position = Vector3(20.0, 0.0, -20.0)
	soldier.reset_physics_interpolation()

	# 5. Embestida: desde 4,5 m se lanza y te alcanza.
	bandit.evade_chance = 0.0
	await _reset(bandit, 4.5)
	bandit.state_machine.transition_to(&"Attack", {"pattern": &"lunge"})
	await _wait(1.2)
	_check("La embestida llega desde lejos (vida %.0f)" % _player.health.current, _player.health.current < _player.health.max_health)

	# 6. Ráfaga: tres tajos seguidos que se pueden desviar uno a uno.
	await _reset(bandit, 1.8)
	var swings: Array = EnemyAttackState.PATTERNS[&"flurry"]
	_check("La ráfaga tiene tres tajos", swings.size() == 3)
	_check("Ningún tajo de la ráfaga es peligroso (todos se desvían)",
		swings.all(func(s: Dictionary) -> bool: return s.get("danger", HitData.Kind.NORMAL) == HitData.Kind.NORMAL))
	bandit.aggro_range = 0.0
	bandit.global_position = Vector3(-20.0, 0.0, -20.0)
	bandit.reset_physics_interpolation()

	# 7. Lancero: llega desde más lejos, abusa de las estocadas y no te deja pegarte a él.
	var spear := _spawn(SPEARMAN, Vector3(0.0, 0.0, -3.0))
	await _wait(0.3)
	_check("El lancero alcanza más lejos (%.1f > %.1f m)" % [spear.attack_range, soldier.attack_range], spear.attack_range > soldier.attack_range + 0.6)
	var thrusts: int = 0
	for i in 400:
		var p: StringName = spear.mind.pick_pattern(3.0)
		if p in THRUSTS or p == &"spear_thrust":
			thrusts += 1
	_check("El lancero usa sobre todo estocadas (%d de 400)" % thrusts, thrusts > 200)
	await _reset(spear, 3.0)
	spear.state_machine.transition_to(&"Attack", {"pattern": &"spear_thrust"})
	await _wait(1.3)
	_check("Su estocada te alcanza a 3 m (vida %.0f)" % _player.health.current, _player.health.current < _player.health.max_health)
	await _wait(0.6)
	var spear_states: Array[StringName] = []
	spear.state_machine.state_changed.connect(func(s: StringName) -> void: spear_states.append(s))
	await _reset(spear, 1.2)
	await _wait(1.0)
	_check("Si te pegas a él, salta hacia atrás para recuperar distancia %s" % str(spear_states), &"Evade" in spear_states)
	spear.aggro_range = 0.0
	spear.global_position = Vector3(-20.0, 0.0, 20.0)
	spear.reset_physics_interpolation()

	# 8. Arquero: dispara desde lejos; las flechas se bloquean y se desvían; huye si te acercas.
	var archer := _spawn(ARCHER, Vector3(0.0, 0.0, -9.0))
	await _wait(0.3)
	_check("El arquero no puede bloquear golpes", not archer.can_block)
	await _reset(archer, 9.0)
	archer.state_machine.transition_to(&"Shoot")
	await _wait(3.0)
	_check("Su flecha te alcanza a 9 m (vida %.0f)" % _player.health.current, _player.health.current < _player.health.max_health)
	await _reset(archer, 9.0)
	Input.action_press("block")
	archer.state_machine.transition_to(&"Shoot")
	await _wait(3.0)
	Input.action_release("block")
	_check("Con la guardia alta, la flecha se bloquea (vida %.0f)" % _player.health.current, _player.health.current == _player.health.max_health)
	await _reset(archer, 9.0)
	_deflects = 0
	var count := func() -> void: _deflects += 1
	_player.deflected.connect(count)
	archer.state_machine.transition_to(&"Shoot")
	var tapped: bool = false
	for i in 240:
		await get_tree().physics_frame
		for node in get_tree().get_nodes_in_group("enemy_projectiles"):
			if not tapped and (node as Node3D).global_position.distance_to(_player.global_position + Vector3.UP) < 3.0:
				tapped = true
				Input.action_press("block")
		if tapped and _deflects > 0:
			break
	Input.action_release("block")
	_player.deflected.disconnect(count)
	_check("Pulsando la guardia justo a tiempo, la flecha se desvía", _deflects == 1)
	await _reset(archer, 3.0)
	archer.state_machine.transition_to(&"Idle", {"wait": 100.0})
	var before: float = archer.distance_to_target()
	await _wait(1.5)
	_check("Si te acercas, retrocede (%.1f → %.1f m)" % [before, archer.distance_to_target()], archer.distance_to_target() > before + 1.0)
	var hit := HitData.create(_player, 10.0, 10.0, 0.0)
	_check("Un tajo de frente le da (no bloquea)", archer.receive_hit(hit) == HitData.Result.HIT)
	archer.aggro_range = 0.0
	archer.global_position = Vector3(20.0, 0.0, 20.0)
	archer.reset_physics_interpolation()

	# 9. Colocado girado en el escenario (como los del nivel), te mira igual al pelear y al disparar.
	for scene: PackedScene in [SPEARMAN, ARCHER, BANDIT]:
		var turned := scene.instantiate() as Enemy
		turned.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -6.0))
		turned.respawn_delay = 0.0
		_level.add_child(turned)
		turned.mind.predictable = true
		_player.global_position = Vector3.ZERO
		_player.reset_physics_interpolation()
		turned.state_machine.transition_to(&"Idle", {"wait": 100.0})
		await _wait(1.0)
		var to_player: Vector3 = (_player.global_position - turned.global_position)
		to_player.y = 0.0
		var dot: float = turned.get_facing().dot(to_player.normalized())
		_check("%s girado en el nivel: te mira (%.2f)" % [turned.display_name, dot], dot > 0.9)
		turned.queue_free()
		await _wait(0.1)


func _spawn(scene: PackedScene, at: Vector3) -> Enemy:
	var e := scene.instantiate() as Enemy
	e.position = at
	e.respawn_delay = 0.0
	_level.add_child(e)
	e.mind.predictable = true
	return e


## Coloca al jugador en el origen y al enemigo delante, a `distance` m, quieto en guardia.
func _reset(enemy: Enemy, distance: float) -> void:
	enemy.aggro_range = 12.0
	enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.4)
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	_player.model.rotation.y = 0.0
	_player.health.heal(_player.health.max_health)
	_player.posture.reset()
	enemy.global_position = Vector3(0.0, 0.0, -distance)
	enemy.model.rotation.y = PI
	enemy.health.heal(enemy.health.max_health)
	enemy.posture.reset()
	_player.reset_physics_interpolation()
	enemy.reset_physics_interpolation()
	enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	Squad.reset()
	await _wait(0.4)


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
