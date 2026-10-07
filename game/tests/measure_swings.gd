extends SceneTree
## Mide en cada animación de ataque el instante de máxima velocidad de la mano derecha (impacto).
## Calcula la cadena de huesos a mano (cinemática directa) desde las pistas de la animación.

const ANIMS := ["x_great_slash", "x_one_hand_combo", "x_sword_fight", "x_two_hand_combo"]
const CHAIN := ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2", "mixamorig_RightShoulder", "mixamorig_RightArm", "mixamorig_RightForeArm", "mixamorig_RightHand"]

var sk: Skeleton3D

func _init() -> void:
	var bot: Node3D = (load("res://assets/animations/mixamo/y_bot.fbx") as PackedScene).instantiate()
	sk = bot.get_node("Skeleton3D")
	for n in ANIMS:
		var s: Node = (load("res://assets/animations/mixamo/%s.fbx" % n) as PackedScene).instantiate()
		var anim: Animation = (s.get_node("AnimationPlayer") as AnimationPlayer).get_animation("mixamo_com")
		var dt := 1.0 / 60.0
		var prev := Vector3.ZERO
		var speeds: Array = []
		var t := 0.0
		while t <= anim.length:
			var p := _hand(anim, t)
			if t > 0.0:
				speeds.append([t, p.distance_to(prev) / dt])
			prev = p
			t += dt
		var peaks: Array = []
		var maxv := 0.0
		for i in range(2, speeds.size() - 2):
			var v: float = speeds[i][1]
			maxv = max(maxv, v)
			if v > 3.0 and v >= speeds[i - 1][1] and v >= speeds[i + 1][1] and v >= speeds[i - 2][1] and v >= speeds[i + 2][1]:
				if peaks.is_empty() or speeds[i][0] - peaks[-1][0] > 0.3:
					peaks.append([speeds[i][0], v])
				elif v > peaks[-1][1]:
					peaks[-1] = [speeds[i][0], v]
		var txt := ""
		for pk in peaks:
			txt += " %.2f(%.0f)" % [pk[0], pk[1]]
		print("%-18s %.2fs max=%.1f picos:%s" % [n, anim.length, maxv, txt])
		s.free()
	bot.free()
	quit()

func _hand(anim: Animation, t: float) -> Vector3:
	var xf := Transform3D()
	for i in CHAIN.size():
		var bone_name: String = CHAIN[i]
		var b := sk.find_bone(bone_name)
		var rest := sk.get_bone_rest(b)
		var pos := rest.origin
		var rot := rest.basis.get_rotation_quaternion()
		var rt := anim.find_track(NodePath("Skeleton3D:" + bone_name), Animation.TYPE_ROTATION_3D)
		if rt >= 0:
			rot = anim.rotation_track_interpolate(rt, t)
		var pt := anim.find_track(NodePath("Skeleton3D:" + bone_name), Animation.TYPE_POSITION_3D)
		if pt >= 0 and i > 0:  # La cadera sin traslación: quitamos el desplazamiento del cuerpo
			pos = anim.position_track_interpolate(pt, t)
		xf = xf * Transform3D(Basis(rot), pos)
	return xf.origin
