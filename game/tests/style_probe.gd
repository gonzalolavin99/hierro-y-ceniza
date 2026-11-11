extends Node3D
## Herramienta: escena de prueba de la guía de estilo (docs/16). Un rincón con 5 objetos y 2 personajes hechos
## solo con la paleta (StylePalette), con la luz y la niebla de cada zona. Capturas con ventana:
## Godot --path game res://tests/style_probe.tscn -- <carpeta>
## Sirve para que el jugador apruebe el estilo antes de vestir el nivel.

const MANNEQUIN: PackedScene = preload("res://scenes/characters/mannequin.tscn")

var _env: Environment
var _sun: DirectionalLight3D


func _ready() -> void:
	DebugOverlay.visible = false
	_build_light()
	_build_set()
	var out: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://style"
	DirAccess.make_dir_recursive_absolute(out)
	get_window().size = Vector2i(1600, 900)
	var cam := Camera3D.new()
	cam.fov = 55.0
	add_child(cam)
	cam.make_current()
	var views: Array = [
		[&"aldea", Vector3(5.5, 2.2, 7.5), Vector3(0, 1.2, 0)],
		[&"bosque", Vector3(-6.5, 1.8, 5.0), Vector3(0.5, 1.2, 0)],
		[&"fortaleza", Vector3(1.0, 1.7, -6.5), Vector3(0, 1.3, 0.5)],
	]
	for view in views:
		_zone(view[0])
		cam.global_position = view[1]
		cam.look_at(view[2])
		await get_tree().create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/estilo_%s.png" % [out, view[0]])
		print("Captura: estilo_%s.png" % view[0])
	get_tree().quit()


func _zone(zone: StringName) -> void:
	var values: Array = StylePalette.ZONES[zone]
	_env.fog_light_color = values[0]
	_env.fog_density = values[1]
	_sun.light_color = values[2]
	_env.background_color = (values[0] as Color).lightened(0.1)


func _build_light() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = StylePalette.ASH
	_env.ambient_light_energy = 0.55
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.ssao_enabled = true  # Sombra suave en las esquinas (calidad baja: cabe en la GTX 1050).
	_env.ssao_intensity = 1.6
	var world := WorldEnvironment.new()
	world.environment = _env
	add_child(world)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-38, 35, 0)
	_sun.light_energy = 1.25
	_sun.shadow_enabled = true
	add_child(_sun)


func _build_set() -> void:
	_box(Vector3(0, -0.5, 0), Vector3(30, 1, 30), StylePalette.EARTH)  # Suelo.
	_box(Vector3(0, 0.01, 0), Vector3(2.4, 0.02, 30), StylePalette.STONE.darkened(0.1))  # Camino empedrado.
	# 1. Casa de piedra con tejado de madera y la tela gris de la cuarentena.
	_box(Vector3(-3.6, 1.5, -1.0), Vector3(3.6, 3.0, 3.6), StylePalette.STONE)
	_box(Vector3(-3.6, 3.25, -1.0), Vector3(4.0, 0.5, 4.0), StylePalette.WOOD.darkened(0.2))
	_box(Vector3(-1.78, 1.0, -1.0), Vector3(0.05, 2.0, 1.2), StylePalette.BONE)
	# 2. Rocas de pocas caras (siluetas claras).
	for r in [[Vector3(3.5, 0.5, -2.5), 0.9], [Vector3(4.6, 0.35, -1.6), 0.55], [Vector3(-5.5, 0.6, 3.0), 1.0]]:
		_rock(r[0], r[1])
	# 3. Cajas de madera.
	_box(Vector3(2.2, 0.4, 1.8), Vector3(0.8, 0.8, 0.8), StylePalette.WOOD, 12.0)
	_box(Vector3(2.5, 1.05, 1.7), Vector3(0.6, 0.5, 0.6), StylePalette.WOOD.lightened(0.08), -20.0)
	# 4. Brasero encendido (acento naranja = lugar seguro / camino).
	_cylinder(Vector3(-1.0, 0.45, 2.6), 0.35, 0.9, StylePalette.SLATE_DARK)
	var flame := _cylinder(Vector3(-1.0, 1.05, 2.6), 0.22, 0.3, StylePalette.EMBER)
	(flame.material_override as StandardMaterial3D).emission_enabled = true
	(flame.material_override as StandardMaterial3D).emission = StylePalette.EMBER
	(flame.material_override as StandardMaterial3D).emission_energy_multiplier = 2.5
	var light := OmniLight3D.new()
	light.light_color = StylePalette.EMBER
	light.light_energy = 2.2
	light.omni_range = 6.0
	light.position = Vector3(-1.0, 1.4, 2.6)
	add_child(light)
	# 5. Valla de madera y un estandarte óxido (acento de peligro: la gente de Varga).
	for i in 4:
		_box(Vector3(5.0, 0.6, 1.0 + i * 0.9), Vector3(0.12, 1.2, 0.12), StylePalette.WOOD.darkened(0.1))
	_box(Vector3(5.0, 0.9, 2.35), Vector3(0.06, 0.12, 2.9), StylePalette.WOOD)
	_box(Vector3(4.2, 2.2, -3.4), Vector3(0.08, 4.4, 0.08), StylePalette.WOOD.darkened(0.3))
	_box(Vector3(4.2, 3.2, -3.0), Vector3(0.04, 1.6, 0.7), StylePalette.RUST)
	# Personajes: Kael (cuero y pizarra, con la cinta de Lira) y un soldado (acero y pizarra, con yelmo).
	_person(Vector3(0.3, 0, 0.6), 200.0, StylePalette.LEATHER, StylePalette.SLATE_DARK, true, false)
	_person(Vector3(1.4, 0, -1.6), 20.0, StylePalette.SLATE, StylePalette.STEEL.darkened(0.25), false, true)


func _person(at: Vector3, yaw: float, body: Color, joints: Color, ribbon: bool, helmet: bool) -> void:
	var m := MANNEQUIN.instantiate() as Mannequin
	m.body_color = body
	m.joints_color = joints
	m.ribbon = ribbon
	m.position = at
	m.rotation_degrees.y = yaw
	add_child(m)
	if helmet:
		var hat := _cylinder(Vector3.ZERO, 0.17, 0.22, StylePalette.STEEL.darkened(0.35))
		hat.reparent(m.bone_attachment(Bones.name(&"Head")))
		hat.position = Vector3(0, 0.14, 0)


func _box(at: Vector3, size: Vector3, color: Color, yaw: float = 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = StylePalette.material(color)
	mesh.position = at
	mesh.rotation_degrees.y = yaw
	add_child(mesh)
	return mesh


func _cylinder(at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius * 1.1
	c.height = height
	c.radial_segments = 8
	mesh.mesh = c
	mesh.material_override = StylePalette.material(color)
	mesh.position = at
	add_child(mesh)
	return mesh


## Roca "low-poly": una esfera de muy pocas caras, aplastada y girada.
func _rock(at: Vector3, size: float) -> void:
	var mesh := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = size
	s.height = size * 1.5
	s.radial_segments = 6
	s.rings = 3
	mesh.mesh = s
	mesh.material_override = StylePalette.material(StylePalette.SLATE)
	mesh.position = at
	mesh.rotation_degrees = Vector3(8, at.x * 40.0, 5)
	add_child(mesh)
