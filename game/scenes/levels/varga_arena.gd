class_name VargaArena
extends Node3D
## Arena de la Capitana Varga: un patio de la fortaleza, con niebla baja y braseros, al que se entra por un
## pasillo desde el nivel. Al entrar, sus soldados bajan el rastrillo (portón de hierro) detrás de Kael y
## empieza el duelo (barra de jefa abajo). Si Kael muere, todo vuelve a empezar (rastrillo arriba); si
## Varga cae, el rastrillo sube para siempre (queda guardado en Story: "boss_varga").
## Todo se construye en código. El origen es el centro del patio; la entrada está al oeste (−X).

signal fight_started
signal boss_defeated

const VARGA: PackedScene = preload("res://scenes/enemies/varga.tscn")
const CAMPFIRE: PackedScene = preload("res://scenes/props/campfire.tscn")
const HALF: float = 15.0
const WALL_HEIGHT: float = 6.0
const GATE_WIDTH: float = 4.0
const GATE_OPEN_Y: float = 4.6
const DEFEATED_FLAG: StringName = &"boss_varga"
const INTRO_FLAG: StringName = &"scene_varga"
## Dónde arde la ropa de los enfermos (junto al sitio de Varga).
const PYRE_AT: Vector3 = Vector3(11.0, 0.0, 1.8)
## Música del duelo (tools/gen_music.py): fase 1 y fase 2, mismo ritmo y duración.
const MUSIC: Array[String] = ["res://assets/audio/music/varga_duel_1.wav", "res://assets/audio/music/varga_duel_2.wav"]
const MUSIC_DB: float = -9.0
const SILENT_DB: float = -50.0
## Fase 2 (tras el primer golpe mortal): más rápida, más agresiva, con el abanico de cuchillos y el combo
## largo. Al reiniciar el duelo vuelve a la fase 1 (sus valores de la escena).
const PHASE_2: Dictionary = {
	"moveset": [&"varga_combo_long", &"varga_combo", &"varga_leap_combo", &"varga_spin", &"varga_fan"],
	"ranged_patterns": [&"varga_fan", &"varga_knives", &"varga_leap_combo"],
	"idle_wait": Vector2(0.08, 0.3),
	"damage_scale": 1.45,
	"walk_speed": 4.8,
	"evade_chance": 0.6,
	"danger_ratio": 0.33,
	"ranged_cooldown": 2.2,
}

var varga: Enemy
## Escena antes del duelo (mientras dura).
var intro: VargaIntro
var _gate: AnimatableBody3D
var _bar: BossBar
var _active: bool = false
var _fog: Array[MeshInstance3D] = []
var _time: float = 0.0
## Valores de la fase 1 (los de la escena), para volver a ellos al reiniciar.
var _phase_1: Dictionary = {}
var _music: Array[AudioStreamPlayer] = []
var _music_tween: Tween


func _ready() -> void:
	add_to_group("arenas")
	_build_floor()
	_build_walls()
	_build_gate()
	_build_fog()
	_build_braziers()
	_build_pyre()
	var fire := CAMPFIRE.instantiate() as Campfire
	fire.camp_name = "Campamento de la fortaleza"
	fire.position = Vector3(-31.0, 0.0, 5.0)
	add_child(fire)
	var trigger := Area3D.new()
	trigger.name = "DuelTrigger"
	trigger.collision_layer = 0
	trigger.collision_mask = 2  # Jugador.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(HALF * 2.0 - 5.0, 4.0, HALF * 2.0 - 2.0)
	shape.shape = box
	shape.position = Vector3(1.5, 2.0, 0.0)
	trigger.add_child(shape)
	add_child(trigger)
	trigger.body_entered.connect(_on_trigger)
	_bar = BossBar.new()
	add_child(_bar)
	_build_music()
	if not Story.heard(DEFEATED_FLAG):
		varga = VARGA.instantiate() as Enemy
		varga.position = Vector3(8.0, 0.0, 0.0)
		varga.rotation.y = PI * 0.5  # Mira hacia la entrada (−X).
		add_child(varga)
		varga.died.connect(_on_varga_died)
		varga.phase_changed.connect(_on_phase_changed)
		for key in PHASE_2:
			_phase_1[key] = varga.get(key)


func is_active() -> bool:
	return _active


func gate_closed() -> bool:
	return _gate.position.y < 0.5


func _process(delta: float) -> void:
	_time += delta
	for i in _fog.size():
		var mat := _fog[i].material_override as StandardMaterial3D
		mat.uv1_offset = Vector3(_time * (0.008 + i * 0.003), _time * 0.004 * (1 - i % 2 * 2), 0.0)


## Empieza el duelo (al entrar Kael en el patio). La primera vez, antes, la escena con Varga.
func start_fight() -> void:
	if _active or varga == null or varga.is_dead():
		return
	_active = true
	_move_gate(0.0, 0.5)
	Sfx.play(&"block", global_position + Vector3(-HALF, 1.5, 0.0), 2.0)
	var player := get_tree().get_first_node_in_group("player") as Player
	if not Story.heard(INTRO_FLAG) and player:
		Story.mark_heard(&"story_varga_before")  # La dice el anciano dentro de la escena.
		intro = VargaIntro.new()
		intro.setup(self, player, varga)
		intro.finished.connect(_begin_duel)
		add_child(intro)
	else:
		_begin_duel()


func _begin_duel() -> void:
	if intro:
		varga.has_spoken_to_target = true  # Ya habló en la escena: no repite su frase al verte.
	Story.mark_heard(INTRO_FLAG)
	intro = null
	varga.aggro_range = 60.0
	varga.alert()
	_bar.show_boss(varga)
	Story.narrate(&"story_varga_before")
	_play_music(0, 1.5)
	fight_started.emit()


## Kael murió (o descansó): el rastrillo sube y Varga vuelve a su puesto, sin pelea.
func reset_arena() -> void:
	_active = false
	_bar.hide_boss()
	_stop_music(1.5)
	_move_gate(GATE_OPEN_Y, 0.8)
	if varga and not varga.is_dead():
		varga.aggro_range = 0.0
		_apply_phase(_phase_1)


func _on_trigger(body: Node3D) -> void:
	if body is Player:
		start_fight()


func _on_phase_changed(phase: int) -> void:
	if phase >= 2:
		_apply_phase(PHASE_2)
		Voice.say(varga.voice, &"phase", varga.lock_point())
		_play_music(1, 1.2)


func _apply_phase(values: Dictionary) -> void:
	for key in values:
		var value: Variant = values[key]
		if value is Array:
			var typed: Array[StringName] = []
			typed.assign(value)
			value = typed
		varga.set(key, value)
	varga.posture.regen_rate = 34.0 if values == PHASE_2 else 26.0
	varga.mind.configure(varga.moveset, varga.danger_moveset, varga.danger_ratio)


## Fase en la que está el duelo (1 o 2).
func phase() -> int:
	return varga.phase() if varga else 0


func _on_varga_died() -> void:
	_active = false
	Story.mark_heard(DEFEATED_FLAG)
	# Recompensas: su estandarte (lo que pidió el Regente) y su técnica, la Ráfaga.
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		if not &"varga_banner" in player.key_items:
			player.key_items.append(&"varga_banner")
		player.arts.unlock(&"art_flurry")
	_bar.hide_boss(2.5)
	_stop_music(3.5)
	_move_gate(GATE_OPEN_Y, 2.0)
	get_tree().create_timer(3.0, false).timeout.connect(Story.narrate.bind(&"story_varga_after"))
	SaveGame.save(get_tree().get_first_node_in_group("player") as Player)
	boss_defeated.emit()


func _move_gate(y: float, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(_gate, "position:y", y, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


# --- Construcción ----------------------------------------------------------------------

func _build_floor() -> void:
	_static_box(Vector3(0.0, -0.5, 0.0), Vector3(HALF * 2.0, 1.0, HALF * 2.0), Color(0.3, 0.29, 0.27))
	# Pasillo de entrada desde el nivel (oeste).
	_static_box(Vector3(-HALF - 6.0, -0.5, 0.0), Vector3(12.0, 1.0, GATE_WIDTH + 2.0), Color(0.27, 0.25, 0.22))


func _build_walls() -> void:
	var stone := Color(0.36, 0.35, 0.33)
	var t: float = 1.0
	_static_box(Vector3(0.0, WALL_HEIGHT * 0.5, -HALF - t * 0.5), Vector3(HALF * 2.0 + t * 2.0, WALL_HEIGHT, t), stone)
	_static_box(Vector3(0.0, WALL_HEIGHT * 0.5, HALF + t * 0.5), Vector3(HALF * 2.0 + t * 2.0, WALL_HEIGHT, t), stone)
	_static_box(Vector3(HALF + t * 0.5, WALL_HEIGHT * 0.5, 0.0), Vector3(t, WALL_HEIGHT, HALF * 2.0), stone)
	# Muro oeste, con el hueco del rastrillo.
	var side: float = (HALF * 2.0 - GATE_WIDTH) * 0.5
	for sign in [-1.0, 1.0]:
		_static_box(Vector3(-HALF - t * 0.5, WALL_HEIGHT * 0.5, sign * (GATE_WIDTH * 0.5 + side * 0.5)), Vector3(t, WALL_HEIGHT, side), stone)
	_static_box(Vector3(-HALF - t * 0.5, WALL_HEIGHT - 0.6, 0.0), Vector3(t, 1.2, GATE_WIDTH), stone)  # dintel
	# Torre sobre la puerta: ahí se guarda el rastrillo cuando está subido.
	_static_box(Vector3(-HALF - t * 0.5, WALL_HEIGHT + 2.6, 0.0), Vector3(t + 1.4, 5.2, GATE_WIDTH + 2.4), stone.darkened(0.08))
	# Paredes del pasillo.
	for sign in [-1.0, 1.0]:
		_static_box(Vector3(-HALF - 6.0, 1.5, sign * (GATE_WIDTH * 0.5 + 1.25)), Vector3(12.0, 3.0, 0.5), stone.darkened(0.1))
	# Almenas sobre los muros (solo vista).
	for i in 15:
		var x: float = -HALF + 1.0 + i * 2.0
		_box(Vector3(x, WALL_HEIGHT + 0.4, -HALF - 0.5), Vector3(1.0, 0.8, 1.0), stone)
		_box(Vector3(x, WALL_HEIGHT + 0.4, HALF + 0.5), Vector3(1.0, 0.8, 1.0), stone)


## Rastrillo: rejilla de barrotes de hierro que baja y sube (cuerpo animable: empuja y bloquea).
func _build_gate() -> void:
	_gate = AnimatableBody3D.new()
	_gate.name = "Gate"
	_gate.position = Vector3(-HALF - 0.5, GATE_OPEN_Y, 0.0)
	add_child(_gate)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, WALL_HEIGHT - 1.2, GATE_WIDTH)
	shape.shape = box
	shape.position.y = (WALL_HEIGHT - 1.2) * 0.5
	_gate.add_child(shape)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.13, 0.13, 0.14)
	iron.metallic = 0.6
	iron.roughness = 0.5
	for i in 9:
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.09, WALL_HEIGHT - 1.2, 0.09)
		mesh.material = iron
		bar.mesh = mesh
		bar.position = Vector3(0.0, (WALL_HEIGHT - 1.2) * 0.5, -GATE_WIDTH * 0.5 + 0.25 + i * (GATE_WIDTH - 0.5) / 8.0)
		_gate.add_child(bar)
	for y in [0.6, 2.0, 3.4]:
		var cross := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.08, 0.1, GATE_WIDTH)
		mesh.material = iron
		cross.mesh = mesh
		cross.position = Vector3(0.0, y, 0.0)
		_gate.add_child(cross)


## Niebla baja: capas planas semitransparentes que se deslizan despacio (barato para la GTX 1050).
func _build_fog() -> void:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	tex.width = 256
	tex.height = 256
	for i in 3:
		var layer := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(HALF * 2.0, HALF * 2.0)
		layer.mesh = plane
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.82, 0.84, 0.86, 0.13 - i * 0.03)
		mat.albedo_texture = tex
		mat.uv1_scale = Vector3(1.5 + i * 0.5, 1.5 + i * 0.5, 1.0)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		layer.material_override = mat
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		layer.position = Vector3(0.0, 0.2 + i * 0.35, 0.0)
		add_child(layer)
		_fog.append(layer)


func _build_braziers() -> void:
	for at in [Vector3(-11.0, 0.0, -11.0), Vector3(-11.0, 0.0, 11.0), Vector3(11.0, 0.0, -11.0), Vector3(11.0, 0.0, 11.0)]:
		_static_box(at + Vector3(0.0, 0.5, 0.0), Vector3(0.6, 1.0, 0.6), Color(0.2, 0.18, 0.16))
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.25
		cone.height = 0.5
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.55, 0.15)
		cone.material = mat
		flame.mesh = cone
		flame.position = at + Vector3(0.0, 1.25, 0.0)
		add_child(flame)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.6, 0.3)
		light.light_energy = 1.6
		light.omni_range = 8.0
		light.position = at + Vector3(0.0, 1.8, 0.0)
		add_child(light)


## Pista de música que suena ahora (0 = fase 1, 1 = fase 2, -1 = ninguna).
func music_track() -> int:
	for i in _music.size():
		if _music[i].playing and _music[i].volume_db > SILENT_DB + 1.0:
			return i
	return -1


func _build_music() -> void:
	for path in MUSIC:
		var player := AudioStreamPlayer.new()
		if ResourceLoader.exists(path):
			var stream := (load(path) as AudioStreamWAV).duplicate() as AudioStreamWAV
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
			player.stream = stream
		player.volume_db = SILENT_DB
		add_child(player)
		_music.append(player)


## Pasa a la pista `index` en `seconds` (si ya sonaba otra, sigue en el mismo punto del compás).
func _play_music(index: int, seconds: float) -> void:
	var position: float = 0.0
	for player in _music:
		if player.playing:
			position = player.get_playback_position()
	var target: AudioStreamPlayer = _music[index]
	if target.stream == null:
		return
	if not target.playing:
		target.play(position)
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel()
	for i in _music.size():
		_music_tween.tween_property(_music[i], "volume_db", MUSIC_DB if i == index else SILENT_DB, seconds)


func _stop_music(seconds: float) -> void:
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel()
	for player in _music:
		_music_tween.tween_property(player, "volume_db", SILENT_DB, seconds)
	_music_tween.chain().tween_callback(func() -> void:
		for player in _music:
			player.stop())


## La ropa de los enfermos ardiendo: un montón de telas grises y llamas, con su humo (las capas de niebla
## ya dan el ambiente). Nada que ver con quemar aldeas: es para frenar el contagio.
func _build_pyre() -> void:
	for i in 7:
		var cloth := _box(PYRE_AT + Vector3(randf_range(-0.5, 0.5), 0.1 + i * 0.06, randf_range(-0.5, 0.5)),
			Vector3(randf_range(0.5, 0.8), 0.08, randf_range(0.3, 0.6)), Color(0.45, 0.45, 0.47).darkened(randf() * 0.3))
		cloth.rotation.y = randf() * TAU
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.5, 0.12)
	for i in 4:
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.22 - i * 0.03
		cone.height = 0.8 - i * 0.1
		cone.material = mat
		flame.mesh = cone
		flame.position = PYRE_AT + Vector3((i % 2) * 0.3 - 0.15, 0.7, (i / 2) * 0.3 - 0.15)
		add_child(flame)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.25)
	light.light_energy = 2.2
	light.omni_range = 9.0
	light.position = PYRE_AT + Vector3(0.0, 1.4, 0.0)
	add_child(light)


func _static_box(at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := _box(Vector3.ZERO, size, color)
	mesh.reparent(body, false)
	return body


func _box(at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mesh.material = mat
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	add_child(mesh_instance)
	return mesh_instance
