extends Node
## Herramienta: mide los FPS con ventana, en la GPU real.
## Godot --path game res://tests/perf_probe.tscn                → el escenario de pruebas
## Godot --path game res://tests/perf_probe.tscn -- iron_pass   → el Paso de Hierro, zona por zona
## Mide sin vsync (lo que da de sí la tarjeta): FPS medio, peor fotograma, llamadas de dibujo y memoria de vídeo.

## Paso de Hierro: [nombre, dónde se pone Kael, hacia dónde mira (grados)].
const ZONES: Array = [
	["Camino (tutorial)", Vector3(0, 0, 130), 180.0],
	["Arco → aldea", Vector3(0, 0, 82), 180.0],
	["Aldea (centro)", Vector3(0, 0, 50), 180.0],
	["Bosque", Vector3(-3, 0, -6), 180.0],
	["Pie de la rampa", Vector3(0, 0, -44), 180.0],
	["Fortaleza (patio)", Vector3(0, 4, -88), 180.0],
	["Patio de Varga", Vector3(48, 4, -125), 90.0],
]
const SECONDS: float = 3.0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var iron: bool = args.has("iron_pass")
	add_child(load("res://scenes/levels/%s.tscn" % ("iron_pass" if iron else "test_level")).instantiate())
	get_window().size = Vector2i(1920, 1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await get_tree().create_timer(2.0).timeout
	print("GPU: %s" % RenderingServer.get_video_adapter_name())
	if not iron:
		_print_line("Escenario de pruebas", await _measure())
		get_tree().quit()
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	var lows: Array[float] = []
	for zone in ZONES:
		player.set_spawn(zone[1], zone[2])
		player.respawn()
		await get_tree().create_timer(1.0).timeout
		var result: Dictionary = await _measure()
		_print_line(zone[0], result)
		lows.append(result["fps"])
	print("PEOR ZONA: %.0f FPS medio" % lows.min())
	get_tree().quit()


func _measure() -> Dictionary:
	var frames: int = 0
	var start: int = Time.get_ticks_usec()
	var worst: float = 0.0
	var last: int = start
	var draws: float = 0.0
	while Time.get_ticks_usec() - start < int(SECONDS * 1_000_000):
		await get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		frames += 1
		draws = maxf(draws, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var seconds: float = (Time.get_ticks_usec() - start) / 1_000_000.0
	return {"fps": frames / seconds, "worst": worst, "draws": draws,
			"vram": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
			"enemies": get_tree().get_nodes_in_group("enemies").size()}


func _print_line(label: String, r: Dictionary) -> void:
	print("%-22s FPS medio=%.0f  peor fotograma=%.1f ms  llamadas de dibujo=%d  VRAM=%.0f MB  enemigos=%d" % [
		label, r["fps"], r["worst"], r["draws"], r["vram"], r["enemies"]])
