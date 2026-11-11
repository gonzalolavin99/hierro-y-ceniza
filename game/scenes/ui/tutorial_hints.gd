class_name TutorialHints
extends Label
## Avisos de una línea que solo salen las primeras veces (revisión del estudio: un novato moría sin entender
## por qué). Cada aviso sale como mucho `TIMES[id]` veces por partida; después se apunta en Story
## ("hint_<id>") y ya no vuelve, ni al cargar la partida.
## - Ataques rojos: la primera vez que ves cada tipo (barrido, estocada, agarre), qué hacer.
## - Golpe mortal: cuando a un enemigo cercano se le rompe la postura.
## - Curarse: la primera vez que Kael está herido (y le quedan vendajes).
## Lo crea el HUD. Los textos usan los botones del aparato en uso (InputSetup.label).

const TEXTS: Dictionary = {
	&"sweep": "¡ROJO! Barrido bajo: no se para → SALTA  {jump}",
	&"thrust": "¡ROJO! Estocada: paso HACIA él  {dodge}  (pisas la hoja) o esquiva a un lado",
	&"grab": "¡ROJO! Agarre: ni guardia ni desvío → esquiva  {dodge}  o salta  {jump}",
	&"deathblow": "◆ Postura rota: ¡GOLPE MORTAL!  {attack}",
	&"heal": "Herido: CÚRATE  {heal}  (quieto y lejos de los golpes)",
	&"stealth": "◆ No te ha visto: ¡GOLPE MORTAL por la espalda!  {attack}",
}
const TIMES: Dictionary = {&"sweep": 3, &"thrust": 3, &"grab": 3, &"deathblow": 3, &"heal": 1, &"stealth": 3}
const KIND_IDS: Dictionary = {HitData.Kind.SWEEP: &"sweep", HitData.Kind.THRUST: &"thrust", HitData.Kind.GRAB: &"grab"}
## Bajo esta parte de la vida, aviso de curarse.
const HURT_RATIO: float = 0.7
const DEATHBLOW_RANGE: float = 8.0
const SHOW_SECONDS: float = 3.2

## Último aviso mostrado (para las pruebas) y cuántas veces salió cada uno en esta partida.
var last_id: StringName = &""
var shown: Dictionary = {}

var _player: Player
var _tween: Tween


func setup(player: Player) -> void:
	_player = player
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 28)
	add_theme_color_override("font_color", Color(1.0, 0.92, 0.78))
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	add_theme_constant_override("outline_size", 9)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_left = -700.0
	offset_right = 700.0
	offset_top = 150.0
	offset_bottom = 200.0
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.health.changed.connect(_on_player_health)
	Story.changed.connect(func() -> void: shown.clear())
	for node in get_tree().get_nodes_in_group("enemies"):
		_watch(node as Enemy)
	get_tree().node_added.connect(func(node: Node) -> void:
		if node is Enemy:
			_watch.call_deferred(node))


func _watch(enemy: Enemy) -> void:
	if enemy == null or enemy.has_meta("hints_watched"):
		return
	enemy.set_meta("hints_watched", true)
	enemy.danger_warned.connect(func(kind: int) -> void:
		if KIND_IDS.has(kind) and _near(enemy, 14.0):
			show_hint(KIND_IDS[kind]))
	enemy.posture.broken.connect(func() -> void:
		if not enemy.is_dead() and _near(enemy, DEATHBLOW_RANGE):
			show_hint(&"deathblow"))


func _near(enemy: Enemy, range_m: float) -> bool:
	return _player != null and is_instance_valid(enemy) and enemy.global_position.distance_to(_player.global_position) <= range_m


func _on_player_health(current: float, maximum: float) -> void:
	if current > 0.0 and current < maximum * HURT_RATIO and _player.bandages > 0:
		show_hint(&"heal")


## ¿Queda alguna vez para este aviso?
func pending(id: StringName) -> bool:
	return not Story.heard(StringName("hint_%s" % id)) and int(shown.get(id, 0)) < int(TIMES.get(id, 1))


func show_hint(id: StringName) -> bool:
	if not pending(id) or get_tree().get_first_node_in_group("cutscene") != null:
		return false
	shown[id] = int(shown.get(id, 0)) + 1
	if shown[id] >= int(TIMES.get(id, 1)):
		Story.mark_heard(StringName("hint_%s" % id))
	last_id = id
	text = IronPassLayout.tip_text(TEXTS[id])
	if _tween:
		_tween.kill()
	modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(SHOW_SECONDS)
	_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	return true
