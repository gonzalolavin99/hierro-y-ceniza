class_name Deserter
extends Node3D
## El desertor (Paso 4.3): un soldado de Varga que, al acercarse Kael, suelta la espada, se arrodilla y dice
## una frase (una sola vez por partida). NO es un enemigo: no está en el grupo "enemies" (no se fija, ni lo ven
## Squad, las bombas ni la alarma de los soldados, ni cuenta como enemigo obligatorio entre fogatas). Tiene
## colisión para no atravesarlo y un Hurtbox para que Kael pueda golpearlo (muere y no vuelve).
## Todo se apunta en Story (se guarda): "deserter_surrendered", "deserter_spared" y "deserter_killed".
## Si Kael se aleja sin golpearlo queda perdonado y, tras el siguiente descanso (Camps.reset_world), aparece
## junto al pozo con un cubo, quieto y en silencio. No hay carteles ni avisos: solo cambia el mundo.

const MANNEQUIN: PackedScene = preload("res://scenes/characters/mannequin.tscn")
## El mismo gris azulado de los soldados de la aldea (training_soldier.tscn).
const SOLDIER_COLOR := Color(0.4, 0.42, 0.45)
## Distancias en el suelo, en metros.
const SURRENDER_RANGE: float = 6.0
const SPARE_RANGE: float = 20.0
const LINE_RANGE: float = 10.0
## Dónde se pone junto al pozo (casa del pozo, oeste) y hacia dónde mira.
const WELL_SPOT := Vector3(-19.5, 0.0, 28.5)
const WELL_CENTER := Vector3(-17.0, 0.0, 30.0)
const BODY_HEIGHT: float = 1.9

const STORY_SURRENDERED: StringName = &"deserter_surrendered"
const STORY_SPARED: StringName = &"deserter_spared"
const STORY_KILLED: StringName = &"deserter_killed"

var body: Mannequin

var _player: Player
var _hand_sword: Node3D
var _ground_sword: Node3D
var _bucket: Node3D
var _wall_shape: CollisionShape3D
var _hurt_shape: CollisionShape3D
var _hurtbox: Hurtbox
var _post: Transform3D
var _dead: bool = false
var _pending_line: bool = false
var _tween: Tween


func _ready() -> void:
	add_to_group("deserters")
	_post = global_transform
	_build()
	Story.changed.connect(_sync)
	_sync.call_deferred()


## ¿Lo perdonó Kael (y no lo mató después)? La variable del final bueno.
static func is_spared() -> bool:
	return Story.heard(STORY_SPARED) and not Story.heard(STORY_KILLED)


func _build() -> void:
	body = MANNEQUIN.instantiate() as Mannequin
	body.body_color = SOLDIER_COLOR
	add_child(body)
	_hand_sword = body.get_node("YBot/Skeleton3D/RightHand/Sword") as Node3D
	# La espada caída: hoja y empuñadura sueltas, en coordenadas del mundo (no sigue al desertor).
	_ground_sword = Node3D.new()
	_ground_sword.top_level = true
	_ground_sword.visible = false
	add_child(_ground_sword)
	_box(_ground_sword, Vector3(0.04, 1.05, 0.09), StylePalette.STEEL, Vector3.ZERO)
	_box(_ground_sword, Vector3(0.035, 0.32, 0.035), StylePalette.LEATHER, Vector3(0.0, -0.68, 0.0))
	# El cubo del pozo.
	var bucket_mesh := CylinderMesh.new()
	bucket_mesh.top_radius = 0.17
	bucket_mesh.bottom_radius = 0.14
	bucket_mesh.height = 0.3
	bucket_mesh.material = StylePalette.material(StylePalette.WOOD)
	var bucket := MeshInstance3D.new()
	bucket.mesh = bucket_mesh
	bucket.position = Vector3(0.35, 0.15, -0.35)
	bucket.visible = false
	add_child(bucket)
	_bucket = bucket
	# Colisión (capa 1, mundo), como la de Villager.
	var wall := StaticBody3D.new()
	_wall_shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = BODY_HEIGHT
	_wall_shape.shape = capsule
	_wall_shape.position.y = BODY_HEIGHT * 0.5
	wall.add_child(_wall_shape)
	add_child(wall)
	# Zona de golpes (capa 16: la que golpean la espada y la ballesta de Kael). `target` va antes de add_child.
	_hurtbox = Hurtbox.new()
	_hurtbox.target = self
	_hurtbox.collision_layer = 16
	_hurtbox.collision_mask = 0
	_hurt_shape = CollisionShape3D.new()
	var hurt_capsule := CapsuleShape3D.new()
	hurt_capsule.radius = 0.4
	hurt_capsule.height = BODY_HEIGHT
	_hurt_shape.shape = hurt_capsule
	_hurt_shape.position.y = BODY_HEIGHT * 0.5
	_hurtbox.add_child(_hurt_shape)
	add_child(_hurtbox)


func _box(parent: Node3D, size: Vector3, color: Color, at: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = StylePalette.material(color)
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = at
	parent.add_child(m)


## Partida nueva o cargada (from_dict emite "changed" dos veces: no debe tener efectos raros al repetirse).
func _sync() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_dead = false
	_pending_line = false
	if Story.heard(STORY_KILLED):
		_vanish()
		return
	_set_present(true)
	if Story.heard(STORY_SPARED):
		_go_to_well()
	elif Story.heard(STORY_SURRENDERED):
		_kneel_at_post()
	else:
		_stand_at_post()


func _set_present(on: bool) -> void:
	visible = on
	set_process(on)
	# Ocultarlo no apaga la física: se desactivan las formas.
	_wall_shape.set_deferred("disabled", not on)
	_hurt_shape.set_deferred("disabled", not on)


func _vanish() -> void:
	_set_present(false)


func _stand_at_post() -> void:
	global_transform = _post
	reset_physics_interpolation()
	_hand_sword.visible = true
	_ground_sword.visible = false
	_bucket.visible = false
	body.stop_action(0.0)


func _kneel_at_post() -> void:
	global_transform = _post
	reset_physics_interpolation()
	_hand_sword.visible = false
	_ground_sword.global_transform = _fallen_sword(rotation.y)
	_ground_sword.visible = true
	_bucket.visible = false
	body.play_action(&"kneel", 0.0, 1.0, 0.0)


func _go_to_well() -> void:
	global_position = WELL_SPOT
	var to: Vector3 = WELL_CENTER - WELL_SPOT
	rotation.y = atan2(-to.x, -to.z)
	reset_physics_interpolation()
	_hand_sword.visible = false
	_bucket.visible = true
	# La espada se queda donde cayó (si ya cayó; si no, en su puesto).
	if not _ground_sword.visible:
		_ground_sword.global_transform = _fallen_sword(_post.basis.get_euler().y, _post.origin)
		_ground_sword.visible = true
	body.stop_action(0.2)


## Espada tumbada en el suelo, delante del desertor según hacia dónde mire (`yaw`).
func _fallen_sword(yaw: float, from: Vector3 = Vector3.INF) -> Transform3D:
	var origin: Vector3 = global_position if from == Vector3.INF else from
	var ahead := Vector3(-sin(yaw), 0.0, -cos(yaw))
	return Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI / 2.0), origin + ahead * 0.7 + Vector3.UP * 0.03)


func _process(_delta: float) -> void:
	if _dead or _player == null or not is_instance_valid(_player) or _player.is_dead():
		return
	var d: Vector3 = _player.global_position - global_position
	var flat: float = Vector2(d.x, d.z).length()
	var near: bool = absf(d.y) < 2.0
	# Rendirse.
	if not Story.heard(STORY_SURRENDERED):
		if flat <= SURRENDER_RANGE and near and get_tree().get_first_node_in_group("cutscene") == null:
			_surrender(d)
		return
	# La frase, una sola vez: si no hay voz libre se reintenta; si Kael se aleja, se pierde.
	if _pending_line:
		if flat > LINE_RANGE:
			_pending_line = false
		elif Voice.say(&"soldier", &"surrender", global_position + Vector3.UP * 1.0):
			_pending_line = false
	# Perdonado: Kael se fue sin golpearlo. No se mueve hasta el próximo reinicio del mundo.
	if not Story.heard(STORY_SPARED) and not Story.heard(STORY_KILLED) and flat > SPARE_RANGE:
		Story.mark_heard(STORY_SPARED)
		SaveGame.save(_player)


func _surrender(d: Vector3) -> void:
	Story.mark_heard(STORY_SURRENDERED)
	SaveGame.save(_player)
	var yaw: float = rotation.y + wrapf(atan2(-d.x, -d.z) - rotation.y, -PI, PI)
	# Suelta la espada: cae de la mano al suelo, delante de él (ya mirando a Kael).
	_ground_sword.global_transform = _hand_sword.global_transform
	_ground_sword.visible = true
	_hand_sword.visible = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "rotation:y", yaw, 0.3)
	_tween.tween_property(_ground_sword, "global_transform", _fallen_sword(yaw), 0.35).set_ease(Tween.EASE_IN)
	body.play_action(&"kneel", 0.0, 1.0, 0.35)
	_pending_line = true


## Lo llama Hurtbox.receive (golpe de la espada o el virote de Kael).
func receive_hit(hit: HitData) -> int:
	if _dead or not visible:
		return HitData.Result.IGNORED
	if hit.attacker == null or not hit.attacker.is_in_group("player"):
		return HitData.Result.IGNORED
	var contact: Vector3 = global_position + Vector3.UP * 1.1
	Sfx.play(&"bolt_hit" if hit.ranged else &"hit", contact)
	CombatFX.blood(contact)
	CombatFX.hitstop(0.05)
	_die(contact)
	return HitData.Result.HIT


func _die(contact: Vector3) -> void:
	_dead = true
	_pending_line = false
	Story.mark_heard(STORY_KILLED)
	SaveGame.save(_player)
	body.play_action(&"death", 0.0, 1.1, 0.06)
	Voice.say(&"soldier", &"death", contact)
	# Diferido: el golpe llega en mitad de la física. Sin experiencia. El cuerpo queda hasta el próximo reinicio.
	_wall_shape.set_deferred("disabled", true)
	_hurt_shape.set_deferred("disabled", true)


## Lo llama Camps.reset_world (al descansar o al morir Kael): el mundo cambia.
func on_world_reset() -> void:
	if Story.heard(STORY_KILLED):
		_vanish()
	elif Story.heard(STORY_SPARED):
		_go_to_well()
