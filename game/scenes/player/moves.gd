class_name PlayerMoves
extends RefCounted
## Repertorio de Kael. Cada movimiento se describe con datos; el estado Attack los ejecuta.
##
## anim:    animación de la biblioteca.
## from:    segundo de la animación en que empieza.
## windup:  segundos reales hasta el primer impacto (la animación se ajusta para coincidir).
## hits:    impactos, en segundos DE LA ANIMACIÓN: {at, damage, posture, guard_break?}.
## end:     segundo de la animación en que termina el movimiento.
## cancel:  desde qué segundo de la animación se puede cancelar con guardia o paso rápido.
## next:    movimiento al que encadena si se vuelve a pulsar ataque (combo).
## air:     se ejecuta en el aire (sin paso real; cae con gravedad).
##
## Impactos medidos con tests/measure_swings.gd (mano) y tests/measure_feet.gd (pie).

const MOVES: Dictionary[StringName, Dictionary] = {
	# Combo ligero: tres tramos seguidos de un mismo combo a una mano.
	&"light_1": {"anim": &"combo_one_hand", "from": 0.72, "windup": 0.19, "end": 1.40, "cancel": 1.08, "next": &"light_2",
		"hits": [{"at": 1.00, "damage": 12.0, "posture": 10.0}]},
	&"light_2": {"anim": &"combo_one_hand", "from": 1.68, "windup": 0.18, "end": 2.35, "cancel": 2.03, "next": &"light_3",
		"hits": [{"at": 1.95, "damage": 12.0, "posture": 10.0}]},
	&"light_3": {"anim": &"combo_one_hand", "from": 2.62, "windup": 0.24, "end": 3.45, "cancel": 3.10,
		"hits": [{"at": 2.98, "damage": 18.0, "posture": 16.0}]},
	# Golpe pesado (RT): tajo descendente lento que castiga mucho la postura.
	&"heavy": {"anim": &"slash_c", "from": 0.15, "windup": 0.45, "end": 1.45, "cancel": 1.00,
		"hits": [{"at": 0.83, "damage": 26.0, "posture": 30.0}]},
	# Ataque a la carrera: estocada que aprovecha el impulso.
	&"run_attack": {"anim": &"slash_b", "from": 0.0, "windup": 0.2, "end": 0.95, "cancel": 0.45,
		"hits": [{"at": 0.33, "damage": 16.0, "posture": 14.0}]},
	# Contraataque justo después de un paso rápido.
	&"dodge_attack": {"anim": &"slash_d", "from": 0.2, "windup": 0.14, "end": 0.95, "cancel": 0.55,
		"hits": [{"at": 0.47, "damage": 14.0, "posture": 14.0}]},
	# Tajo descendente desde el aire.
	&"air_attack": {"anim": &"slash_c", "from": 0.45, "windup": 0.22, "end": 1.30, "cancel": 1.00, "air": true,
		"hits": [{"at": 0.83, "damage": 20.0, "posture": 24.0}]},
	# Patada (Y): poco daño, pero rompe la guardia y deja al rival expuesto.
	&"kick": {"anim": &"kick", "from": 0.25, "windup": 0.2, "end": 1.10, "cancel": 0.75,
		"hits": [{"at": 0.53, "damage": 4.0, "posture": 30.0, "guard_break": true}]},
	# Técnica "Torbellino" (LB + RB): giro completo con dos tajos.
	&"art_whirlwind": {"anim": &"spin", "from": 0.25, "windup": 0.3, "end": 1.60, "cancel": 1.30,
		"hits": [{"at": 0.52, "damage": 14.0, "posture": 14.0}, {"at": 1.12, "damage": 18.0, "posture": 20.0}]},
}

## Margen (en segundos de animación) alrededor de cada impacto en que el arma hace daño.
const HIT_BEFORE: float = 0.05
const HIT_AFTER: float = 0.07
