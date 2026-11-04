extends Node
## Prueba automática de la pelea en grupo (Squad + estado Circle): varios soldados se turnan para
## atacar (nunca dos a la vez), los que esperan guardan distancia con la guardia alta y te rodean,
## no se hieren entre ellos y, al caer el enemigo fijado, la cámara pasa al siguiente.
## Ejecutar: Godot --headless --path game res://tests/group_test.tscn

const SOLDIER: PackedScene = preload("res://scenes/enemies/training_soldier.tscn")
const SPEARMAN: PackedScene = preload("res://scenes/enemies/spearman.tscn")
const ARCHER: PackedScene = preload("res://scenes/enemies/archer.tscn")
const RUN_TIME: float = 16.0

var _player: Player
var _level: Node
var _soldiers: Array[Enemy] = []
var _failures: int = 0


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	_level = level
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	# Los soldados del escenario se apartan: aquí pelean solo los de la prueba.
	for node in get_tree().get_nodes_in_group("enemies"):
		var other := node as Enemy
		other.aggro_range = 0.0
		other.global_position += Vector3(0.0, 0.0, -80.0)
		other.reset_physics_interpolation()
	for offset: Vector3 in [Vector3(0.0, 0.0, -4.0), Vector3(3.0, 0.0, -3.0), Vector3(-3.0, 0.0, -3.0)]:
		var soldier := SOLDIER.instantiate() as Enemy
		soldier.position = offset
		soldier.respawn_delay = 0.0
		level.add_child(soldier)
		_soldiers.append(soldier)
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	_player.global_position = Vector3.ZERO
	_player.reset_physics_interpolation()
	_player.invulnerable = true  # Que le peguen sin morir: aquí se mira cómo se organizan.
	Squad.reset()
	await _wait(0.2)

	# 1. Pelea de 16 s quieto en medio de tres soldados.
	var start: float = Squad.clock()
	var prev: Dictionary = {}
	var attacks: Dictionary = {}
	var max_attacking: int = 0
	var last_end: float = -100.0
	var last_attacker: Enemy = null
	var min_gap: float = INF
	var min_wait_dist: float = INF
	var spread_sum: float = 0.0
	var spread_samples: int = 0
	var circled: bool = false
	var circle_since: Dictionary = {}
	for s in _soldiers:
		prev[s] = &""
		attacks[s] = 0
	while Squad.clock() - start < RUN_TIME:
		await get_tree().physics_frame
		var now: float = Squad.clock()
		var attacking: int = 0
		for s in _soldiers:
			var state: StringName = s.state_name()
			if state == &"Attack":
				attacking += 1
				if prev[s] != &"Attack":
					attacks[s] += 1
					if last_attacker != null and last_attacker != s:
						min_gap = minf(min_gap, now - last_end)
			elif prev[s] == &"Attack":
				last_end = now
				last_attacker = s
			if state == &"Circle":
				if prev[s] != &"Circle":
					circle_since[s] = now
				circled = true
				# Al empezar a esperar puede estar cerca (venía de atacar): se mide cuando ya se apartó.
				if now - circle_since[s] > 1.0:
					min_wait_dist = minf(min_wait_dist, s.distance_to_target())
			prev[s] = state
		max_attacking = maxi(max_attacking, attacking)
		if now - start > 5.0:
			spread_sum += _min_spread_degrees()
			spread_samples += 1

	_check("Nunca atacan dos a la vez (máximo %d)" % max_attacking, max_attacking == 1)
	var counts: Array = _soldiers.map(func(s: Enemy) -> int: return attacks[s])
	_check("Se turnan: todos atacan alguna vez %s" % str(counts), counts.all(func(n: int) -> bool: return n >= 1))
	_check("Entre el ataque de uno y el del siguiente hay respiro (%.2f s)" % min_gap, min_gap >= Squad.TURN_GAP - 0.05)
	_check("Los que esperan se quedan rodeando", circled)
	_check("Los que esperan guardan distancia (mín. %.1f m)" % min_wait_dist, min_wait_dist >= 2.6)
	var spread: float = spread_sum / maxf(spread_samples, 1.0)
	_check("Se reparten alrededor, no en fila (separación media %.0f°)" % spread, spread >= 45.0)
	var hurt: Array = _soldiers.filter(func(s: Enemy) -> bool: return s.health.current < s.health.max_health)
	_check("No se hieren entre ellos (%d heridos)" % hurt.size(), hurt.is_empty())

	# 2. Fuego amigo directo: un soldado ataca con un compañero en medio; el compañero no sufre nada.
	for s in _soldiers:
		s.aggro_range = 0.0
		s.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(1.6)
	var a: Enemy = _soldiers[0]
	var b: Enemy = _soldiers[1]
	a.global_position = Vector3(0.0, 0.0, -2.4)
	b.global_position = Vector3(0.0, 0.0, -1.2)
	_soldiers[2].global_position = Vector3(6.0, 0.0, 0.0)
	for s in _soldiers:
		s.reset_physics_interpolation()
		s.posture.reset()
	a.model.rotation.y = 0.0
	b.model.rotation.y = 0.0
	a.state_machine.transition_to(&"Attack", {"pattern": &"double"})
	await _wait(1.8)
	_check("El tajo de un compañero no hiere (vida %.0f) ni carga la postura (%.0f)" % [b.health.current, b.posture.current],
		b.health.current == b.health.max_health and b.posture.current == 0.0)

	# 3. Fijar objetivo: al caer el fijado, pasa al siguiente cercano (como en Sekiro).
	for s in _soldiers:
		s.state_machine.transition_to(&"Idle", {"wait": 100.0})
	_soldiers[2].global_position = Vector3(1.5, 0.0, -3.0)
	_soldiers[2].reset_physics_interpolation()
	_player.model.rotation.y = 0.0
	_player.camera_rig.recenter()
	await _wait(0.5)
	_player.lock_target = b
	await _wait(0.2)
	b.receive_deathblow(_player)
	await _wait(0.2)
	var next: Enemy = _player.lock_target
	_check("Al caer el fijado, fija al siguiente (%s)" % (next.name if next else "nadie"), next != null and next != b and not next.is_dead())

	# 4. Grupo mixto (soldado + lancero + arquero): el arquero también respeta los turnos. Nunca tensa o
	# apunta mientras otro está atacando, así que no te llegan dos amenazas a la vez.
	for s in _soldiers:
		s.queue_free()
	_soldiers.clear()
	await _wait(0.2)
	var mixed: Array[Enemy] = []
	for pair: Array in [[SOLDIER, Vector3(0.0, 0.0, -4.0)], [SPEARMAN, Vector3(3.5, 0.0, -3.5)], [ARCHER, Vector3(-2.0, 0.0, -10.0)]]:
		var e := (pair[0] as PackedScene).instantiate() as Enemy
		e.position = pair[1]
		e.respawn_delay = 0.0
		_level.add_child(e)
		e.mind.predictable = true
		mixed.append(e)
	_soldiers = mixed
	var archer: Enemy = mixed[2]
	_player.global_position = Vector3.ZERO
	_player.reset_physics_interpolation()
	_player.lock_target = null
	Squad.reset()
	var arrows: int = 0
	var seen_arrows: Dictionary = {}
	var overlap_frames: int = 0
	var melee_attacks: Dictionary = {mixed[0]: 0, mixed[1]: 0}
	var was_attacking: Dictionary = {mixed[0]: false, mixed[1]: false}
	var t0: float = Squad.clock()
	while Squad.clock() - t0 < 20.0:
		await get_tree().physics_frame
		var melee_busy: bool = false
		for m: Enemy in [mixed[0], mixed[1]]:
			var attacking: bool = m.state_name() == &"Attack"
			if attacking and not was_attacking[m]:
				melee_attacks[m] += 1
			was_attacking[m] = attacking
			melee_busy = melee_busy or attacking
		var shoot := archer.state_machine.current as EnemyShootState
		if shoot and shoot.is_aiming() and melee_busy:
			overlap_frames += 1
		for node in get_tree().get_nodes_in_group("enemy_projectiles"):
			if not seen_arrows.has(node):
				seen_arrows[node] = true
				arrows += 1
	_check("Grupo mixto: el arquero dispara (%d flechas)" % arrows, arrows >= 2)
	_check("Grupo mixto: soldado y lancero atacan %s" % str(melee_attacks.values()), melee_attacks.values().all(func(n: int) -> bool: return n >= 1))
	_check("El arquero nunca apunta mientras otro ataca (%d fotogramas)" % overlap_frames, overlap_frames == 0)


## Menor ángulo (visto desde el jugador) entre dos soldados.
func _min_spread_degrees() -> float:
	var angles: Array[float] = []
	for s in _soldiers:
		var to: Vector3 = s.global_position - _player.global_position
		angles.append(atan2(to.x, to.z))
	var best: float = 360.0
	for i in angles.size():
		for j in range(i + 1, angles.size()):
			best = minf(best, rad_to_deg(absf(angle_difference(angles[i], angles[j]))))
	return best


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
