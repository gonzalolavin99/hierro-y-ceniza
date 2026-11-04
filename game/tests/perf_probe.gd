extends Node
## Herramienta: mide los FPS del escenario de pruebas (con ventana, en la GPU real).
## Godot --path game res://tests/perf_probe.tscn [-- sin_lejanos]
## Con "sin_lejanos" desactiva a los enemigos alejados (para comparar).

func _ready() -> void:
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	get_window().size = Vector2i(1920, 1080)
	await get_tree().create_timer(2.0).timeout
	var frames: int = 0
	var start: int = Time.get_ticks_usec()
	var worst: float = 0.0
	var last: int = start
	while Time.get_ticks_usec() - start < 6_000_000:
		await get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		frames += 1
	var seconds: float = (Time.get_ticks_usec() - start) / 1_000_000.0
	var enemies: int = get_tree().get_nodes_in_group("enemies").size()
	print("FPS medio=%.1f  peor fotograma=%.1f ms  enemigos=%d" % [frames / seconds, worst, enemies])
	get_tree().quit()
