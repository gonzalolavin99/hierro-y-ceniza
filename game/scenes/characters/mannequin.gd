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
@export var ground_alignment_speed: float = 12.0

@onready var _bot: Node3D = $YBot
@onready var _skeleton: Skeleton3D = $YBot/Skeleton3D
@onready var _foot_grounding: FootGroundingModifier = $YBot/Skeleton3D/FootGrounding
@onready var _glint: Node3D = $YBot/Skeleton3D/RightHand/Sword/Glint

var _tree: AnimationTree
## Orientación base del modelo de Mixamo (girado 180°), guardada al iniciar.
var _bot_facing: Basis
var _loco_pos: Vector2 = Vector2.ZERO
var _loco_target: Vector2 = Vector2.ZERO
var _block: float = 0.0
var _block_target: float = 0.0
var _crouch: float = 0.0
var _crouch_target: float = 0.0
var _crouch_pos: Vector2 = Vector2.ZERO
var _crouch_pos_target: Vector2 = Vector2.ZERO
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
## Posición (en segundos de la animación) de la acción en curso.
var _action_time: float = 0.0
var _action_speed: float = 1.0
var _flinch_tween: Tween
var _danger_material: StandardMaterial3D
var _danger_mark: Label3D
var _danger_tween: Tween
## Desplazamiento acumulado de las animaciones (en el mundo) pendiente de aplicar.
var _root_motion: Vector3 = Vector3.ZERO


func _ready() -> void:
	_bot_facing = _bot.basis
	_paint()
	_glint.visible = false
	_build_danger_flash()
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
	_crouch = move_toward(_crouch, _crouch_target, delta / CROUCH_FADE)
	_crouch_pos = _crouch_pos.lerp(_crouch_pos_target, 1.0 - exp(-10.0 * delta))
	_tree.set("parameters/crouch_loco/blend_position", _crouch_pos)
	_tree.set("parameters/crouch_blend/blend_amount", smoothstep(0.0, 1.0, _crouch))
	_action = move_toward(_action, _action_target, delta / maxf(_action_fade, 0.01))
	_mix = move_toward(_mix, _mix_target, delta / maxf(_action_fade, 0.01))
	_tree.set("parameters/loco/blend_position", _loco_pos)
	_tree.set("parameters/block_blend/blend_amount", _block)
	# Curva en S: las mezclas arrancan y terminan despacio (sin tirones al empezar o acabar).
	_tree.set("parameters/act_mix/blend_amount", smoothstep(0.0, 1.0, _mix))
	_tree.set("parameters/act_blend/blend_amount", smoothstep(0.0, 1.0, _action))
	_update_shape(delta)
	_action_time += _action_speed * delta


# --- API -------------------------------------------------------------------------

## Velocidad real de pisada de cada animación de locomoción (tests/measure_locomotion.gd).
const WALK_SPEEDS: Dictionary = {"fwd": 0.99, "back": 0.90, "left": 1.00, "right": 1.11}
## Correr: medido en el juego con tests/anim_audit.gd (paso del pie apoyado ≈ 100 % del avance).
const RUN_SPEEDS: Dictionary = {"fwd": 4.9, "back": 2.5, "left": 2.35, "right": 3.5}
## Cuánto se puede acelerar caminar y frenar correr antes de mezclar los dos pasos.
const GAIT_STRETCH_UP: float = 1.5
const GAIT_STRETCH_DOWN: float = 0.6
## Distancia al centro del espacio de mezcla a la que están las animaciones de caminar.
const WALK_BLEND: float = 0.25
## Mezcla mínima al empezar una acción: más corta, el cuerpo "salta" de una pose a otra.
const MIN_ACTION_FADE: float = 0.08
## Caminar agachado: velocidad de pisada de cada dirección. Provisional (son las de caminar de pie
## mientras no estén las animaciones de Mixamo de caminar agachado; medir con measure_locomotion).
const CROUCH_SPEEDS: Dictionary = {"fwd": 0.99, "back": 0.90, "left": 1.00, "right": 1.11}
## Segundos que tarda en agacharse o levantarse.
const CROUCH_FADE: float = 0.3


## Locomoción. `local_velocity`: x = lateral (+ derecha), y = adelante; 1 = posición de las animaciones
## de correr en el espacio de mezcla. `time_scale` acelera las piernas.
func set_locomotion(local_velocity: Vector2, time_scale: float = 1.0) -> void:
	_loco_target = local_velocity.limit_length(1.0)
	if _tree:
		_tree.set("parameters/loco_speed/scale", time_scale)


func set_blocking(enabled: bool) -> void:
	_block_target = 1.0 if enabled else 0.0


## Agachado (sigilo): cambia la locomoción a la de caminar agachado.
func set_crouching(enabled: bool) -> void:
	_crouch_target = 1.0 if enabled else 0.0


func is_crouching() -> bool:
	return _crouch_target > 0.5


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
	_action_time = from
	_action_speed = speed
	_mix_target = 1.0 if _slot_b else 0.0
	if _action < 0.01:
		_mix = _mix_target
	_action_target = 1.0
	_action_fade = maxf(fade, MIN_ACTION_FADE)
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
	_action_speed = speed


func set_action_speed(speed: float) -> void:
	_shape_active = false
	_action_speed = speed
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
	play_action(anim, from, speed, MIN_ACTION_FADE)
	get_tree().create_timer(duration, false).timeout.connect(stop_action_if.bind(anim, 0.15))


## Inclina solo el cuerpo visual para acompañar el suelo sin girar la cápsula de colisión.
func align_to_ground(floor_normal: Vector3, grounded: bool, delta: float) -> void:
	_foot_grounding.grounded = grounded
	var normal_world: Vector3 = floor_normal.normalized() if grounded else Vector3.UP
	var normal_local: Vector3 = (global_basis.inverse() * normal_world).normalized()
	var forward: Vector3 = Vector3(0.0, 0.0, -1.0)
	forward -= normal_local * forward.dot(normal_local)
	if forward.length_squared() < 0.0001:
		forward = Vector3(0.0, 0.0, -1.0)
	forward = forward.normalized()
	var right: Vector3 = forward.cross(normal_local).normalized()
	var target_basis: Basis = Basis(right, normal_local, -forward).orthonormalized()
	# El modelo de Mixamo mira hacia +Z: hay que conservar su giro de 180° sobre la inclinación.
	target_basis = target_basis * _bot_facing
	var weight: float = 1.0 - exp(-ground_alignment_speed * delta)
	_bot.basis = _bot.basis.slerp(target_basis, weight)

## Elige la mezcla de caminar/correr y su velocidad de reproducción para que el pie apoyado
## avance exactamente lo que avanza el cuerpo (sin patinar), en cualquier dirección.
func update_locomotion(velocity: Vector3, facing: Vector3) -> void:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var right := facing.cross(Vector3.UP)
	var local := Vector2(flat.dot(right), flat.dot(facing))
	var speed: float = local.length()
	if speed < 0.05:
		set_locomotion(Vector2.ZERO, 1.0)
		_set_crouch_locomotion(Vector2.ZERO, 1.0)
		return
	var dir: Vector2 = local / speed
	# Agachado: un solo paso (caminar agachado), que se acelera si hace falta.
	var crouch_natural: float = _crouch_natural_speed(dir)
	_set_crouch_locomotion(dir * minf(speed / crouch_natural, 1.0), maxf(speed / crouch_natural, 1.0))
	var walk: float = natural_speed(dir, false)
	var run: float = natural_speed(dir, true)
	# Como un cuerpo real, elige un paso (caminar o correr) y ajusta su ritmo; solo mezcla los dos en
	# una franja estrecha, porque al tener ritmos distintos la mezcla deja los pies "a medias".
	var walk_top: float = walk * GAIT_STRETCH_UP
	var run_bottom: float = run * GAIT_STRETCH_DOWN
	var amount: float
	var time_scale: float = 1.0
	if speed <= walk:
		amount = WALK_BLEND * speed / walk
	elif speed <= walk_top:
		amount = WALK_BLEND
		time_scale = speed / walk
	elif speed < run_bottom:
		var f: float = (speed - walk_top) / (run_bottom - walk_top)
		amount = lerpf(WALK_BLEND, 1.0, f)
		time_scale = speed / lerpf(walk, run, f)
	else:
		amount = 1.0
		time_scale = speed / run
	set_locomotion(dir * amount, minf(time_scale, 2.4))


func _set_crouch_locomotion(position: Vector2, time_scale: float) -> void:
	_crouch_pos_target = position
	if _tree:
		_tree.set("parameters/crouch_speed/scale", minf(time_scale, 2.4))


static func _crouch_natural_speed(dir: Vector2) -> float:
	var forward: float = CROUCH_SPEEDS["fwd"] if dir.y >= 0.0 else CROUCH_SPEEDS["back"]
	var side: float = CROUCH_SPEEDS["right"] if dir.x >= 0.0 else CROUCH_SPEEDS["left"]
	var wy: float = absf(dir.y)
	var wx: float = absf(dir.x)
	return (forward * wy + side * wx) / maxf(wx + wy, 0.001)


## Velocidad (m/s) a la que pisan las animaciones de caminar o correr en una dirección local
## (x = derecha, y = adelante). Medido con tests/measure_locomotion.gd.
static func natural_speed(dir: Vector2, running: bool) -> float:
	var s: Dictionary = RUN_SPEEDS if running else WALK_SPEEDS
	var forward: float = s["fwd"] if dir.y >= 0.0 else s["back"]
	var side: float = s["right"] if dir.x >= 0.0 else s["left"]
	var wy: float = absf(dir.y)
	var wx: float = absf(dir.x)
	return (forward * wy + side * wx) / maxf(wx + wy, 0.001)


## Devuelve (y vacía) cuánto avanzó la animación desde la última llamada, en el mundo y en horizontal.
func consume_root_motion() -> Vector3:
	var motion := Vector3(_root_motion.x, 0.0, _root_motion.z)
	_root_motion = Vector3.ZERO
	return motion


## En qué segundo de su animación va la acción en curso.
func action_time() -> float:
	return _action_time


## Inclinación breve al recibir un golpe, alejándose de donde vino (reacción según dirección).
func flinch(from_direction: Vector3, strength: float = 1.0) -> void:
	var local := global_basis.inverse() * from_direction
	# El maniquí mira hacia -Z de su padre: golpe de frente = inclinarse hacia atrás.
	var tilt := Vector3(-local.z * 0.22, 0.0, local.x * 0.22) * strength
	if _flinch_tween:
		_flinch_tween.kill()
	_flinch_tween = create_tween()
	# 0,09 s: rápido, pero sin saltar de pose en uno o dos fotogramas.
	_flinch_tween.tween_property(self, "rotation", tilt, 0.09).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_flinch_tween.tween_property(self, "rotation", Vector3.ZERO, 0.35).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


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


## Aviso de ataque peligroso: destello ROJO en el filo y un "!" rojo sobre la cabeza.
## Más largo y llamativo que el destello blanco normal, para que se lea al instante.
func danger_flash() -> void:
	_glint.material_override = _danger_material
	_glint.visible = true
	_glint.scale = Vector3.ONE * 0.3
	_danger_mark.visible = true
	_danger_mark.modulate.a = 1.0
	_danger_mark.scale = Vector3.ONE * 0.6
	if _danger_tween:
		_danger_tween.kill()
	_danger_tween = create_tween()
	_danger_tween.tween_property(_glint, "scale", Vector3.ONE * 2.4, 0.1)
	_danger_tween.parallel().tween_property(_danger_mark, "scale", Vector3.ONE * 1.15, 0.12)
	_danger_tween.tween_property(_glint, "scale", Vector3.ONE * 0.1, 0.3)
	_danger_tween.parallel().tween_property(_danger_mark, "modulate:a", 0.0, 0.45).set_delay(0.25)
	_danger_tween.tween_callback(func() -> void:
		_glint.visible = false
		_glint.material_override = null
		_danger_mark.visible = false)


func is_danger_flash_visible() -> bool:
	return _danger_mark.visible


func _build_danger_flash() -> void:
	_danger_material = ((_glint.mesh as PrimitiveMesh).material as StandardMaterial3D).duplicate()
	_danger_material.albedo_color = Color(1.0, 0.12, 0.08)
	_danger_mark = Label3D.new()
	_danger_mark.text = "!"
	_danger_mark.font_size = 160
	_danger_mark.outline_size = 24
	_danger_mark.modulate = Color(1.0, 0.15, 0.1)
	_danger_mark.outline_modulate = Color(0.2, 0.0, 0.0, 0.8)
	_danger_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_danger_mark.no_depth_test = true
	_danger_mark.pixel_size = 0.004
	_danger_mark.position = Vector3(0.0, 2.35, 0.0)
	_danger_mark.visible = false
	add_child(_danger_mark)


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

	# Locomoción agachado (sigilo), que se mezcla con la normal según _crouch.
	var crouch := AnimationNodeBlendSpace2D.new()
	crouch.min_space = Vector2(-1, -1)
	crouch.max_space = Vector2(1, 1)
	for point in [
		[&"crouch_idle", Vector2.ZERO],
		[&"crouch_fwd", Vector2(0, 1)], [&"crouch_back", Vector2(0, -1)],
		[&"crouch_left", Vector2(-1, 0)], [&"crouch_right", Vector2(1, 0)],
	]:
		crouch.add_blend_point(_anim(point[0]), point[1], -1, point[0])
	bt.add_node(&"crouch_loco", crouch, Vector2(0, -200))
	bt.add_node(&"crouch_speed", AnimationNodeTimeScale.new(), Vector2(200, -200))
	bt.connect_node(&"crouch_speed", 0, &"crouch_loco")
	bt.add_node(&"crouch_blend", AnimationNodeBlend2.new(), Vector2(300, -100))
	bt.connect_node(&"crouch_blend", 0, &"loco_speed")
	bt.connect_node(&"crouch_blend", 1, &"crouch_speed")

	bt.add_node(&"block_anim", _anim(&"block_hold"), Vector2(0, 200))
	var block_blend := AnimationNodeBlend2.new()
	block_blend.filter_enabled = true
	for bone in UPPER_BODY:
		block_blend.set_filter_path(NodePath("Skeleton3D:mixamorig_" + bone), true)
	bt.add_node(&"block_blend", block_blend, Vector2(400, 100))
	bt.connect_node(&"block_blend", 0, &"crouch_blend")
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
	_tree.set("parameters/crouch_speed/scale", 1.0)
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
