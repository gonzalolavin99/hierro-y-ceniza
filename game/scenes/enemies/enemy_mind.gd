class_name EnemyMind
extends RefCounted
## "Mente" del enemigo: observa los hábitos del jugador (solo lo que un rival real vería: si desvía,
## si esquiva, si se cubre, si ataca sin pausa) y adapta su estrategia AL EMPEZAR cada ataque.
## No hace trampas: nunca reacciona al botón que el jugador pulsa en mitad de un golpe.

## Ataques normales y peligrosos que elige (ver EnemyAttackState.PATTERNS).
const NORMAL: Array[StringName] = [&"single", &"double", &"double", &"thrust_combo", &"single", &"double"]
const DANGER: Array[StringName] = [&"sweep", &"thrust", &"slash_thrust"]
const THRUSTS: Array[StringName] = [&"thrust", &"slash_thrust", &"thrust_combo"]
## Proporción de ataques peligrosos en condiciones normales.
const DANGER_RATIO: float = 0.33
## El agarre solo tiene sentido de cerca.
const GRAB_RANGE: float = 1.9
## Ventanas de memoria (segundos).
const DASH_MEMORY: float = 4.0
const BLOCKED_MEMORY: float = 5.0
## Desde cuántos desvíos seguidos empieza a retrasar golpes, y desde cuántos amaga.
const DELAY_FROM_STREAK: int = 3
const FEINT_FROM_STREAK: int = 5
## Segundos con la guardia alta para considerar que el jugador "se esconde" tras ella.
const TURTLE_TIME: float = 2.0

var rng := RandomNumberGenerator.new()
## Repertorio de este tipo de enemigo (por defecto, el del soldado). Ver Enemy.moveset.
var normal_patterns: Array[StringName] = NORMAL.duplicate()
var danger_patterns: Array[StringName] = DANGER.duplicate()
var danger_ratio: float = DANGER_RATIO
## ¿Puede agarrar? (el agarre se elige aparte, solo de cerca)
var can_grab: bool = true
## Solo para pruebas que no tratan de la IA: no se adapta al jugador (ni retrasa, ni amaga, ni cambia
## de ataques o de cuándo contraataca); se comporta como un soldado de ritmo fijo y repetible.
var predictable: bool = false
## Desvíos seguidos del jugador sin que le acierte un golpe.
var deflect_streak: int = 0

var _clock: float = 0.0
var _dash_times: Array[float] = []
var _blocked_times: Array[float] = []
var _guard_time: float = 0.0


func _init() -> void:
	rng.randomize()


# --- Observación -----------------------------------------------------------------

func observe_time(delta: float) -> void:
	_clock += delta
	_dash_times = _dash_times.filter(func(t: float) -> bool: return _clock - t <= DASH_MEMORY)
	_blocked_times = _blocked_times.filter(func(t: float) -> bool: return _clock - t <= BLOCKED_MEMORY)


## Cada fotograma: ¿tiene el jugador la guardia alta?
func observe_guard(guarding: bool, delta: float) -> void:
	observe_time(delta)
	_guard_time = _guard_time + delta if guarding else 0.0


func on_player_deflect() -> void:
	deflect_streak += 1


## Le acertó un golpe al jugador: la racha de desvíos se rompe.
func on_player_hit() -> void:
	deflect_streak = 0


func on_player_dash() -> void:
	_dash_times.append(_clock)


## El jugador le golpeó y él lo bloqueó.
func on_attack_blocked() -> void:
	_blocked_times.append(_clock)


# --- Lectura del jugador ---------------------------------------------------------

func is_dash_abusing() -> bool:
	return _dash_times.size() >= 3 and not predictable


func is_turtling() -> bool:
	return _guard_time >= TURTLE_TIME and not predictable


func is_reckless() -> bool:
	return _blocked_times.size() >= 5 and not predictable


## Probabilidad de retrasar un golpe normal (aguantar la espada arriba antes de soltarla).
func delay_chance() -> float:
	if predictable:
		return 0.0
	if deflect_streak < DELAY_FROM_STREAK:
		return 0.1
	return minf(0.5 + 0.07 * (deflect_streak - DELAY_FROM_STREAK), 0.75)


## Probabilidad de que un golpe retrasado sea un amago (no llega a soltarlo).
func feint_chance() -> float:
	return 0.25 if deflect_streak >= FEINT_FROM_STREAK and not predictable else 0.0


## Tras cuántos bloqueos seguidos contraataca (antes si el jugador ataca sin pausa).
func blocks_before_counter(base: int) -> int:
	return maxi(base - 1, 2) if is_reckless() else base


# --- Decisiones (se toman al empezar cada ataque) --------------------------------

## Ajusta el repertorio a un tipo de enemigo. `danger` puede incluir &"grab" (solo se usa de cerca).
func configure(normal: Array[StringName], danger: Array[StringName], ratio: float) -> void:
	if not normal.is_empty():
		normal_patterns = normal.duplicate()
	danger_patterns = danger.filter(func(p: StringName) -> bool: return p != &"grab")
	can_grab = &"grab" in danger
	danger_ratio = ratio


func pick_pattern(distance: float) -> StringName:
	var close: bool = distance <= GRAB_RANGE
	if is_turtling() and rng.randf() < 0.75:
		if close and can_grab and rng.randf() < 0.5:
			return &"grab"
		if &"sweep" in danger_patterns:
			return &"sweep"
	if is_dash_abusing() and rng.randf() < 0.6:
		var thrusts: Array[StringName] = THRUSTS.filter(func(p: StringName) -> bool:
			return p in normal_patterns or p in danger_patterns)
		if not thrusts.is_empty():
			return thrusts[rng.randi() % thrusts.size()]
	if rng.randf() < danger_ratio:
		var options: Array[StringName] = danger_patterns.duplicate()
		if close and can_grab:
			options.append(&"grab")
		if not options.is_empty():
			return options[rng.randi() % options.size()]
	return normal_patterns[rng.randi() % normal_patterns.size()]


## Segundos que aguantará un golpe normal antes de soltarlo (0 = sin retraso).
func choose_delay() -> float:
	return rng.randf_range(0.25, 0.5) if rng.randf() < delay_chance() else 0.0


func choose_feint() -> bool:
	return rng.randf() < feint_chance()


## Resumen para la pantalla de depuración (F3).
func describe() -> String:
	var reads: PackedStringArray = []
	if deflect_streak >= DELAY_FROM_STREAK:
		reads.append("desvías mucho (%d) → retrasa golpes%s" % [deflect_streak, " y amaga" if feint_chance() > 0.0 else ""])
	if is_dash_abusing():
		reads.append("esquivas mucho → estocadas")
	if is_turtling():
		reads.append("te cubres → barridos y agarres")
	if is_reckless():
		reads.append("atacas sin pausa → contraataca antes")
	return "normal" if reads.is_empty() else " · ".join(reads)
