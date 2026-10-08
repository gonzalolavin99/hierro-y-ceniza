extends PlayerState
## Ejecuta cualquier movimiento del repertorio (PlayerMoves): combos, golpe pesado, patada, técnicas…
## Todo se sincroniza con el reloj de la animación: el arma hace daño justo cuando la animación golpea.
## Pulsar RB tras el primer impacto encadena el siguiente golpe del combo.
## Desde el segundo `cancel` se puede salir con guardia (LB) o paso rápido (B), como en Sekiro.

var _name: StringName
var _move: Dictionary
var _hit_index: int
var _hit_active: bool
var _queued: bool
var _elapsed: float


func enter(msg: Dictionary) -> void:
	_name = msg.get("move", &"light_1")
	_move = PlayerMoves.MOVES[_name]
	_hit_index = 0
	_hit_active = false
	_queued = false
	_elapsed = 0.0
	player.consume_attack()
	player.snap_facing(player.attack_direction())
	player.body.set_blocking(false)
	var hits: Array = _move["hits"]
	player.body.play_shaped(_move["anim"], _move["from"], hits[0]["at"], _move["windup"])
	player.body.set_trail(true)


func exit() -> void:
	player.hitbox.deactivate()
	player.body.set_trail(false)


func physics_update(delta: float) -> void:
	_elapsed += delta
	var t: float = player.body.action_time()
	var hits: Array = _move["hits"]
	var air: bool = _move.get("air", false)

	# Movimiento: en tierra, el paso real de la animación; en el aire, caída con algo de impulso.
	player.apply_gravity(delta)
	if air:
		player.velocity.x *= 0.98
		player.velocity.z *= 0.98
	else:
		player.apply_root_motion(player.lock_target)
	# Antes del primer impacto, sigue un poco al objetivo fijado.
	if t < hits[0]["at"] and player.lock_target:
		player.face_direction(player.direction_to_lock_target(), delta * 0.6)

	# Impactos
	if _hit_index < hits.size():
		var hit: Dictionary = hits[_hit_index]
		if not _hit_active and t >= hit["at"] - PlayerMoves.HIT_BEFORE:
			var data := HitData.create(player, hit["damage"], hit["posture"])
			data.guard_break = hit.get("guard_break", false)
			player.hitbox.activate(data)
			_hit_active = true
			Sfx.play(&"swing", player.global_position + Vector3.UP * 1.3, -2.0)
		elif _hit_active and t > hit["at"] + PlayerMoves.HIT_AFTER:
			player.hitbox.deactivate()
			_hit_active = false
			_hit_index += 1
			if _hit_index >= hits.size():
				player.body.set_trail(false)

	# Encadenar: tras el primer impacto, RB guarda el siguiente golpe del combo.
	if t >= hits[0]["at"] - 0.1 and player.wants_attack():
		if player.try_deathblow():
			return
		if _move.has("next"):
			_queued = true
		player.consume_attack()

	var done_hitting: bool = _hit_index >= hits.size()
	if done_hitting and _queued:
		machine.transition_to(&"Attack", {"move": _move["next"]})
	elif t >= _move["cancel"] and Input.is_action_pressed("block"):
		machine.transition_to(&"Block")
	elif t >= _move["cancel"] and Input.is_action_just_pressed("dodge"):
		machine.transition_to(&"Dash")
	elif t >= _move["end"] or _elapsed > 3.0 or (air and done_hitting and player.is_on_floor()):
		machine.transition_to(&"Ground" if player.is_on_floor() else &"Air")
