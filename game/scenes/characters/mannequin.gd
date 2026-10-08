class_name Mannequin
extends Node3D
## Cuerpo animado (maniquí de Mixamo) con espada en la mano. Lo usan el jugador y los enemigos.
## Arma el árbol de animación por código:
##
##   locomoción (BlendSpace2D) ─┐
##                              ├─ guardia (solo torso y brazos) ─┐
##   guardia (block_hold) ──────┘                                 ├─ acción ─► salida
##   acción A / acción B (se cruzan entre sí para encadenar golpes) ┘
##
## Así las transiciones son mezclas suaves y no cortes bruscos.

const LIBRARY_PATH: String = "res://assets/animations/mixamo_library.res"

## Huesos que mueve la guardia (de la cintura para arriba).
const UPPER_BODY: Array[String] = [
	"Spine", "Spine1", "Spine2", "Neck", "Head",
	"LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand",
	"RightShoulder", "RightArm", "RightForeArm", "RightHand",
]

@export var body_color: Color = Color(0.55, 0.15, 0.12)
@export var joints_color: Color = Color(0.15, 0.13, 0.12)
## Qué tan rápido entran/salen las mezclas (por segundo).
@export var block_blend_speed: float = 12.0

@onready var _bot: Node3D = $YBot
@onready var _skeleton: Skeleton3D = $YBot/Skeleton3D
@onready var _glint: Node3D = $YBot/Skeleton3D/RightHand/Sword/Glint

var _tree: AnimationTree
var _loco_pos: Vector2 = Vector2.ZERO
var _loco_target: Vector2 = Vector2.ZERO
var _block: float = 0.0
var _block_target: float = 0.0
var _action: float = 0.0
var _action_target: float = 0.0
var _action_fade: float = 0.1
var _mix: float = 0.0  # 0 = slot A, 1 = slot B
var _mix_target: float = 0.0
var _slot_b: bool = false
var _action_name: StringName = &""
## Ritmo del ataque en curso (ver play_shaped).
var _shape_active: bool = false
var _shape_elapsed: float = 0.0
var _shape_seconds: float = 0.0
var _shape_base: float = 1.0
var _trail: SwordTrail
## Desplazamiento acumulado de las animaciones (en el mundo) pendiente de aplicar.
var _root_motion: Vector3 = Vector3.ZERO


func _ready() -> void:
	_paint()
	_glint.visible = false
	_trail = SwordTrail.new()
	_trail.base_node = $YBot/Skeleton3D/RightHand/Sword/Guard
	_trail.tip_node = _glint
	add_child(_trail)
	var player := _bot.get_node("AnimationPlayer") as AnimationPlayer
	if not ResourceLoader.exists(LIBRARY_PATH):
		push_warning("Falta %s: ejecuta tests/build_anim_library.gd" % LIBRARY_PATH)
		return
	player.add_animation_library(&"m", load(LIBRARY_PATH))
	_build_tree()


func _process(delta: float) -> void:
	if _tree == null:
		return
	_loco_pos = _loco_pos.lerp(_loco_target, 1.0 - exp(-10.0 * delta))
	_block = move_toward(_block, _block_target, block_blend_speed * delta)
	_action = move_toward(_action, _action_target, delta / maxf(_action_fade, 0.01))
	_mix = move_toward(_mix, _mix_target, delta / maxf(_action_fade, 0.01))
	_tree.set("parameters/loco/blend_position", _loco_pos)
	_tree.set("parameters/block_blend/blend_amount", _block)
	_tree.set("parameters/act_mix/blend_amount", _mix)
	_tree.set("parameters/act_blend/blend_amount", _action)
	_update_shape(delta)


# --- API -------------------------------------------------------------------------

## Locomoción. `local_velocity`: x = lateral (+ derecha), y = adelante, en múltiplos de la velocidad
## de carrera (1 = correr). `time_scale` acelera las piernas (p. ej. al esprintar).
func set_locomotion(local_velocity: Vector2, time_scale: float = 1.0) -> void:
	_loco_target = local_velocity.limit_length(1.0)
	if _tree:
		_tree.set("parameters/loco_speed/scale", time_scale)


func set_blocking(enabled: bool) -> void:
	_block_target = 1.0 if enabled else 0.0


## Reproduce una animación de acción (ataque, golpe recibido, salto…) sobre la locomoción.
## Empieza en `from` y avanza a `speed`. Si había otra acción, se mezclan durante `fade`.
func play_action(anim: StringName, from: float = 0.0, speed: float = 1.0, fade: float = 0.08) -> void:
	if _tree == null:
		return
	_shape_active = false
	_slot_b = not _slot_b if _action > 0.01 else false
	var slot: String = "b" if _slot_b else "a"
	(_tree.tree_root.get_node("anim_" + slot) as AnimationNodeAnimation).animation = &"m/" + anim
	_tree.set("parameters/seek_%s/seek_request" % slot, from)
	_tree.set("parameters/scale_%s/scale" % slot, speed)
	_mix_target = 1.0 if _slot_b else 0.0
	if _action < 0.01:
		_mix = _mix_target
	_action_target = 1.0
	_action_fade = fade
	_action_name = anim


## Igual que play_action, pero ajusta la velocidad para que el instante `impact` de la animación
## coincida con `seconds` desde ahora (sincroniza el golpe visual con el daño).
func play_timed(anim: StringName, from: float, impact: float, seconds: float, fade: float = 0.06) -> void:
	play_action(anim, from, clampf((impact - from) / maxf(seconds, 0.01), 0.4, 3.0), fade)


## Como play_timed pero con ritmo de esgrima: la preparación arranca lenta y acelera hasta un
## impacto seco (llega exactamente en `seconds`); después, un instante de "peso" antes de recuperar.
## La velocidad sigue v(u) = base·(0,35 + 1,3·u), cuya integral en [0,1] es 1: el impacto no se mueve.
func play_shaped(anim: StringName, from: float, impact: float, seconds: float, fade: float = 0.05) -> void:
	_shape_base = clampf((impact - from) / maxf(seconds, 0.01), 0.3, 3.0)
	play_action(anim, from, _shape_base * 0.35, fade)
	_shape_active = true
	_shape_elapsed = 0.0
	_shape_seconds = seconds


func _update_shape(delta: float) -> void:
	if not _shape_active:
		return
	_shape_elapsed += delta
	var u: float = _shape_elapsed / _shape_seconds
	var speed: float
	if u < 1.0:
		speed = _shape_base * (0.35 + 1.3 * u)
	else:
		# Tras el impacto: el filo "pesa" y frena, luego vuelve a velocidad normal.
		var after: float = _shape_elapsed - _shape_seconds
		speed = lerpf(_shape_base * 0.45, 1.0, clampf(after / 0.2, 0.0, 1.0))
		if after > 0.2:
			_shape_active = false
	_tree.set("parameters/scale_%s/scale" % ("b" if _slot_b else "a"), speed)


func set_action_speed(speed: float) -> void:
	_shape_active = false
	if _tree:
		_tree.set("parameters/scale_%s/scale" % ("b" if _slot_b else "a"), speed)


## Vuelve a la locomoción mezclando durante `fade` segundos.
## Estela del filo (solo durante el tajo).
func set_trail(enabled: bool) -> void:
	if _trail:
		_trail.emitting = enabled


func stop_action(fade: float = 0.2) -> void:
	set_trail(false)
	_action_target = 0.0
	_action_fade = fade
	_action_name = &""


## Detiene la acción solo si sigue siendo `anim` (para no cortar una acción más nueva).
func stop_action_if(anim: StringName, fade: float = 0.2) -> void:
	if _action_name == anim:
		stop_action(fade)


## Reproduce una acción corta y vuelve sola a la locomoción/guardia al cabo de `duration`.
func play_reaction(anim: StringName, duration: float, from: float = 0.0, speed: float = 1.0) -> void:
	play_action(anim, from, speed, 0.04)
	get_tree().create_timer(duration, false).timeout.connect(stop_action_if.bind(anim, 0.15))


## Ajusta la locomoción según la velocidad real del personaje.
## `facing`: hacia dónde mira; `reference_speed`: velocidad que corresponde a "correr" (1.0).
func update_locomotion(velocity: Vector3, facing: Vector3, reference_speed: float) -> void:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var right := facing.cross(Vector3.UP)
	var local := Vector2(flat.dot(right), flat.dot(facing)) / reference_speed
	var amount: float = local.length()
	# Las piernas se aceleran un poco al correr y más al esprintar, para que los pies no "patinen".
	var time_scale: float = lerpf(1.0, 1.3, clampf(amount, 0.0, 1.0)) * maxf(amount, 1.0)
	set_locomotion(local, minf(time_scale, 2.4))


## Devuelve (y vacía) cuánto avanzó la animación desde la última llamada, en el mundo y en horizontal.
func consume_root_motion() -> Vector3:
	var motion := Vector3(_root_motion.x, 0.0, _root_motion.z)
	_root_motion = Vector3.ZERO
	return motion


func current_action() -> StringName:
	return _action_name


## Destello en el filo antes de atacar (aviso, como en Sekiro).
func glint() -> void:
	_glint.visible = true
	_glint.scale = Vector3.ONE * 0.2
	var t := create_tween()
	t.tween_property(_glint, "scale", Vector3.ONE * 1.5, 0.08)
	t.tween_property(_glint, "scale", Vector3.ONE * 0.1, 0.16)
	t.tween_callback(func() -> void: _glint.visible = false)


# --- Construcción ----------------------------------------------------------------

func _build_tree() -> void:
	var bt := AnimationNodeBlendTree.new()

	var loco := AnimationNodeBlendSpace2D.new()
	loco.min_space = Vector2(-1, -1)
	loco.max_space = Vector2(1, 1)
	for point in [
		[&"idle", Vector2.ZERO],
		[&"walk_fwd", Vector2(0, 0.25)], [&"walk_back", Vector2(0, -0.25)],
		[&"walk_left", Vector2(-0.25, 0)], [&"walk_right", Vector2(0.25, 0)],
		[&"run_fwd", Vector2(0, 1)], [&"run_back", Vector2(0, -1)],
		[&"run_left", Vector2(-1, 0)], [&"run_right", Vector2(1, 0)],
	]:
		loco.add_blend_point(_anim(point[0]), point[1], -1, point[0])
	bt.add_node(&"loco", loco, Vector2(0, 0))
	bt.add_node(&"loco_speed", AnimationNodeTimeScale.new(), Vector2(200, 0))
	bt.connect_node(&"loco_speed", 0, &"loco")

	bt.add_node(&"block_anim", _anim(&"block_hold"), Vector2(0, 200))
	var block_blend := AnimationNodeBlend2.new()
	block_blend.filter_enabled = true
	for bone in UPPER_BODY:
		block_blend.set_filter_path(NodePath("Skeleton3D:mixamorig_" + bone), true)
	bt.add_node(&"block_blend", block_blend, Vector2(400, 100))
	bt.connect_node(&"block_blend", 0, &"loco_speed")
	bt.connect_node(&"block_blend", 1, &"block_anim")

	for slot in ["a", "b"]:
		bt.add_node(StringName("anim_" + slot), _anim(&"idle"), Vector2(0, 400 if slot == "a" else 600))
		bt.add_node(StringName("seek_" + slot), AnimationNodeTimeSeek.new(), Vector2(200, 400 if slot == "a" else 600))
		bt.add_node(StringName("scale_" + slot), AnimationNodeTimeScale.new(), Vector2(400, 400 if slot == "a" else 600))
		bt.connect_node(StringName("seek_" + slot), 0, StringName("anim_" + slot))
		bt.connect_node(StringName("scale_" + slot), 0, StringName("seek_" + slot))
	bt.add_node(&"act_mix", AnimationNodeBlend2.new(), Vector2(600, 500))
	bt.connect_node(&"act_mix", 0, &"scale_a")
	bt.connect_node(&"act_mix", 1, &"scale_b")

	bt.add_node(&"act_blend", AnimationNodeBlend2.new(), Vector2(800, 200))
	bt.connect_node(&"act_blend", 0, &"block_blend")
	bt.connect_node(&"act_blend", 1, &"act_mix")
	bt.connect_node(&"output", 0, &"act_blend")

	var root_motion_node := Node3D.new()
	root_motion_node.name = "RootMotion"
	_bot.add_child(root_motion_node)

	_tree = AnimationTree.new()
	_tree.name = "AnimationTree"
	_bot.add_child(_tree)
	_tree.anim_player = NodePath("../AnimationPlayer")
	_tree.root_motion_track = NodePath("RootMotion")
	_tree.mixer_applied.connect(_on_mixer_applied)
	_tree.tree_root = bt
	_tree.active = true
	_tree.set("parameters/loco_speed/scale", 1.0)
	_tree.set("parameters/scale_a/scale", 1.0)
	_tree.set("parameters/scale_b/scale", 1.0)


func _on_mixer_applied() -> void:
	# Pasar el avance de la animación del espacio del maniquí al mundo.
	_root_motion += _bot.global_basis * _tree.get_root_motion_position()


func _anim(anim_name: StringName) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = &"m/" + anim_name
	return node


func _paint() -> void:
	var surface := StandardMaterial3D.new()
	surface.albedo_color = body_color
	surface.roughness = 0.7
	var joints := StandardMaterial3D.new()
	joints.albedo_color = joints_color
	joints.roughness = 0.5
	for mesh in _skeleton.get_children():
		if mesh is MeshInstance3D:
			(mesh as MeshInstance3D).material_override = joints if String(mesh.name).contains("Joints") else surface
