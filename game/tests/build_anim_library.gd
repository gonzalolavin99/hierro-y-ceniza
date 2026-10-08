extends SceneTree
## Construye res://assets/animations/mixamo_library.res a partir de los FBX de Mixamo.
## - Renombra las animaciones con nombres claros.
## - Quita el desplazamiento horizontal de la cadera. En las animaciones que no son bucle, ese
##   desplazamiento se guarda en una pista aparte "RootMotion" para que el código mueva al
##   personaje exactamente lo que la animación avanza (sin patinar).
## - Marca en bucle las de locomoción.
## Ejecutar: Godot --headless --path game --script res://tests/build_anim_library.gd

## nombre_en_el_juego: [archivo, en_bucle]
const MAP := {
	"idle": ["idle", true],
	"idle_alert": ["idle_3", true],
	"walk_fwd": ["walk", true],
	"walk_back": ["walk_2", true],
	"walk_left": ["strafe", true],
	"walk_right": ["strafe_2", true],
	"run_fwd": ["run_2", true],
	"run_back": ["run", true],
	"run_left": ["strafe_3", true],
	"run_right": ["strafe_4", true],
	"jump": ["jump_2", false],
	"block_enter": ["blocking", false],
	"block_hold": ["blocking_2", true],
	"block_impact": ["impact", false],
	"hit": ["impact_2", false],
	"hit_light": ["impact_3", false],
	"kneel": ["crouching_3", true],
	"kneel_hit": ["impact_5", false],
	"death": ["death", false],
	"death_back": ["death_2", false],
	"slash_a": ["slash", false],
	"slash_b": ["slash_4", false],
	"slash_c": ["slash_3", false],
	"slash_d": ["attack", false],
	"combo_long": ["slash_2", false],
	"sweep_low": ["slash_5", false],
	"spin": ["high_spin_attack", false],
	"leap": ["jump_attack", false],
	"slide": ["slide_attack", false],
	"kick": ["kick", false],
	"shove": ["kick_2", false],
	"draw": ["draw_a_2", false],
	"turn_180": ["180_turn", false],
	"combo_one_hand": ["x_one_hand_combo", false],
	"combo_two_hand": ["x_two_hand_combo", false],
	"sparring": ["x_sword_fight", false],
}

## Retoques del taller (AnimPolish) por animación. Postura más baja y firme (kenjutsu/Sekiro)
## y tajos que nacen de la cadera. Los impactos son los medidos con tests/measure_swings.gd.
const POLISH := {
	"idle": {"hips_drop": 0.05},
	"idle_alert": {"hips_drop": 0.05},
	"block_hold": {"hips_drop": 0.05},
	"walk_fwd": {"hips_drop": 0.04}, "walk_back": {"hips_drop": 0.04},
	"walk_left": {"hips_drop": 0.04}, "walk_right": {"hips_drop": 0.04},
	"run_fwd": {"hips_drop": 0.03}, "run_back": {"hips_drop": 0.03},
	"run_left": {"hips_drop": 0.03}, "run_right": {"hips_drop": 0.03},
	"combo_one_hand": {"hips_drop": 0.04, "cut_emphasis": {"impacts": [1.00, 1.95, 2.98], "hips": 12.0, "spine": 10.0}},
	"combo_two_hand": {"hips_drop": 0.04, "cut_emphasis": {"impacts": [0.63, 1.33, 2.25], "hips": 10.0, "spine": 8.0}},
	"slash_a": {"cut_emphasis": {"impacts": [0.53], "hips": 10.0, "spine": 8.0}},
	"slash_b": {"cut_emphasis": {"impacts": [0.33], "hips": 10.0, "spine": 8.0}},
	"slash_c": {"cut_emphasis": {"impacts": [0.83], "hips": 12.0, "spine": 10.0}},
	"slash_d": {"cut_emphasis": {"impacts": [0.47], "hips": 10.0, "spine": 8.0}},
}


func _init() -> void:
	var lib := AnimationLibrary.new()
	var bot: Node = (load("res://assets/animations/mixamo/y_bot.fbx") as PackedScene).instantiate()
	var polisher := AnimPolish.new(bot.get_node("Skeleton3D"))
	for key in MAP:
		var file: String = MAP[key][0]
		var s: Node = (load("res://assets/animations/mixamo/%s.fbx" % file) as PackedScene).instantiate()
		var anim: Animation = (s.get_node("AnimationPlayer") as AnimationPlayer).get_animation("mixamo_com").duplicate(true)
		s.free()
		if POLISH.has(key):
			var report := polisher.polish(anim, POLISH[key].duplicate(true))
			print("  retocada %-16s pies_error=%.4f m" % [key, report["pies_error_max"]])
		var hips := anim.find_track(NodePath("Skeleton3D:mixamorig_Hips"), Animation.TYPE_POSITION_3D)
		if hips >= 0 and anim.track_get_key_count(hips) > 0:
			var first: Vector3 = anim.track_get_key_value(hips, 0)
			var root := -1
			if not MAP[key][1]:
				root = anim.add_track(Animation.TYPE_POSITION_3D)
				anim.track_set_path(root, NodePath("RootMotion"))
			for k in anim.track_get_key_count(hips):
				var v: Vector3 = anim.track_get_key_value(hips, k)
				var t: float = anim.track_get_key_time(hips, k)
				anim.track_set_key_value(hips, k, Vector3(first.x, v.y, first.z))
				if root >= 0:
					anim.position_track_insert_key(root, t, Vector3(v.x - first.x, 0.0, v.z - first.z))
		anim.loop_mode = Animation.LOOP_LINEAR if MAP[key][1] else Animation.LOOP_NONE
		lib.add_animation(key, anim)
	bot.free()
	var err := ResourceSaver.save(lib, "res://assets/animations/mixamo_library.res")
	print("Biblioteca guardada: %d animaciones (error=%d)" % [lib.get_animation_list().size(), err])
	quit()
