extends Node
## Mide a qué altura sobre el suelo quedan tobillos y puntas de los pies (plano y rampa).
func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	var p: Player = get_tree().get_first_node_in_group("player")
	var sk: Skeleton3D = p.body.get_node("YBot/Skeleton3D")
	var gm: Node = sk.get_node("FootGrounding")
	for mode in ["plano", "rampa_quieto", "rampa_subiendo"]:
		p.global_position = Vector3(0, 0.1, 0) if mode == "plano" else Vector3(-12.0, 1.5, -6.0)
		p.model.rotation.y = 0.0
		p.camera_rig.rotation.y = 0.0
		p.reset_physics_interpolation()
		await get_tree().create_timer(0.8).timeout
		if mode == "rampa_subiendo":
			Input.action_press("move_forward")
			await get_tree().create_timer(0.35).timeout
		for active in [true, false]:
			gm.active = active
			await get_tree().physics_frame
			# La pose final (con los ajustes aplicados) solo existe justo después de actualizar el esqueleto.
			await sk.skeleton_updated
			var line := "%-15s ajuste=%-5s" % [mode, active]
			for b in ["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]:
				var w: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("mixamorig_" + b)).origin
				var q := PhysicsRayQueryParameters3D.create(w + Vector3.UP * 0.5, w + Vector3.DOWN * 2.0, 1)
				var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
				var h: float = (w - hit["position"]).dot(hit["normal"]) if not hit.is_empty() else -1.0
				line += "  %s=%.3f" % [b, h]
			print(line)
		gm.active = true
		Input.action_release("move_forward")
	get_tree().quit()
