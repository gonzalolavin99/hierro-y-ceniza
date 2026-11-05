extends Node
## Herramienta: secuencias de capturas de Varga (salto desde lejos y cuchillos), vistas de lado. Con ventana.
## Godot --path game res://tests/varga_shot.tscn -- <carpeta>

var _out: String
var _player: Player
var _arena: VargaArena


func _ready() -> void:
	_out = OS.get_cmdline_user_args()[0]
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player") as Player
	_arena = get_tree().get_first_node_in_group("arenas") as VargaArena
	DebugOverlay.visible = false
	_player.health.max_health = 9999.0
	await get_tree().create_timer(0.5).timeout
	var cam := Camera3D.new()
	add_child(cam)
	cam.make_current()
	var c: Vector3 = _arena.global_position
	cam.global_position = c + Vector3(0.0, 2.0, 9.0)
	cam.look_at(c + Vector3(0.0, 1.2, 0.0))
	for pattern in [&"varga_leap", &"varga_knives", &"varga_spin"]:
		await _setup(8.0 if pattern == &"varga_leap" else 4.0)
		_arena.varga.state_machine.transition_to(&"Attack", {"pattern": pattern})
		for i in 6:
			await get_tree().create_timer(0.15).timeout
			await _shot("%s_%d" % [pattern, i])
	get_tree().quit()


func _setup(distance: float) -> void:
	var varga: Enemy = _arena.varga
	varga.aggro_range = 60.0
	varga.alert()
	varga.state_machine.transition_to(&"Idle", {"wait": 100.0})
	var c: Vector3 = _arena.global_position
	varga.global_position = c + Vector3(distance * 0.5, 0.0, 0.0)
	varga.rotation.y = PI * 0.5
	varga.model.rotation.y = 0.0
	varga.reset_physics_interpolation()
	_player.global_position = c - Vector3(distance * 0.5, 0.0, 0.0)
	_player.model.rotation.y = -PI * 0.5
	_player.reset_physics_interpolation()
	_player.health.heal(9999.0)
	await get_tree().create_timer(0.6).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(480, 270)
	img.save_png(_out.path_join("v_" + name + ".png"))
