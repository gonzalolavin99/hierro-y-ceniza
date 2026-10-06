extends CanvasLayer
## HUD al estilo Sekiro:
## - Jugador: vida abajo a la izquierda, postura en el centro inferior.
## - Enemigo (fijado o con el que peleas): vida y postura sobre su cabeza.
## - Punto de fijación y marca roja de golpe mortal.
## Las barras de postura crecen desde el centro y se ocultan vacías.

const POSTURE_COLORS: Array[Color] = [Color(1.0, 0.85, 0.35), Color(1.0, 0.55, 0.15), Color(0.95, 0.2, 0.1)]

@onready var _health_fill: ColorRect = $HealthBar/Fill
@onready var _posture_bar: Control = $PostureBar
@onready var _posture_fill: ColorRect = $PostureBar/Fill
@onready var _enemy_panel: Control = $EnemyPanel
@onready var _enemy_name: Label = $EnemyPanel/Name
@onready var _enemy_health_fill: ColorRect = $EnemyPanel/Health/Fill
@onready var _enemy_posture: Control = $EnemyPanel/Posture
@onready var _enemy_posture_fill: ColorRect = $EnemyPanel/Posture/Fill
@onready var _lock_dot: Control = $LockDot
@onready var _deathblow_mark: Control = $DeathblowMark

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


func _process(_delta: float) -> void:
	if _player == null:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	var enemy: Enemy = _player.engaged_enemy
	if enemy and (enemy.is_dead() or _player.global_position.distance_to(enemy.global_position) > 20.0):
		enemy = null

	_enemy_panel.visible = enemy != null and not camera.is_position_behind(enemy.lock_point())
	if _enemy_panel.visible:
		var head: Vector2 = camera.unproject_position(enemy.lock_point() + Vector3.UP * 1.0)
		_enemy_panel.position = head - Vector2(_enemy_panel.size.x * 0.5, _enemy_panel.size.y)
		_enemy_name.text = enemy.display_name
		_enemy_health_fill.anchor_right = enemy.health.ratio()
		_set_posture_fill(_enemy_posture, _enemy_posture_fill, enemy.posture.ratio())

	var locked: Enemy = _player.lock_target
	_lock_dot.visible = locked != null and not camera.is_position_behind(locked.lock_point())
	if _lock_dot.visible:
		_lock_dot.position = camera.unproject_position(locked.lock_point()) - _lock_dot.size * 0.5

	var exposed: Enemy = _find_exposed_enemy()
	_deathblow_mark.visible = exposed != null
	if exposed:
		_deathblow_mark.position = camera.unproject_position(exposed.lock_point()) - _deathblow_mark.size * 0.5
		_lock_dot.visible = false


func _find_exposed_enemy() -> Enemy:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.can_be_deathblowed() and _player.global_position.distance_to(enemy.global_position) < 6.0:
			return enemy
	return null


func _on_health_changed(current: float, maximum: float) -> void:
	_health_fill.anchor_right = current / maximum


func _on_posture_changed(current: float, maximum: float) -> void:
	_set_posture_fill(_posture_bar, _posture_fill, current / maximum)


func _set_posture_fill(bar: Control, fill: ColorRect, ratio: float) -> void:
	bar.visible = ratio > 0.001
	# Crece desde el centro: 0.5 ± ratio/2
	fill.anchor_left = 0.5 - ratio * 0.5
	fill.anchor_right = 0.5 + ratio * 0.5
	var color_index: int = 0 if ratio < 0.5 else (1 if ratio < 0.8 else 2)
	fill.color = POSTURE_COLORS[color_index]
