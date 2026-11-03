class_name Bomb
extends Node3D
## Bomba lanzada en arco (pólvora) o dejada a los pies (humo). Al tocar el suelo o a alguien,
## estalla: la de pólvora daña en un radio; la de humo crea una nube que aturde.

enum Kind { POWDER, SMOKE }

const GRAVITY: float = 18.0
## Capas: 1 = mundo, 3 = cuerpos de enemigos.
const MASK: int = 1 | (1 << 2)
const BLAST_RADIUS: float = 2.8
const BLAST_DAMAGE: float = 25.0
const BLAST_POSTURE: float = 35.0

var kind: Kind
var thrower: Node3D
var velocity: Vector3
var _age: float = 0.0


## Lanza la bomba para que caiga en `target` tras `flight_time` segundos.
static func throw(parent: Node, from: Vector3, target: Vector3, flight_time: float, bomb_kind: Kind, owner_node: Node3D) -> Bomb:
	var bomb := Bomb.new()
	bomb.kind = bomb_kind
	bomb.thrower = owner_node
	bomb.velocity = (target - from) / flight_time + Vector3.UP * 0.5 * GRAVITY * flight_time
	parent.add_child(bomb)
	bomb.global_position = from
	return bomb


func _ready() -> void:
	add_to_group("projectiles")
	var mesh := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.07
	ball.height = 0.14
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.11, 0.1) if kind == Kind.POWDER else Color(0.55, 0.53, 0.5)
	ball.material = material
	mesh.mesh = ball
	add_child(mesh)


func _physics_process(delta: float) -> void:
	_age += delta
	velocity.y -= GRAVITY * delta
	var from: Vector3 = global_position
	var to: Vector3 = from + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to, MASK)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() or _age > 3.0:
		_burst(hit["position"] if not hit.is_empty() else to)
		return
	global_position = to


func _burst(at: Vector3) -> void:
	if kind == Kind.POWDER:
		_explode(at)
	else:
		SmokeCloud.create(get_parent(), at)
	queue_free()


func _explode(at: Vector3) -> void:
	Sfx.play(&"explosion", at)
	CombatFX.explosion(at)
	CombatFX.shake(0.7)
	CombatFX.hitstop(0.06)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.global_position.distance_to(at) <= BLAST_RADIUS:
			enemy.receive_blast(at, BLAST_DAMAGE, BLAST_POSTURE)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and player.global_position.distance_to(at) <= BLAST_RADIUS:
		player.receive_blast(at, BLAST_DAMAGE * 0.6)
