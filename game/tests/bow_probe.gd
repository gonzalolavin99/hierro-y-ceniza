extends Node
## Herramienta: mide la orientación de la mano izquierda del arquero mientras apunta, para colocar el
## arco (Mannequin.BOW_GRIP). Imprime "arriba" y "adelante" del mundo vistos desde la mano.
## Godot --headless --path game res://tests/bow_probe.tscn

func _ready() -> void:
	var archer := (load("res://scenes/enemies/archer.tscn") as PackedScene).instantiate() as Enemy
	archer.aggro_range = 0.0
	add_child(archer)
	await get_tree().physics_frame
	archer.body.play_action(&"bow_aim", 0.4, 0.0, 0.01)
	for i in 30:
		await get_tree().physics_frame
	var hand := archer.body.get_node("YBot/Skeleton3D/LeftHand") as Node3D
	var inv: Basis = hand.global_basis.orthonormalized().inverse()
	var up: Vector3 = (inv * Vector3.UP).normalized()
	var forward: Vector3 = (inv * archer.get_facing()).normalized()
	print("arriba_en_mano=", up.snappedf(0.01), " adelante_en_mano=", forward.snappedf(0.01))
	print("mano_pos_rel=", (hand.global_position - archer.global_position).snappedf(0.01))
	get_tree().quit()
