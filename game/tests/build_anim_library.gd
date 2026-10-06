extends SceneTree
## Construye res://assets/animations/mixamo_library.res a partir de los FBX de Mixamo.
## - Renombra las animaciones con nombres claros.
## - Quita el desplazamiento horizontal de la cadera (el movimiento lo controla el código).
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
}

func _init() -> void:
	var lib := AnimationLibrary.new()
	for key in MAP:
		var file: String = MAP[key][0]
		var s: Node = (load("res://assets/animations/mixamo/%s.fbx" % file) as PackedScene).instantiate()
		var anim: Animation = (s.get_node("AnimationPlayer") as AnimationPlayer).get_animation("mixamo_com").duplicate(true)
		s.free()
		var hips := anim.find_track(NodePath("Skeleton3D:mixamorig_Hips"), Animation.TYPE_POSITION_3D)
		if hips >= 0 and anim.track_get_key_count(hips) > 0:
			var first: Vector3 = anim.track_get_key_value(hips, 0)
			for k in anim.track_get_key_count(hips):
				var v: Vector3 = anim.track_get_key_value(hips, k)
				anim.track_set_key_value(hips, k, Vector3(first.x, v.y, first.z))
		anim.loop_mode = Animation.LOOP_LINEAR if MAP[key][1] else Animation.LOOP_NONE
		lib.add_animation(key, anim)
	var err := ResourceSaver.save(lib, "res://assets/animations/mixamo_library.res")
	print("Biblioteca guardada: %d animaciones (error=%d)" % [lib.get_animation_list().size(), err])
	quit()
