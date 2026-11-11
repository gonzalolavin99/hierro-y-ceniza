extends Node
## Prueba automática del Paso de Hierro en bloques (Hito 9, paso 3): el nivel carga con todas sus piezas;
## los enemigos aparecen sobre suelo firme (ni dentro de un muro ni en el aire); se puede ir a pie del inicio
## a cada zona (búsqueda por una rejilla de 1 m: escalones de hasta 0,7 m, sin muros en medio); y el
## portón del atajo está cerrado hasta que Frank lo abre.
## Ejecutar: Godot --headless --path game res://tests/iron_pass_test.tscn

const TEST_PATH: String = "user://save_iron_pass_test.json"
const CELL: float = 1.0
const STEP: float = 0.7
const MIN: Vector2 = Vector2(-46.0, -152.0)
const MAX: Vector2 = Vector2(80.0, 147.0)

var _failures: int = 0
var _space: PhysicsDirectSpaceState3D
var _probe := SphereShape3D.new()
var _steps: Dictionary = {}


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	add_child(load("res://scenes/levels/iron_pass.tscn").instantiate())
	var enemies: Array[Enemy] = []
	var spawned: Dictionary = {}
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		enemy.aggro_range = 0.0
		enemy.state_machine.transition_to(&"Idle", {"wait": 1000.0})
		enemies.append(enemy)
		spawned[enemy] = enemy.global_position
	await get_tree().create_timer(2.0).timeout
	_space = get_viewport().world_3d.direct_space_state
	_probe.radius = 0.35

	var player := get_tree().get_first_node_in_group("player") as Player
	_check("Kael empieza en el camino, de pie", player.is_on_floor() and player.global_position.distance_to(IronPassLayout.START) < 1.0)
	_check("En el nivel real solo trae el Torbellino (%s): las demás técnicas se ganan" % str(player.arts.unlocked),
			player.arts.unlocked == [PlayerArts.STARTING])
	_check("Hay 17 o más enemigos (son %d)" % enemies.size(), enemies.size() >= 17)
	_check("Dos campamentos (aldea y bosque)", get_tree().get_nodes_in_group("campfires").size() == 2)
	var fires: Array[Campfire] = []
	for node in get_tree().get_nodes_in_group("campfires"):
		fires.append(node as Campfire)
	var village_fire: Campfire = fires[0] if fires[0].global_position.z > fires[1].global_position.z else fires[1]
	var forest_fire: Campfire = fires[1] if village_fire == fires[0] else fires[0]
	_check("La fogata 2 está en el campamento de los cazadores (%s)" % forest_fire.global_position.snappedf(0.1),
			forest_fire.global_position.distance_to(Vector3(-29, 0, -12)) < 6.0)
	var varga_door := Vector3(IronPassLayout.ARENA_AT.x - 20.0, IronPassLayout.FORT_Y, IronPassLayout.ARENA_AT.z)
	_check("No hay fogata a la entrada del patio de Varga", fires.all(func(f: Campfire) -> bool: return f.global_position.distance_to(varga_door) > 25.0))

	# Tutorial: el bandido ya no está en el camino; el 2.º enemigo solo hace el barrido rojo.
	var on_road: Array[String] = []
	var sweeper: Enemy
	for enemy in enemies:
		if enemy.global_position.z > 78.0:
			on_road.append(enemy.display_name)
		if enemy.get_meta("teaches", &"") == &"sweep":
			sweeper = enemy
	_check("En el camino del tutorial solo hay soldados de práctica (%s)" % [on_road], on_road.size() == 2 and not on_road.has("Bandido"))
	_check("El soldado del barrido solo hace barridos rojos", sweeper != null and sweeper.mind.danger_ratio >= 1.0 and sweeper.mind.danger_patterns == [&"sweep"] and not sweeper.mind.can_grab)

	# Ritmo: como mucho 8 enemigos obligatorios (alerta, ni opcionales ni desprevenidos) entre dos fogatas.
	var stretch_a: int = 0
	var stretch_b: int = 0
	for enemy in enemies:
		if enemy.boss or enemy.starts_unaware or enemy.get_meta("optional", false) or enemy.global_position.z > 78.0:
			continue
		if enemy.global_position.z > forest_fire.global_position.z:
			stretch_a += 1
		else:
			stretch_b += 1
	_check("Aldea → fogata del bosque: %d enemigos obligatorios (≤ 8)" % stretch_a, stretch_a <= 8)
	_check("Fogata del bosque → Varga: %d enemigos obligatorios (≤ 8)" % stretch_b, stretch_b <= 8)
	_check("La red de Frank está en el camino", get_tree().get_nodes_in_group("frank_snare").size() == 1)
	_check("La despensa y las dos puertas del atajo", get_tree().get_nodes_in_group("latched_gates").size() == 3)
	_check("Dos escondites en el bosque", get_tree().get_nodes_in_group("hidden_caches").size() == 2)
	_check("El patio de Varga", get_tree().get_nodes_in_group("arenas").size() == 1)
	_check("Cuatro narraciones de zona", get_tree().get_nodes_in_group("narration_zones").size() == 4)

	var misplaced: Array[String] = []
	for enemy in enemies:
		var start: Vector3 = spawned[enemy]
		if not enemy.is_on_floor() or enemy.global_position.distance_to(start) > 0.6:
			misplaced.append("%s %s→%s" % [enemy.display_name, start, enemy.global_position.snappedf(0.1)])
	_check("Todos los enemigos sobre suelo firme %s" % [misplaced], misplaced.is_empty())

	var reach: Dictionary = _walkable_from(IronPassLayout.START)
	var goals: Dictionary = {
		"el arco de la aldea": Vector3(0, 0, 76), "el campamento de la aldea": Vector3(0, 0, 70),
		"la casa del pozo": Vector3(-18, 0, 33), "la azotea del arquero": Vector3(25, 3.5, 44),
		"la entrada del bosque": Vector3(0, 0, 16), "el campamento de los cazadores": Vector3(-29, 0, -12),
		"el escondite del fondo": Vector3(26, 0, -46), "el pie de la rampa": Vector3(0, 0, -48),
		"la meseta de la fortaleza": Vector3(0, 4, -90), "lo alto de una torre": Vector3(8, 7.5, -73),
		"el patio del lazareto": Vector3(-20, 4, -118), "el pasillo de Varga": Vector3(27, 4, -118),
		"el patio de Varga": Vector3(60, 4, -125),
	}
	for label in goals:
		_check("Se llega a pie a %s" % label, _reached(reach, goals[label]))
	_check("No se puede salir del mapa por el sur", not _reached(reach, Vector3(0, 0, 150)))
	_check("Desde la aldea, el sendero del atajo está cerrado (puerta atrancada)", not _reached(reach, Vector3(40, 0, 0)))
	_check("Farolillos marcan el camino (%d)" % get_tree().get_nodes_in_group("lanterns").size(), get_tree().get_nodes_in_group("lanterns").size() >= 15)
	var lit: int = 0
	for node in get_tree().get_nodes_in_group("lanterns"):
		var spot: Vector3 = (node as Node3D).global_position
		spot.y -= 2.35
		if _reached(reach, spot + Vector3(0, 0, 0)) or _reached(reach, spot + Vector3(1.5, 0, 0)) or _reached(reach, spot + Vector3(-1.5, 0, 0)):
			lit += 1
	_check("…todos junto al camino que se recorre (%d)" % lit, lit == get_tree().get_nodes_in_group("lanterns").size())

	var gate: LatchedGate
	for node in get_tree().get_nodes_in_group("latched_gates"):
		if (node as LatchedGate).gate_id == &"fortress_shortcut":
			gate = node
	var door_from := Vector3(29.0, 5.0, -85.0)
	var door_to := Vector3(34.0, 5.0, -85.0)
	_check("El portón del atajo está cerrado al principio", not gate.is_open() and _blocked(door_from, door_to))
	Story.mark_heard(gate.story_flag())
	Story.changed.emit()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check("Abierto, se pasa de la fortaleza al sendero", not _blocked(door_from, door_to))
	var down: Dictionary = _walkable_from(Vector3(0, 4, -90))
	_check("…el sendero baja hasta la puerta de la aldea", _reached(down, Vector3(40, 0, 38)))
	var through_from := Vector3(38.0, 1.2, 39.0)
	var through_to := Vector3(33.0, 1.2, 39.0)
	_check("…que sigue atrancada", _blocked(through_from, through_to))
	var village_door: LatchedGate
	for node in get_tree().get_nodes_in_group("latched_gates"):
		if (node as LatchedGate).gate_id == &"village_shortcut":
			village_door = node
	_check("La puerta de la aldea la abre Kael solo, desde el sendero", not village_door.needs_frank and village_door.passage)
	Story.mark_heard(village_door.story_flag())
	Story.changed.emit()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check("Quitada la tranca, se pasa del sendero a la aldea", not _blocked(through_from, through_to))

	# El atajo es la vuelta rápida: de la fogata de la aldea a la puerta de Varga corriendo, ≤ 45 s.
	var from_camp: Vector3 = village_fire.rest_position()
	_walkable_from(Vector3(roundf(from_camp.x), 0.0, roundf(from_camp.z)))
	var meters: float = _steps_to(varga_door) * CELL
	var seconds: float = meters / player.sprint_speed
	_check("Con el atajo abierto, de la fogata 1 a Varga: %.0f m ≈ %.0f s corriendo (≤ 45 s)" % [meters, seconds], meters > 0.0 and seconds <= 45.0)

	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


## Sitios a los que se llega a pie desde `from`. Clave: Vector3i(celda x, altura redondeada, celda z), así
## una rampa y el suelo de debajo son sitios distintos. Valor: la altura del suelo.
func _walkable_from(from: Vector3) -> Dictionary:
	var start := Vector3i(roundi(from.x / CELL), roundi(from.y), roundi(from.z / CELL))
	var seen: Dictionary = {start: from.y}
	_steps = {start: 0}
	var queue: Array[Vector3i] = [start]
	while not queue.is_empty():
		var cell: Vector3i = queue.pop_front()
		var h: float = seen[cell]
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var x: int = cell.x + d.x
			var z: int = cell.z + d.y
			if x * CELL < MIN.x or x * CELL > MAX.x or z * CELL < MIN.y or z * CELL > MAX.y:
				continue
			var floor_y: float = _floor_at(Vector3(x * CELL, h, z * CELL))
			if is_nan(floor_y):
				continue
			var next := Vector3i(x, roundi(floor_y), z)
			if seen.has(next):
				continue
			var at := Vector3(x * CELL, floor_y, z * CELL)
			if _blocked(Vector3(cell.x * CELL, h + 1.0, cell.z * CELL), at + Vector3.UP * 1.0) or _crowded(at):
				continue
			seen[next] = floor_y
			_steps[next] = int(_steps[cell]) + 1
			queue.append(next)
	return seen


## Pasos de 1 m (por la rejilla) desde el origen de la última búsqueda hasta `at` (-1 si no se llega).
## La rejilla solo va en cruz: algo más largo que el camino real (la cuenta es prudente).
func _steps_to(at: Vector3) -> int:
	var best: int = -1
	for key in _steps:
		var k: Vector3i = key
		if absi(k.x - roundi(at.x / CELL)) <= 1 and absi(k.z - roundi(at.z / CELL)) <= 1 and absf(float(k.y) - at.y) < 1.5:
			if best < 0 or int(_steps[key]) < best:
				best = int(_steps[key])
	return best


## Suelo bajo `at` entre un escalón por encima y una caída de 1,5 m (NAN si no hay).
func _floor_at(at: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * (STEP + 0.05), at + Vector3.DOWN * 1.5, 1)
	var hit: Dictionary = _space.intersect_ray(query)
	if hit.is_empty() or (hit["normal"] as Vector3).y < 0.7:
		return NAN
	return (hit["position"] as Vector3).y


func _blocked(a: Vector3, b: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(a, b, 1)
	return not _space.intersect_ray(query).is_empty()


## ¿Choca un cuerpo del tamaño de Kael (a la altura del pecho y de la cabeza)?
func _crowded(at: Vector3) -> bool:
	for y in [0.9, 1.6]:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = _probe
		query.transform = Transform3D(Basis(), at + Vector3.UP * y)
		query.collision_mask = 1
		if not _space.intersect_shape(query, 1).is_empty():
			return true
	return false


func _reached(reach: Dictionary, at: Vector3) -> bool:
	for key in reach:
		var k: Vector3i = key
		if absi(k.x - roundi(at.x / CELL)) <= 1 and absi(k.z - roundi(at.z / CELL)) <= 1 and absf(float(reach[key]) - at.y) < 1.0:
			return true
	return false


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
