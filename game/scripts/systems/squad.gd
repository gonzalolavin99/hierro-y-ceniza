extends Node
## Turnos de ataque en las peleas de grupo (autoload Squad). Como en Sekiro, aunque haya varios
## enemigos, ataca uno cada vez: el que tiene el "turno". Los demás esperan rodeando al jugador con la
## guardia alta (estado Circle) y piden el turno; lo recibe el que lleva más rato esperando, y entre el
## ataque de uno y el del siguiente hay un respiro (TURN_GAP) para que el jugador pueda leerlos.
## Con un solo enemigo no cambia nada: siempre tiene el turno.

## Respiro entre el ataque de un enemigo y el de otro distinto.
const TURN_GAP: float = 0.6
## Si quien tiene el turno no llega a atacar en este tiempo (p. ej. el jugador huye), lo pierde.
const TURN_TIMEOUT: float = 4.0
## Quien deja de pedir el turno durante este rato sale de la cola.
const WAIT_FORGET: float = 0.5

var _clock: float = 0.0
var _turn: Enemy = null
var _turn_since: float = 0.0
var _last_end: float = -100.0
var _last_attacker: Enemy = null
## Enemigo -> [desde cuándo espera, última vez que pidió]
var _waiting: Dictionary = {}
## Distancia a la que duermen los enemigos tranquilos (0 = nunca). Ver update_sleep().
var sleep_distance: float = 0.0
const SLEEP_DISTANCE: float = 40.0
const SLEEP_CHECK: float = 0.25
var _sleep_left: float = 0.0


func _physics_process(delta: float) -> void:
	_clock += delta
	_sleep_left -= delta
	if _sleep_left <= 0.0:
		_sleep_left = SLEEP_CHECK
		update_sleep()


## Enemigos que "duermen" (revisión del estudio, programación): a más de `sleep_distance` de Kael, un enemigo
## tranquilo (quieto, de ronda o muerto) deja de pensar, animarse y ajustar los pies hasta que Kael se acerca.
## 0 = nadie duerme (el patio de pruebas). El Paso de Hierro lo pone a SLEEP_DISTANCE.
func update_sleep() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var awake: int = 0
	var total: int = 0
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null:
			continue
		total += 1
		var far: bool = sleep_distance > 0.0 and player != null 			and enemy.global_position.distance_to(player.global_position) > sleep_distance
		enemy.set_asleep(far and enemy.can_sleep())
		if not enemy.asleep:
			awake += 1
	if sleep_distance > 0.0:
		DebugOverlay.watch("Enemigos activos", "%d de %d" % [awake, total])


## Reloj de juego (se frena con la pausa de impacto).
func clock() -> float:
	return _clock


## Pide el turno de ataque. Devuelve true si este enemigo puede atacar ya.
func request_turn(enemy: Enemy) -> bool:
	_drop_invalid()
	if _turn == enemy:
		return true
	var entry: Array = _waiting.get(enemy, [_clock, _clock])
	entry[1] = _clock
	_waiting[enemy] = entry
	_forget_idle()
	if _turn != null:
		return false
	if enemy != _last_attacker and _clock - _last_end < TURN_GAP:
		return false
	for other: Enemy in _waiting:
		if other != enemy and _waiting[other][0] < entry[0]:
			return false  # Otro lleva más rato esperando: va antes.
	_give(enemy)
	return true


## Toma el turno sin pedirlo (al empezar cualquier ataque, p. ej. un contraataque tras bloquear).
func take_turn(enemy: Enemy) -> void:
	_give(enemy)


## Termina su ataque: suelta el turno y empieza el respiro.
func end_turn(enemy: Enemy) -> void:
	if _turn == enemy:
		_turn = null
		_last_end = _clock
		_last_attacker = enemy


## ¿Tiene otro enemigo el turno? (para no meterse a atacar mientras tanto)
## ¿Tiene este enemigo el turno de ataque?
func has_turn(enemy: Enemy) -> bool:
	return _turn == enemy


func is_busy_for(enemy: Enemy) -> bool:
	_drop_invalid()
	return _turn != null and _turn != enemy


func reset() -> void:
	_turn = null
	_last_end = -100.0
	_last_attacker = null
	_waiting.clear()


func _give(enemy: Enemy) -> void:
	_turn = enemy
	_turn_since = _clock
	_waiting.erase(enemy)


## Suelta el turno si quien lo tiene ya no puede usarlo (muerto, roto, aturdido, sin objetivo, o tarda mucho).
func _drop_invalid() -> void:
	if _turn == null:
		return
	var lost: bool = not is_instance_valid(_turn) or _turn.is_dead() or not _turn.has_target()
	if not lost:
		var state: StringName = _turn.state_name()
		lost = state == &"Broken" or state == &"Dazed" \
			or (state != &"Attack" and _clock - _turn_since > TURN_TIMEOUT)
	if lost:
		var who: Enemy = _turn if is_instance_valid(_turn) else null
		_turn = null
		_last_end = _clock
		_last_attacker = who


func _forget_idle() -> void:
	for other: Enemy in _waiting.keys():
		if not is_instance_valid(other) or other.is_dead() or _clock - _waiting[other][1] > WAIT_FORGET:
			_waiting.erase(other)
