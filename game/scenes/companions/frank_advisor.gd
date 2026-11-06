class_name FrankAdvisor
extends Node
## Cuándo habla Frank (guion §12, "Consejos y bromas"): escucha lo que pasa (estados de Kael, vendajes,
## voces de los demás) y elige qué chillar. Nunca da la respuesta exacta: da pistas.
## - Vendarse con un enemigo alerta cerca: se tapa la cara ("¿Ahora? ¿En serio?").
## - Al quedarse sin vendas: dónde conseguir más. Si le rompen la guardia a Kael: "¡Respira!".
## - Al morir Kael se tapa los ojos; al reaparecer, un ánimo; desde la segunda muerte con el mismo
##   enemigo, una pista para ese enemigo (alternando con un ánimo).
## - Al entrar en las zonas (después del anciano), al descansar, al llevar rato quieto, y a veces tras un
##   golpe mortal: la conciencia de Kael ("¿Seguro que eran rebeldes?").
## - Momentos serios: en los duelos con jefes no bromea (solo pistas), y tras la muerte de Varga se queda
##   quieto y cabizbajo un buen rato.
## - Avisos (paso 3): un arquero tensa el arco contra Kael, un enemigo lo descubre por la espalda, o uno
##   sospecha ("?"): chilla y señala hacia él.
## - Hallazgos: cerca de un escondite (HiddenCache) lo señala y el escondite brilla.
## Solo habla si Frank va con Kael y no hay ninguna escena.

const HEAL_DANGER_RANGE: float = 10.0
## Segundos quieto antes de la broma (variable para las pruebas).
var idle_long_after: float = 25.0
const AFTER_RESPAWN: float = 1.2
const QUIET_AFTER_SAD: float = 25.0
## Pista según el enemigo que lo venció (por su nombre).
const HINTS: Dictionary = {
	"Soldado": &"hint_soldier", "Soldado de práctica": &"hint_soldier", "Lancero": &"hint_spear",
	"Arquero": &"hint_archer", "Bandido": &"hint_bandit", "Capitana Varga": &"hint_varga",
}
const ZONES: Dictionary = {
	&"story_pass_village": &"zone_village", &"story_pass_forest": &"zone_forest",
	&"story_pass_fortress": &"zone_fortress",
}
const REST_FIRST: StringName = &"frank_rest_first"
## Enemigo "por la espalda": más allá de este ángulo respecto a donde mira Kael, y a esta distancia o menos.
const BEHIND_DOT: float = -0.25
const BEHIND_RANGE: float = 15.0
const SUSPICIOUS_RANGE: float = 20.0

## Muertes de Kael por enemigo (nombre -> veces), en esta sesión.
var deaths_by: Dictionary = {}

var _frank: Frank
var _player: Player
var _time: float = 0.0
var _quiet_until: float = 0.0
var _still: float = 0.0
var _killer: String = ""
var _was_dead: bool = false


func setup(frank: Frank, player: Player) -> void:
	_frank = frank
	_player = player


func _ready() -> void:
	_player.state_machine.state_changed.connect(_on_state_changed)
	_player.bandages_changed.connect(_on_bandages_changed)
	_player.posture.broken.connect(_on_guard_broken)
	Voice.spoken.connect(_on_spoken)
	_watch_enemies.call_deferred()


## Escucha a cada enemigo del nivel (cuándo apunta, sospecha o se lanza a por Kael).
func _watch_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.state_machine.state_changed.is_connected(_on_enemy_state):
			enemy.state_machine.state_changed.connect(_on_enemy_state.bind(enemy))


func _on_enemy_state(state_name: StringName, enemy: Enemy) -> void:
	if not can_talk() or enemy.is_dead():
		return
	var to_enemy: Vector3 = enemy.global_position - _player.global_position
	match state_name:
		&"Shoot":
			if enemy.target == _player:
				_warn(&"warn_archer", enemy)
		&"Suspicious":
			if to_enemy.length() <= SUSPICIOUS_RANGE:
				_warn(&"warn_suspicious", enemy)
		&"Chase":
			if is_behind(enemy) and to_enemy.length() <= BEHIND_RANGE:
				_warn(&"warn_behind", enemy)


## ¿Está el enemigo a la espalda de Kael (fuera de lo que ve)?
func is_behind(enemy: Enemy) -> bool:
	var to_enemy: Vector3 = enemy.global_position - _player.global_position
	to_enemy.y = 0.0
	var facing: Vector3 = -_player.camera_rig.global_basis.z
	facing.y = 0.0
	return to_enemy.length() > 0.01 and facing.normalized().dot(to_enemy.normalized()) < BEHIND_DOT


func _warn(event: StringName, enemy: Enemy) -> void:
	if _frank.say(event):
		_frank.point_at(enemy.lock_point(), 1.8)


## Escondites: el más cercano sin encontrar, a su alcance, lo señala.
func _look_for_caches() -> void:
	if not can_talk() or _player.lock_target != null:
		return
	for node in get_tree().get_nodes_in_group("hidden_caches"):
		var cache := node as HiddenCache
		if cache == null or cache.revealed or cache.is_taken():
			continue
		if cache.global_position.distance_to(_player.global_position) <= HiddenCache.FIND_RANGE:
			if _frank.say(&"find_item"):
				cache.reveal()
				_frank.point_at(cache.global_position + Vector3.UP * 0.2, 2.0)
			return


## ¿Puede hablar Frank ahora? (va con Kael y no hay escena)
func can_talk() -> bool:
	return _frank.mode == Frank.Mode.PERCHED and get_tree().get_node_count_in_group("cutscene") == 0


## Momento serio: ni bromas ni parloteo (sí pistas y avisos).
func is_quiet() -> bool:
	return _time < _quiet_until or in_boss_fight()


func in_boss_fight() -> bool:
	for arena in get_tree().get_nodes_in_group("arenas"):
		if arena.has_method("is_active") and arena.is_active():
			return true
	return false


func _process(delta: float) -> void:
	_time += delta
	_look_for_caches()
	# Rato quieto sin pelear: una broma.
	var calm: bool = _player.state_machine.current.name == &"Ground" and _player.lock_target == null \
		and Vector2(_player.velocity.x, _player.velocity.z).length() < 0.2
	_still = _still + delta if calm else 0.0
	if _still >= idle_long_after:
		_still = 0.0
		if can_talk() and not is_quiet():
			_frank.say(&"idle_long")


func _on_state_changed(state_name: StringName) -> void:
	match state_name:
		&"Heal":
			if not can_talk():
				return
			if _enemy_watching():
				_frank.gesture(Frank.Pose.COVER_EYES, 1.8)
				_frank.say(&"heal_danger")
			elif not is_quiet():
				_frank.say(&"heal")
		&"Rest":
			if not can_talk():
				return
			if not Story.heard(REST_FIRST):
				Story.mark_heard(REST_FIRST)
				_later(1.5, &"rest_first")
			else:
				_later(1.5, &"rest")
		&"Dead":
			var winner: Enemy = _player.engaged_enemy
			_killer = winner.display_name if winner else ""
			deaths_by[_killer] = int(deaths_by.get(_killer, 0)) + 1
			_was_dead = true
			if _frank.mode == Frank.Mode.PERCHED:
				_frank.gesture(Frank.Pose.COVER_EYES, 3.2)
		&"Ground":
			if _was_dead:
				_was_dead = false
				_after_respawn()


## Qué dice al reaparecer: ánimo la primera vez; luego pista y ánimo alternados.
func respawn_event(killer: String, deaths: int) -> StringName:
	if deaths <= 1:
		return &"death_first"
	if deaths % 2 == 1:
		return &"death_again"
	if deaths % 4 == 0:
		return &"hint_danger"
	return HINTS.get(killer, &"death_again")


func _after_respawn() -> void:
	var event: StringName = respawn_event(_killer, int(deaths_by.get(_killer, 0)))
	await get_tree().create_timer(AFTER_RESPAWN, false).timeout
	# Espera a que el anciano termine de corregirse ("No… no fue así").
	var waited: float = 0.0
	while Voice.is_speaking(&"narrator") and waited < 8.0:
		await get_tree().create_timer(0.2, false).timeout
		waited += 0.2
	await get_tree().create_timer(0.4, false).timeout
	if can_talk():
		_frank.say(event)


func _on_bandages_changed(count: int) -> void:
	if count == 0 and can_talk():
		_later(1.8, &"bandages_out")


func _on_guard_broken() -> void:
	if can_talk():
		_frank.gesture(Frank.Pose.CLING, 1.0)
		_frank.say(&"stagger")


func _on_spoken(speaker: StringName, event: StringName, _id: String) -> void:
	if speaker == &"kael" and event == &"deathblow":
		if can_talk() and not is_quiet():
			_later(1.6, &"kill", Frank.Pose.SAD, 3.0)
	elif speaker == &"narrator" and ZONES.has(event):
		_later(Voice.last_seconds + 0.6, ZONES[event])
	elif speaker == &"varga" and event == &"death":
		_quiet_until = _time + QUIET_AFTER_SAD
		if _frank.mode == Frank.Mode.PERCHED:
			_frank.gesture(Frank.Pose.SAD, 12.0)


## Dice `event` dentro de `seconds` (si sigue pudiendo); con gesto opcional si llega a hablar.
func _later(seconds: float, event: StringName, pose: int = -1, pose_seconds: float = 0.0) -> void:
	await get_tree().create_timer(seconds, false).timeout
	if not can_talk():
		return
	if _frank.say(event) and pose >= 0:
		_frank.gesture(pose as Frank.Pose, pose_seconds)


func _enemy_watching() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_dead() and enemy.has_target() \
				and enemy.global_position.distance_to(_player.global_position) <= HEAL_DANGER_RANGE:
			return true
	return false
