class_name FrankMeet
extends LevelCutscene
## Escena de la red (guion §12): Kael corta la cuerda, Frank cae, se sacude y le habla a chillidos.
## Kael lo manda con los suyos; Frank le cuenta (a su manera) que los suyos no lo quieren por los rulos.
## El anciano recuerda que aquella mirada sí la entendió, y Frank se le sube al hombro para quedarse.
## Planos: cut, frank, kael, curls, two, hop, end. Mantener A 1 s la salta (Frank acaba igual en el hombro).

var _snare: FrankSnare
var _frank: Frank


func setup(snare: FrankSnare, player: Player, frank: Frank) -> void:
	_snare = snare
	_player = player
	_frank = frank


func _begin() -> void:
	# Kael, delante de la red y mirándola.
	var spot: Vector3 = _snare.kael_spot()
	_player.global_position = Vector3(spot.x, _player.global_position.y, spot.z)
	_player.reset_physics_interpolation()
	var to_bag: Vector3 = _snare.bag_position() - _player.global_position
	_player.model.global_rotation.y = atan2(-to_bag.x, -to_bag.z)


func _run() -> void:
	var kael: Vector3 = _player.global_position
	var to_bag: Vector3 = _snare.bag_position() - kael
	to_bag.y = 0.0
	to_bag = to_bag.normalized()
	var side: Vector3 = to_bag.cross(Vector3.UP)
	var mid: Vector3 = kael + to_bag * 0.6
	# 1. Plano de lado: Kael corta la cuerda y Frank cae a sus pies.
	shot = &"cut"
	_place(mid + side * 3.4 + Vector3.UP * 1.5, mid + Vector3.UP * 1.2)
	_push(mid + side * 3.0 + Vector3.UP * 1.4, 4.0)
	_frank.say(&"happy")
	if not await _wait(0.5):
		return
	_player.body.play_action(&"slash_a", 0.0, 1.1, 0.1)
	if not await _wait(0.4):
		return
	_snare.drop_bag()
	var landing: Vector3 = kael + to_bag * 0.55 + side * 0.5
	landing.y = kael.y
	var to_kael: Vector3 = kael - landing
	_frank.hop_to_ground(landing, to_kael, 0.55, 0.35)
	if not await _wait(0.7):
		return
	_frank.shake()
	_player.body.stop_action(0.4)
	if not await _wait(0.8):
		return
	# 2. Frank, desde abajo, a la altura del mono: "¡Por fin!"
	shot = &"frank"
	_frank.look_target = _player.global_position + Vector3.UP * 1.6
	_frank_close_up(landing, to_kael.normalized(), side)
	if not await _line(&"frank", &"meet_1", 0.4, _frank.head_position()):
		return
	# 3. Kael, visto desde el suelo (lo que ve Frank): "Anda, vete."
	shot = &"kael"
	var low: Vector3 = landing - to_kael.normalized() * 1.0 + Vector3.UP * 0.85
	_place(low, kael + Vector3.UP * 1.5)
	_push(low + Vector3.UP * 0.05 + to_kael.normalized() * 0.15, 4.0)
	if not await _line(&"kael_scene", &"frank_1"):
		return
	# 4. Se toca los rulos y se queda cabizbajo: "Los míos no me quieren. Por los rulos."
	shot = &"curls"
	_frank.pose = Frank.Pose.TOUCH_CURLS
	_frank_close_up(landing, to_kael.normalized(), side)
	if not await _wait(0.9):
		return
	_frank.pose = Frank.Pose.SAD
	if not await _line(&"frank", &"meet_2", 0.6, _frank.head_position()):
		return
	# 5. Plano de los dos; el anciano recuerda.
	shot = &"two"
	_frank.pose = Frank.Pose.IDLE
	var two: Vector3 = (kael + landing) * 0.5
	_place(two + side * 2.6 + Vector3.UP * 0.9 - to_bag * 0.8, two + Vector3.UP * 0.6)
	_push(two + side * 2.2 + Vector3.UP * 0.85 - to_bag * 0.7, 6.0)
	if not await _line(&"narrator", &"story_frank_meet", 0.4):
		return
	# 6. De un salto, al hombro: "Me quedo contigo. Alguien tiene que cuidarte."
	shot = &"hop"
	_frank.look_target = null
	_close_up(_player.body, 1.45, 1.9)
	_frank.hop_to_shoulder(0.6)
	if not await _wait(0.8):
		return
	_frank.look_target = _camera.global_position
	if not await _line(&"frank", &"meet_3", 0.4, _frank.head_position()):
		return
	# 7. "…Haz lo que quieras." Frank, encantado.
	shot = &"end"
	_frank.look_target = _player.global_position + Vector3.UP * 1.65
	if not await _line(&"kael_scene", &"frank_2", 0.2):
		return
	_frank.say(&"happy")
	if not await _wait(1.0):
		return
	_finish()


func _frank_close_up(at: Vector3, frank_forward: Vector3, side: Vector3) -> void:
	var head: Vector3 = at + Vector3.UP * 0.22
	_place(head + frank_forward * 0.95 + side * 0.45 + Vector3.UP * 0.12, head + Vector3.DOWN * 0.04)
	_push(head + frank_forward * 0.8 + side * 0.38 + Vector3.UP * 0.1, 4.0)


func _end() -> void:
	_player.body.stop_action(0.2)
	_snare.drop_bag()
	_frank.perch()
	Story.mark_heard(Frank.STORY_MET)
	Story.mark_heard(Frank.STORY_FREED)
	SaveGame.save(_player)
