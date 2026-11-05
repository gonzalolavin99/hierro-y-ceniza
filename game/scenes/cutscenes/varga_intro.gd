class_name VargaIntro
extends LevelCutscene
## Escena antes del duelo con Varga (solo la primera vez): en el propio patio, con bandas negras de cine.
## Varga está junto a la ropa de los enfermos que arde; se gira, habla con Kael y desenvaina.
## Kael y Varga quedan en el estado "Scripted" mientras dura. Mantener A 1 s la salta.
## Al terminar emite `finished` y devuelve la cámara y los controles. Planos: wide, varga, kael, walk, draw.

var _arena: Node3D
var _varga: Enemy


func setup(arena: Node3D, player: Player, varga: Enemy) -> void:
	_arena = arena
	_player = player
	_varga = varga


func _begin() -> void:
	_varga.state_machine.transition_to(&"Scripted")
	# La ropa de los enfermos ardiendo: Frank no bromea, se queda cabizbajo.
	if _player.frank and _player.frank.mode == Frank.Mode.PERCHED:
		_player.frank.pose = Frank.Pose.SAD


func _run() -> void:
	# 1. Plano abierto desde detrás de Kael: Varga, de espaldas, junto al fuego de la ropa.
	shot = &"wide"
	var kael_at: Vector3 = _player.global_position
	var varga_at: Vector3 = _varga.global_position
	var across: Vector3 = (varga_at - kael_at).normalized()
	_face(_varga, across)  # Mira hacia el fuego (de espaldas a Kael).
	_place(kael_at - across * 2.6 + Vector3.UP * 1.9 + across.cross(Vector3.UP) * 0.9, varga_at + Vector3.UP * 1.2)
	_push(kael_at - across * 1.8 + Vector3.UP * 1.8 + across.cross(Vector3.UP) * 0.8, 7.0)
	if not await _line(&"narrator", &"story_varga_before", 0.3):
		return
	# 2. Se gira hacia Kael y habla (primer plano).
	_face(_varga, -across)
	if not await _wait(0.6):
		return
	shot = &"varga"
	_close_up(_varga.body, 1.6, 1.5)
	if not await _say_varga(&"intro_1"):
		return
	shot = &"kael"
	_close_up(_player.body, 1.6, 1.4)
	if not await _line(&"kael_scene", &"varga_1"):
		return
	# 3. Avanza hacia él mientras le contesta (plano de lado).
	shot = &"walk"
	var side: Vector3 = across.cross(Vector3.UP)
	var gap: float = kael_at.distance_to(varga_at)
	var mid: Vector3 = (kael_at + varga_at) * 0.5 + across * 1.5  # Algo más cerca de ella, que avanza.
	_place(mid + side * maxf(gap * 0.75, 6.0) + Vector3.UP * 1.8, mid + Vector3.UP * 1.0)
	(_varga.state_machine.current as EnemyScripted).walk_velocity = -across * 1.1
	if not await _say_varga(&"intro_2"):
		return
	(_varga.state_machine.current as EnemyScripted).walk_velocity = Vector3.ZERO
	shot = &"kael"
	_close_up(_player.body, 1.6, 1.3)
	if not await _line(&"kael_scene", &"varga_2"):
		return
	# 4. Desenvaina: "Entonces ven."
	shot = &"draw"
	_varga.body.play_action(&"draw", 0.0, 1.0, 0.15)
	var head: Vector3 = _varga.global_position + Vector3.UP * 1.5
	_place(head - across * 3.4 + side * 1.2 + Vector3.DOWN * 0.5, head)
	_push(head - across * 2.8 + side * 1.0 + Vector3.DOWN * 0.45, 4.0)
	if not await _say_varga(&"intro_3"):
		return
	_finish()


func _say_varga(event: StringName) -> bool:
	return await _line(&"varga", event, 0.5, _varga.lock_point())


func _face(enemy: Enemy, direction: Vector3) -> void:
	direction.y = 0.0
	enemy.model.global_rotation.y = atan2(-direction.x, -direction.z)


func _end() -> void:
	if _player.frank and _player.frank.mode == Frank.Mode.PERCHED:
		_player.frank.pose = Frank.Pose.IDLE
	_varga.body.stop_action(0.2)
	_varga.state_machine.transition_to(&"Idle", {"wait": 0.4})
