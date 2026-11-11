extends Node
## Reproduce efectos de sonido 3D. Elige una variante al azar y varía un poco el tono
## para que los golpes repetidos no suenen idénticos.
## Uso: Sfx.play(&"deflect", posicion)

const SFX_DIR: String = "res://assets/audio/sfx/"
const POOL_SIZE: int = 16

## Volumen base (dB) de cada sonido.
const VOLUMES: Dictionary[StringName, float] = {
	&"deflect": 2.0,
	&"block": -2.0,
	&"hit": 0.0,
	&"swing": -8.0,
	&"posture_break": 2.0,
	&"deathblow": 3.0,
	&"glint": -8.0,
	&"danger": 0.0,
	&"counter": 2.0,
	&"crossbow": -2.0,
	&"bolt_hit": -2.0,
	&"smoke": -2.0,
	&"explosion": 4.0,
	&"bandage": -4.0,
	&"pickup": -4.0,
}

var _streams: Dictionary[StringName, Array] = {}
var _pool: Array[AudioStreamPlayer3D] = []
var _next: int = 0
## Última variante que sonó de cada sonido.
var _last_variant: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound in VOLUMES:
		var variants: Array[AudioStream] = []
		for i in range(1, 10):
			var path: String = "%s%s_%d.wav" % [SFX_DIR, sound, i]
			if not ResourceLoader.exists(path):
				break
			variants.append(load(path))
		_streams[sound] = variants
	for i in POOL_SIZE:
		var player := AudioStreamPlayer3D.new()
		player.unit_size = 8.0
		player.max_distance = 60.0
		player.bus = AudioMix.SFX
		add_child(player)
		_pool.append(player)


func play(sound: StringName, at: Vector3, volume_offset: float = 0.0, pitch_variation: float = 0.06) -> void:
	var variants: Array = _streams.get(sound, [])
	if variants.is_empty():
		return
	var player: AudioStreamPlayer3D = _free_player()
	player.stream = _pick_variant(sound, variants)
	player.volume_db = VOLUMES.get(sound, 0.0) + volume_offset
	player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	player.global_position = at
	player.play()


## Un reproductor libre (que no esté sonando); si todos suenan, el que lleva más rato (revisión del estudio:
## antes se reciclaban en orden y en las peleas de grupo se cortaban colas de sonido).
func _free_player() -> AudioStreamPlayer3D:
	for i in POOL_SIZE:
		var candidate: AudioStreamPlayer3D = _pool[(_next + i) % POOL_SIZE]
		if not candidate.playing:
			_next = (_next + i + 1) % POOL_SIZE
			return candidate
	var oldest: AudioStreamPlayer3D = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	return oldest


## Una variante al azar, pero nunca la misma dos veces seguidas.
func _pick_variant(sound: StringName, variants: Array) -> AudioStream:
	var pick: AudioStream = variants.pick_random()
	if variants.size() > 1:
		while pick == _last_variant.get(sound):
			pick = variants.pick_random()
	_last_variant[sound] = pick
	return pick
