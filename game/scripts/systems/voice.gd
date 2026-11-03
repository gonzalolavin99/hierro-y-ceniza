extends Node
## Voces de los personajes: elige una línea del evento (VoiceLines), respeta su probabilidad y su
## pausa para no saturar, reproduce el audio si existe y avisa del subtítulo si es una frase.
## Uso: Voice.say(&"kael", &"hurt", posicion)

signal spoken(speaker: StringName, event: StringName, line_id: String)
signal subtitle(text: String, speaker_name: String, seconds: float)

const VOICE_DIR: String = "res://assets/audio/voice/"
const EXTENSIONS: Array[String] = ["mp3", "ogg", "wav"]
const POOL_SIZE: int = 6

## Solo para pruebas: ignora la probabilidad (habla siempre que la pausa lo permita).
var always_speak: bool = false

var _last_time: Dictionary = {}  # "personaje/evento" -> segundos
var _last_line: Dictionary = {}  # "personaje/evento" -> id
var _pool: Array[AudioStreamPlayer3D] = []
var _next: int = 0
var _narrator: AudioStreamPlayer


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


## Intenta que `speaker` diga algo del `event`. Devuelve true si habló.
func say(speaker: StringName, event: StringName, at: Vector3 = Vector3.ZERO) -> bool:
	var events: Dictionary = VoiceLines.LINES.get(speaker, {})
	if not events.has(event):
		return false
	var data: Dictionary = events[event]
	var key: String = "%s/%s" % [speaker, event]
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_time.get(key, -1000.0) < data["cooldown"]:
		return false
	if not always_speak and randf() > data["chance"]:
		return false
	_last_time[key] = now
	var line: Dictionary = _pick(data["lines"], _last_line.get(key, ""))
	_last_line[key] = line["id"]
	var seconds: float = _play(speaker, line["id"], at)
	if line.has("es"):
		var text: String = line["es"]
		subtitle.emit(text, VoiceLines.SPEAKER_NAMES.get(speaker, ""), maxf(seconds + 0.6, 1.5 + text.length() * 0.05))
	spoken.emit(speaker, event, line["id"])
	return true


## Olvida las pausas (al reaparecer o en pruebas).
func reset() -> void:
	_last_time.clear()


func _pick(lines: Array, avoid: String) -> Dictionary:
	if lines.size() == 1:
		return lines[0]
	var options: Array = lines.filter(func(l: Dictionary) -> bool: return l["id"] != avoid)
	return options.pick_random()


## Reproduce el archivo de la línea si existe. Devuelve su duración (0 si no hay audio).
func _play(speaker: StringName, id: String, at: Vector3) -> float:
	var stream: AudioStream = null
	for ext in EXTENSIONS:
		var path: String = "%s%s/%s.%s" % [VOICE_DIR, speaker, id, ext]
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream == null:
		return 0.0
	if speaker in VoiceLines.NARRATORS:
		_narrator.stream = stream
		_narrator.play()
	else:
		var p: AudioStreamPlayer3D = _pool[_next]
		_next = (_next + 1) % POOL_SIZE
		p.stream = stream
		p.pitch_scale = randf_range(0.97, 1.03)
		p.global_position = at
		p.play()
	return stream.get_length()
