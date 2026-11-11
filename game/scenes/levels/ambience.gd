class_name Ambience
extends Node3D
## Sonido de ambiente del Paso de Hierro (revisión del estudio, audio: "el silencio tiene que tener aire"). Todo
## va al canal Ambiente, que baja solo cuando alguien habla (AudioMix).
## - Viento en bucle; sopla más fuerte arriba, en la fortaleza.
## - Rumor del arroyo junto al sendero del atajo (sonido 3D: se oye más cerca de él).
## - Pájaros lejanos de vez en cuando, en el camino, la aldea y el bosque (solo se oyen; aprobado por el
##   jugador el 2026-11-09). Callan en el duelo con un jefe.
## - Música de exploración muy suave, y una capa de tensión que entra cuando un enemigo cercano te descubre y se
##   va al calmarse (mismo tempo: entra en el mismo punto del compás). Calla en el duelo con un jefe, que pone
##   su propia música. (Aviso del jugador, 2026-11-11: "no sentí música de fondo".)
## Sonidos de tools/gen_ambient.py; música de tools/gen_music.py.

const DIR: String = "res://assets/audio/ambient/"
const WIND_DB: float = -17.0
const WIND_HIGH_DB: float = -11.0
const RIVER_DB: float = -6.0
const BIRD_DB: float = -14.0
## Cada cuánto canta un pájaro (s) y a qué distancia de Kael (m).
const BIRD_EVERY: Vector2 = Vector2(5.0, 13.0)
const BIRD_DISTANCE: Vector2 = Vector2(18.0, 40.0)
## Por encima de esta altura (la fortaleza) sopla más el viento y no hay pájaros.
const HIGH_Y: float = 3.0

const MUSIC_DIR: String = "res://assets/audio/music/"
const EXPLORE_DB: float = -13.0
const TENSION_DB: float = -11.0
const SILENT_DB: float = -60.0
## Un enemigo alerta y con Kael a esta distancia (o menos) pone la capa de tensión.
const TENSION_RANGE: float = 16.0

## Dónde suena el arroyo.
@export var river_points: PackedVector3Array = PackedVector3Array()

var wind: AudioStreamPlayer
var explore: AudioStreamPlayer
var tension: AudioStreamPlayer
var birds_sung: int = 0
var _birds: Array[AudioStream] = []
var _bird_player: AudioStreamPlayer3D
var _bird_left: float = 3.0
var _player: Player
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("ambience")
	_rng.randomize()
	wind = AudioStreamPlayer.new()
	wind.bus = AudioMix.AMBIENT
	wind.stream = _loop(DIR + "wind_loop.wav")
	wind.volume_db = WIND_DB
	wind.autoplay = true
	add_child(wind)
	explore = _music_player("pass_explore.wav", EXPLORE_DB)
	tension = _music_player("pass_tension.wav", SILENT_DB)
	for at in river_points:
		var river := AudioStreamPlayer3D.new()
		river.bus = AudioMix.AMBIENT
		river.stream = _loop(DIR + "river_loop.wav")
		river.volume_db = RIVER_DB
		river.unit_size = 6.0
		river.max_distance = 45.0
		river.autoplay = true
		river.position = at
		add_child(river)
	for i in range(1, 10):
		var path: String = "%sbird_%d.wav" % [DIR, i]
		if not ResourceLoader.exists(path):
			break
		_birds.append(load(path))
	_bird_player = AudioStreamPlayer3D.new()
	_bird_player.bus = AudioMix.AMBIENT
	_bird_player.unit_size = 14.0
	_bird_player.max_distance = 90.0
	add_child(_bird_player)


func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
			return
	var high: bool = _player.global_position.y > HIGH_Y
	wind.volume_db = move_toward(wind.volume_db, WIND_HIGH_DB if high else WIND_DB, delta * 3.0)
	var fight: bool = _boss_fight()
	var target_explore: float = SILENT_DB if fight else EXPLORE_DB
	var target_tension: float = TENSION_DB if (not fight and in_danger()) else SILENT_DB
	explore.volume_db = move_toward(explore.volume_db, target_explore, delta * 20.0)
	tension.volume_db = move_toward(tension.volume_db, target_tension, delta * (30.0 if target_tension > tension.volume_db else 12.0))
	if tension.playing and absf(tension.get_playback_position() - explore.get_playback_position()) > 0.1:
		tension.seek(explore.get_playback_position())  # Siempre en el mismo punto del compás.
	_bird_left -= delta
	if _bird_left <= 0.0:
		_bird_left = _rng.randf_range(BIRD_EVERY.x, BIRD_EVERY.y)
		if not high and not _boss_fight():
			sing()


## ¿Hay un enemigo cerca que ya ha visto a Kael y va a por él?
func in_danger() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.boss and not enemy.is_dead() and not enemy.asleep and enemy.has_target() 				and enemy.distance_to_target() <= TENSION_RANGE:
			return true
	return false


func _music_player(file: String, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = AudioMix.MUSIC
	p.stream = _loop(MUSIC_DIR + file)
	p.volume_db = db
	p.autoplay = true
	add_child(p)
	return p


## Un pájaro canta en algún sitio lejos de Kael.
func sing() -> bool:
	if _birds.is_empty() or _player == null:
		return false
	var angle: float = _rng.randf() * TAU
	var distance: float = _rng.randf_range(BIRD_DISTANCE.x, BIRD_DISTANCE.y)
	_bird_player.global_position = _player.global_position + Vector3(cos(angle) * distance, 8.0, sin(angle) * distance)
	_bird_player.stream = _birds[_rng.randi() % _birds.size()]
	_bird_player.volume_db = BIRD_DB
	_bird_player.pitch_scale = _rng.randf_range(0.92, 1.08)
	_bird_player.play()
	birds_sung += 1
	return true


func _boss_fight() -> bool:
	for arena in get_tree().get_nodes_in_group("arenas"):
		if arena.has_method("is_active") and arena.is_active():
			return true
	return false


static func _loop(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	var stream := (load(path) as AudioStreamWAV).duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	return stream
