extends Node
## Prueba automática de los aldeanos, la promesa del prólogo y el desertor (Paso 4.2 a 4.6), en el nivel real
## (el Paso de Hierro): los aldeanos se asustan ante un soldado en alerta (#46), cada aldeano dice su frase una sola vez (antes y después de Varga), la niña y la madre
## reaccionan a la promesa, el desertor se rinde, queda perdonado o muere (también al morir o descansar con él
## rendido), y todo se guarda con la partida.
## Usa un archivo de guardado de prueba aparte y no necesita audio real.
## Ejecutar: Godot --headless --path game res://tests/villagers_test.tscn

const TEST_PATH: String = "user://save_villagers_test.json"
const VILLAGERS: Array[StringName] = [&"sweeper", &"old_man", &"child", &"road_man", &"mother"]

var _level: Node
var _player: Player
var _failures: int = 0
## Lo que se ha dicho, como "personaje/evento" (por ejemplo "villager/child_vow_stop").
var _spoken: Array[String] = []
## Dónde aparece Kael al cargar (lejos de la aldea).
var _start: Vector3 = Vector3.ZERO


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	Voice.spoken.connect(func(speaker: StringName, event: StringName, _id: String) -> void:
		_spoken.append("%s/%s" % [speaker, event]))
	await _load_level()
	await _villagers()
	await _vow()
	await _gestures()
	await _scare()
	await _deserter_case()
	await _deserter_reset_case()
	Engine.time_scale = 1.0
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


# --- 1. Cada aldeano dice su frase una sola vez, antes y después de Varga ---------------------------------

func _villagers() -> void:
	await _fresh()
	var old: Villager = _villager(&"old_man")
	var to_fire: Vector3 = Vector3(5.0, 0.0, 50.0) - old.global_position
	to_fire.y = 0.0
	var face: Vector3 = old.global_basis.z
	face.y = 0.0
	_check("El viejo mira la hoguera de ropa", face.normalized().dot(to_fire.normalized()) > 0.9)
	for e in VILLAGERS:
		var v: Villager = _villager(e)
		_check("Existe el aldeano %s" % e, v != null)
		if v == null:
			continue
		_check("%s aún no habló" % e, not v.has_spoken())
		await _visit(v)
		_check("%s dice su frase (%s)" % [e, str(_spoken)], Story.heard(StringName("villager_%s" % e)) and _said("villager/%s" % e) == 1)
	# Volver a pasar no la repite.
	for e in VILLAGERS:
		await _visit(_villager(e))
		_check("%s no repite su frase" % e, _said("villager/%s" % e) == 1)
	_check("Sin promesa no hay frase extra", not _any_vow())

	# Tras vencer a Varga, cada uno dice la 2.ª una sola vez.
	Story.mark_heard(&"boss_varga")
	for e in VILLAGERS:
		var v: Villager = _villager(e)
		var after := StringName("%s_after" % e)
		_check("%s: ahora le toca «%s»" % [e, after], v.current_event() == after and not v.has_spoken())
		await _visit(v)
		_check("%s dice la 2.ª frase" % e, Story.heard(StringName("villager_%s" % after)) and _said("villager/%s" % after) == 1)
	await _visit(_villager(&"sweeper"))
	_check("La 2.ª frase no se repite", _said("villager/sweeper_after") == 1)

	# Si no oyó la 1.ª antes de Varga, dice solo la 2.ª.
	await _fresh()
	Story.mark_heard(&"boss_varga")
	await _visit(_villager(&"sweeper"))
	_check("Sin oír la 1.ª, dice solo la 2.ª", Story.heard(&"villager_sweeper_after") and not Story.heard(&"villager_sweeper") \
			and _said("villager/sweeper") == 0 and _said("villager/sweeper_after") == 1)

	# Guardar, «cerrar y volver a abrir»: no se repite.
	SaveGame.save(_player)
	await _load_level()
	_spoken.clear()
	_check("Lo oído se recuerda al cargar", Story.heard(&"villager_sweeper_after") and Story.heard(&"boss_varga"))
	await _visit(_villager(&"sweeper"))
	_check("Tras cargar no repite la frase (%s)" % str(_spoken), _said("villager/sweeper_after") == 0 and _said("villager/sweeper") == 0)


# --- 2. La promesa del prólogo (paso 4.6) ---------------------------------------------------------------------

func _vow() -> void:
	# Promesa «Los detendré» (vow_stop): frase extra de la niña y de la madre.
	await _fresh()
	Story.mark_heard(&"vow_stop")
	var child: Villager = _villager(&"child")
	var mother: Villager = _villager(&"mother")
	await _visit(child)
	await _visit(child)
	_check("vow_stop: la niña dice su frase y la de la promesa (%s)" % str(_spoken),
			_said("villager/child") == 1 and _said("villager/child_vow_stop") == 1 and Story.heard(&"villager_child_vow"))
	_check("vow_stop: la niña no baja el dibujo",
			not child._drawing_lowered() and child._paper.position.is_equal_approx(Villager.PAPER_UP * child.size))
	await _visit(mother)
	await _visit(mother)
	_check("vow_stop: la madre dice la de la promesa", _said("villager/mother_vow_stop") == 1 and Story.heard(&"villager_mother_vow"))
	await _visit(child)
	await _visit(mother)
	_check("vow_stop: una 3.ª visita no añade nada", _said("villager/child_vow_stop") == 1 and _said("villager/mother_vow_stop") == 1)

	# Otros aldeanos no tienen frase de promesa.
	var sweeper: Villager = _villager(&"sweeper")
	await _visit(sweeper)
	await _visit(sweeper)
	_check("El barrendero no tiene frase de promesa", sweeper.vow_event() == &"" and _said("villager/sweeper") == 1 and not _any_vow_of("sweeper"))

	# Promesa «Acabaré con ellos» (vow_end): la madre se lleva a la hija; la niña calla y baja el dibujo.
	await _fresh()
	Story.mark_heard(&"vow_end")
	child = _villager(&"child")
	mother = _villager(&"mother")
	_check("vow_end: la niña aún lleva el dibujo en alto", not child._drawing_lowered())
	await _visit(mother)
	await _visit(mother)
	_check("vow_end: la madre dice la de la promesa", _said("villager/mother_vow_end") == 1)
	await _visit(child)
	await _visit(child)
	_check("vow_end: la niña solo dice su frase, nada de promesa (%s)" % str(_spoken),
			_said("villager/child") == 1 and not _any_vow_of("child") and child.vow_event() == &"")
	_check("vow_end: la niña baja el dibujo",
			child._drawing_lowered() and child._paper.position.is_equal_approx(Villager.PAPER_DOWN * child.size))

	# Tras vencer a Varga ya no hay frase de promesa.
	await _fresh()
	Story.mark_heard(&"vow_stop")
	Story.mark_heard(&"boss_varga")
	child = _villager(&"child")
	mother = _villager(&"mother")
	await _visit(child)
	await _visit(child)
	await _visit(mother)
	await _visit(mother)
	_check("Tras Varga solo hay frases «después» (%s)" % str(_spoken),
			_said("villager/child_after") == 1 and _said("villager/mother_after") == 1 and not _any_vow())
	_check("Tras Varga no hay promesa", child.vow_event() == &"" and mother.vow_event() == &"")


# --- 4. Gestos de la aldea (#29) ---------------------------------------------------------------------------

func _gestures() -> void:
	await _fresh()
	var sweeper: Villager = _villager(&"sweeper")
	var mother: Villager = _villager(&"mother")
	# Varias lecturas cortas: con solo dos, separadas 0,3 s, a veces caen simétricas al pico y salen iguales (#35).
	var first: float = sweeper._broom.rotation.z
	var moved := false
	var in_range := absf(first) <= Villager.BROOM_SWING + 0.001
	for i in 3:
		await _wait(0.1)
		var now: float = sweeper._broom.rotation.z
		moved = moved or absf(now - first) > 0.01
		in_range = in_range and absf(now) <= Villager.BROOM_SWING + 0.001
	_check("La escoba se mueve sola (Kael lejos)", moved and in_range)
	var only_ok := true
	for e in [&"old_man", &"road_man", &"child"]:
		var v: Villager = _villager(e)
		only_ok = only_ok and v._broom == null and v._covered == null
	_check("Solo la barrendera lleva escoba y solo la madre tapa ojos", only_ok and mother._broom == null \
			and mother._covered != null and mother._covered.event == &"")
	var gap: float = _flat(mother).distance_to(_flat(mother._covered)) if mother._covered != null else -1.0
	_check("La hija está junto a su madre (%.2f m)" % gap, gap > 0.6 and gap < 0.75)
	await _wait(0.8)
	_check("Con Kael lejos la mano está en reposo", mother._hand_pos.is_equal_approx(mother._hand_rest))
	await _visit(mother)
	await _wait(0.8)
	_check("Con Kael cerca la mano tapa los ojos", mother._hand_pos.distance_to(mother._cover_point()) < 0.02)
	var girl: Villager = mother._covered
	_check("La mano no atraviesa la cabeza de la niña", \
			mother._hand.global_position.distance_to(girl._head.global_position) > 0.12 * girl.size)
	_teleport(_start)
	await _wait(0.8)
	_check("Al alejarse la mano baja", mother._hand_pos.is_equal_approx(mother._hand_rest))


# --- 5. El susto ante un soldado en alerta (#46) -----------------------------------------------------------

func _scare() -> void:
	await _fresh()
	var v: Villager = _villager(&"old_man")
	var e: Enemy = get_tree().get_nodes_in_group("enemies")[0] as Enemy
	_check("Hay un enemigo para el susto", e != null)
	if e == null:
		return
	_check("Sin alertas el aldeano está tranquilo", not v.is_scared() and absf(v._body.scale.y - 1.0) <= 0.01)
	# A 20 m: no se asusta.
	e.alerted = false
	e.global_position = v.global_position + Vector3(20.0, 0.0, 0.0)
	e.alert()
	await _wait(0.5)
	_check("Un soldado en alerta a 20 m no lo asusta", not v.is_scared() and absf(v._body.scale.y - 1.0) <= 0.01)
	# A 6 m: se asusta, se encoge y aparta la mirada.
	e.alerted = false
	e.global_position = v.global_position + Vector3(6.0, 0.0, 0.0)
	e.alert()
	await _wait(0.5)
	_check("Un soldado en alerta a 6 m lo asusta (escala %.2f)" % v._body.scale.y,
			v.is_scared() and v._body.scale.y < 1.0 - Villager.SCARE_SQUASH * 0.5)
	# 4 s sin alertas: vuelve a su postura.
	await _wait(Villager.SCARE_TIME + 0.2)
	_check("Pasado el susto vuelve a su postura (escala %.2f)" % v._body.scale.y,
			not v.is_scared() and absf(v._body.scale.y - 1.0) <= 0.01)
	e.alerted = false


# --- 3. El desertor (paso 4.3) --------------------------------------------------------------------------------

func _deserter_case() -> void:
	await _fresh()
	await _wait(0.1)
	var d: Deserter = _deserter()
	_check("Hay un desertor", d != null)
	if d == null:
		return
	var post := Vector2(-17.0, 50.0)
	_check("Empieza en su puesto, sin marcas", _flat(d).distance_to(post) < 0.5 and not Story.heard(Deserter.STORY_SURRENDERED) \
			and not Story.heard(Deserter.STORY_SPARED) and not Story.heard(Deserter.STORY_KILLED))

	# Se rinde al acercarse Kael (a 4 m; fuera del alcance de los aldeanos).
	Voice.reset()
	_teleport(Vector3(-13.0, 0.0, 50.0))
	await _wait(0.5)
	_check("A ≤6 m se rinde", Story.heard(Deserter.STORY_SURRENDERED) and not Story.heard(Deserter.STORY_SPARED))
	_check("Dice su frase (%s)" % str(_spoken), _said("soldier/surrender") == 1)
	await _wait(0.5)
	_check("La frase no se repite", _said("soldier/surrender") == 1)

	# Kael se aleja sin golpearlo: queda perdonado.
	_teleport(_start)
	await _wait(0.3)
	_check("Al alejarse >20 m queda perdonado", Story.heard(Deserter.STORY_SPARED) and Deserter.is_spared())
	_check("Aún no va al pozo: solo tras descansar", _flat(d).distance_to(post) < 0.5)

	# Tras descansar, junto al pozo.
	Camps.reset_world()
	await _wait(0.1)
	var well := Vector2(Deserter.WELL_SPOT.x, Deserter.WELL_SPOT.z)
	_check("Tras descansar está junto al pozo", _flat(d).distance_to(well) < 0.1 and d.visible)

	# Guardar y cargar: sigue perdonado y en el pozo.
	SaveGame.save(_player)
	await _load_level()
	d = _deserter()
	_check("Tras cargar sigue perdonado", Deserter.is_spared())
	_check("…y junto al pozo", d != null and _flat(d).distance_to(well) < 0.1 and d.visible)
	if d == null:
		return

	# Un golpe que no es de Kael no cuenta; uno de Kael lo mata.
	var stray := HitData.create(null, 10.0, 10.0)
	_check("Un golpe ajeno se ignora", d.receive_hit(stray) == HitData.Result.IGNORED and not Story.heard(Deserter.STORY_KILLED))
	var hit := HitData.create(_player, 10.0, 10.0)
	var result: int = d.receive_hit(hit)
	Engine.time_scale = 1.0  # El golpe llama a la pausa de impacto (cámara lenta).
	_check("Un golpe de Kael lo mata", result == HitData.Result.HIT and Story.heard(Deserter.STORY_KILLED) and not Deserter.is_spared())
	var again: int = d.receive_hit(HitData.create(_player, 10.0, 10.0))
	Engine.time_scale = 1.0
	_check("Un 2.º golpe se ignora", again == HitData.Result.IGNORED)

	# No vuelve, ni al descansar ni al cargar.
	Camps.reset_world()
	await _wait(0.1)
	_check("Tras descansar ya no está", not d.visible)
	SaveGame.save(_player)
	await _load_level()
	d = _deserter()
	_check("Tras cargar no vuelve (%s)" % str(d), d != null and not d.visible)
	_check("Se conservan las dos marcas", Story.heard(Deserter.STORY_KILLED) and Story.heard(Deserter.STORY_SPARED))
	_check("…y ya no cuenta como perdonado", not Deserter.is_spared())


## El desertor y el reinicio del mundo (morir o descansar) sin alejarse 20 m.
func _deserter_reset_case() -> void:
	# Sin verlo: reiniciar no cambia nada.
	await _fresh()
	await _wait(0.1)
	var d: Deserter = _deserter()
	var post := Vector2(-17.0, 50.0)
	var well := Vector2(Deserter.WELL_SPOT.x, Deserter.WELL_SPOT.z)
	Camps.reset_world()
	await _wait(0.1)
	_check("Sin verlo, reiniciar no cambia nada", _flat(d).distance_to(post) < 0.5 and d.visible \
			and not Story.heard(Deserter.STORY_SURRENDERED) and not Story.heard(Deserter.STORY_SPARED))

	# Rendido y Kael cerca (como si muriera a su lado): al reiniciar queda perdonado y va al pozo.
	Voice.reset()
	_teleport(Vector3(-13.0, 0.0, 50.0))
	await _wait(0.5)
	_check("Rendido, aún sin perdón", Story.heard(Deserter.STORY_SURRENDERED) and not Story.heard(Deserter.STORY_SPARED))
	Camps.reset_world()
	await _wait(0.1)
	_check("Al reiniciar sin alejarse queda perdonado", Deserter.is_spared())
	_check("…y ya está junto al pozo", _flat(d).distance_to(well) < 0.1 and d.visible)
	await _wait(0.5)
	_check("No repite la frase en el pozo", _said("soldier/surrender") == 1)

	# Lo guardó el propio reinicio: se carga sin guardar a mano.
	await _load_level()
	d = _deserter()
	_check("Tras cargar sigue perdonado y en el pozo", Deserter.is_spared() and d != null \
			and _flat(d).distance_to(well) < 0.1 and d.visible)

	# Rendido y muerto por Kael: al reiniciar desaparece y no queda perdonado.
	await _fresh()
	await _wait(0.1)
	d = _deserter()
	Voice.reset()
	_teleport(Vector3(-13.0, 0.0, 50.0))
	await _wait(0.5)
	d.receive_hit(HitData.create(_player, 10.0, 10.0))
	Engine.time_scale = 1.0  # La pausa de impacto.
	Camps.reset_world()
	await _wait(0.1)
	_check("Muerto antes del perdón: desaparece", not d.visible)
	_check("…y no queda perdonado", Story.heard(Deserter.STORY_KILLED) and not Story.heard(Deserter.STORY_SPARED))


# --- Ayudantes ---------------------------------------------------------------------------------------------------

## Carga el nivel (como al abrir el juego), quitando el anterior. Los enemigos se quedan quietos y dormidos
## para que no avisen ni ataquen a Kael mientras está en la aldea.
func _load_level() -> void:
	if _level:
		_level.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	_level = load("res://scenes/levels/iron_pass.tscn").instantiate()
	add_child(_level)
	_player = get_tree().get_first_node_in_group("player") as Player
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		enemy.aggro_range = 0.0
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(0.6, true, true).timeout
	if _start == Vector3.ZERO:
		_start = _player.global_position


## El aldeano con ese evento.
func _villager(event: StringName) -> Villager:
	for node in get_tree().get_nodes_in_group("villagers"):
		var v := node as Villager
		if v.event == event:
			return v
	return null


func _deserter() -> Deserter:
	return get_tree().get_first_node_in_group("deserters") as Deserter


func _teleport(at: Vector3) -> void:
	_player.global_position = at
	_player.reset_physics_interpolation()


## Kael junto a un aldeano (a 1,5 m): la voz «villager» se libera antes, porque solo habla uno a la vez.
func _visit(v: Villager) -> void:
	Voice.reset()
	_teleport(v.global_position + Vector3(1.5, 0.0, 0.0))
	await _wait(0.4)


## Partida nueva y Kael lejos, sin nada dicho.
func _fresh() -> void:
	Voice.reset()
	Story.reset()
	_spoken.clear()
	_teleport(_start)
	await _wait(0.2)


## Cuántas veces se dijo «personaje/evento».
func _said(key: String) -> int:
	return _spoken.count(key)


## ¿Se dijo alguna frase de promesa (cualquiera)?
func _any_vow() -> bool:
	for s in _spoken:
		if "_vow_" in s:
			return true
	return false


## ¿Se dijo alguna frase de promesa de ese aldeano?
func _any_vow_of(event: String) -> bool:
	for s in _spoken:
		if s.begins_with("villager/%s_vow_" % event):
			return true
	return false


func _flat(n: Node3D) -> Vector2:
	return Vector2(n.global_position.x, n.global_position.z)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
