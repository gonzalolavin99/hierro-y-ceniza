extends Node
## Prueba automática de la cámara al fijar objetivo: transición suave y encuadre en peleas cercanas.
## Ejecutar: Godot --headless --path game res://tests/camera_test.tscn
## Con ventana y una carpeta guarda capturas: Godot --path game res://tests/camera_test.tscn -- <carpeta>

var _player: Player
var _enemy: Enemy
var _rig: CameraRig
var _cam: Camera3D
var _failures: int = 0
var _shots_dir: String = ""


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	_rig = _player.camera_rig
	_cam = _rig.camera
	if not OS.get_cmdline_user_args().is_empty():
		_shots_dir = OS.get_cmdline_user_args()[0]
	# Soldado quieto: solo medimos la cámara.
	_enemy.process_mode = Node.PROCESS_MODE_DISABLED
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	# Jugador en el origen mirando a -Z; el soldado a su derecha, a 2,5 m (giro de 90° al fijar).
	_place(Vector3(2.5, 0.0, 0.0))
	await _wait(0.5)

	# 1. Transición al fijar: arranca suave (sin tirón) y llega en menos de un segundo.
	await _tap("lock_on")
	_check("R3 fija al soldado", _player.lock_target == _enemy)
	var speeds: Array[float] = await _yaw_speeds(1.0)
	# Promedio de los primeros 5 fotogramas (un solo fotograma varía según el ritmo de dibujo).
	var first: float = 0.0
	for v: float in speeds.slice(0, 5):
		first += v / 5.0
	var peak: float = speeds.max()
	_check("El giro arranca suave (%.0f °/s de media en los primeros fotogramas)" % first, first < 150.0)
	_check("El giro no da latigazos (máx %.0f °/s)" % peak, peak < 420.0)
	_check("Mira al soldado tras 1 s (desvío %.1f°)" % _aim_error(), _aim_error() < 6.0)

	# 2. Encuadre a media distancia y muy cerca.
	for dist: float in [2.5, 1.4]:
		_move_to_distance(dist)
		await _wait(1.0)
		await _shot("cerca_%.1f" % dist)
		_check("A %.1f m se ven los dos enteros" % dist, _both_in_frame())
		_check("A %.1f m el jugador no tapa al soldado" % dist, not _player_covers_enemy())
		_check("A %.1f m la cámara no está dentro del soldado (%.2f m)" % [dist, _cam_to_enemy()], _cam_to_enemy() > 0.8)

	# 3. Girar alrededor del soldado a corta distancia: siempre encuadrados y sin latigazos.
	var bad_frames: int = 0
	var max_speed: float = 0.0
	var prev_yaw: float = _rig.get_yaw()
	Input.action_press("move_right")
	for i in 120:
		await get_tree().physics_frame
		if not _both_in_frame() or _player_covers_enemy():
			bad_frames += 1
		max_speed = maxf(max_speed, absf(rad_to_deg(angle_difference(prev_yaw, _rig.get_yaw()))) * 60.0)
		prev_yaw = _rig.get_yaw()
		if i % 40 == 20:
			await _shot("rodeando_%d" % i)
	Input.action_release("move_right")
	_check("Rodeando al soldado sigue el encuadre (%d fotogramas malos de 120)" % bad_frames, bad_frames <= 6)
	_check("Rodeando no da latigazos (máx %.0f °/s)" % max_speed, max_speed < 420.0)

	# 4. Al soltar, la cámara no salta.
	await _wait(0.3)
	var yaw_before: float = _rig.get_yaw()
	var cam_before: Vector3 = _cam.global_position
	await _tap("lock_on")
	_check("R3 suelta la fijación", _player.lock_target == null)
	await get_tree().physics_frame
	_check("Al soltar no gira de golpe", absf(rad_to_deg(angle_difference(yaw_before, _rig.get_yaw()))) < 3.0)
	_check("Al soltar no se mueve de golpe (%.2f m)" % cam_before.distance_to(_cam.global_position), cam_before.distance_to(_cam.global_position) < 0.35)
	await _wait(1.0)


# --- Ayudas ---------------------------------------------------------------------

func _place(enemy_offset: Vector3) -> void:
	_player.global_position = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	_player.model.rotation.y = 0.0
	_rig.rotation.y = 0.0
	_enemy.global_position = enemy_offset
	_player.reset_physics_interpolation()
	_enemy.reset_physics_interpolation()


## Coloca al jugador a `dist` del soldado, en el lado donde ya está, sin tocar la cámara.
func _move_to_distance(dist: float) -> void:
	var away: Vector3 = _player.global_position - _enemy.global_position
	away.y = 0.0
	_player.global_position = _enemy.global_position + away.normalized() * dist
	_player.global_position.y = 0.0
	_player.reset_physics_interpolation()


func _yaw_speeds(seconds: float) -> Array[float]:
	var out: Array[float] = []
	var prev: float = _rig.get_yaw()
	for i in int(seconds * 60.0):
		await get_tree().physics_frame
		out.append(absf(rad_to_deg(angle_difference(prev, _rig.get_yaw()))) * 60.0)
		prev = _rig.get_yaw()
	return out


func _aim_error() -> float:
	var to: Vector3 = _enemy.lock_point() - _cam.global_position
	to.y = 0.0
	var fwd: Vector3 = -_cam.global_basis.z
	fwd.y = 0.0
	return rad_to_deg(fwd.angle_to(to))


func _screen(p: Vector3) -> Vector2:
	return _cam.unproject_position(p)


func _in_frame(p: Vector3) -> bool:
	if _cam.is_position_behind(p):
		return false
	var size: Vector2 = _cam.get_viewport().get_visible_rect().size
	var s: Vector2 = _screen(p)
	var m: Vector2 = size * 0.04
	return s.x > m.x and s.x < size.x - m.x and s.y > m.y and s.y < size.y - m.y


func _both_in_frame() -> bool:
	var pp: Vector3 = _player.global_position
	var ep: Vector3 = _enemy.global_position
	return _in_frame(pp + Vector3.UP * 0.1) and _in_frame(pp + Vector3.UP * 1.7) \
		and _in_frame(ep + Vector3.UP * 0.1) and _in_frame(ep + Vector3.UP * 1.75)


## ¿El jugador tapa en pantalla más de la mitad del cuerpo del soldado (cabeza, pecho, cintura, rodillas)?
func _player_covers_enemy() -> bool:
	var pp: Vector3 = _player.global_position
	var right: Vector3 = _cam.global_basis.x
	var head: Vector2 = _screen(pp + Vector3.UP * 1.8)
	var feet: Vector2 = _screen(pp)
	var half_w: float = absf(_screen(pp + Vector3.UP * 1.0 + right * 0.45).x - _screen(pp + Vector3.UP * 1.0).x)
	var covered: int = 0
	for h: float in [1.65, 1.3, 0.95, 0.5]:
		var s: Vector2 = _screen(_enemy.global_position + Vector3.UP * h)
		if absf(s.x - head.x) < half_w and s.y > head.y and s.y < feet.y:
			covered += 1
	return covered >= 2


## Distancia de la cámara al eje vertical del soldado (su cuerpo mide ~1,85 m).
func _cam_to_enemy() -> float:
	var d: Vector3 = _cam.global_position - _enemy.global_position
	d.y -= clampf(d.y, 0.0, 1.85)
	return d.length()


func _shot(label: String) -> void:
	if _shots_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.resize(800, 450)
	img.save_png(_shots_dir.path_join(label + ".png"))


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)
	await get_tree().physics_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
