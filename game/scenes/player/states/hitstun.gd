class_name PlayerHitstun
extends PlayerState
## Golpe recibido: Kael reacciona según la FUERZA y la DIRECCIÓN del golpe, sin poder actuar un momento.
## - Ligero: sacudida y un pequeño paso atrás.
## - Medio: retrocede tambaleándose.
## - Fuerte (golpes peligrosos, saltos, mucho daño): sale despedido, con un pequeño salto, y tarda más
##   en rehacerse.
## Golpe por la espalda: trastabilla hacia delante sin girarse.

enum Strength { LIGHT, MEDIUM, HEAVY }

## A partir de cuánto daño un golpe es medio o fuerte.
const MEDIUM_DAMAGE: float = 18.0
const HEAVY_DAMAGE: float = 34.0
## Empujón (m/s), segundos sin poder actuar y animación de cada fuerza.
const KNOCKBACK: Dictionary = {Strength.LIGHT: 3.2, Strength.MEDIUM: 5.2, Strength.HEAVY: 8.0}
const DURATION: Dictionary = {Strength.LIGHT: 0.35, Strength.MEDIUM: 0.5, Strength.HEAVY: 0.78}
## Frenado del empujón (m/s²): da unos 0,3 m (ligero), 0,7 m (medio) y 1,3 m (fuerte) de retroceso.
const BRAKE: Dictionary = {Strength.LIGHT: 16.0, Strength.MEDIUM: 20.0, Strength.HEAVY: 24.0}

var _elapsed: float
var _duration: float
var strength: Strength = Strength.LIGHT


## Fuerza de un golpe según su daño y su tipo.
static func strength_of(damage: float, perilous: bool) -> Strength:
	if perilous or damage >= HEAVY_DAMAGE:
		return Strength.HEAVY
	return Strength.MEDIUM if damage >= MEDIUM_DAMAGE else Strength.LIGHT


func enter(msg: Dictionary) -> void:
	_elapsed = 0.0
	var from: Vector3 = msg.get("from", player.get_facing())
	strength = msg.get("strength", Strength.LIGHT)
	_duration = maxf(DURATION[strength], player.hitstun_duration)
	var behind: bool = player.get_facing().dot(from) < -0.3
	# Lo empuja en la dirección del golpe (alejándolo del atacante).
	var push: Vector3 = -from * KNOCKBACK[strength]
	player.velocity.x = push.x
	player.velocity.z = push.z
	if strength == Strength.HEAVY and player.is_on_floor():
		player.velocity.y = 2.6  # Sale despedido: los pies dejan el suelo un instante.
	if behind:
		# Por la espalda: no se gira; se inclina hacia delante y trastabilla.
		player.body.flinch(from, 1.4)
		player.body.play_action(&"hit_light", 0.1, 1.8, 0.04)
	else:
		player.snap_facing(from)
		match strength:
			Strength.LIGHT:
				player.body.play_action(&"hit_light", 0.05, 1.6, 0.04)
			Strength.MEDIUM:
				player.body.play_action(&"hit", 0.0, 1.5, 0.04)
			Strength.HEAVY:
				player.body.play_action(&"hit", 0.0, 1.05, 0.03)
	Voice.say(&"kael", &"hurt", player.global_position + Vector3.UP * 1.6)


func physics_update(delta: float) -> void:
	_elapsed += delta
	# El empujón se frena como un cuerpo que arrastra los pies.
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z).move_toward(Vector3.ZERO, BRAKE[strength] * delta)
	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.z
	player.apply_gravity(delta)
	if _elapsed >= _duration:
		machine.transition_to(&"Ground" if player.is_on_floor() else &"Air")
