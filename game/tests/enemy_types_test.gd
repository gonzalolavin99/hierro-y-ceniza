extends Node
## Prueba automática de los tipos de enemigo: el bandido es más frágil, rápido e impaciente que el
## soldado, usa solo su repertorio (tajos rápidos, ráfagas, embestida; sin estocadas), lee el inicio de
## tus ataques para apartarse de un salto (el soldado bloquea) y su embestida llega desde lejos.
## Ejecutar: Godot --headless --path game res://tests/enemy_types_test.tscn

const SOLDIER: PackedScene = preload("res://scenes/enemies/training_soldier.tscn")
const BANDIT: PackedScene = preload("res://scenes/enemies/bandit.tscn")
const THRUSTS: Array[StringName] = [&"thrust", &"slash_thrust", &"thrust_combo"]

var _player: Player
var _level: Node
var _failures: int = 0


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
	_check("Se aparta fuera de tu alcance (%.1f m)" % dist, dist >= 2.6)
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
