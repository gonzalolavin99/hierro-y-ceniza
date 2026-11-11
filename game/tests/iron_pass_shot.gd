extends Node
## Herramienta: capturas del Paso de Hierro en bloques desde varios puntos y una vista desde arriba.
## Godot --path game res://tests/iron_pass_shot.tscn -- <carpeta>

const VIEWS: Array = [
	["01_inicio", Vector3(0, 2.5, 144), Vector3(0, 1, 118)],
	["02_red_frank", Vector3(-2, 2.2, 101), Vector3(7, 1.2, 95)],
	["03_arco", Vector3(0, 2.2, 86), Vector3(0, 2, 50)],
	["04_aldea", Vector3(30, 22, 86), Vector3(0, 0, 45)],
	["05_bosque", Vector3(0, 2, 24), Vector3(-4, 1, -10)],
	["06_rampa", Vector3(0, 3, -36), Vector3(0, 6, -76)],
	["07_fortaleza", Vector3(0, 12, -70), Vector3(10, 4, -122)],
	["08_atajo", Vector3(22, 6.5, -85), Vector3(31, 5, -85)],
	["10_puerta_aldea", Vector3(28, 2.2, 42), Vector3(36, 1.2, 39)],
]


func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/iron_pass.tscn").instantiate())
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	var hud := get_tree().get_first_node_in_group("hud") as CanvasItem
	if hud:
		hud.visible = false
	await get_tree().create_timer(1.0).timeout
	var cam := Camera3D.new()
	add_child(cam)
	cam.far = 600.0
	cam.make_current()
	for view in VIEWS:
		cam.global_position = view[1]
		cam.look_at(view[2])
		await get_tree().create_timer(0.3).timeout
		await _shot(out, view[0])
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 310.0
	cam.global_position = Vector3(18, 200, -2)
	cam.rotation = Vector3(-PI * 0.5, 0, 0)
	(get_tree().get_first_node_in_group("player") as Node3D).get_parent().get_node("WorldEnvironment").environment.fog_enabled = false
	await get_tree().create_timer(0.3).timeout
	await _shot(out, "09_mapa", 1000)
	get_tree().quit()


func _shot(out: String, name: String, width: int = 960) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(width, width * img.get_height() / img.get_width())
	img.save_png(out.path_join(name + ".png"))
