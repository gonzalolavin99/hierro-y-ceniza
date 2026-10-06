extends CanvasLayer
## HUD al estilo Sekiro: vida abajo a la izquierda, postura en el centro inferior
## (crece desde el centro hacia los lados y se oculta cuando está vacía).

const POSTURE_COLORS: Array[Color] = [Color(1.0, 0.85, 0.35), Color(1.0, 0.55, 0.15), Color(0.95, 0.2, 0.1)]

@onready var _health_fill: ColorRect = $HealthBar/Fill
@onready var _posture_bar: Control = $PostureBar
@onready var _posture_fill: ColorRect = $PostureBar/Fill

var _player: Player


func _ready() -> void:
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player") as Player
	if _player == null:
		return
	_player.health.changed.connect(_on_health_changed)
	_player.posture.changed.connect(_on_posture_changed)
	_on_health_changed(_player.health.current, _player.health.max_health)
	_on_posture_changed(0.0, _player.posture.max_posture)


func _on_health_changed(current: float, maximum: float) -> void:
	_health_fill.anchor_right = current / maximum


func _on_posture_changed(current: float, maximum: float) -> void:
	var ratio: float = current / maximum
	_posture_bar.visible = ratio > 0.001
	# Crece desde el centro: 0.5 ± ratio/2
	_posture_fill.anchor_left = 0.5 - ratio * 0.5
	_posture_fill.anchor_right = 0.5 + ratio * 0.5
	var color_index: int = 0 if ratio < 0.5 else (1 if ratio < 0.8 else 2)
	_posture_fill.color = POSTURE_COLORS[color_index]
