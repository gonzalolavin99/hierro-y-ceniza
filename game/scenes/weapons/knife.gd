class_name ThrowingKnife
extends Arrow
## Cuchillo arrojadizo de la Capitana Varga: vuela más rápido que una flecha y hace algo menos de daño.
## Como la flecha, se bloquea o se desvía (pulsado a tiempo) y la voltereta lo esquiva.

const KNIFE_SPEED: float = 30.0


static func throw(parent: Node, from: Vector3, target: Vector3, owner_node: Node3D) -> ThrowingKnife:
	var knife := ThrowingKnife.new()
	knife.shooter = owner_node
	knife.damage = 11.0
	knife.posture_damage = 15.0
	var direction: Vector3 = (target - from).normalized()
	knife.velocity = direction * KNIFE_SPEED
	parent.add_child(knife)
	knife.global_position = from
	knife.look_at(from + direction, Vector3.UP)
	return knife


func _build() -> void:
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.7, 0.72, 0.75)
	steel.metallic = 0.9
	steel.roughness = 0.25
	var blade := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.025, 0.006, 0.2)
	box.material = steel
	blade.mesh = box
	blade.position = Vector3(0.0, 0.0, -0.08)
	add_child(blade)
	var grip := MeshInstance3D.new()
	var handle := BoxMesh.new()
	handle.size = Vector3(0.02, 0.02, 0.09)
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color(0.25, 0.15, 0.1)
	handle.material = leather
	grip.mesh = handle
	grip.position = Vector3(0.0, 0.0, 0.07)
	add_child(grip)
