extends SceneTree
## Compara una animación retocada en Blender con la original (estructura y posiciones de huesos).
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var orig: Node = (load(args[0]) as PackedScene).instantiate()
	var pol: Node = (load(args[1]) as PackedScene).instantiate()
	var ao: Animation = (orig.get_node("AnimationPlayer") as AnimationPlayer).get_animation("mixamo_com")
	var ap_p := pol.find_child("AnimationPlayer", true, false) as AnimationPlayer
	print("Animaciones retocadas: ", ap_p.get_animation_list())
	var anp: Animation = ap_p.get_animation(ap_p.get_animation_list()[0])
	print("Duración: original %.2f  retocada %.2f  pistas %d / %d" % [ao.length, anp.length, ao.get_track_count(), anp.get_track_count()])
	print("Ejemplos de pistas retocadas: ", anp.track_get_path(0), " | ", anp.track_get_path(1))
	var sk := pol.find_child("Skeleton3D", true, false) as Skeleton3D
	print("Ruta del esqueleto en la escena retocada: ", pol.get_path_to(sk), "  huesos=", sk.get_bone_count())
	var sko := orig.get_node("Skeleton3D") as Skeleton3D
	var rest_diff := 0.0
	for i in sko.get_bone_count():
		var j := sk.find_bone(sko.get_bone_name(i))
		if j < 0:
			print("FALTA hueso ", sko.get_bone_name(i)); continue
		rest_diff = max(rest_diff, sko.get_bone_rest(i).basis.get_rotation_quaternion().angle_to(sk.get_bone_rest(j).basis.get_rotation_quaternion()))
	print("Máxima diferencia de rotación en reposo: %.4f rad" % rest_diff)
	for bone in ["mixamorig_Hips", "mixamorig_LeftFoot", "mixamorig_RightHand"]:
		for t in [0.0, ao.length * 0.5]:
			var p0: Variant = _pos(ao, bone, t)
			var p1: Variant = _pos_any(anp, bone, t)
			print("%s t=%.2f  original=%s  retocada=%s" % [bone, t, p0, p1])
	orig.free(); pol.free()
	quit()
func _pos(a: Animation, bone: String, t: float) -> Variant:
	var i := a.find_track(NodePath("Skeleton3D:" + bone), Animation.TYPE_POSITION_3D)
	return a.position_track_interpolate(i, t) if i >= 0 else "-"
func _pos_any(a: Animation, bone: String, t: float) -> Variant:
	for i in a.get_track_count():
		if String(a.track_get_path(i)).ends_with(":" + bone) and a.track_get_type(i) == Animation.TYPE_POSITION_3D:
			return a.position_track_interpolate(i, t)
	return "-"
