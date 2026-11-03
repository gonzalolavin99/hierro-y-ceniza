extends PlayerState
## Muerte (temporal): cae y reaparece en el punto de inicio.
## En el Hito 3 aquí entrará el campamento, la pérdida de experiencia
## y la voz del narrador: "No… no fue así".

const RESPAWN_AFTER: float = 2.5

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	player.hitbox.deactivate()
	player.lock_target = null
	player.body.set_blocking(false)
	player.body.play_action(&"death", 0.0, 1.0, 0.08)
	Voice.say(&"kael", &"death", player.global_position + Vector3.UP * 1.0)
	# El enemigo celebra y, al poco, el narrador (Kael anciano) se corrige: "No… no fue así."
	var winner: Enemy = player.engaged_enemy
	if winner and not winner.is_dead():
		get_tree().create_timer(0.7, false).timeout.connect(Voice.say.bind(&"soldier", &"victory", winner.lock_point()))
	get_tree().create_timer(1.6, false).timeout.connect(Voice.say.bind(&"narrator", &"player_death", Vector3.ZERO))


func physics_update(delta: float) -> void:
	_elapsed += delta
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_acceleration, delta)
	player.apply_gravity(delta)
	if _elapsed >= RESPAWN_AFTER:
		player.respawn()
		machine.transition_to(&"Ground")
