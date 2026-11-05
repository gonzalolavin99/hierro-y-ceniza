extends PlayerState
## Muerte: cae, el narrador se corrige ("No… no fue así"), la pantalla se funde a negro y Kael
## reaparece en el último campamento donde descansó. Los enemigos vuelven todos a su puesto.

const FADE_FROM: float = 2.6
const RESPAWN_AFTER: float = 3.4
const FADE_IN: float = 0.9

var _faded: bool

var _elapsed: float


func enter(_msg: Dictionary) -> void:
	_elapsed = 0.0
	_faded = false
	player.drop_xp()
	player.hitbox.deactivate()
	player.lock_target = null
	player.body.set_blocking(false)
	player.body.play_action(&"death", 0.0, 1.0, 0.08)
	Voice.say(&"kael", &"death", player.global_position + Vector3.UP * 1.0)
	# El enemigo celebra y, al poco, el narrador (Kael anciano) se corrige: "No… no fue así."
	var winner: Enemy = player.engaged_enemy
	if winner and not winner.is_dead():
		get_tree().create_timer(0.7, false).timeout.connect(Voice.say.bind(&"soldier", &"victory", winner.lock_point()))
	get_tree().create_timer(2.3, false).timeout.connect(Voice.say.bind(&"narrator", Story.death_event(), Vector3.ZERO))


func physics_update(delta: float) -> void:
	_elapsed += delta
	player.move_horizontal(Vector3.ZERO, 0.0, player.ground_acceleration, delta)
	player.apply_gravity(delta)
	if not _faded and _elapsed >= FADE_FROM:
		_faded = true
		Camps.fade_to(1.0, RESPAWN_AFTER - FADE_FROM)
	if _elapsed >= RESPAWN_AFTER:
		player.respawn()
		Camps.reset_world()
		Camps.fade_to(0.0, FADE_IN)
		machine.transition_to(&"Ground")
