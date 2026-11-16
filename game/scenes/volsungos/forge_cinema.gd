class_name VolsungosCinema
extends Control
signal closed
var player: VideoStreamPlayer
var _back: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	player = VideoStreamPlayer.new()
	player.expand = true
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var clip: VideoStream
	if ResourceLoader.exists("res://assets/volsungos/forge.ogv"):
		clip = load("res://assets/volsungos/forge.ogv") as VideoStream
	player.stream = clip
	add_child(player)
	resized.connect(_fit_video)
	_fit_video()
	_back = Button.new()
	_back.text = "Volver · Esc / B"
	_back.position = Vector2(30, 30)
	_back.custom_minimum_size = Vector2(220, 50)
	_back.pressed.connect(close)
	add_child(_back)
	_back.grab_focus()
	if clip:
		player.finished.connect(close)
		player.play()
	else:
		_back.text = "Vídeo no disponible · Volver"


func _fit_video() -> void:
	# Letterbox the 16:9 source instead of stretching it on ultrawide or 4:3 windows.
	var fit := Vector2(size.x, size.x * 9.0 / 16.0)
	if fit.y > size.y:
		fit = Vector2(size.y * 16.0 / 9.0, size.y)
	player.set_anchors_preset(Control.PRESET_TOP_LEFT)
	player.size = fit
	player.position = (size - fit) * 0.5


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if is_queued_for_deletion():
		return
	player.stop()
	closed.emit()
	queue_free()
