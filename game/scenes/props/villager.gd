class_name Villager
extends Node3D
## Aldeano (Paso 4.2): gente de la aldea que cuenta lo que pasa sin explicarlo. No pelea y no es un enemigo:
## no está en el grupo "enemies" (no se fija, ni lo ven las bombas ni Squad), no tiene Hurtbox (los tajos lo
## atraviesan) y tiene colisión para no atravesarlo. Cuando Kael pasa a menos de TALK_RANGE dice su frase una
## sola vez (Story "villager_<evento>", se guarda); tras vencer a Varga dice otra, también una vez (evento
## "<evento>_after", paso 4.5). Antes de Varga, la niña y la madre dicen además una frase según la promesa
## del prólogo (paso 4.6). La cabeza lo sigue con la mirada (como mucho 60°).
## Gestos (#29): la barrendera barre (la escoba se balancea siempre) y la madre tapa los ojos de su hija cuando
## Kael está cerca (`cover_eyes_of`).
## Con la promesa «Acabaré con ellos» se apartan hasta DODGE_DISTANCE cuando Kael pasa a menos de DODGE_RANGE y
## vuelven a más de RETURN_RANGE (#41); la hija copia a la madre. Solo visual, no se guarda.
## Se construye en código, con bloques de colores de StylePalette (el arte llega en el paso 7).

## Distancia en el suelo a la que habla.
const TALK_RANGE: float = 4.0
## Distancia a la que gira la cabeza hacia Kael.
const LOOK_RANGE: float = 7.0
## Giro máximo de la cabeza (unos 60°).
const HEAD_TURN_MAX: float = 1.05
const HEAD_TURN_SPEED: float = 4.0
## Altura de la colisión, igual para todos (Kael salta 1,5 m: así no se queda de pie sobre una cabeza).
const BODY_HEIGHT: float = 1.9
## Hoja del dibujo: en alto (mirándola) y bajada (paso 4.6, si Kael prometió «Acabaré con ellos»).
const PAPER_UP: Vector3 = Vector3(0.0, 0.85, 0.3)
const PAPER_DOWN: Vector3 = Vector3(0.0, 0.5, 0.24)
## Escoba (gesto de barrer, #29): balanceo de lado a lado alrededor de las manos.
const BROOM_SWING: float = 0.35  # rad, a cada lado
const BROOM_PERIOD: float = 1.2  # s por ciclo completo
## Punta de arriba del palo (donde lo agarra): misma posición que tenía el palo fijo.
const BROOM_GRIP: Vector3 = Vector3(0.32, 1.26, 0.40)
const BROOM_TILT: float = 0.35
## Tapar los ojos (#29): hombro y mano en reposo (en local, se multiplican por size; x lleva el signo del lado de la hija).
const SHOULDER: Vector3 = Vector3(0.2, 1.25, 0.0)
const HAND_REST: Vector3 = Vector3(0.24, 0.75, 0.08)
const HAND_SPEED: float = 1.5  # m/s
## Apartarse (#41, solo si Kael prometió «Acabaré con ellos»; también tras Varga). Distancias en el suelo.
const DODGE_RANGE: float = 1.8    # Kael más cerca que esto: se aparta
const RETURN_RANGE: float = 4.0   # Kael más lejos que esto: vuelve a su sitio
const DODGE_DISTANCE: float = 0.6 # cuánto se aparta como mucho
const DODGE_SPEED: float = 1.5    # m/s
## Radio de la colisión y holgura contra los muros.
const BODY_RADIUS: float = 0.3
const WALL_MARGIN: float = 0.05

## Evento en VoiceLines.LINES[&"villager"]. Vacío = no habla.
@export var event: StringName = &""
@export var robe: Color = StylePalette.EARTH
## Escala de lo que se ve (la colisión no cambia).
@export var size: float = 1.0
## Objeto que lleva: &"broom", &"drawing" o vacío.
@export var prop: StringName = &""

var _player: Player
var _head: Node3D
var _paper: MeshInstance3D
var _broom: Node3D
var _broom_time: float = 0.0
## Aldeano al que tapa los ojos (solo la madre). null = no hace el gesto.
var _covered: Villager
var _arm: Node3D
var _hand: MeshInstance3D
var _shoulder: Vector3
var _hand_rest: Vector3
var _hand_pos: Vector3
## Sitio original (global) y desplazamiento actual en el suelo (#41).
var _home: Vector3
var _dodge: Vector3 = Vector3.ZERO
var _dodge_goal: Vector3 = Vector3.ZERO
## La hija: copia el desplazamiento de su madre en vez de calcular el suyo. null = se mueve sola.
var _leader: Villager
var _wall: StaticBody3D


func _ready() -> void:
	add_to_group("villagers")
	_build()
	_home = global_position
	Story.changed.connect(_sync)
	_sync.call_deferred()


## Evento que toca ahora: tras vencer a Varga, el de "después" (<evento>_after). Vacío = no habla.
func current_event() -> StringName:
	if event == &"":
		return &""
	if Story.heard(VargaArena.DEFEATED_FLAG):
		return StringName("%s_after" % event)
	return event


func story_flag() -> StringName:
	return StoryMarks.villager(current_event())


## ¿Ya dijo la frase que toca ahora (o no tiene)?
func has_spoken() -> bool:
	return current_event() == &"" or Story.heard(story_flag())


## Promesa del prólogo: "stop", "end" o "" (sin elegir / partida antigua).
static func vow() -> String:
	if Story.heard(StoryMarks.VOW_STOP):
		return "stop"
	if Story.heard(StoryMarks.VOW_END):
		return "end"
	return ""


## Frase extra según la promesa (paso 4.6): solo antes de Varga y después de la 1.ª frase. Vacío = no hay.
func vow_event() -> StringName:
	if event == &"" or vow() == "" or Story.heard(VargaArena.DEFEATED_FLAG):
		return &""
	if not Story.heard(StoryMarks.villager(event)):
		return &""
	var e := StringName("%s_vow_%s" % [event, vow()])
	return e if VoiceLines.LINES[&"villager"].has(e) else &""


func vow_flag() -> StringName:
	return StoryMarks.villager_vow(event)


## ¿Baja el dibujo? (la niña, tras su 1.ª frase, si Kael prometió acabar con ellos).
func _drawing_lowered() -> bool:
	return vow() == "end" and Story.heard(StoryMarks.villager(event))


## La madre tapa los ojos de su hija cuando Kael está cerca (#29). Lo llama el nivel con las dos ya en el árbol.
func cover_eyes_of(other: Villager) -> void:
	_covered = other
	other._leader = self
	var side: float = -1.0 if to_local(other.global_position).x < 0.0 else 1.0
	_shoulder = Vector3(SHOULDER.x * side, SHOULDER.y, SHOULDER.z) * size
	_hand_rest = Vector3(HAND_REST.x * side, HAND_REST.y, HAND_REST.z) * size
	_hand_pos = _hand_rest
	_arm = Node3D.new()
	add_child(_arm)
	var arm := BoxMesh.new()
	arm.size = Vector3(0.07, 0.07, 1.0)
	_box(_arm, arm, robe, Vector3(0.0, 0.0, -0.5))
	var hand := BoxMesh.new()
	hand.size = Vector3(0.09, 0.09, 0.12)
	_hand = _box(self, hand, StylePalette.ASH, _hand_pos)
	_place_arm()


## Delante de la cara de la hija, un poco arriba (los ojos). Sigue a su cabeza, que también mira a Kael.
func _cover_point() -> Vector3:
	var h: Node3D = _covered._head
	var at: Vector3 = h.global_position + h.global_basis.z * (0.12 * _covered.size + 0.04) \
			+ Vector3.UP * 0.02 * _covered.size
	return to_local(at)


## Pone la mano en _hand_pos y estira el brazo del hombro a la mano.
func _place_arm() -> void:
	_hand.position = _hand_pos
	var dir: Vector3 = _hand_pos - _shoulder
	var length: float = dir.length()
	if length < 0.01:
		return
	# Si el brazo cuelga casi vertical, looking_at falla con up = UP: se usa otro eje (no se nota, la sección es cuadrada).
	var up: Vector3 = Vector3.UP if absf(dir.y / length) < 0.95 else Vector3.BACK
	var b := Basis.looking_at(dir, up)
	_arm.transform = Transform3D(b.scaled_local(Vector3(1.0, 1.0, length)), _shoulder)
	_hand.basis = b


## ¿Se aparta de Kael? Solo con la promesa «Acabaré con ellos» (#41; guion: «se apartan a su paso»).
static func wants_dodge() -> bool:
	return vow() == "end"


## Cuánto puede apartarse en la dirección `dir` (normalizada, plana) sin meterse en un muro.
## La madre mira también por su hija, para que ninguna entre en una casa.
func free_distance(dir: Vector3) -> float:
	var exclude: Array[RID] = [_wall.get_rid()]
	if _covered != null:
		exclude.append(_covered._wall.get_rid())
	var reach: float = _ray_reach(_home, dir, exclude)
	if _covered != null:
		reach = minf(reach, _ray_reach(_covered._home, dir, exclude))
	return reach


## Un rayo corto desde `start` en la dirección `dir` contra el mundo (capa 1; Kael está en la 2).
func _ray_reach(start: Vector3, dir: Vector3, exclude: Array[RID]) -> float:
	var from: Vector3 = start + Vector3.UP * BODY_HEIGHT * 0.5
	var to: Vector3 = from + dir * (DODGE_DISTANCE + BODY_RADIUS + WALL_MARGIN)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, exclude)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return DODGE_DISTANCE
	return minf(DODGE_DISTANCE, maxf(0.0, from.distance_to(hit.position) - BODY_RADIUS - WALL_MARGIN))


func _physics_process(delta: float) -> void:
	if _leader != null and is_instance_valid(_leader):
		# La hija sigue a su madre: mismo desplazamiento, así no se separan.
		global_position = _home + _leader._dodge
		return
	_dodge_goal = _dodge_target()
	_dodge = _dodge.move_toward(_dodge_goal, DODGE_SPEED * delta)
	global_position = _home + _dodge


## Hacia dónde apartarse ahora. Entre DODGE_RANGE y RETURN_RANGE se queda donde iba (sin temblar en el borde).
func _dodge_target() -> Vector3:
	if not wants_dodge() or _player == null or not is_instance_valid(_player) or _player.is_dead():
		return Vector3.ZERO
	var d: Vector3 = _player.global_position - global_position
	var flat := Vector2(d.x, d.z)
	if absf(d.y) >= 2.0 or flat.length() > RETURN_RANGE:
		return Vector3.ZERO
	if flat.length() >= DODGE_RANGE or flat.length() < 0.05:
		return _dodge_goal
	var away := Vector3(-flat.x, 0.0, -flat.y).normalized()
	return away * free_distance(away)


func _sync() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player


func _process(delta: float) -> void:
	# La escoba se mueve siempre, también sin Kael.
	if _broom != null:
		_broom_time = fmod(_broom_time + delta, BROOM_PERIOD)
		_broom.rotation.z = BROOM_SWING * sin(_broom_time * TAU / BROOM_PERIOD)
	if _player == null or not is_instance_valid(_player):
		return
	var d: Vector3 = _player.global_position - global_position
	var flat: float = Vector2(d.x, d.z).length()
	var near: bool = absf(d.y) < 2.0
	# La cabeza mira a Kael (la cara está en +Z local).
	var target: float = 0.0
	if flat <= LOOK_RANGE and near:
		var local: Vector3 = global_basis.inverse() * d
		target = clampf(atan2(local.x, local.z), -HEAD_TURN_MAX, HEAD_TURN_MAX)
	_head.rotation.y = move_toward(_head.rotation.y, target, HEAD_TURN_SPEED * delta)
	if _covered != null:
		# Misma condición que girar la cabeza: sube la mano si Kael está cerca, baja si se aleja.
		var cover: bool = flat <= LOOK_RANGE and near and is_instance_valid(_covered)
		var goal: Vector3 = _cover_point() if cover else _hand_rest
		_hand_pos = _hand_pos.move_toward(goal, HAND_SPEED * delta)
		_place_arm()
	if _paper != null:
		_paper.position = (PAPER_DOWN if _drawing_lowered() else PAPER_UP) * size
	if flat > TALK_RANGE or not near or _player.is_dead():
		return
	if get_tree().get_first_node_in_group("cutscene") != null:
		return
	# Primero la frase que toca (antes o después de Varga); luego, si hay, la de la promesa del prólogo.
	var say_event: StringName = &""
	var flag: StringName = &""
	if not has_spoken():
		say_event = current_event()
		flag = story_flag()
	elif vow_event() != &"" and not Story.heard(vow_flag()):
		say_event = vow_event()
		flag = vow_flag()
	else:
		return
	# Si no hay voz libre (habla el narrador u otro aldeano), no se marca y se reintenta al fotograma siguiente.
	if Voice.say(&"villager", say_event, global_position + Vector3.UP * 1.6):
		Story.mark_heard(flag)
		SaveGame.save(_player)


func _box(parent: Node3D, mesh: PrimitiveMesh, color: Color, at: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	mesh.material = StylePalette.material(color)
	m.mesh = mesh
	m.position = at
	parent.add_child(m)
	return m


func _build() -> void:
	var body := CapsuleMesh.new()
	body.radius = 0.26 * size
	body.height = 1.45 * size
	_box(self, body, robe, Vector3(0.0, 0.725 * size, 0.0))
	_head = Node3D.new()
	_head.position = Vector3(0.0, 1.6 * size, 0.0)
	add_child(_head)
	var face := SphereMesh.new()
	face.radius = 0.12 * size
	face.height = 0.24 * size
	_box(_head, face, StylePalette.ASH, Vector3.ZERO)
	# Capucha (guía de estilo: personajes tapados), retrasada para que la cara asome por +Z.
	var hood := SphereMesh.new()
	hood.radius = 0.155 * size
	hood.height = 0.31 * size
	_box(_head, hood, robe.darkened(0.2), Vector3(0.0, 0.02, -0.035) * size)
	if prop == &"broom":
		_broom = Node3D.new()
		_broom.position = BROOM_GRIP
		_broom.rotation.x = BROOM_TILT
		add_child(_broom)
		var stick := CylinderMesh.new()
		stick.top_radius = 0.025
		stick.bottom_radius = 0.025
		stick.height = 1.3
		_box(_broom, stick, StylePalette.WOOD, Vector3(0.0, -0.65, 0.0))
		var bristles := BoxMesh.new()
		bristles.size = Vector3(0.28, 0.12, 0.08)
		_box(_broom, bristles, StylePalette.EARTH, Vector3(0.0, -1.28, 0.0))
	elif prop == &"drawing":
		var paper := BoxMesh.new()
		paper.size = Vector3(0.24, 0.17, 0.01)
		_paper = _box(self, paper, StylePalette.ASH, PAPER_UP * size)
	# Colisión (capa 1, mundo): no gira con la cabeza.
	_wall = StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	shape.shape = capsule
	shape.position.y = BODY_HEIGHT * 0.5
	_wall.add_child(shape)
	add_child(_wall)
