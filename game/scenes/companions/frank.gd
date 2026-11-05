class_name Frank
extends Node3D
## Frank, el tití con rulos (guion §12, D22): el compañero de Kael. No habla, chilla; los subtítulos dicen
## lo que Kael entiende. Es un animal de verdad: no es un enemigo ni tiene nada sobrenatural.
## Todo él se construye en código con piezas sencillas y se anima por código (respira, mueve la cola,
## parpadea, mira, gesticula). Lo crea el jugador (Player._ready) y empieza oculto: hasta que Kael lo
## encuentra en la red (FrankSnare) no aparece. Después va siempre en el hombro izquierdo de Kael.
## Su estado se guarda en Story: STORY_MET (ya va con Kael) y STORY_FREED (Kael lo soltó; si pasó de
## largo, Frank lo siguió igual, ofendido).

enum Mode { HIDDEN, TRAPPED, GROUND, RUNNING, HOPPING, PERCHED }
enum Pose { IDLE, CLING, COVER_EYES, POINT, SAD, TOUCH_CURLS }

signal perched

const STORY_MET: StringName = &"frank_met"
const STORY_FREED: StringName = &"frank_freed"

const FUR := Color(0.58, 0.37, 0.2)
const FUR_DARK := Color(0.4, 0.24, 0.13)
const CURLS := Color(0.68, 0.38, 0.16)
const FACE := Color(0.93, 0.83, 0.68)
const HANDS := Color(0.22, 0.16, 0.12)
## Sobre el hombro: cuánto hacia el cuello (0 = articulación del brazo, 1 = cuello) y cuánto encima.
const PERCH_TOWARD_NECK: float = 0.3
const PERCH_HEIGHT: float = 0.065
const TAIL_SEGMENTS: int = 12
const TAIL_SEGMENT_LENGTH: float = 0.042
const RUN_SPEED: float = 8.0
const MOUTH_SIZE: Vector3 = Vector3(0.011, 0.005, 0.004)
## Rato (s) entre intentos de parlotear solo cuando va tranquilo en el hombro.
const IDLE_CHATTER_EVERY: Vector2 = Vector2(35.0, 70.0)

var mode: Mode = Mode.HIDDEN
var pose: Pose = Pose.IDLE
## Hacia dónde mira la cabeza (en el mundo); null = al frente.
var look_target: Variant = null
## Hacia dónde señala (pose POINT).
var point_direction: Vector3 = Vector3.FORWARD

var _player: Player
var _shoulder: Node3D
var _neck: Node3D
var _rig: Node3D
var _head: Node3D
var _mouth: MeshInstance3D
var _eyes: Array[Node3D] = []
var _arms: Array[Node3D] = []  # [izquierdo, derecho]
var _legs: Array[Node3D] = []
var _tail: Array[Node3D] = []
var _time: float = 0.0
var _blink_at: float = 2.0
var _blink_end: float = 0.0
var _talk_until: float = 0.0
var _shake_until: float = 0.0
var _flinch_until: float = 0.0
var _arm_angles: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]  # (x, z) actuales, suavizados
var _head_angles: Vector2 = Vector2.ZERO
# Salto: de `_hop_from` a lo que devuelva `_hop_target` (se recalcula: el hombro se mueve).
var _hop_from: Transform3D
var _hop_target: Callable
var _hop_elapsed: float = 0.0
var _hop_time: float = 0.6
var _hop_height: float = 0.8
var _hop_then: Mode = Mode.PERCHED
# Atrapado: sigue a este nodo (la red).
var _trap_anchor: Node3D
# Corriendo por el suelo hacia Kael.
var _run_then_hop: bool = true
var _next_idle_chatter: float = 40.0
var _last_health: float = -1.0
var _gesture_until: float = 0.0
## Quién decide cuándo habla (consejos, bromas, pistas).
var advisor: FrankAdvisor


func setup(player: Player) -> void:
	_player = player


func _ready() -> void:
	top_level = true
	_build()
	visible = false
	Voice.spoken.connect(_on_spoken)
	Story.changed.connect(sync_with_story)
	if _player:
		_shoulder = _player.body.bone_attachment("mixamorig_LeftArm")
		_neck = _player.body.bone_attachment("mixamorig_Neck")
		_player.health.changed.connect(_on_health_changed)
		_last_health = _player.health.current
		advisor = FrankAdvisor.new()
		advisor.name = "Advisor"
		advisor.setup(self, _player)
		add_child(advisor)
	sync_with_story.call_deferred()


## Coloca a Frank según la partida: en el hombro si ya lo conoció; si no, oculto (la red lo atrapa).
func sync_with_story() -> void:
	if Story.heard(STORY_MET):
		perch()
	elif mode == Mode.PERCHED:
		hide_away()


func is_with_kael() -> bool:
	return mode == Mode.PERCHED or mode == Mode.HOPPING or mode == Mode.RUNNING


# --- Órdenes -----------------------------------------------------------------------------

func hide_away() -> void:
	mode = Mode.HIDDEN
	visible = false


## Queda colgando dentro de la red (sigue al nodo `anchor`).
func trap(anchor: Node3D) -> void:
	_trap_anchor = anchor
	mode = Mode.TRAPPED
	pose = Pose.CLING
	visible = true


## Directo al hombro de Kael.
func perch() -> void:
	mode = Mode.PERCHED
	pose = Pose.IDLE
	_gesture_until = 0.0
	look_target = null
	visible = true
	if _shoulder:
		global_transform = perch_transform()
		reset_physics_interpolation()


## Salta desde donde esté hasta `target` (un Callable que devuelve el Transform3D de llegada).
func hop(target: Callable, seconds: float, height: float, then: Mode) -> void:
	_hop_from = global_transform.orthonormalized()
	_hop_target = target
	_hop_elapsed = 0.0
	_hop_time = seconds
	_hop_height = height
	_hop_then = then
	mode = Mode.HOPPING
	visible = true


func hop_to_shoulder(seconds: float = 0.55) -> void:
	hop(perch_transform, seconds, 0.7, Mode.PERCHED)


## Cae / salta al suelo en `at`, mirando hacia `facing`.
func hop_to_ground(at: Vector3, facing: Vector3, seconds: float = 0.5, height: float = 0.4) -> void:
	var target := Transform3D(_basis_facing(facing), at)
	hop(func() -> Transform3D: return target, seconds, height, Mode.GROUND)


## Corre por el suelo hasta Kael y le salta al hombro.
func run_to_kael(from: Vector3) -> void:
	global_position = from
	reset_physics_interpolation()
	mode = Mode.RUNNING
	pose = Pose.IDLE
	visible = true


## Gesto durante unos segundos (taparse los ojos, cabizbajo…); luego vuelve a estar tranquilo.
func gesture(which: Pose, seconds: float) -> void:
	pose = which
	_gesture_until = _time + seconds


## Sacudida de "perro mojado" (al caer de la red).
func shake(seconds: float = 0.7) -> void:
	_shake_until = _time + seconds


## Chilla un evento de Frank (VoiceLines[&"frank"]). Devuelve true si sonó.
func say(event: StringName) -> bool:
	return Voice.say(&"frank", event, head_position())


func head_position() -> Vector3:
	return _head.global_position if _head else global_position


## Dónde se sienta en el hombro de Kael (mirando hacia donde mira Kael).
func perch_transform() -> Transform3D:
	var arm: Vector3 = _shoulder.global_position
	var neck: Vector3 = _neck.global_position
	var inward: Vector3 = neck - arm
	inward.y = 0.0
	var at: Vector3 = arm + inward * PERCH_TOWARD_NECK + Vector3.UP * PERCH_HEIGHT
	var forward: Vector3 = -_player.model.global_basis.z
	# Un poco girado hacia fuera, como quien va sentado de lado.
	forward = forward.rotated(Vector3.UP, deg_to_rad(18.0))
	return Transform3D(_basis_facing(forward), at)


# --- Cada fotograma ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	if _gesture_until > 0.0 and _time >= _gesture_until:
		_gesture_until = 0.0
		if mode == Mode.PERCHED:
			pose = Pose.IDLE
	match mode:
		Mode.TRAPPED:
			if _trap_anchor:
				global_transform = _trap_anchor.global_transform.orthonormalized()
		Mode.PERCHED:
			if _shoulder:
				global_transform = perch_transform()
			_idle_chatter()
		Mode.HOPPING:
			_update_hop(delta)
		Mode.RUNNING:
			_update_run(delta)
	if visible:
		_animate(delta)


func _update_hop(delta: float) -> void:
	_hop_elapsed += delta
	var t: float = clampf(_hop_elapsed / _hop_time, 0.0, 1.0)
	var to: Transform3D = _hop_target.call()
	var at: Vector3 = _hop_from.origin.lerp(to.origin, t) + Vector3.UP * sin(t * PI) * _hop_height
	var turn: Basis = _hop_from.basis.slerp(to.basis.orthonormalized(), minf(t * 1.5, 1.0))
	global_transform = Transform3D(turn, at)
	if t >= 1.0:
		mode = _hop_then
		if mode == Mode.PERCHED:
			pose = Pose.IDLE
			perched.emit()


func _update_run(delta: float) -> void:
	var shoulder: Transform3D = perch_transform()
	var goal: Vector3 = shoulder.origin
	goal.y = _player.global_position.y
	var to: Vector3 = goal - global_position
	to.y = 0.0
	if to.length() < 1.1:
		hop_to_shoulder(0.45)
		return
	var step: Vector3 = to.normalized() * minf(RUN_SPEED * delta, to.length())
	global_position = Vector3(global_position.x + step.x, _player.global_position.y, global_position.z + step.z)
	global_basis = _basis_facing(to)


func _idle_chatter() -> void:
	if _time < _next_idle_chatter:
		return
	_next_idle_chatter = _time + randf_range(IDLE_CHATTER_EVERY.x, IDLE_CHATTER_EVERY.y)
	if advisor and advisor.is_quiet():
		return
	if _player and _player.lock_target == null and _player.state_machine.current.name == &"Ground":
		say(&"idle")


func _on_health_changed(current: float, _maximum: float) -> void:
	if _last_health >= 0.0 and current < _last_health and mode == Mode.PERCHED:
		_flinch_until = _time + 0.45
		say(&"scared")
	_last_health = current


func _on_spoken(speaker: StringName, _event: StringName, _id: String) -> void:
	if speaker == &"frank":
		_talk_until = _time + Voice.last_seconds


# --- Animación por código ------------------------------------------------------------------------

func _animate(delta: float) -> void:
	var talking: bool = _time < _talk_until
	var running: bool = mode == Mode.RUNNING
	# Respira y, si corre, va a saltitos.
	var bob: float = sin(_time * 3.2) * 0.004
	if running:
		bob = absf(sin(_time * 16.0)) * 0.07
	elif mode == Mode.TRAPPED:
		bob = sin(_time * 7.0) * 0.012  # Forcejea.
	_rig.position.y = bob
	# Sacudida tras caer de la red.
	var shake_left: float = _shake_until - _time
	_rig.rotation.y = sin(_time * 42.0) * 0.6 * clampf(shake_left / 0.7, 0.0, 1.0) if shake_left > 0.0 else 0.0
	# Agacharse del susto.
	var flinch: float = 1.0 if _time < _flinch_until else 0.0
	_rig.rotation.x = lerpf(_rig.rotation.x, -0.35 * flinch, minf(delta * 14.0, 1.0))
	# Brazos según la pose.
	var targets: Array[Vector2] = _pose_arms(pose if flinch == 0.0 else Pose.CLING)
	for i in 2:
		_arm_angles[i] = _arm_angles[i].lerp(targets[i], minf(delta * 10.0, 1.0))
		var swing: float = sin(_time * 16.0 + i * PI) * 0.6 if running else 0.0
		_arms[i].rotation = Vector3(_arm_angles[i].x + swing, 0.0, _arm_angles[i].y)
	for i in 2:
		_legs[i].rotation.x = 1.3 + (sin(_time * 16.0 + i * PI) * 0.7 if running else 0.0)
	# Cabeza: mira al objetivo; al hablar, cabecea deprisa; triste, cabizbajo.
	var aim: Vector2 = _head_aim()
	if pose == Pose.SAD:
		aim = Vector2(-0.45, aim.y * 0.3)
	if talking:
		aim += Vector2(sin(_time * 28.0) * 0.08, sin(_time * 13.0) * 0.06)
	_head_angles = _head_angles.lerp(aim, minf(delta * 9.0, 1.0))
	_head.rotation = Vector3(_head_angles.x, _head_angles.y, sin(_time * 1.1) * 0.06 if pose != Pose.TOUCH_CURLS else 0.25)
	_mouth.scale.y = MOUTH_SIZE.y * ((0.6 + absf(sin(_time * 30.0)) * 2.2) if talking else 0.4)
	# Parpadeo.
	if _time >= _blink_at:
		_blink_end = _time + 0.12
		_blink_at = _time + randf_range(2.5, 5.0)
	for eye in _eyes:
		eye.scale.y = 0.15 if _time < _blink_end else 1.0
	# Cola: cuelga hacia atrás, se mece y la punta se enrosca (triste: se la abraza).
	for i in _tail.size():
		var k: float = float(i) / float(_tail.size())
		var sway: float = sin(_time * 1.8 - i * 0.45) * (0.08 + 0.1 * k)
		var curl: float = -0.32 if i >= _tail.size() - 4 else 0.05
		if pose == Pose.SAD:
			curl = -0.25
		if running:
			sway = sin(_time * 16.0 - i * 0.6) * 0.15
			curl = 0.1
		_tail[i].rotation = Vector3(curl, 0.0, sway)


## Ángulos (x adelante/arriba, z hacia dentro/fuera) de los brazos [izquierdo, derecho] para cada pose.
func _pose_arms(which: Pose) -> Array[Vector2]:
	match which:
		Pose.CLING:
			return [Vector2(2.7, -0.45), Vector2(2.7, 0.45)]
		Pose.COVER_EYES:
			return [Vector2(2.35, 0.55), Vector2(2.35, -0.55)]
		Pose.POINT:
			return [Vector2(0.3, -0.1), Vector2(1.55, 0.0)]
		Pose.SAD:
			return [Vector2(0.9, 0.7), Vector2(0.9, -0.7)]
		Pose.TOUCH_CURLS:
			return [Vector2(0.35, -0.15), Vector2(2.9, -0.35)]
	return [Vector2(0.4, -0.15), Vector2(0.4, 0.15)]


## (inclinación, giro) de la cabeza hacia `look_target` o hacia donde señala.
func _head_aim() -> Vector2:
	var target: Variant = look_target
	if pose == Pose.POINT:
		target = head_position() + point_direction * 3.0
	if target == null:
		return Vector2(0.0, sin(_time * 0.37) * 0.35)  # Curioseando.
	var local: Vector3 = global_basis.inverse() * ((target as Vector3) - head_position())
	var yaw: float = clampf(atan2(-local.x, -local.z), -1.3, 1.3)
	var pitch: float = clampf(atan2(local.y, Vector2(local.x, local.z).length()), -0.6, 0.6)
	return Vector2(pitch, yaw)


static func _basis_facing(direction: Vector3) -> Basis:
	direction.y = 0.0
	if direction.length() < 0.001:
		return Basis.IDENTITY
	return Basis.looking_at(direction.normalized(), Vector3.UP)


# --- Construcción (piezas simples) --------------------------------------------------------------

func _build() -> void:
	var fur: StandardMaterial3D = _material(FUR)
	var fur_dark: StandardMaterial3D = _material(FUR_DARK)
	var face: StandardMaterial3D = _material(FACE)
	var hands: StandardMaterial3D = _material(HANDS)
	var curls: StandardMaterial3D = _material(CURLS)
	var eye_mat: StandardMaterial3D = _material(Color(0.04, 0.03, 0.03))
	eye_mat.roughness = 0.15
	eye_mat.metallic_specular = 0.9
	var glint := StandardMaterial3D.new()
	glint.albedo_color = Color.WHITE
	glint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)
	# Cuerpo (un huevo sentado) y la barriga clara.
	_rig.add_child(_ball(Vector3(0.0, 0.095, 0.01), Vector3(0.07, 0.095, 0.065), fur))
	_rig.add_child(_ball(Vector3(0.0, 0.09, -0.03), Vector3(0.05, 0.07, 0.04), face))
	# Patas dobladas (sentado) con los pies oscuros.
	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(0.04 * side, 0.05, -0.01)
		_rig.add_child(hip)
		hip.add_child(_ball(Vector3(0.0, -0.035, 0.0), Vector3(0.026, 0.045, 0.026), fur))
		hip.add_child(_ball(Vector3(0.0, -0.075, -0.012), Vector3(0.02, 0.012, 0.03), hands))
		_legs.append(hip)
	# Brazos: pivote en el hombro, el brazo cuelga hacia -Y.
	for side in [-1.0, 1.0]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(0.055 * side, 0.16, -0.01)
		_rig.add_child(shoulder)
		shoulder.add_child(_ball(Vector3(0.0, -0.045, 0.0), Vector3(0.017, 0.05, 0.017), fur))
		shoulder.add_child(_ball(Vector3(0.0, -0.095, 0.0), Vector3(0.016, 0.014, 0.016), hands))
		_arms.append(shoulder)
	# Cabeza: redonda, cara clara, ojos grandes con brillo, orejitas y los rulos.
	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.0, 0.215, -0.005)
	_rig.add_child(_head)
	_head.add_child(_ball(Vector3.ZERO, Vector3(0.062, 0.058, 0.06), fur))
	_head.add_child(_ball(Vector3(0.0, -0.012, -0.04), Vector3(0.045, 0.04, 0.03), face))
	_head.add_child(_ball(Vector3(0.0, -0.026, -0.064), Vector3(0.024, 0.018, 0.016), face))
	_head.add_child(_ball(Vector3(0.0, -0.018, -0.079), Vector3(0.008, 0.005, 0.004), hands))  # Nariz.
	_mouth = _ball(Vector3(0.0, -0.036, -0.075), MOUTH_SIZE, hands)
	_head.add_child(_mouth)
	for side in [-1.0, 1.0]:
		var eye := Node3D.new()
		eye.position = Vector3(0.023 * side, 0.004, -0.058)
		_head.add_child(eye)
		eye.add_child(_ball(Vector3.ZERO, Vector3(0.0155, 0.0165, 0.012), eye_mat))
		eye.add_child(_ball(Vector3(0.005 * side, 0.006, -0.009), Vector3(0.0045, 0.0045, 0.003), glint))
		_eyes.append(eye)
		_head.add_child(_ball(Vector3(0.058 * side, 0.004, 0.005), Vector3(0.012, 0.018, 0.008), fur_dark))
	_build_curls(curls)
	# Cola: cadena de articulaciones que nace detrás, abajo.
	var parent: Node3D = _rig
	var base := Node3D.new()
	base.position = Vector3(0.0, 0.04, 0.06)
	base.rotation.x = -1.0  # Hacia atrás y abajo.
	_rig.add_child(base)
	parent = base
	for i in TAIL_SEGMENTS:
		var joint := Node3D.new()
		if i > 0:
			joint.position = Vector3(0.0, -TAIL_SEGMENT_LENGTH, 0.0)
		parent.add_child(joint)
		var radius: float = lerpf(0.013, 0.008, float(i) / TAIL_SEGMENTS)
		joint.add_child(_ball(Vector3(0.0, -TAIL_SEGMENT_LENGTH * 0.5, 0.0),
			Vector3(radius, TAIL_SEGMENT_LENGTH * 0.62, radius), fur_dark if i >= TAIL_SEGMENTS - 3 else fur))
		_tail.append(joint)
		parent = joint


## Rulos: anillitos (toros) sobre la coronilla, la nuca y los lados; ninguno en la cara.
func _build_curls(material: StandardMaterial3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var torus := TorusMesh.new()
	torus.inner_radius = 0.006
	torus.outer_radius = 0.016
	torus.rings = 10
	torus.ring_segments = 6
	torus.material = material
	var placed: int = 0
	while placed < 22:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.1, 1), rng.randf_range(-0.55, 1)).normalized()
		if dir.z < -0.3 and dir.y < 0.6:
			continue  # Deja la cara despejada.
		var curl := MeshInstance3D.new()
		curl.mesh = torus
		curl.position = Vector3(dir.x * 0.06, dir.y * 0.056 + 0.006, dir.z * 0.058)
		var up: Vector3 = dir.cross(Vector3(rng.randf(), rng.randf(), rng.randf()).normalized()).normalized()
		curl.basis = Basis(up, dir, up.cross(dir)).orthonormalized().scaled(Vector3.ONE * rng.randf_range(0.8, 1.15))
		curl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_head.add_child(curl)
		placed += 1


func _ball(at: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.material = material
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.scale = radii
	return part


static func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	return m
