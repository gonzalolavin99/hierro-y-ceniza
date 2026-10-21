extends Node
## Prueba automática de los ataques peligrosos (aviso rojo): barrido, estocada y agarre,
## y las respuestas del jugador: saltar + pisotón, pisar la hoja, esquivar.
## Ejecutar: Godot --headless --path game res://tests/danger_test.tscn
## Con ventana y una carpeta guarda capturas: Godot --path game res://tests/danger_test.tscn -- <carpeta>

var _player: Player
var _enemy: Enemy
var _failures: int = 0
var _warnings: Array[int] = []
var _deflects: int = 0
var _shots_dir: String = ""


func _ready() -> void:
	var level: Node = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(level)
	_player = get_tree().get_first_node_in_group("player") as Player
	_enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	if not OS.get_cmdline_user_args().is_empty():
		_shots_dir = OS.get_cmdline_user_args()[0]
	_enemy.danger_warned.connect(func(kind: int) -> void: _warnings.append(kind))
	_player.deflected.connect(func() -> void: _deflects += 1)
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	await _wait(0.3)
	await _tap("lock_on")
	_check("R3 fija al soldado", _player.lock_target == _enemy)

	# 1. Aviso rojo solo en los ataques peligrosos.
	await _reset()
	_attack(&"single")
	await _wait(0.3)
	_check("Un tajo normal no da aviso rojo", _warnings.is_empty())
	await _finish_attack()
	await _reset()
	_attack(&"sweep")
	await _wait(0.1)
	_check("El barrido da aviso rojo", _warnings == [HitData.Kind.SWEEP])
	_check("Se ve el destello rojo", _enemy.body.is_danger_flash_visible())
	await _shot("aviso_rojo")
	await _until_impact(0.0)
	await _shot("barrido")
	await _finish_attack()

	# 2. Un tajo normal se sigue pudiendo desviar.
	await _reset()
	_attack(&"single")
	await _until_impact(0.08)
	await _tap("block")
	await _finish_attack()
	_check("El tajo normal se desvía (%d)" % _deflects, _deflects >= 1)

	# 3. Barrido: bloquearlo no sirve; saltarlo, sí; y en el aire se puede pisar al enemigo.
	await _reset()
	Input.action_press("block")
	_attack(&"sweep")
	await _finish_attack()
	Input.action_release("block")
	_check("El barrido atraviesa la guardia (vida %.0f)" % _player.health.current, _hurt())

	await _reset()
	_attack(&"sweep")
	await _until_impact(0.15)
	await _tap("jump")
	await _finish_attack()
	_check("Saltar evita el barrido (vida %.0f)" % _player.health.current, not _hurt())

	await _reset()
	var posture_before: float = _enemy.posture.current
	_attack(&"sweep")
	await _until_impact(0.15)
	await _tap("jump")
	await _wait(0.2)
	await _shot("salto_sobre_barrido")
	await _tap("jump")
	await get_tree().physics_frame
	_check("Pisotón: rebota hacia arriba (%.1f m/s)" % _player.velocity.y, _player.velocity.y > 2.0)
	await _finish_attack()
	_check("Pisotón: daña la postura (%.0f → %.0f)" % [posture_before, _enemy.posture.current], _enemy.posture.current - posture_before >= 25.0)
	_check("Pisotón: sin daño al jugador", not _hurt())

	# 4. Estocada: atraviesa la guardia; pisar la hoja (paso hacia él) la contrarresta.
	await _reset()
	Input.action_press("block")
	_attack(&"thrust")
	await _finish_attack()
	Input.action_release("block")
	_check("La estocada atraviesa la guardia", _hurt())

	await _reset()
	posture_before = _enemy.posture.current
	_attack(&"thrust")
	await _until_impact(0.1)
	Input.action_press("move_forward")
	await _tap("dodge")
	Input.action_release("move_forward")
	var recoiled: bool = false
	for i in 60:
		await get_tree().physics_frame
		recoiled = recoiled or _enemy.state_name() == &"Recoil"
		if i == 10:
			await _shot("pisar_la_hoja")
	_check("Pisar la hoja: sin daño", not _hurt())
	_check("Pisar la hoja: el soldado queda expuesto", recoiled)
	_check("Pisar la hoja: mucha postura (%.0f → %.0f)" % [posture_before, _enemy.posture.current], _enemy.posture.current - posture_before >= 35.0)
	await _finish_attack()

	await _reset()
	posture_before = _enemy.posture.current
	_attack(&"thrust")
	await _until_impact(0.1)
	Input.action_press("move_right")
	await _tap("dodge")
	Input.action_release("move_right")
	await _finish_attack()
	_check("Esquivar la estocada a un lado: sin daño", not _hurt())
	_check("Esquivar a un lado no es contraataque", _enemy.posture.current - posture_before < 10.0)

	# 5. Agarre: ni bloqueo ni desvío sirven; esquivar sí.
	await _reset()
	Input.action_press("block")
	_attack(&"grab")
	await _finish_attack()
	Input.action_release("block")
	_check("El agarre atraviesa la guardia (vida %.0f)" % _player.health.current, _player.health.current <= _player.health.max_health - 30.0)

	await _reset()
	var deflects_before: int = _deflects
	_attack(&"grab")
	await _until_impact(0.08)
	await _tap("block")
	await _finish_attack()
	_check("El agarre no se puede desviar", _hurt() and _deflects == deflects_before)

	await _reset()
	_attack(&"grab")
	await _until_impact(0.12)
	Input.action_press("move_right")
	await _tap("dodge")
	Input.action_release("move_right")
	await _finish_attack()
	_check("Esquivar evita el agarre", not _hurt())


# --- Ayudas ---------------------------------------------------------------------

func _reset() -> void:
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.6)
	_player.global_position = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	_player.model.rotation.y = 0.0
	_enemy.global_position = Vector3(0.0, 0.0, -2.0)
	_enemy.model.rotation.y = PI
	_player.reset_physics_interpolation()
	_enemy.reset_physics_interpolation()
	_player.health.heal(_player.health.max_health)
	_player.posture.reset()
	_enemy.posture.reset()
	_warnings.clear()
	await _wait(0.3)


func _attack(pattern: StringName) -> void:
	_enemy.state_machine.transition_to(&"Attack", {"pattern": pattern})


## Espera hasta `lead` segundos antes del primer instante en que el tajo puede golpear.
func _until_impact(lead: float) -> void:
	for i in 300:
		var a := _enemy.state_machine.current as EnemyAttackState
		if a == null or a._phase != EnemyAttackState.Phase.WINDUP:
			return
		if a._timer >= a._swings[a._index]["windup"] - lead:
			return
		await get_tree().physics_frame


func _finish_attack() -> void:
	for i in 300:
		if not _enemy.state_machine.current is EnemyAttackState and _enemy.state_name() != &"Recoil":
			break
		await get_tree().physics_frame
	_enemy.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.4)


func _shot(label: String) -> void:
	if _shots_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.resize(800, 450)
	img.save_png(_shots_dir.path_join(label + ".png"))


func _hurt() -> bool:
	return _player.health.current < _player.health.max_health


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
