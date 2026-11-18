class_name Villager
extends Node3D
## Aldeano (Paso 4.2): gente de la aldea que cuenta lo que pasa sin explicarlo. No pelea y no es un enemigo:
## no está en el grupo "enemies" (no se fija, ni lo ven las bombas ni Squad), no tiene Hurtbox (los tajos lo
## atraviesan) y tiene colisión para no atravesarlo. Cuando Kael pasa a menos de TALK_RANGE dice su frase una
## sola vez (Story "villager_<evento>", se guarda); tras vencer a Varga dice otra, también una vez (evento
## "<evento>_after", paso 4.5). Antes de Varga, la niña y la madre dicen además una frase según la promesa
## del prólogo (paso 4.6). La cabeza lo sigue con la mirada (como mucho 60°).
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


func _ready() -> void:
	add_to_group("villagers")
	_build()
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
	return StringName("villager_%s" % current_event())


## ¿Ya dijo la frase que toca ahora (o no tiene)?
func has_spoken() -> bool:
	return current_event() == &"" or Story.heard(story_flag())


## Promesa del prólogo: "stop", "end" o "" (sin elegir / partida antigua).
static func vow() -> String:
	if Story.heard(&"vow_stop"):
		return "stop"
	if Story.heard(&"vow_end"):
		return "end"
	return ""


## Frase extra según la promesa (paso 4.6): solo antes de Varga y después de la 1.ª frase. Vacío = no hay.
func vow_event() -> StringName:
	if event == &"" or vow() == "" or Story.heard(VargaArena.DEFEATED_FLAG):
		return &""
	if not Story.heard(StringName("villager_%s" % event)):
		return &""
	var e := StringName("%s_vow_%s" % [event, vow()])
	return e if VoiceLines.LINES[&"villager"].has(e) else &""


func vow_flag() -> StringName:
	return StringName("villager_%s_vow" % event)


## ¿Baja el dibujo? (la niña, tras su 1.ª frase, si Kael prometió acabar con ellos).
func _drawing_lowered() -> bool:
	return vow() == "end" and Story.heard(StringName("villager_%s" % event))


func _sync() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player


func _process(delta: float) -> void:
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
		var stick := CylinderMesh.new()
		stick.top_radius = 0.025
		stick.bottom_radius = 0.025
		stick.height = 1.3
		var s := _box(self, stick, StylePalette.WOOD, Vector3(0.32, 0.65, 0.18))
		s.rotation.x = 0.35
		var bristles := BoxMesh.new()
		bristles.size = Vector3(0.28, 0.12, 0.08)
		var b := _box(self, bristles, StylePalette.EARTH, Vector3(0.32, 0.06, 0.18))
		b.rotation.x = 0.35
	elif prop == &"drawing":
		var paper := BoxMesh.new()
		paper.size = Vector3(0.24, 0.17, 0.01)
		_paper = _box(self, paper, StylePalette.ASH, PAPER_UP * size)
	# Colisión (capa 1, mundo): no gira con la cabeza.
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = BODY_HEIGHT
	shape.shape = capsule
	shape.position.y = BODY_HEIGHT * 0.5
	wall.add_child(shape)
	add_child(wall)
