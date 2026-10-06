extends CanvasLayer
## Panel de depuración: FPS, GPU, memoria de vídeo y mandos conectados.
## Se oculta/muestra con F3 o con el botón "Vista" (View) del mando Xbox.

const REFRESH_SECONDS: float = 0.25

@onready var _label: Label = $Panel/Label

var _timer: float = 0.0


func _ready() -> void:
	layer = 100
	print("[Debug] GPU: %s (%s)" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor()])
	print("[Debug] Mandos: %s" % _joypads_text())
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= REFRESH_SECONDS:
		_timer = 0.0
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var button := event as InputEventJoypadButton
	var toggle_key: bool = key != null and key.pressed and not key.echo and key.keycode == KEY_F3
	var toggle_pad: bool = button != null and button.pressed and button.button_index == JOY_BUTTON_BACK
	if toggle_key or toggle_pad:
		visible = not visible


func _refresh() -> void:
	var gpu: String = RenderingServer.get_video_adapter_name()
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var vram_mb: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0

	var lines: PackedStringArray = []
	lines.append("FPS: %d" % fps)
	lines.append("GPU: %s" % gpu)
	if gpu.containsn("intel"):
		lines.append("  ⚠ Usando la GPU Intel: forzar NVIDIA (ver docs/01)")
	lines.append("VRAM: %.0f MB   Draw calls: %d" % [vram_mb, draw_calls])
	lines.append("Mandos: %s" % _joypads_text())
	lines.append("[F3 / botón Vista: ocultar]")
	_label.text = "\n".join(lines)

	# Verde si va fluido, amarillo si aceptable, rojo si va mal.
	if fps >= 58.0:
		_label.modulate = Color(0.6, 1.0, 0.6)
	elif fps >= 45.0:
		_label.modulate = Color(1.0, 0.9, 0.4)
	else:
		_label.modulate = Color(1.0, 0.45, 0.4)


func _joypads_text() -> String:
	var pads: Array[int] = Input.get_connected_joypads()
	if pads.is_empty():
		return "ninguno"
	var names: PackedStringArray = []
	for id in pads:
		names.append(Input.get_joy_name(id))
	return ", ".join(names)


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh()
