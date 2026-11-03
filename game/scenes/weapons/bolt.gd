class_name Bolt
extends Node3D
## Virote de la ballesta de muñeca: vuela recto y rápido. Al tocar a un enemigo le pasa el golpe
## como una espada (puede bloquearlo); si lo pilla preparando un ataque, se lo interrumpe.

const SPEED: float = 38.0
const LIFETIME: float = 1.2
const DAMAGE: float = 8.0
const POSTURE: float = 6.0
## Capas: 1 = mundo, 5 = zonas de impacto de los enemigos.
const MASK: int = 1 | (1 << 4)

var shooter: Node3D
var velocity: Vector3
var _age: float = 0.0


static func spawn(parent: Node, from: Vector3, direction: Vector3, owner_node: Node3D) -> Bolt:
	var bolt := Bolt.new()
	bolt.shooter = owner_node
	bolt.velocity = direction.normalized() * SPEED
	parent.add_child(bolt)
	bolt.global_position = from
	bolt.look_at(from + direction, Vector3.UP)
	return bolt


func _ready() -> void:
	add_to_group("projectiles")
	var mesh := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.008
	shaft.bottom_radius = 0.008
	shaft.height = 0.32
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.25, 0.15)
	shaft.material = material
	mesh.mesh = shaft
	mesh.rotation.x = PI * 0.5  # El cilindro va a lo largo de -Z (hacia donde vuela).
	add_child(mesh)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	var from: Vector3 = global_position
	var to: Vector3 = from + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to, MASK)
	query.collide_with_areas = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
		return
	var hurtbox := hit["collider"] as Hurtbox
	if hurtbox and hurtbox.target != shooter:
		var data := HitData.create(shooter, DAMAGE, POSTURE, 0.0)
		data.ranged = true
		data.interrupts = true
		hurtbox.receive(data)
	else:
		Sfx.play(&"bolt_hit", hit["position"], -4.0)
		CombatFX.sparks(hit["position"], 6, 3.0)
	queue_free()
