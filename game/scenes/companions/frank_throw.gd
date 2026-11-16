class_name FrankThrow
extends Node
## Frank distrae (guion §12, paso 4): con la cruz abajo (G en teclado) le lanza una fruta a un enemigo.
## - Enemigo desprevenido (no alerta): la fruta cae detrás de él, al otro lado de Kael; se gira a mirar qué
##   fue (estado "Suspicious") y le da la espalda a Kael: ventana para un golpe por la espalda.
## - En plena pelea: le da en la cara y lo aturde un momento (estado "Dazed"). A un jefe, casi nada: un respingo.
## Objetivo: el fijado; si no hay, el enemigo vivo más centrado delante de la cámara (a THROW_RANGE o menos).
## Recarga lenta (COOLDOWN). Solo con Frank en el hombro y Kael de pie (andando, corriendo o en guardia).

const COOLDOWN: float = 40.0
const THROW_RANGE: float = 16.0
## Ángulo mínimo con la cámara (coseno) para elegir objetivo sin fijar.
const AIM_DOT: float = 0.6
## Dónde cae, por detrás del enemigo desprevenido.
const DISTRACT_BEHIND: float = 3.0
const DAZE_SECONDS: float = 1.4
const ALLOWED_STATES: Array[StringName] = [&"Ground", &"Sprint", &"Block"]

var _frank: Frank
var _player: Player
## Segundos que faltan para poder lanzar otra.
var cooldown_left: float = 0.0
## Para pruebas: la última fruta lanzada.
var last_fruit: FrankFruit
## Enemigo al que acaba de distraer (para que Frank no avise además de que "ha oído algo").
var distracted: Enemy


func setup(frank: Frank, player: Player) -> void:
	_frank = frank
	_player = player


func is_available() -> bool:
	return _frank.mode == Frank.Mode.PERCHED and get_tree().get_node_count_in_group("cutscene") == 0


func is_ready() -> bool:
	return is_available() and cooldown_left <= 0.0


func _process(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if Input.is_action_just_pressed("frank_throw") and not get_tree().paused:
		try_throw()


## Intenta lanzar. Devuelve el enemigo al que va, o null (sin Frank, recargando o sin nadie a tiro).
func try_throw() -> Enemy:
	if not is_available() or not (_player.state_machine.current.name in ALLOWED_STATES):
		return null
	if cooldown_left > 0.0:
		_frank.say(&"throw_wait")
		return null
	var enemy: Enemy = pick_target()
	if enemy == null:
		_frank.say(&"throw_nobody")
		return null
	throw_at(enemy)
	return enemy


func pick_target() -> Enemy:
	var locked: Enemy = _player.lock_target as Enemy
	if locked and not locked.is_dead() and locked.global_position.distance_to(_player.global_position) <= THROW_RANGE:
		return locked
	var forward: Vector3 = -_player.camera_rig.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var best: Enemy = null
	var best_score: float = -1.0
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead():
			continue
		var to: Vector3 = enemy.global_position - _player.global_position
		to.y = 0.0
		var distance: float = to.length()
		if distance > THROW_RANGE or distance < 0.01:
			continue
		var dot: float = forward.dot(to / distance)
		if dot < AIM_DOT:
			continue
		var score: float = dot - distance / THROW_RANGE * 0.3
		if score > best_score:
			best_score = score
			best = enemy
	return best


func throw_at(enemy: Enemy) -> void:
	cooldown_left = COOLDOWN
	var unaware: bool = not enemy.alerted and not enemy.warns_first
	var target: Vector3
	var follow: Node3D = null
	if unaware:
		var away: Vector3 = enemy.global_position - _player.global_position
		away.y = 0.0
		target = enemy.global_position + away.normalized() * DISTRACT_BEHIND
		target.y = enemy.global_position.y + 0.06
	else:
		# A la cara: sigue la cabeza del enemigo durante el vuelo.
		follow = enemy.body.bone_attachment(Bones.name(&"Head"))
		target = follow.global_position
	_frank.point_at(target, 0.8)
	_frank.say(&"throw_go")
	var fruit := FrankFruit.launch(_player.get_parent(), _frank.head_position() + Vector3.UP * 0.1, target, enemy.global_position.y, follow)
	last_fruit = fruit
	fruit.landed.connect(_on_landed.bind(enemy, unaware), CONNECT_ONE_SHOT)


func _on_landed(at: Vector3, enemy: Enemy, unaware: bool) -> void:
	if not is_instance_valid(enemy) or enemy.is_dead():
		return
	var state: StringName = enemy.state_name()
	if state == &"Broken" or state == &"Rally" or state == &"Scripted" or state == &"Dead":
		return
	if unaware and not enemy.alerted:
		# "¿Qué ha sido eso?": va a mirar donde cayó, de espaldas a Kael.
		distracted = enemy
		enemy.state_machine.transition_to(&"Suspicious", {"at": at})
		_say_later(&"throw_distract", 0.5)
	elif enemy.boss:
		enemy.body.flinch(enemy.global_position - _player.global_position, 0.6)
		_say_later(&"throw_boss", 0.4)
	else:
		if enemy.warns_first:
			enemy.alert()  # Fruta a la cara de quien avisaba: lo toma como un golpe y pelea (con sus compañeros).
		enemy.state_machine.transition_to(&"Dazed", {"seconds": DAZE_SECONDS})
		_say_later(&"throw_hit", 0.3)


func _say_later(event: StringName, seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
	if _frank.mode == Frank.Mode.PERCHED:
		_frank.say(event)
