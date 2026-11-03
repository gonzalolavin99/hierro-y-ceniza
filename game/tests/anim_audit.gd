extends Node
## Auditoría de animaciones en el juego real: hace que el jugador y el soldado ejecuten todo su
## repertorio y mide, fotograma a fotograma, los defectos típicos:
##   - SALTO: un hueso cambia de velocidad de golpe (la animación "pega un tirón" o se teletransporta).
##   - PATINA: un pie apoyado en el suelo se desliza.
##   - HUNDE: un pie se mete bajo el suelo.
##   - CHOQUE: los cuerpos de los dos personajes se atraviesan.
## Ejecutar: Godot --headless --fixed-fps 60 --path game res://tests/anim_audit.tscn
## Al final comprueba que no vuelvan los defectos ya corregidos (sirve también como prueba).
## Depurar un hueso: AUDIT_TRACE="Jugador · J quieto|Head" imprime su posición en cada fotograma.
## (--fixed-fps hace que cada fotograma dure exactamente 1/60 s y las medidas sean comparables)

const BONES: Array[String] = ["Hips", "Spine2", "Head", "LeftArm", "RightArm", "LeftForeArm", "RightForeArm",
	"LeftHand", "RightHand", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot",
	"LeftToeBase", "RightToeBase"]
## Huesos con los que se mide el choque entre cuerpos (radio aproximado de cada parte, en metros).
const BODY_RADIUS: Dictionary = {"Hips": 0.16, "Spine2": 0.17, "Head": 0.11, "LeftArm": 0.07, "RightArm": 0.07,
	"LeftForeArm": 0.05, "RightForeArm": 0.05, "LeftUpLeg": 0.09, "RightUpLeg": 0.09, "LeftLeg": 0.07,
	"RightLeg": 0.07, "LeftFoot": 0.05, "RightFoot": 0.05}
const DT: float = 1.0 / 60.0

var _player: Player
var _enemy: Enemy
var _label: String = ""
## Datos por personaje: {"p": {...}, "e": {...}} con posiciones locales/mundiales del fotograma anterior.
var _prev: Dictionary = {}
var _report: Dictionary = {}  # label -> {stats}
var _order: Array[String] = []


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	_skeleton(_player).skeleton_updated.connect(_sample.bind("p"))
	_skeleton(_enemy).skeleton_updated.connect(_sample.bind("e"))
	await _run()
	_print_report()
	var failures: int = _check_regressions()
	print("RESULTADO: %s" % ("TODO OK" if failures == 0 else "%d FALLOS" % failures))
	get_tree().quit(failures)


func _skeleton(who: Node) -> Skeleton3D:
	return who.body.get_node("YBot/Skeleton3D") as Skeleton3D


# --- Guion ------------------------------------------------------------------------

func _run() -> void:
	# Mientras se mide al jugador, el soldado no ataca por su cuenta (solo bloquea y reacciona).
	_enemy.aggro_range = 0.0
	await _setup(true)
	await _segment("J quieto", 1.0)
	await _hold("J camina adelante (fijado)", &"move_forward", 1.2)
	await _setup(true)
	await _hold("J camina atrás (fijado)", &"move_back", 1.2)
	await _setup(true)
	await _hold("J camina izquierda (fijado)", &"move_left", 1.2)
	await _setup(true)
	await _hold("J camina derecha (fijado)", &"move_right", 1.2)
	await _setup(false)
	await _hold("J corre (libre)", &"move_back", 1.2)
	await _setup(false)
	_enemy.global_position = Vector3(0.0, 0.0, -9.0)
	_enemy.reset_physics_interpolation()
	Input.action_press(&"move_back")
	Input.action_press(&"dodge")
	await _frames(40)
	_prev.clear()
	_label = "J esprinta"
	await _frames(60)
	Input.action_release(&"dodge")
	Input.action_release(&"move_back")
	await _segment("J frena tras esprintar", 0.6)
	for dir: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right", &""]:
		await _setup(true)
		_label = "J esquiva %s" % (dir if dir != &"" else "sin dirección")
		if dir != &"":
			Input.action_press(dir)
		await _tap(&"dodge")
		await _frames(30)
		if dir != &"":
			Input.action_release(dir)
		await _frames(20)
	await _setup(true)
	_label = "J salta en el sitio"
	await _tap(&"jump")
	await _frames(80)
	await _setup(true)
	_label = "J combo ligero x3"
	for i in 3:
		await _tap(&"attack")
		await _frames(24)
	await _frames(50)
	for move: StringName in [&"heavy", &"kick", &"art_whirlwind", &"run_attack", &"dodge_attack"]:
		await _setup(true)
		_label = "J %s" % move
		_player.state_machine.transition_to(&"Attack", {"move": move})
		await _frames(110)
	await _setup(true)
	_label = "J ataque en salto"
	await _tap(&"jump")
	await _frames(12)
	await _tap(&"attack")
	await _frames(90)
	await _setup(true)
	_label = "J guardia (mantener)"
	Input.action_press(&"block")
	await _frames(70)
	Input.action_release(&"block")
	await _frames(20)

	# Soldado: cada patrón de ataque contra un jugador quieto (invulnerable).
	_enemy.aggro_range = 12.0
	for pattern: StringName in EnemyAttackState.PATTERNS:
		await _setup(true)
		_label = "S %s" % pattern
		_player.invulnerable = true
		_enemy.state_machine.transition_to(&"Attack", {"pattern": pattern})
		for i in 240:
			await get_tree().physics_frame
			if not _enemy.state_machine.current is EnemyAttackState:
				break
		await _frames(20)
		_player.invulnerable = false
	await _setup(true)
	_enemy.aggro_range = 0.0
	_label = "S bloquea tajos del jugador"
	for i in 3:
		await _tap(&"attack")
		await _frames(24)
	await _frames(40)
	await _setup(true)
	_label = "S retrocede (Recoil)"
	_enemy.state_machine.transition_to(&"Recoil", {"long": true})
	await _frames(90)
	await _setup(true)
	_label = "S persigue"
	_enemy.aggro_range = 12.0
	_enemy.global_position = Vector3(0.0, 0.0, -8.0)
	_enemy.reset_physics_interpolation()
	_enemy.state_machine.transition_to(&"Chase")
	await _frames(120)
	await _setup(true)
	_label = "S postura rota + golpe mortal"
	_enemy.posture.add(1000.0)
	await _frames(50)
	await _tap(&"attack")
	await _frames(150)
	_label = ""


func _setup(locked: bool) -> void:
	_label = ""
	for a: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right", &"dodge", &"block", &"attack"]:
		Input.action_release(a)
	if _enemy.is_dead():
		_enemy.respawn()
		_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	_player.state_machine.transition_to(&"Ground")
	await _frames(25)
	_player.global_position = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	_player.model.rotation.y = 0.0
	_enemy.global_position = Vector3(0.0, 0.0, -2.2)
	_enemy.velocity = Vector3.ZERO
	_enemy.model.rotation.y = PI
	_player.reset_physics_interpolation()
	_enemy.reset_physics_interpolation()
	_player.health.heal(_player.health.max_health)
	_player.posture.reset()
	_enemy.health.heal(_enemy.health.max_health)
	_enemy.posture.reset()
	if locked and _player.lock_target == null:
		await _tap(&"lock_on")
	elif not locked and _player.lock_target != null:
		await _tap(&"lock_on")
	await _frames(30)
	_prev.clear()


func _segment(label: String, seconds: float) -> void:
	_label = label
	await _frames(int(seconds * 60.0))


## Mantiene una dirección. Los primeros 0,4 s (arranque y giro) no se miden: solo el paso estable.
## El soldado se aparta a 9 m para no chocar con él.
func _hold(label: String, action: StringName, seconds: float) -> void:
	_enemy.global_position = Vector3(0.0, 0.0, -9.0)
	_enemy.reset_physics_interpolation()
	Input.action_press(action)
	await _frames(24)
	_prev.clear()
	_label = label
	await _frames(int(seconds * 60.0))
	Input.action_release(action)
	await _frames(30)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


# --- Medición ---------------------------------------------------------------------

func _sample(who: String) -> void:
	if _label.is_empty():
		_prev.erase(who)
		return
	var character: Node3D = _player if who == "p" else _enemy
	var sk: Skeleton3D = _skeleton(character)
	var model: Node3D = character.model
	var to_local: Transform3D = model.global_transform.affine_inverse()
	var world: Dictionary = {}
	var local: Dictionary = {}
	for bone in BONES:
		var idx: int = sk.find_bone("mixamorig_" + bone)
		var p: Vector3 = sk.global_transform * sk.get_bone_global_pose(idx).origin
		world[bone] = p
		local[bone] = to_local * p
	var key: String = ("Jugador" if who == "p" else "Soldado") + " · " + _label
	if not _report.has(key):
		_report[key] = {"frames": 0, "pop": 0.0, "pop_bone": "", "pop_at": 0, "pops": 0, "slip": 0.0,
			"travel": 0.0, "stride": 0.0, "support_frames": 0, "sink": 0.0, "clip": 0, "clip_min": INF, "clip_pair": ""}
		_order.append(key)
	var r: Dictionary = _report[key]
	r["frames"] += 1
	# Depuración: AUDIT_TRACE="Jugador · J quieto|Head" imprime la posición local de ese hueso.
	var trace: PackedStringArray = OS.get_environment("AUDIT_TRACE").split("|")
	if trace.size() == 2 and trace[0] == key:
		print("    %3d %s %s estado=%s acción=%s act=%.2f guard=%.2f mix=%.2f" % [r["frames"], trace[1], local[trace[1]], character.state_machine.current.name, character.body.current_action(), character.body._action, character.body._block, character.body._mix])
	var prev: Dictionary = _prev.get(who, {})
	# Salto: el desplazamiento de un hueso en UN fotograma es mucho mayor que en el anterior y el
	# siguiente (teletransporte). Se evalúa el fotograma anterior, que ya tiene vecinos a ambos lados.
	var disp: Dictionary = {}
	if prev.has("local"):
		for bone in BONES:
			disp[bone] = (local[bone] - prev["local"][bone]).length()
		# La pausa de impacto (hitstop) congela el tiempo a propósito: junto a ella no se juzgan saltos.
		var frozen: bool = Engine.time_scale < 0.99 or prev.get("frozen", false) or prev.get("frozen2", false)
		if not frozen and not prev.get("disp", {}).is_empty() and not prev.get("disp2", {}).is_empty():
			for bone in BONES:
				var middle: float = prev["disp"][bone]
				var neighbours: float = maxf(prev["disp2"][bone], disp[bone])
				var ratio: float = middle / maxf(neighbours, 0.004)
				if middle > 0.035 and ratio > 2.5:
					r["pops"] += 1
					if middle > r["pop"]:
						r["pop"] = middle
						r["pop_bone"] = bone
						r["pop_at"] = r["frames"] - 1
	# Pies: el pie de apoyo (el más bajo) no debería deslizarse por el suelo mientras está apoyado.
	var floor_y: float = character.global_position.y
	var grounded: bool = (character as CharacterBody3D).is_on_floor()
	var support: String = "Left" if world["LeftToeBase"].y < world["RightToeBase"].y else "Right"
	var toe: Vector3 = world[support + "ToeBase"]
	if grounded:
		r["sink"] = maxf(r["sink"], floor_y - minf(toe.y, world[support + "Foot"].y - 0.08))
	if grounded and prev.has("world") and prev.get("support", "") == support and toe.y - floor_y < 0.04:
		var before: Vector3 = prev["world"][support + "ToeBase"]
		r["slip"] += Vector2(toe.x - before.x, toe.z - before.z).length()
		var hips_before: Vector3 = prev["world"]["Hips"]
		r["travel"] += Vector2(world["Hips"].x - hips_before.x, world["Hips"].z - hips_before.z).length()
		r["support_frames"] += 1
		var local_before: Vector3 = prev["local"][support + "ToeBase"]
		var local_now: Vector3 = local[support + "ToeBase"]
		r["stride"] += Vector2(local_now.x - local_before.x, local_now.z - local_before.z).length()
	# Choque entre cuerpos (se mide desde el jugador, con los últimos datos del soldado).
	if who == "p" and _prev.has("e") and _prev["e"].has("world"):
		var other: Dictionary = _prev["e"]["world"]
		for a: String in BODY_RADIUS:
			for b: String in BODY_RADIUS:
				var gap: float = world[a].distance_to(other[b]) - BODY_RADIUS[a] - BODY_RADIUS[b]
				if gap < r["clip_min"]:
					r["clip_min"] = gap
					r["clip_pair"] = "%s/%s" % [a, b]
				if gap < -0.04:
					r["clip"] += 1
	_prev[who] = {"local": local, "world": world, "disp": disp, "disp2": prev.get("disp", {}), "support": support,
		"frozen": Engine.time_scale < 0.99, "frozen2": prev.get("frozen", false)}


## Comprobaciones que fijan las mejoras ya hechas (para que no vuelvan los defectos).
func _check_regressions() -> int:
	var failures: int = 0
	var checks: Array = []
	# 1. Al saltar, los pies no saltan de golpe (antes 29 cm: el apoyo de pies se apagaba de golpe).
	for key: String in ["Jugador · J salta en el sitio", "Jugador · J ataque en salto"]:
		checks.append(["%s: sin saltos de pies (mayor %.0f cm)" % [key, _report[key]["pop"] * 100.0], _report[key]["pop"] < 0.12])
	# 2. Las reacciones del soldado al bloquear no teletransportan las manos (antes 33–49 cm).
	for key: String in ["Soldado · S bloquea tajos del jugador", "Soldado · J heavy", "Soldado · J run_attack"]:
		checks.append(["%s: sin saltos grandes (mayor %.0f cm)" % [key, _report[key]["pop"] * 100.0], _report[key]["pop"] < 0.15])
	# 3. Al caminar/correr, el pie apoyado retrocede lo mismo que avanza el cuerpo (antes 140–200 %).
	for key: String in ["Jugador · J camina adelante (fijado)", "Jugador · J camina atrás (fijado)",
			"Jugador · J camina izquierda (fijado)", "Jugador · J camina derecha (fijado)", "Jugador · J corre (libre)"]:
		var ratio: float = _report[key]["stride"] / maxf(_report[key]["travel"], 0.05)
		checks.append(["%s: paso sincronizado (%.0f %%)" % [key, ratio * 100.0], ratio > 0.85 and ratio < 1.15])
	print("")
	for c: Array in checks:
		print("  [%s] %s" % ["OK" if c[1] else "FALLO", c[0]])
		if not c[1]:
			failures += 1
	return failures


func _print_report() -> void:
	print("
%-50s %5s %4s %-20s %9s %6s %6s %6s %6s %s" % ["segmento", "fotog", "saltos", "mayor salto", "patina", "%cuerpo", "paso", "hunde", "choque", "par más cercano"])
	for key in _order:
		var r: Dictionary = _report[key]
		var flags: String = ""
		var support_secs: float = r["support_frames"] / 60.0
		var slip_speed: float = r["slip"] / maxf(support_secs, 0.001)
		var slip_ratio: float = r["slip"] / maxf(r["travel"], 0.05)
		if r["pops"] > 0:
			flags += " SALTO"
		if support_secs > 0.2 and slip_speed > 0.25 and slip_ratio > 0.25:
			flags += " PATINA"
		if r["sink"] > 0.03:
			flags += " HUNDE"
		if r["clip"] > 0:
			flags += " CHOQUE"
		var clip_txt: String = "%.2f" % r["clip_min"] if r["clip_min"] < INF else "-"
		var pop_txt: String = "%s %.0fcm @%d" % [r["pop_bone"], r["pop"] * 100.0, r["pop_at"]] if r["pops"] > 0 else "-"
		var stride_ratio: float = r["stride"] / maxf(r["travel"], 0.05)
		print("%-50s %5d %4d %-20s %6.0fcm/s %5.0f%% %5.0f%% %4.1fcm %6s %-20s%s" % [key, r["frames"], r["pops"], pop_txt, slip_speed * 100.0, slip_ratio * 100.0, stride_ratio * 100.0, r["sink"] * 100.0, clip_txt, r["clip_pair"], flags])
