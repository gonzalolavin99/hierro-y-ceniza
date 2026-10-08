class_name AnimPolish
extends RefCounted
## Taller de animación: retoca animaciones de Mixamo directamente sobre sus datos.
##
## Técnica (la misma de un animador): se calcula la pose completa de cada fotograma, se modifica
## el cuerpo (bajar la cadera, girarla más en el tajo, acompañar con el pecho) y las piernas se
## recalculan con IK de dos huesos (ley de los cosenos) para que cada pie quede EXACTAMENTE donde
## estaba, con la rodilla apuntando hacia el mismo lado. Después se escriben los nuevos valores.
##
## Ajustes (Dictionary):
##   hips_drop: float           metros que baja la cadera (postura más baja y firme).
##   hips_yaw:  [[seg, grados]] giro EXTRA de cadera en el tiempo (koshi-mawari).
##   spine_yaw: [[seg, grados]] giro EXTRA del pecho (Spine2) en el tiempo.
##   cut_emphasis: {"impacts": [seg...], "hips": grados, "spine": grados}
##       Genera hips_yaw/spine_yaw automáticamente: en cada impacto la cadera y el pecho giran
##       MÁS en la dirección del tajo, con un pequeño contragiro antes (anticipación).

const BONES := ["Hips", "Spine", "Spine1", "Spine2", "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot", "RightShoulder", "RightArm", "RightForeArm", "RightHand"]
const LEGS := [["LeftUpLeg", "LeftLeg", "LeftFoot"], ["RightUpLeg", "RightLeg", "RightFoot"]]

var _sk: Skeleton3D
var _idx: Dictionary = {}  # nombre corto -> índice de hueso


func _init(skeleton: Skeleton3D) -> void:
	_sk = skeleton
	for b in BONES:
		_idx[b] = _sk.find_bone("mixamorig_" + b)


## Aplica los ajustes a `anim` (se modifica en el sitio). Devuelve un informe con los errores.
func polish(anim: Animation, cfg: Dictionary) -> Dictionary:
	if cfg.has("cut_emphasis"):
		_build_cut_curves(anim, cfg)
	var times := _key_times(anim, "Hips", Animation.TYPE_ROTATION_3D)
	var new_keys := {}  # "Bone/rot|pos" -> Array[[t, value]]
	var foot_err := 0.0
	for t in times:
		var L := _locals(anim, t)
		var G0 := _globals(L)
		# --- Cuerpo
		var drop: float = cfg.get("hips_drop", 0.0)
		var hips: Transform3D = L["Hips"]
		hips.origin.y -= drop
		hips.basis = Basis(Vector3.UP, deg_to_rad(_curve(cfg.get("hips_yaw", []), t))) * hips.basis
		L["Hips"] = hips
		var spine_yaw: float = deg_to_rad(_curve(cfg.get("spine_yaw", []), t))
		if spine_yaw != 0.0:
			var G1 := _globals(L)
			var parent: Transform3D = G1["Spine1"]
			var g: Transform3D = G1["Spine2"]
			L["Spine2"] = Transform3D(parent.basis.inverse() * (Basis(Vector3.UP, spine_yaw) * g.basis), L["Spine2"].origin)
		var G := _globals(L)
		# --- Piernas con IK: pies clavados donde estaban
		for leg in LEGS:
			_solve_leg(L, G, G0, leg[0], leg[1], leg[2])
		var G2 := _globals(L)
		for leg in LEGS:
			foot_err = maxf(foot_err, G2[leg[2]].origin.distance_to(G0[leg[2]].origin))
		for b in ["Hips", "Spine2", "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot"]:
			_push(new_keys, b + "/rot", t, L[b].basis.get_rotation_quaternion())
		_push(new_keys, "Hips/pos", t, L["Hips"].origin)
	_write(anim, new_keys)
	return {"pies_error_max": foot_err, "fotogramas": times.size()}


# --- IK de dos huesos ----------------------------------------------------------------

func _solve_leg(L: Dictionary, G: Dictionary, G0: Dictionary, up: String, low: String, foot: String) -> void:
	var a: Vector3 = G[up].origin                    # cadera (ya modificada)
	var target: Vector3 = G0[foot].origin            # pie original
	var a0: Vector3 = G0[up].origin
	var k0: Vector3 = G0[low].origin
	var f0: Vector3 = G0[foot].origin
	var l1: float = a0.distance_to(k0)
	var l2: float = k0.distance_to(f0)
	var to_t := target - a
	var d: float = clampf(to_t.length(), absf(l1 - l2) + 0.001, l1 + l2 - 0.0005)
	var u := to_t.normalized()
	# Hacia dónde apunta la rodilla: igual que en la pose original
	var u0 := (f0 - a0).normalized()
	var bend0 := (k0 - a0) - u0 * (k0 - a0).dot(u0)
	if bend0.length() < 0.0001:
		bend0 = G0["Hips"].basis.z
	var pole := bend0 - u * bend0.dot(u)
	pole = pole.normalized() if pole.length() > 0.0001 else bend0.normalized()
	var along: float = (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h: float = sqrt(maxf(l1 * l1 - along * along, 0.0))
	var knee: Vector3 = a + u * along + pole * h
	# Rotar muslo y espinilla desde su orientación original a la nueva (mismo plano de flexión)
	var thigh: Basis = _frame_rotation(k0 - a0, bend0, knee - a, pole) * G0[up].basis
	var shin: Basis = _frame_rotation(f0 - k0, bend0, target - knee, pole) * G0[low].basis
	var foot_b: Basis = G0[foot].basis
	var hips_b: Basis = G["Hips"].basis
	L[up] = Transform3D(hips_b.inverse() * thigh, L[up].origin)
	L[low] = Transform3D(thigh.inverse() * shin, L[low].origin)
	L[foot] = Transform3D(shin.inverse() * foot_b, L[foot].origin)


## Rotación que lleva el sistema (dir_a, plano_a) al sistema (dir_b, plano_b).
func _frame_rotation(dir_a: Vector3, plane_a: Vector3, dir_b: Vector3, plane_b: Vector3) -> Basis:
	return _frame(dir_b, plane_b) * _frame(dir_a, plane_a).inverse()


func _frame(dir: Vector3, plane: Vector3) -> Basis:
	var x := dir.normalized()
	var y := (plane - x * plane.dot(x)).normalized()
	return Basis(x, y, x.cross(y))


# --- Énfasis del tajo (koshi-mawari) -----------------------------------------------

func _build_cut_curves(anim: Animation, cfg: Dictionary) -> void:
	var e: Dictionary = cfg["cut_emphasis"]
	var hips_pts: Array = []
	var spine_pts: Array = []
	for impact in e["impacts"]:
		var s := _cut_direction(anim, impact)
		hips_pts.append_array([[impact - 0.3, 0.0], [impact - 0.12, -0.35 * e.get("hips", 10.0) * s],
			[impact + 0.02, e.get("hips", 10.0) * s], [impact + 0.35, 0.0]])
		spine_pts.append_array([[impact - 0.3, 0.0], [impact - 0.1, -0.35 * e.get("spine", 8.0) * s],
			[impact + 0.04, e.get("spine", 8.0) * s], [impact + 0.4, 0.0]])
	cfg["hips_yaw"] = hips_pts
	cfg["spine_yaw"] = spine_pts


## +1 si en el impacto la mano barre en sentido antihorario visto desde arriba, -1 si horario.
func _cut_direction(anim: Animation, t: float) -> float:
	var g0 := _globals(_locals(anim, t - 0.03))
	var g1 := _globals(_locals(anim, t + 0.03))
	var r: Vector3 = g0["RightHand"].origin - g0["Hips"].origin
	var v: Vector3 = g1["RightHand"].origin - g0["RightHand"].origin
	return 1.0 if r.cross(v).y >= 0.0 else -1.0


# --- Utilidades ------------------------------------------------------------------------

func _locals(anim: Animation, t: float) -> Dictionary:
	var L := {}
	for b in BONES:
		var i: int = _idx[b]
		var rest := _sk.get_bone_rest(i)
		var pos := rest.origin
		var rot := rest.basis.get_rotation_quaternion()
		var pt := anim.find_track(NodePath("Skeleton3D:mixamorig_" + b), Animation.TYPE_POSITION_3D)
		if pt >= 0:
			pos = anim.position_track_interpolate(pt, t)
		var rt := anim.find_track(NodePath("Skeleton3D:mixamorig_" + b), Animation.TYPE_ROTATION_3D)
		if rt >= 0:
			rot = anim.rotation_track_interpolate(rt, t)
		L[b] = Transform3D(Basis(rot), pos)
	return L


func _globals(L: Dictionary) -> Dictionary:
	var G := {}
	for b in BONES:  # BONES está ordenado de padre a hijo
		var parent := _sk.get_bone_parent(_idx[b])
		var pname := _sk.get_bone_name(parent).trim_prefix("mixamorig_") if parent >= 0 else ""
		G[b] = (G[pname] * L[b]) if G.has(pname) else L[b]
	return G


func _curve(points: Array, t: float) -> float:
	if points.is_empty():
		return 0.0
	var pts := points.duplicate()
	pts.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	if t <= pts[0][0]:
		return pts[0][1]
	for i in pts.size() - 1:
		var p: Array = pts[i]
		var q: Array = pts[i + 1]
		if t >= p[0] and t <= q[0]:
			var k: float = (t - p[0]) / maxf(q[0] - p[0], 0.0001)
			return lerpf(p[1], q[1], k * k * (3.0 - 2.0 * k))
	return pts[-1][1]


func _key_times(anim: Animation, bone: String, type: int) -> Array[float]:
	var tr := anim.find_track(NodePath("Skeleton3D:mixamorig_" + bone), type)
	var out: Array[float] = []
	for k in anim.track_get_key_count(tr):
		out.append(anim.track_get_key_time(tr, k))
	return out


func _push(keys: Dictionary, id: String, t: float, value: Variant) -> void:
	if not keys.has(id):
		keys[id] = []
	keys[id].append([t, value])


func _write(anim: Animation, keys: Dictionary) -> void:
	for id in keys:
		var parts: PackedStringArray = id.split("/")
		var path := NodePath("Skeleton3D:mixamorig_" + parts[0])
		var type := Animation.TYPE_ROTATION_3D if parts[1] == "rot" else Animation.TYPE_POSITION_3D
		var tr := anim.find_track(path, type)
		if tr < 0:
			tr = anim.add_track(type)
			anim.track_set_path(tr, path)
		while anim.track_get_key_count(tr) > 0:
			anim.track_remove_key(tr, 0)
		for kv in keys[id]:
			anim.track_insert_key(tr, kv[0], kv[1])
