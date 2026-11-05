extends Node
## Prueba automática del duelo con la Capitana Varga: entrar en el patio baja el rastrillo y muestra su
## barra; el primer golpe mortal no la vence (se rehace con todo: fase 2); el segundo sí; al caer sube el
## rastrillo y queda vencida para siempre. Si Kael muere en el duelo, todo vuelve a empezar.
## Ejecutar: Godot --headless --path game res://tests/varga_test.tscn

const TEST_PATH: String = "user://save_varga_test.json"

var _player: Player
var _arena: VargaArena
var _failures: int = 0


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	_player = get_tree().get_first_node_in_group("player") as Player
	_arena = get_tree().get_first_node_in_group("arenas") as VargaArena
	for node in get_tree().get_nodes_in_group("enemies"):
		if node != _arena.varga:
			(node as Enemy).aggro_range = 0.0
	await _wait(0.5)
	await _run()
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	var varga: Enemy = _arena.varga
	_check("Varga está en su patio, esperando", varga != null and not varga.has_target() and not _arena.is_active())
	_check("Es jefa: 2 golpes mortales", varga.boss and varga.deathblows == 2 and varga.deathblows_left == 2)
	_check("El rastrillo está arriba y se puede pasar", not _arena.gate_closed() and not _blocked_exit())

	# 1. Kael entra en el patio: empieza el duelo.
	_teleport(_arena.global_position + Vector3(-11.0, 0.0, 0.0))
	await _wait(1.0)
	_check("Al entrar empieza el duelo", _arena.is_active() and varga.has_target())
	_check("…bajan el rastrillo detrás", _arena.gate_closed())
	var bar: BossBar = _arena.find_children("*", "BossBar", true, false)[0]
	_check("…y aparece su barra con 2 puntos", bar.is_showing() and bar.dots_left() == 2)
	_check("El rastrillo cierra la salida", _blocked_exit())

	_check("Habla con su propia voz", varga.voice == &"varga" and VoiceLines.LINES.has(&"varga"))
	await _moves(varga)

	# 2. Primer golpe mortal: se rehace (fase 2).
	await _break_and_deathblow(varga)
	_check("El primer golpe mortal no la vence (%s)" % varga.state_name(), not varga.is_dead() and varga.state_name() == &"Rally")
	_check("…pasa a la fase 2 con 1 punto", varga.phase() == 2 and bar.dots_left() == 1)
	_check("…con la vida y la postura llenas", varga.health.ratio() == 1.0 and varga.posture.current == 0.0)
	_check("En la fase 2 cambia: más rápida, abanico de cuchillos y combo largo (%s)" % str(varga.moveset),
		&"varga_fan" in varga.ranged_patterns and &"varga_combo_long" in varga.moveset and varga.walk_speed > 4.5)
	await _wait(2.8)
	_check("Se levanta y sigue peleando (%s)" % varga.state_name(), varga.state_name() != &"Rally" and not varga.is_dead())

	# 3. Kael muere en el duelo: todo vuelve a empezar.
	_player.state_machine.transition_to(&"Dead")
	await _wait(4.2)
	_check("Al morir Kael, el rastrillo sube", not _arena.gate_closed() and not _arena.is_active())
	_check("Varga vuelve a su puesto, entera (2 puntos)", varga.deathblows_left == 2 and not varga.has_target())
	_check("La barra se oculta", not bar.is_showing())
	_check("Vuelve a la fase 1 (sin el abanico)", not &"varga_fan" in varga.ranged_patterns and varga.walk_speed < 4.5)

	# 4. Revancha: dos golpes mortales la vencen.
	_teleport(_arena.global_position + Vector3(-11.0, 0.0, 0.0))
	await _wait(1.0)
	_check("Volver a entrar empieza otra vez el duelo", _arena.is_active() and _arena.gate_closed())
	await _break_and_deathblow(varga)
	await _wait(2.8)
	await _break_and_deathblow(varga)
	await _wait(0.5)
	_check("El segundo golpe mortal la vence", varga.is_dead())
	await _wait(2.5)
	_check("El rastrillo sube", not _arena.gate_closed())
	_check("…y la salida queda libre", not _blocked_exit())
	_check("Queda vencida en la historia y en la partida", Story.heard(VargaArena.DEFEATED_FLAG) and "boss_varga" in SaveGame.read().get("story", {}).get("heard", []))
	Camps.reset_world()
	await _wait(0.5)
	_check("Descansar no la devuelve", varga.is_dead())


## Su repertorio propio: cada ataque termina bien; el salto acorta la distancia; los cuchillos hieren y se
## pueden bloquear.
func _moves(varga: Enemy) -> void:
	var names: Array[StringName] = []
	for key in EnemyAttackState.PATTERNS:
		if String(key).begins_with("varga_"):
			names.append(key)
	_check("Tiene su repertorio propio (%d ataques)" % names.size(), names.size() >= 7)
	for pattern in names:
		await _face_off(varga, 3.0)
		varga.state_machine.transition_to(&"Attack", {"pattern": pattern})
		var ended: bool = false
		for i in 60:
			await _wait(0.1)
			if varga.state_name() != &"Attack":
				ended = true
				break
		_check("%s termina (%s)" % [pattern, varga.state_name()], ended and varga.is_on_floor())

	# Salto: desde lejos cae junto a Kael.
	await _face_off(varga, 8.0)
	varga.state_machine.transition_to(&"Attack", {"pattern": &"varga_leap"})
	await _wait(0.9)
	_check("El salto la deja junto a Kael (%.1f m)" % varga.distance_to_target(), varga.distance_to_target() < 3.0)

	# Cuchillos: hieren a Kael quieto; con la guardia, se bloquean.
	await _face_off(varga, 6.0)
	_player.health.heal(999.0)
	var before: float = _player.health.current
	varga.state_machine.transition_to(&"Attack", {"pattern": &"varga_knives_far"})
	await _wait(1.4)
	_check("Los cuchillos hieren (vida %.0f → %.0f)" % [before, _player.health.current], _player.health.current < before)
	await _face_off(varga, 6.0)
	_player.health.heal(999.0)
	before = _player.health.current
	_player.state_machine.transition_to(&"Block")
	Input.action_press("block")
	varga.state_machine.transition_to(&"Attack", {"pattern": &"varga_knives_far"})
	await _wait(1.4)
	Input.action_release("block")
	_check("Con la guardia se bloquean (vida %.0f)" % _player.health.current, is_equal_approx(_player.health.current, before))
	await _face_off(varga, 4.0)


## Kael y Varga frente a frente a `distance` metros, en el centro del patio, sin que ella ataque sola.
func _face_off(varga: Enemy, distance: float) -> void:
	varga.state_machine.transition_to(&"Idle", {"wait": 100.0})
	await _wait(0.2)
	var center: Vector3 = _arena.global_position
	varga.global_position = center + Vector3(distance * 0.5, 0.0, 0.0)
	varga.velocity = Vector3.ZERO
	varga.model.rotation.y = 0.0
	varga.rotation.y = PI * 0.5
	varga.reset_physics_interpolation()
	_teleport(center - Vector3(distance * 0.5, 0.0, 0.0))
	_player.model.rotation.y = -PI * 0.5
	_player.health.heal(999.0)
	_player.posture.reset()
	await _wait(0.3)


## ¿Hay algo sólido entre el patio y el pasillo de salida, a la altura del pecho?
func _blocked_exit() -> bool:
	var space := _player.get_world_3d().direct_space_state
	var from: Vector3 = _arena.global_position + Vector3(-VargaArena.HALF + 2.0, 1.2, 0.0)
	var to: Vector3 = _arena.global_position + Vector3(-VargaArena.HALF - 4.0, 1.2, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return not space.intersect_ray(query).is_empty()


## Rompe su postura y da el golpe mortal (como lo haría Kael).
func _break_and_deathblow(varga: Enemy) -> void:
	varga.posture.add(varga.posture.max_posture + 10.0)
	await _wait(0.2)
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = varga.global_position - varga.get_facing() * -1.2
	_player.reset_physics_interpolation()
	varga.receive_deathblow(_player)
	await _wait(0.2)


func _teleport(at: Vector3) -> void:
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
