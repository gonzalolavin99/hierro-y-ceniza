extends Node
## Herramienta: recorre el escenario de pruebas acercando a Kael a cada zona de enemigos y dejando que
## peleen un rato, para que salgan en la consola los errores que solo aparecen jugando.
## Godot --headless --path game res://tests/error_sweep.tscn

const SPOTS: Array[Vector3] = [
	Vector3(0.0, 0.0, 13.0),     # Soldado de práctica
	Vector3(12.0, 0.0, 30.0),    # Bandido
	Vector3(-12.0, 0.0, 30.0),   # Lancero
	Vector3(0.0, 0.0, 45.0),     # Arquero
	Vector3(26.0, 0.0, 17.0),    # Grupo
	Vector3(-27.0, 0.0, 9.5),    # Sigilo
]


func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	player.invulnerable = true
	for spot in SPOTS:
		player.global_position = spot
		player.reset_physics_interpolation()
		print("--- zona ", spot)
		# Pelea un poco: ataca y se cubre de vez en cuando.
		for i in 8:
			Input.action_press("attack")
			await get_tree().physics_frame
			Input.action_release("attack")
			await get_tree().create_timer(0.5, true, true).timeout
			Input.action_press("block")
			await get_tree().create_timer(0.4, true, true).timeout
			Input.action_release("block")
	print("--- fin")
	get_tree().quit()
