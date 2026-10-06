extends Node
## Prueba automática del movimiento: simula el mando y comprueba resultados.
## Ejecutar: Godot --headless --path game res://tests/movement_test.tscn

var _player: Player
var _failures: int = 0


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	await _wait(0.5)
	_check("Empieza en el suelo", _player.is_on_floor() and _state() == &"Ground")

	# Caminar hacia delante 1 s
	var start: Vector3 = _player.global_position
	Input.action_press("move_forward")
	await _wait(1.0)
	var speed: float = Vector2(_player.velocity.x, _player.velocity.z).length()
	_check("Corre a ~5,5 m/s (%.2f)" % speed, absf(speed - _player.run_speed) < 0.3)
	_check("Avanza hacia -Z (%.2f m)" % (start.z - _player.global_position.z), start.z - _player.global_position.z > 4.0)
	Input.action_release("move_forward")
	await _wait(0.4)

	# Paso rápido sin dirección = hacia atrás
	start = _player.global_position
	await _tap("dodge")
	_check("Entra en Dash", _state() == &"Dash")
	_check("Invulnerable al inicio", _player.invulnerable)
	await _wait(0.45)
	var dist: float = start.distance_to(_player.global_position)
	_check("Paso atrás de ~3,6 m (%.2f)" % dist, absf(dist - _player.dash_distance) < 0.5)
	_check("Paso hacia atrás (+Z)", _player.global_position.z > start.z)
	_check("Ya no es invulnerable", not _player.invulnerable)

	# Paso + mantener = correr
	Input.action_press("move_left")
	Input.action_press("dodge")
	await _wait(1.0)
	speed = Vector2(_player.velocity.x, _player.velocity.z).length()
	_check("Mantener B = Sprint (%s, %.2f m/s)" % [_state(), speed], _state() == &"Sprint" and speed > 7.5)
	Input.action_release("dodge")
	Input.action_release("move_left")
	await _wait(0.5)
	_check("Soltar = vuelve a Ground", _state() == &"Ground")

	# Salto
	var floor_y: float = _player.global_position.y
	var peak: float = floor_y
	await _tap("jump")
	for i in 60:
		await get_tree().physics_frame
		peak = maxf(peak, _player.global_position.y)
	_check("Salta ~1,5 m (%.2f)" % (peak - floor_y), absf(peak - floor_y - _player.jump_height) < 0.2)
	_check("Aterriza", _player.is_on_floor() and _state() == &"Ground")

	# Placa de postura → aturdimiento
	_player.global_position = Vector3(5, 0.1, 3)
	_player.reset_physics_interpolation()
	await _wait(1.5)
	_check("La postura sube en la placa (%.0f)" % _player.posture.current, _player.posture.current > 20.0)
	await _wait(2.0)
	_check("Postura llena = aturdido (%s)" % _state(), _state() == &"Stagger")
	_player.global_position = Vector3(0, 0.1, 0)
	await _wait(2.5)
	_check("Se recupera del aturdimiento", _state() == &"Ground")

	# Subir escaleras (la cámara mira hacia -Z, así que "adelante" = subir)
	_player.global_position = Vector3(8, 0.1, -1.5)
	_player.reset_physics_interpolation()
	await _wait(0.3)
	Input.action_press("move_forward")
	await _wait(2.0)
	Input.action_release("move_forward")
	_check("Sube las escaleras (altura %.2f)" % _player.global_position.y, _player.global_position.y > 2.3)


func _state() -> StringName:
	return _player.state_machine.current.name


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
