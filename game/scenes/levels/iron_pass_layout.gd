class_name IronPassLayout
extends Node3D
## El Paso de Hierro "en bloques" (greybox, Hito 9 paso 3): el mapa entero con cajas, rampas y muros
## sencillos, sin arte, para probar el camino, las distancias y los combates (docs/12).
## Sube de sur a norte (norte = −Z): camino del Paso (tutorial, red de Frank) → aldea en cuarentena
## (campamento 1) → bosque (obligatorio, sigilo) → fortaleza (rampa, torres, lazareto, atajo) → patio de
## Varga (su campamento está a la entrada). El atajo es un portón en el muro este de la fortaleza: Frank lo
## abre y un sendero baja por el este hasta la aldea.
## Este nodo va el primero en la escena (antes que Kael), así todo existe cuando Kael aparece.
## Todo se construye en código: cambiar una medida es cambiar un número aquí.

const SOLDIER: PackedScene = preload("res://scenes/enemies/training_soldier.tscn")
const BANDIT: PackedScene = preload("res://scenes/enemies/bandit.tscn")
const SPEARMAN: PackedScene = preload("res://scenes/enemies/spearman.tscn")
const ARCHER: PackedScene = preload("res://scenes/enemies/archer.tscn")
const CAMPFIRE: PackedScene = preload("res://scenes/props/campfire.tscn")

## Dónde empieza Kael (tras la escena del prólogo) y hacia dónde mira (180° = hacia el norte).
const START: Vector3 = Vector3(0.0, 0.0, 140.0)
const START_FACING: float = 180.0
## Altura de la meseta de la fortaleza.
const FORT_Y: float = 4.0
## Centro del patio de Varga (su entrada está al oeste).
const ARENA_AT: Vector3 = Vector3(60.0, FORT_Y, -125.0)
## El portón del atajo (muro este de la fortaleza).
const SHORTCUT_AT: Vector3 = Vector3(31.8, FORT_Y, -85.0)
const TREE_SEED: int = 7
## El sendero de tierra que cruza el bosque (de la aldea a la rampa): sin árboles encima y con farolillos.
const FOREST_PATH: PackedVector3Array = [Vector3(0, 0, 20), Vector3(-5, 0, 8), Vector3(-3, 0, -6),
	Vector3(5, 0, -18), Vector3(4, 0, -30), Vector3(0, 0, -40), Vector3(0, 0, -51)]
## Farolillos que marcan el camino principal (luz cálida = por aquí se sigue; aviso del jugador: sin pistas
## no se sabía hacia dónde ir).
const LANTERNS: PackedVector3Array = [
	Vector3(-3.2, 0, 76), Vector3(3.2, 0, 76),  # El arco.
	Vector3(3.5, 0, 60), Vector3(-3.5, 0, 44), Vector3(3.5, 0, 30),  # La calle de la aldea.
	Vector3(-4.5, 0, 21.5), Vector3(4.5, 0, 21.5),  # Salida al bosque.
	Vector3(-3.2, 0, 8), Vector3(-1.2, 0, -6), Vector3(6.8, 0, -18), Vector3(5.8, 0, -30),  # El sendero del bosque.
	Vector3(-4.5, 0, -49), Vector3(4.5, 0, -49),  # Pie de la rampa.
	Vector3(-3.5, FORT_Y, -71), Vector3(3.5, FORT_Y, -71),  # El portón de la fortaleza.
	Vector3(24, FORT_Y, -121.5), Vector3(24, FORT_Y, -128.5),  # Hacia el patio de Varga.
]
## La puerta atrancada del atajo en la aldea: se abre desde el sendero (Kael quita la tranca).
const VILLAGE_DOOR_AT: Vector3 = Vector3(34.2, 0.0, 39.0)

const ROCK := Color(0.4, 0.38, 0.35)
const CLIFF := Color(0.33, 0.32, 0.3)
const DIRT := Color(0.36, 0.32, 0.26)
const PATH := Color(0.42, 0.37, 0.3)
const HOUSE := Color(0.5, 0.44, 0.36)
const ROOF := Color(0.33, 0.24, 0.18)
const CLOTH := Color(0.62, 0.62, 0.6)
const WOOD := Color(0.45, 0.33, 0.22)
const FOREST := Color(0.25, 0.3, 0.2)
const FORT := Color(0.45, 0.44, 0.42)

var world: StaticBody3D
var _materials: Dictionary = {}


func _ready() -> void:
	Squad.sleep_distance = Squad.SLEEP_DISTANCE  # Los enemigos lejanos duermen (rendimiento).
	world = StaticBody3D.new()
	world.name = "World"
	add_child(world)
	_box(Vector3(0.0, -0.5, 0.0), Vector3(420.0, 1.0, 420.0), DIRT)  # El suelo de todo.
	_build_road()
	_build_village()
	_build_forest()
	_build_fortress()
	_build_shortcut()
	_build_arena()
	var nordic_props := NordicProps.new()
	nordic_props.name = "VolsungosVillage"
	add_child(nordic_props)
	nordic_props.dress_village()
	for at in LANTERNS:
		_lantern(at)
	# Ambiente: viento, el arroyo junto al sendero del atajo y pájaros lejanos.
	var ambience := Ambience.new()
	ambience.name = "Ambience"
	ambience.river_points = PackedVector3Array([Vector3(43.0, 0.5, 30.0), Vector3(43.0, 0.5, -5.0), Vector3(43.0, 0.5, -40.0)])
	add_child(ambience)


# --- A. Camino del Paso (tutorial) -------------------------------------------

func _build_road() -> void:
	_box(Vector3(0.0, 0.01, 112.0), Vector3(9.0, 0.02, 66.0), PATH, false)
	# Paredes de roca a los lados, con dos ensanches (soldado de práctica y bandido).
	_cliff_x(-5.5, 80.0, 94.0)
	_cliff_x(-5.5, 108.0, 146.0)
	_cliff_x(5.5, 80.0, 82.0)
	_cliff_x(5.5, 104.0, 146.0)
	_cliff_z(146.0, -6.0, 6.0)
	# Ensanche del soldado de práctica (oeste, z 94–108) y del bandido (este, z 82–94).
	_cliff_x(-14.0, 94.0, 108.0)
	_cliff_z(94.0, -14.0, -5.5)
	_cliff_z(108.0, -14.0, -5.5)
	_cliff_x(14.0, 82.0, 94.0)
	_cliff_z(82.0, 5.5, 14.0)
	_cliff_z(94.0, 5.5, 14.0)
	# Rincón de la red de Frank (x 5,5–14, z 94–104), abierto al camino. Más grande que antes (aviso del jugador:
	# en la escena de Frank la roca tapaba la cámara).
	_cliff_x(14.0, 94.0, 104.0)
	_cliff_z(104.0, 5.5, 14.0)

	_tip(Vector3(-2.8, 2.2, 134.0), "MOVERSE  {move}\nCÁMARA  {camera}")
	# Un tronco caído: hay que saltarlo.
	_box(Vector3(0.0, 0.3, 127.0), Vector3(9.0, 0.6, 0.7), WOOD)
	_tip(Vector3(2.8, 2.0, 129.5), "SALTAR  {jump}")
	_tip(Vector3(-2.8, 2.2, 120.0), "ESQUIVAR  {dodge} (tocar)\nCORRER  {dodge} (mantener)")
	# Un desnivel: subir por los bloques y bajar del otro lado.
	_box(Vector3(-2.5, 0.5, 114.0), Vector3(4.0, 1.0, 2.0), ROCK)
	_box(Vector3(2.5, 0.9, 114.0), Vector3(4.0, 1.8, 2.0), ROCK)
	_tip(Vector3(2.8, 2.4, 109.0), "ATACAR  {attack}      FIJAR  {lock_on}\nCUBRIRSE  {block} (mantener)\nDESVIAR  {block} justo antes del golpe")
	# Tutorial (revisión del estudio): una idea por tramo y un enemigo por idea. El soldado de práctica solo
	# da golpes normales y a ritmo fijo (para aprender a desviar); el siguiente solo hace el barrido rojo.
	# Curarse se explica la primera vez que Kael está herido y agacharse a la entrada del bosque (TutorialHints).
	var practice := _enemy(SOLDIER, Vector3(-9.5, 0.0, 101.0), -90.0, func(e: Enemy) -> void:
		e.danger_ratio = 0.0)
	practice.display_name = "Soldado de práctica"
	practice.aggro_range = 6.0
	practice.mind.predictable = true
	_tip(Vector3(-9.5, 2.6, 106.5), "Rompe su POSTURA desviando sus golpes\ny remata con {attack}")
	# La red de Frank, en el hueco del este.
	var snare := FrankSnare.new()
	snare.name = "FrankSnare"
	snare.position = Vector3(10.0, 0.0, 99.0)
	snare.rotation.y = PI * 0.5
	add_child(snare)
	var sweeper := _enemy(SOLDIER, Vector3(9.5, 0.0, 88.0), 90.0, func(e: Enemy) -> void:
		e.moveset = [&"single"]
		e.danger_moveset = [&"sweep"]
		e.danger_ratio = 1.0)
	sweeper.display_name = "Soldado del barrido"
	sweeper.aggro_range = 7.0
	sweeper.mind.predictable = true
	sweeper.set_meta("teaches", &"sweep")
	_tip(Vector3(-2.8, 2.4, 90.0), "¡ROJO! No se para ni se desvía.\nBarrido bajo → SALTA  {jump}")
	_zone(&"story_prologue", Vector3(0.0, 0.0, 140.0), Vector3(10.0, 4.0, 10.0), 1)
	# El arco de piedra: la primera vista de la aldea.
	_box(Vector3(-4.6, 2.75, 79.0), Vector3(1.6, 5.5, 1.6), ROCK)
	_box(Vector3(4.6, 2.75, 79.0), Vector3(1.6, 5.5, 1.6), ROCK)
	_box(Vector3(0.0, 6.0, 79.0), Vector3(10.8, 1.2, 1.6), ROCK)


# --- B. Aldea en cuarentena ---------------------------------------------------

func _build_village() -> void:
	# Muros del valle: abierto al sur (el arco), al norte (el bosque) y al este (el sendero del atajo).
	_cliff_z(78.0, -36.0, -5.5)
	_cliff_z(78.0, 5.5, 36.0)
	_cliff_x(-36.0, 20.0, 78.0)
	_cliff_x(36.0, 40.8, 78.0)
	_cliff_x(36.0, 20.0, 37.2)
	var door := LatchedGate.new()
	door.name = "VillageShortcutDoor"
	door.gate_id = &"village_shortcut"
	door.passage = true
	door.needs_frank = false
	door.position = VILLAGE_DOOR_AT
	door.rotation.y = -PI * 0.5  # Su lado de abrir (−Z) da al sendero (este).
	add_child(door)
	_cliff_z(20.0, -42.0, -6.0)
	_cliff_z(20.0, 6.0, 36.0)
	_box(Vector3(0.0, 0.01, 49.0), Vector3(8.0, 0.02, 58.0), PATH, false)

	var camp := _campfire(Vector3(-4.0, 0.0, 71.0), "Campamento de la aldea")
	camp.rotation.y = PI * 0.5
	_zone(&"story_pass_village", Vector3(0.0, 0.0, 64.0), Vector3(16.0, 4.0, 6.0))
	# Casas (las de tela gris están en cuarentena).
	_house(Vector3(-24.0, 0.0, 64.0), 0.0, true)
	_house(Vector3(-25.0, 0.0, 50.0), 0.2, false)
	_house(Vector3(-11.0, 0.0, 42.0), -0.1, true)
	_house(Vector3(13.0, 0.0, 66.0), 0.15, false)
	_house(Vector3(25.0, 0.0, 58.0), 0.0, true)
	_house(Vector3(13.0, 0.0, 33.0), -0.2, false)
	_house(Vector3(27.0, 0.0, 27.0), 0.1, true)
	# La casa del pozo (oeste), con su pozo delante.
	_house(Vector3(-24.0, 0.0, 30.0), 0.0, true)
	_cylinder(Vector3(-17.0, 0.45, 30.0), 1.1, 0.9, ROCK)
	_sign(Vector3(-24.0, 4.6, 30.0), "Casa del pozo")
	# La casa del arquero: azotea plana con rampa por detrás.
	_box(Vector3(25.0, 1.75, 44.0), Vector3(7.0, 3.5, 7.0), HOUSE)
	for side in [-1.0, 1.0]:
		_box(Vector3(25.0 + side * 3.3, 3.85, 44.0), Vector3(0.4, 0.7, 7.0), HOUSE)
	_box(Vector3(25.0, 3.85, 47.3), Vector3(7.0, 0.7, 0.4), HOUSE)
	_ramp(Vector3(25.0, 0.0, 33.0), Vector3(25.0, 3.5, 40.5), 2.5, WOOD)
	# La hoguera de la ropa (humo que se ve desde el arco).
	_cylinder(Vector3(5.0, 0.4, 50.0), 1.6, 0.8, Color(0.15, 0.13, 0.12))
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.55, 0.25)
	glow.light_energy = 2.0
	glow.omni_range = 9.0
	glow.position = Vector3(5.0, 1.6, 50.0)
	add_child(glow)
	for i in 4:
		_ball(Vector3(5.0 + i * 0.6, 3.0 + i * 3.0, 50.0 - i * 0.8), 1.2 + i * 0.5, Color(0.5, 0.5, 0.5, 0.35))
	_sign(Vector3(-4.0, 2.4, 56.0), "(Aldeanos: paso 4)")
	_tip(Vector3(2.8, 2.4, 62.0), "PATADA  {kick}: rompe la guardia\nde quien se cubre mucho")
	# Grupo 1 (junto a la hoguera), grupo 2 con el lancero (salida norte) y el arquero en la azotea.
	_enemy(SOLDIER, Vector3(9.0, 0.0, 55.0), 180.0)
	_enemy(SOLDIER, Vector3(12.0, 0.0, 53.0), 180.0)
	_enemy(SOLDIER, Vector3(-5.0, 0.0, 30.0), 180.0)
	_enemy(SOLDIER, Vector3(-1.0, 0.0, 32.0), 180.0)
	_enemy(SPEARMAN, Vector3(2.0, 0.0, 25.0), 180.0)
	var archer := _enemy(ARCHER, Vector3(25.0, FORT_Y - 0.5, 44.5), 180.0)
	archer.aggro_range = 20.0


# --- C. Bosque (sigilo, obligatorio) ------------------------------------------

func _build_forest() -> void:
	_cliff_x(-42.0, -52.0, 20.0)
	_cliff_x(31.0, -52.0, 20.0)
	_cliff_z(-52.0, -42.0, -5.5)
	_cliff_z(-52.0, 5.5, 31.0)
	_box(Vector3(-5.5, 0.01, -16.0), Vector3(70.0, 0.02, 70.0), FOREST, false)
	_zone(&"story_pass_forest", Vector3(0.0, 0.0, 14.0), Vector3(12.0, 4.0, 6.0))
	_tip(Vector3(-2.8, 2.4, 16.5), "AGACHARSE  {crouch}: casi no haces ruido\nPor la espalda, sin que te vean:\n{attack} = golpe mortal")
	# Rocas para esconderse.
	for at in [Vector3(-8, 0, 6), Vector3(6, 0, -2), Vector3(-18, 0, -8), Vector3(14, 0, -18),
			Vector3(-3, 0, -24), Vector3(-26, 0, -26), Vector3(20, 0, -36), Vector3(-12, 0, -40),
			Vector3(4, 0, -42), Vector3(24, 0, 4)]:
		_box(at + Vector3(0.0, 0.65, 0.0), Vector3(2.6, 1.3, 1.8), ROCK)
	for i in FOREST_PATH.size() - 1:
		_strip(FOREST_PATH[i], FOREST_PATH[i + 1], 2.6, PATH)
	_plant_trees()
	# El campamento de los cazadores (oeste): la despensa de la nota.
	var store := LatchedGate.new()
	store.name = "PoacherStore"
	store.gate_id = &"poacher_store"
	store.position = Vector3(-33.0, 0.0, -12.0)
	store.rotation.y = -PI * 0.5  # Puerta hacia el este.
	add_child(store)
	_cache(&"poacher_note", Vector3(-33.6, 0.0, -11.4), 150, &"poacher_note")
	_cache(&"forest_back", Vector3(26.5, 0.0, -47.5), 200)
	_box(Vector3(-28.5, 0.3, -9.0), Vector3(1.6, 0.6, 1.0), WOOD)  # Tronco donde se sentaban.
	_sign(Vector3(-29.0, 3.0, -12.0), "Campamento de los cazadores")
	# Fogata 2 (revisión del estudio): aquí, un poco fuera del sendero, parte en dos el tramo largo y premia
	# explorar. La del patio de Varga se quitó: desde la aldea, el atajo es la vuelta rápida a Varga.
	_campfire(Vector3(-26.5, 0.0, -15.0), "Campamento de los cazadores")
	# El bandido (esquiva y embiste) ya no está en el tutorial: guarda el escondite del fondo (opcional).
	var bandit := _enemy(BANDIT, Vector3(22.0, 0.0, -44.0), 135.0)
	bandit.aggro_range = 9.0
	bandit.set_meta("optional", true)
	# Centinelas desprevenidos (golpe por la espalda) y una patrulla.
	_sentry(Vector3(-14.0, 0.0, 2.0), 0.0)
	_sentry(Vector3(9.0, 0.0, -12.0), 90.0)
	_sentry(Vector3(-22.0, 0.0, -34.0), -90.0)
	var patrol := _sentry(Vector3(-4.0, 0.0, -18.0), 90.0)
	patrol.patrol_points = PackedVector3Array([Vector3(-4, 0, -18), Vector3(16, 0, -26), Vector3(16, 0, -6), Vector3(-4, 0, -6)])
	var archer := _enemy(ARCHER, Vector3(4.0, 1.4, -42.0), 180.0)  # Sobre la roca del fondo.
	archer.starts_unaware = true
	archer.display_name = "Centinela"
	# Grupo mixto al pie de la rampa de la fortaleza.
	_enemy(SOLDIER, Vector3(-3.0, 0.0, -46.0), 180.0)
	_enemy(SPEARMAN, Vector3(3.0, 0.0, -47.0), 180.0)


func _plant_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = TREE_SEED
	var spots: Array[Vector3] = []
	var tries: int = 0
	while spots.size() < 70 and tries < 2000:
		tries += 1
		var at := Vector3(rng.randf_range(-40.0, 29.0), 0.0, rng.randf_range(-50.0, 18.0))
		if absf(at.x) < 3.5 and at.z > 10.0:
			continue  # La entrada desde la aldea, despejada.
		if absf(at.x) < 4.5 and at.z < -38.0:
			continue  # La salida a la rampa.
		if at.distance_to(Vector3(-31.0, 0.0, -11.0)) < 6.0:
			continue  # El campamento de los cazadores.
		if _distance_to_path(at) < 2.8:
			continue  # El sendero.
		var near := false
		for other in spots:
			if other.distance_to(at) < 4.5:
				near = true
				break
		if not near:
			spots.append(at)
	var trunks := MultiMesh.new()
	trunks.transform_format = MultiMesh.TRANSFORM_3D
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.3
	trunk_mesh.bottom_radius = 0.4
	trunk_mesh.height = 7.0
	trunk_mesh.radial_segments = 8
	trunk_mesh.material = _mat(Color(0.3, 0.22, 0.15))
	trunks.mesh = trunk_mesh
	trunks.instance_count = spots.size()
	var crowns := MultiMesh.new()
	crowns.transform_format = MultiMesh.TRANSFORM_3D
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 2.4
	crown_mesh.height = 4.0
	crown_mesh.radial_segments = 10
	crown_mesh.rings = 5
	crown_mesh.material = _mat(Color(0.2, 0.32, 0.18))
	crowns.mesh = crown_mesh
	crowns.instance_count = spots.size()
	for i in spots.size():
		var at: Vector3 = spots[i]
		trunks.set_instance_transform(i, Transform3D(Basis(), at + Vector3.UP * 3.5))
		var s: float = rng.randf_range(0.85, 1.25)
		crowns.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), at + Vector3.UP * 6.8))
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = 0.4
		cylinder.height = 7.0
		shape.shape = cylinder
		shape.position = at + Vector3.UP * 3.5
		world.add_child(shape)
	for mm in [trunks, crowns]:
		var node := MultiMeshInstance3D.new()
		node.multimesh = mm
		add_child(node)


# --- D. Fortaleza (exterior) ---------------------------------------------------

func _build_fortress() -> void:
	# La rampa entre paredes de roca, del bosque a la meseta.
	_cliff_x(-5.5, -68.0, -52.0, 8.0)
	_cliff_x(5.5, -68.0, -52.0, 8.0)
	_ramp(Vector3(0.0, 0.0, -50.0), Vector3(0.0, FORT_Y, -68.0), 10.0, PATH)
	# La meseta (un bloque macizo) y sus muros.
	_box(Vector3(0.0, FORT_Y * 0.5, -108.5), Vector3(62.0, FORT_Y, 83.0), FORT.darkened(0.15))
	var top: float = FORT_Y
	_wall(Vector3(-17.5, top, -69.0), Vector3(25.0, 5.0, 1.0))
	_wall(Vector3(17.5, top, -69.0), Vector3(25.0, 5.0, 1.0))
	_wall(Vector3(-30.5, top, -109.0), Vector3(1.0, 5.0, 82.0))
	_wall(Vector3(0.0, top, -150.5), Vector3(62.0, 5.0, 1.0))
	# Muro este: con el hueco del atajo (z −86,8…−83,2) y el del pasillo de Varga (z −128…−122).
	_wall(Vector3(30.5, top, -76.0), Vector3(1.0, 5.0, 14.4))
	_wall(Vector3(30.5, top, -104.4), Vector3(1.0, 5.0, 35.2))
	_wall(Vector3(30.5, top, -139.5), Vector3(1.0, 5.0, 23.0))
	# Torres del portón, con arqueros arriba y una rampa por dentro.
	for side in [-1.0, 1.0]:
		var at := Vector3(side * 8.0, top, -73.0)
		_box(at + Vector3(0.0, 1.75, 0.0), Vector3(6.0, 3.5, 6.0), FORT)
		for x in [-1.0, 1.0]:
			_box(at + Vector3(x * 2.8, 4.0, 0.0), Vector3(0.4, 1.0, 6.0), FORT)
		_box(at + Vector3(0.0, 4.0, 2.8), Vector3(6.0, 1.0, 0.4), FORT)
		# La rampa entra 0,4 m en la torre: si acaba justo en el borde, queda una "grieta" (ver doc 09, lecciones).
		_ramp(at + Vector3(0.0, 0.0, -11.0), at + Vector3(0.0, 3.5, -2.6), 2.4, WOOD)
		var archer := _enemy(ARCHER, at + Vector3(0.0, 3.6, 0.5), 180.0)
		archer.aggro_range = 22.0
	_zone(&"story_pass_fortress", Vector3(0.0, top, -76.0), Vector3(10.0, 4.0, 6.0))
	# Patio de armas: un grupo y unos cajones.
	for at in [Vector3(-12, 0, -95), Vector3(10, 0, -100), Vector3(-4, 0, -112)]:
		_box(at + Vector3(0.0, top + 0.6, 0.0), Vector3(1.2, 1.2, 1.2), WOOD)
	_enemy(SOLDIER, Vector3(-6.0, top, -98.0), 180.0)
	_enemy(SPEARMAN, Vector3(5.0, top, -104.0), 180.0)
	# El lazareto (oeste) y su patio: aquí estará Bram.
	_box(Vector3(-20.0, top + 2.5, -132.0), Vector3(18.0, 5.0, 12.0), HOUSE)
	_box(Vector3(-20.0, top + 5.2, -132.0), Vector3(19.0, 0.4, 13.0), ROOF)
	_cloth(Vector3(-20.0, top + 1.2, -125.95), Vector3(2.0, 2.4, 0.05))
	_sign(Vector3(-20.0, top + 6.5, -132.0), "Lazareto")
	# Bram aún no existe (Hito 9, paso 5): que el cartel lo diga claro (aviso del jugador: "no está, ¿qué hago?").
	_sign(Vector3(-20.0, top + 2.6, -117.0), "Aquí luchará Bram, el Carcelero\n(aún no está hecho: llegará en el paso 5)\nSigue hacia el este, al patio de Varga")


# --- El atajo: portón este y sendero hasta la aldea -----------------------------

func _build_shortcut() -> void:
	var gate := LatchedGate.new()
	gate.name = "ShortcutGate"
	gate.gate_id = &"fortress_shortcut"
	gate.passage = true
	gate.position = SHORTCUT_AT
	gate.rotation.y = PI * 0.5  # Puerta hacia el oeste (el patio de la fortaleza).
	add_child(gate)
	# Rellano al otro lado del portón, a la altura de la meseta, y rampa que baja hacia el sur.
	_box(Vector3(37.0, FORT_Y * 0.5, -86.0), Vector3(12.0, FORT_Y, 10.0), FORT.darkened(0.25))
	_ramp(Vector3(40.0, FORT_Y, -81.0), Vector3(40.0, 0.0, -57.0), 7.0, PATH)
	_cliff_x(31.5, -81.0, 20.0, 9.0)
	_cliff_x(44.0, -91.0, 44.0, 9.0)
	_cliff_z(-91.0, 31.0, 44.0, 9.0)
	_cliff_z(44.0, 36.0, 44.0)
	_box(Vector3(40.0, 0.01, -8.0), Vector3(7.0, 0.02, 98.0), PATH, false)
	# El arroyo que baja junto al sendero (solo de vista; su rumor lo pone Ambience).
	_box(Vector3(42.9, 0.025, -6.0), Vector3(1.0, 0.02, 94.0), Color(0.28, 0.36, 0.42), false)


# --- E. Patio de Varga ---------------------------------------------------------

func _build_arena() -> void:
	# Bloque macizo bajo el patio y el pasillo (que no flote) y el tramo que lo une a la meseta.
	_box(Vector3(ARENA_AT.x - 6.5, FORT_Y * 0.5 - 0.01, ARENA_AT.z), Vector3(47.0, FORT_Y, 34.0), FORT.darkened(0.3))
	for side in [-1.0, 1.0]:  # Paredes del tramo entre el muro y el pasillo.
		_box(Vector3(32.0, FORT_Y + 1.5, ARENA_AT.z + side * 3.25), Vector3(2.0, 3.0, 0.5), FORT)
	var arena := VargaArena.new()
	arena.name = "VargaArena"
	arena.position = ARENA_AT
	arena.with_campfire = false  # La fogata 2 está en el bosque (campamento de los cazadores).
	add_child(arena)


# --- Piezas ---------------------------------------------------------------------

func _mat(color: Color) -> StandardMaterial3D:
	if _materials.has(color):
		return _materials[color]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[color] = m
	return m


func _exit_tree() -> void:
	Squad.sleep_distance = 0.0
	Squad.update_sleep()


## Caja con colisión (en el cuerpo `world`), o solo de vista.
func _box(at: Vector3, size: Vector3, color: Color, collide: bool = true, basis: Basis = Basis()) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _mat(color)
	mesh.mesh = box
	mesh.transform = Transform3D(basis, at)
	add_child(mesh)
	if collide:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		shape.transform = Transform3D(basis, at)
		world.add_child(shape)


## Farolillo en un poste: marca el camino principal.
func _lantern(at: Vector3) -> void:
	_box(at + Vector3(0.0, 1.1, 0.0), Vector3(0.14, 2.2, 0.14), WOOD)
	var lamp := MeshInstance3D.new()
	lamp.add_to_group("lanterns")
	var sphere := SphereMesh.new()
	sphere.radius = 0.17
	sphere.height = 0.34
	sphere.radial_segments = 8
	sphere.rings = 4
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.7, 0.35)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.62, 0.25)
	glow.emission_energy_multiplier = 3.0
	sphere.material = glow
	lamp.mesh = sphere
	lamp.position = at + Vector3(0.0, 2.35, 0.0)
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lamp)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.68, 0.35)
	light.light_energy = 1.3
	light.omni_range = 6.0
	light.shadow_enabled = false
	light.position = at + Vector3(0.0, 2.3, 0.0)
	add_child(light)


## Franja plana de suelo (de vista) de `a` a `b`.
func _strip(a: Vector3, b: Vector3, width: float, color: Color) -> void:
	var run: Vector3 = b - a
	var basis := Basis(Vector3.UP, atan2(run.x, run.z))
	_box((a + b) * 0.5 + Vector3.UP * 0.015, Vector3(width, 0.02, run.length() + width * 0.5), color, false, basis)


## Distancia (en el suelo) de `at` al sendero del bosque.
func _distance_to_path(at: Vector3) -> float:
	var best: float = INF
	var p := Vector2(at.x, at.z)
	for i in FOREST_PATH.size() - 1:
		var a := Vector2(FOREST_PATH[i].x, FOREST_PATH[i].z)
		var b := Vector2(FOREST_PATH[i + 1].x, FOREST_PATH[i + 1].z)
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return best


## Pared de roca a lo largo de Z (en x), de z0 a z1.
func _cliff_x(x: float, z0: float, z1: float, height: float = 7.0) -> void:
	_box(Vector3(x, height * 0.5, (z0 + z1) * 0.5), Vector3(1.0, height, absf(z1 - z0)), CLIFF)


## Pared de roca a lo largo de X (en z), de x0 a x1.
func _cliff_z(z: float, x0: float, x1: float, height: float = 7.0) -> void:
	_box(Vector3((x0 + x1) * 0.5, height * 0.5, z), Vector3(absf(x1 - x0), height, 1.0), CLIFF)


## Muro de la fortaleza apoyado en `at` (la base).
func _wall(at: Vector3, size: Vector3) -> void:
	_box(at + Vector3(0.0, size.y * 0.5, 0.0), size, FORT)


## Rampa recta de `from` (abajo, centro) a `to` (arriba, centro).
func _ramp(from: Vector3, to: Vector3, width: float, color: Color) -> void:
	var run: Vector3 = to - from
	var length: float = run.length()
	var forward: Vector3 = run / length
	var side: Vector3 = forward.cross(Vector3.UP).normalized()
	var up: Vector3 = side.cross(forward)
	var basis := Basis(side, up, -forward)
	_box((from + to) * 0.5 - up * 0.2, Vector3(width, 0.4, length), color, true, basis)


func _cylinder(at: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.material = _mat(color)
	mesh.mesh = cylinder
	mesh.position = at
	add_child(mesh)
	var shape := CollisionShape3D.new()
	var cylinder_shape := CylinderShape3D.new()
	cylinder_shape.radius = radius
	cylinder_shape.height = height
	shape.shape = cylinder_shape
	shape.position = at
	world.add_child(shape)


## Bola sin colisión (el humo de la hoguera).
func _ball(at: Vector3, radius: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	sphere.material = _mat(color)
	mesh.mesh = sphere
	mesh.position = at
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)


## Casa maciza de 6 × 3,5 × 6 m con tejado a dos aguas (de vista); la puerta mira al camino (+X o −X).
func _house(at: Vector3, yaw: float, quarantine: bool) -> void:
	var basis := Basis(Vector3.UP, yaw)
	_box(at + Vector3(0.0, 1.75, 0.0), Vector3(6.0, 3.5, 6.0), HOUSE, true, basis)
	for side in [-1.0, 1.0]:
		var tilt := basis * Basis(Vector3.FORWARD, side * 0.6)
		_box(at + basis * Vector3(side * 1.55, 4.4, 0.0), Vector3(3.8, 0.25, 6.6), ROOF, false, tilt)
	# La puerta (o la tela gris) en la cara que da al centro de la aldea.
	var face: float = -1.0 if at.x > 0.0 else 1.0
	var door_at: Vector3 = at + basis * Vector3(face * 3.03, 1.1, 0.0)
	if quarantine:
		_cloth(door_at, Vector3(0.05, 2.2, 1.4), basis)
	else:
		_box(door_at, Vector3(0.05, 2.2, 1.2), Color(0.2, 0.15, 0.1), false, basis)


func _cloth(at: Vector3, size: Vector3, basis: Basis = Basis()) -> void:
	_box(at, size, CLOTH, false, basis)


func _sign(at: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 44
	label.outline_size = 12
	label.pixel_size = 0.006
	label.modulate = Color(1.0, 0.95, 0.85)
	add_child(label)


## Cartel del tutorial: solo se ve de cerca (que no se amontonen a lo lejos) y nombra los botones del mando o
## del teclado, según lo que use el jugador ({jump} → "A" o "Espacio"; ver InputSetup.LABELS).
func _tip(at: Vector3, template: String) -> void:
	_sign(at, tip_text(template))
	var label := get_child(get_child_count() - 1) as Label3D
	label.add_to_group("tutorial_tips")
	label.set_meta("template", template)
	label.visibility_range_end = 13.0
	label.visibility_range_end_margin = 2.0
	label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	InputSetup.device_changed.connect(func(_pad: bool) -> void: label.text = tip_text(template))


static func tip_text(template: String) -> String:
	var text: String = template
	for action in InputSetup.LABELS:
		text = text.replace("{%s}" % action, InputSetup.label(action))
	return text


## `setup` cambia valores del enemigo antes de que entre en el nivel (su repertorio se lee al aparecer).
func _enemy(scene: PackedScene, at: Vector3, facing_degrees: float, setup: Callable = Callable()) -> Enemy:
	var enemy := scene.instantiate() as Enemy
	enemy.position = at
	enemy.rotation.y = deg_to_rad(facing_degrees)
	if setup.is_valid():
		setup.call(enemy)
	add_child(enemy)
	return enemy


## Soldado desprevenido (se le puede rematar por la espalda).
func _sentry(at: Vector3, facing_degrees: float) -> Enemy:
	var enemy := SOLDIER.instantiate() as Enemy
	enemy.position = at
	enemy.rotation.y = deg_to_rad(facing_degrees)
	enemy.display_name = "Centinela"
	enemy.starts_unaware = true
	add_child(enemy)
	return enemy


func _campfire(at: Vector3, camp_name: String) -> Campfire:
	var fire := CAMPFIRE.instantiate() as Campfire
	fire.camp_name = camp_name
	fire.position = at
	add_child(fire)
	return fire


func _zone(event: StringName, at: Vector3, size: Vector3, act: int = 0) -> void:
	var zone := NarrationZone.new()
	zone.event = event
	zone.size = size
	zone.act = act
	zone.position = at
	add_child(zone)


func _cache(id: StringName, at: Vector3, xp: int, item: StringName = &"") -> void:
	var cache := HiddenCache.new()
	cache.cache_id = id
	cache.reward_xp = xp
	cache.reward_item = item
	cache.position = at
	add_child(cache)
