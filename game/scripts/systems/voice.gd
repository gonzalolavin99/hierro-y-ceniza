extends Node
## Voces de los personajes: elige una línea del evento (VoiceLines), respeta su probabilidad y su
## pausa para no saturar, reproduce el audio si existe y avisa del subtítulo si es una frase.
## Para que no se pisen: cada personaje dice una cosa a la vez, suenan como mucho MAX_VOICES a la vez
## (gana la más importante, VoiceLines.EVENT_PRIORITY) y el narrador, cuando habla, calla a los demás.
## Uso: Voice.say(&"kael", &"hurt", posicion)

signal spoken(speaker: StringName, event: StringName, line_id: String)
signal subtitle(text: String, speaker_name: String, seconds: float)

const VOICE_DIR: String = "res://assets/audio/voice/"
const EXTENSIONS: Array[String] = ["mp3", "ogg", "wav"]
const POOL_SIZE: int = 6
## Voces a la vez en toda la escena (sin contar al narrador, que va solo).
const MAX_VOICES: int = 2

## Solo para pruebas: ignora la probabilidad (habla siempre que la pausa lo permita).
var always_speak: bool = false

var _last_time: Dictionary = {}  # "personaje/evento" -> segundos de juego
## Reloj en tiempo de juego (se detiene en pausa y en la pausa de impacto), para medir las pausas entre voces.
var _clock: float = 0.0
var _last_line: Dictionary = {}  # "personaje/evento" -> id
var _pool: Array[AudioStreamPlayer3D] = []
var _next: int = 0
var _narrator: AudioStreamPlayer
## Quién está hablando ahora: personaje -> {priority, until (reloj de juego), player}.
var _active: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 10.0
		p.max_distance = 50.0
		add_child(p)
		_pool.append(p)
	_narrator = AudioStreamPlayer.new()
	add_child(_narrator)


func _process(delta: float) -> void:
	if not get_tree().paused:
		_clock += delta


## Intenta que `speaker` diga algo del `event`. Devuelve true si habló.
func say(speaker: StringName, event: StringName, at: Vector3 = Vector3.ZERO) -> bool:
	var events: Dictionary = VoiceLines.LINES.get(speaker, {})
	if not events.has(event):
		return false
	var data: Dictionary = events[event]
	var key: String = "%s/%s" % [speaker, event]
	var now: float = _clock
	if now - _last_time.get(key, -1000.0) < data["cooldown"]:
		return false
	if not always_speak and randf() > data["chance"]:
		return false
	var priority: int = VoiceLines.EVENT_PRIORITY.get(event, 1)
	if not _make_room(speaker, priority):
		return false
	_last_time[key] = now
	var line: Dictionary = _pick(data["lines"], _last_line.get(key, ""))
	_last_line[key] = line["id"]
	var played: Array = _play(speaker, line["id"], at)
	var seconds: float = played[0]
	# Sin audio, se estima cuánto "ocupa" la línea (para los turnos y los subtítulos).
	var busy: float = seconds if seconds > 0.0 else (0.5 + String(line.get("es", "")).length() * 0.05)
	_active[speaker] = {"priority": priority, "until": _clock + busy, "player": played[1]}
	if line.has("es"):
		var text: String = line["es"]
		subtitle.emit(text, VoiceLines.SPEAKER_NAMES.get(speaker, ""), maxf(seconds + 0.6, 1.5 + text.length() * 0.05))
	spoken.emit(speaker, event, line["id"])
	return true


## Olvida las pausas y calla a todos (al reaparecer o en pruebas).
func reset() -> void:
	_last_time.clear()
	for speaker: StringName in _active.keys():
		_silence(speaker)


## ¿Está hablando ahora este personaje?
func is_speaking(speaker: StringName) -> bool:
	_prune()
	return _active.has(speaker)


## Cuántas voces suenan ahora.
func active_count() -> int:
	_prune()
	return _active.size()


## Decide si `speaker` puede hablar ya con esta importancia, callando a quien haga falta.
func _make_room(speaker: StringName, priority: int) -> bool:
	_prune()
	var narrator: bool = speaker in VoiceLines.NARRATORS
	if narrator:
		for other: StringName in _active.keys():
			_silence(other)
		return true
	for other: StringName in _active:
		if other in VoiceLines.NARRATORS:
			return false  # Nadie pisa al narrador.
	if _active.has(speaker):
		if priority <= _active[speaker]["priority"]:
			return false  # Ya está diciendo algo igual o más importante.
		_silence(speaker)
	if _active.size() >= MAX_VOICES:
		var weakest: StringName = &""
		for other: StringName in _active:
			if weakest == &"" or _active[other]["priority"] < _active[weakest]["priority"]:
				weakest = other
		if priority <= _active[weakest]["priority"]:
			return false
		_silence(weakest)
	return true


func _silence(speaker: StringName) -> void:
	var player: Node = _active[speaker]["player"]
	if player and player.has_method("stop"):
		player.call("stop")
	_active.erase(speaker)


func _prune() -> void:
	for speaker: StringName in _active.keys():
		if _active[speaker]["until"] <= _clock:
			_active.erase(speaker)


func _pick(lines: Array, avoid: String) -> Dictionary:
	if lines.size() == 1:
		return lines[0]
	var options: Array = lines.filter(func(l: Dictionary) -> bool: return l["id"] != avoid)
	return options.pick_random()


## Reproduce el archivo de la línea si existe. Devuelve [duración (0 si no hay audio), reproductor o null].
func _play(speaker: StringName, id: String, at: Vector3) -> Array:
	var stream: AudioStream = null
	for ext in EXTENSIONS:
		var path: String = "%s%s/%s.%s" % [VOICE_DIR, speaker, id, ext]
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream == null:
		return [0.0, null]
	if speaker in VoiceLines.NARRATORS:
		_narrator.stream = stream
		_narrator.play()
		return [stream.get_length(), _narrator]
	var p: AudioStreamPlayer3D = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.pitch_scale = randf_range(0.97, 1.03)
	p.global_position = at
	p.play()
	return [stream.get_length(), p]
