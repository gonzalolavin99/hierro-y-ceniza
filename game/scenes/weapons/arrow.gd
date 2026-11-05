class_name Arrow
extends Node3D
## Flecha del arquero enemigo: vuela recta (a una velocidad que da tiempo a reaccionar) y, al tocar al
## jugador, le pasa el golpe como una espada: se puede bloquear y desviar (como en Sekiro).

const SPEED: float = 26.0
const LIFETIME: float = 2.0
const DAMAGE: float = 16.0
const POSTURE: float = 16.0
## Capas: 1 = mundo, 4 = zona de impacto del jugador.
const MASK: int = 1 | (1 << 3)

var shooter: Node3D
var velocity: Vector3
## Daño y postura que hace (los cuchillos de Varga usan otros valores).
var damage: float = DAMAGE
var posture_damage: float = POSTURE
var _age: float = 0.0


static func spawn(parent: Node, from: Vector3, target: Vector3, owner_node: Node3D) -> Arrow:
	var arrow := Arrow.new()
	arrow.shooter = owner_node
	var direction: Vector3 = (target - from).normalized()
	arrow.velocity = direction * SPEED
	parent.add_child(arrow)
	arrow.global_position = from
	arrow.look_at(from + direction, Vector3.UP)
	return arrow


func _ready() -> void:
	add_to_group("enemy_projectiles")
	_build()


## Forma de la flecha (los cuchillos la cambian).
func _build() -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.3, 0.18)
	var shaft := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.009
	cylinder.bottom_radius = 0.009
	cylinder.height = 0.75
	cylinder.material = wood
	shaft.mesh = cylinder
	shaft.rotation.x = PI * 0.5  # A lo largo de -Z (hacia donde vuela).
	add_child(shaft)
	var tip := MeshInstance3D.new()
	var head := BoxMesh.new()
	head.size = Vector3(0.03, 0.02, 0.08)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.25, 0.25, 0.27)
	iron.metallic = 0.8
	head.material = iron
	tip.mesh = head
	tip.position = Vector3(0.0, 0.0, -0.4)
	add_child(tip)


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
	if hurtbox and is_instance_valid(shooter) and hurtbox.target != shooter:
		var data := HitData.create(shooter, damage, posture_damage, 0.0)
		data.ranged = true
		var result: int = hurtbox.receive(data)
		if result == HitData.Result.IGNORED:
			global_position = to  # Lo esquivó (invulnerable): la flecha sigue de largo.
			return
	else:
		Sfx.play(&"bolt_hit", hit["position"], -6.0)
		CombatFX.sparks(hit["position"], 4, 2.0)
	queue_free()
