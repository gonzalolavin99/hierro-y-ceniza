"""Taller de animación: retoca una animación de Mixamo en Blender y la exporta para Godot.

Uso:
  blender -b --python tools/blender/polish.py -- <entrada.fbx> <salida.fbx> '<json de ajustes>'

Ajustes (todos opcionales, en metros/grados):
  hips_drop:   baja la cadera (postura más baja y firme, estilo kenjutsu/Sekiro).
  hips_yaw:    [[fotograma, grados], ...] giro EXTRA de cadera en el tiempo (koshi-mawari:
               el tajo nace de la cadera). Se interpola entre puntos.
  spine_yaw:   igual que hips_yaw pero para el pecho (Spine2), para acompañar el giro.
  arm_reach:   [[fotograma, grados], ...] estira el hombro derecho hacia delante en el remate.

Técnica: se graba dónde está cada pie en cada fotograma, se modifica el cuerpo, y las piernas
se recalculan con IK (cinemática inversa) para que los pies queden clavados donde estaban.
Después se "hornea" el resultado en fotogramas clave normales y se exporta.
"""
import bpy
import json
import math
import sys
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = args[0], args[1]
CFG = json.loads(args[2]) if len(args) > 2 else {}

LEGS = [("Left", "mixamorig:LeftUpLeg", "mixamorig:LeftLeg", "mixamorig:LeftFoot"),
        ("Right", "mixamorig:RightUpLeg", "mixamorig:RightLeg", "mixamorig:RightFoot")]


def curve(points, frame):
    """Interpola linealmente una lista [[frame, valor], ...] (suavizada con smoothstep)."""
    if not points:
        return 0.0
    pts = sorted(points)
    if frame <= pts[0][0]:
        return pts[0][1]
    for (f0, v0), (f1, v1) in zip(pts, pts[1:]):
        if f0 <= frame <= f1:
            t = (frame - f0) / max(f1 - f0, 1e-6)
            t = t * t * (3 - 2 * t)
            return v0 + (v1 - v0) * t
    return pts[-1][1]


def world(arm, pb):
    return arm.matrix_world @ pb.matrix


def set_world(arm, pb, m):
    pb.matrix = arm.matrix_world.inverted() @ m


def key(pb, frame):
    pb.keyframe_insert("location", frame=frame)
    pb.keyframe_insert("rotation_quaternion", frame=frame)


def rotate_about(m, pivot, axis, degrees):
    r = Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(degrees), 4, axis) @ Matrix.Translation(-pivot)
    return r @ m


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=SRC, automatic_bone_orientation=False)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
for o in list(bpy.data.objects):
    if o.type == "MESH":
        bpy.data.objects.remove(o)
scene = bpy.context.scene
action = arm.animation_data.action
f_start, f_end = int(action.frame_range[0]), int(action.frame_range[1])
scene.frame_start, scene.frame_end = f_start, f_end
P = arm.pose.bones

# 1) Grabar pies, rodillas y caderas originales
rec = {}
for f in range(f_start, f_end + 1):
    scene.frame_set(f)
    rec[f] = {name: world(arm, P[name]).copy() for leg in LEGS for name in leg[1:]}
    rec[f]["hips"] = world(arm, P["mixamorig:Hips"]).copy()
    rec[f]["spine2"] = world(arm, P["mixamorig:Spine2"]).copy()

# 3) IK de piernas: pies clavados donde estaban
def make_empty(name):
    e = bpy.data.objects.new(name, None)
    scene.collection.objects.link(e)
    return e

pole_angle = math.radians(float(CFG.get("pole_angle", -90.0)))
for side, up, low, foot in LEGS:
    tgt, pole, rot = make_empty(side + "_foot"), make_empty(side + "_pole"), make_empty(side + "_rot")
    for f in range(f_start, f_end + 1):
        fm, km, hm = rec[f][foot], rec[f][low], rec[f][up]
        tgt.matrix_world = Matrix.Translation(fm.translation)
        tgt.keyframe_insert("location", frame=f)
        # Dirección hacia donde apunta la rodilla (si la pierna está casi recta, hacia delante).
        mid = (hm.translation + fm.translation) / 2
        out = km.translation - mid
        if out.length < 0.01:
            out = rec[f]["hips"].to_3x3().normalized() @ Vector((0, 0, 1))
        out.normalize()
        pole.matrix_world = Matrix.Translation(km.translation + out * 0.6)
        pole.keyframe_insert("location", frame=f)
        rot.matrix_world = fm
        rot.keyframe_insert("rotation_quaternion" if rot.rotation_mode == "QUATERNION" else "rotation_euler", frame=f)
    ik = P[low].constraints.new("IK")
    ik.target, ik.pole_target, ik.pole_angle, ik.chain_count = tgt, pole, pole_angle, 2
    cr = P[foot].constraints.new("COPY_ROTATION")
    cr.target = rot
    # Calibración automática del ángulo del polo de ESTA pierna: el que mejor reproduce
    # las rodillas originales (se mide sin modificar el cuerpo, en varios fotogramas).
    if "pole_angle" not in CFG:
        hips_backup = {}
        sample = list(range(f_start, f_end + 1, max(1, (f_end - f_start) // 8)))
        best = (1e9, 0.0)
        for deg in range(-180, 180, 5):
            ik.pole_angle = math.radians(deg)
            e = 0.0
            for f in sample:
                scene.frame_set(f)
                e += (world(arm, P[low]).translation - rec[f][low].translation).length
            best = min(best, (e, deg))
        for deg10 in range(best[1] * 10 - 50, best[1] * 10 + 51, 5):
            ik.pole_angle = math.radians(deg10 / 10)
            e = 0.0
            for f in sample:
                scene.frame_set(f)
                e += (world(arm, P[low]).translation - rec[f][low].translation).length
            best = min(best, (e, deg10 / 10))
        ik.pole_angle = math.radians(best[1])
        print("POLISH polo %s = %.1f°" % (side, best[1]))

# 2) Modificar el cuerpo
drop = float(CFG.get("hips_drop", 0.0))
for f in range(f_start, f_end + 1):
    scene.frame_set(f)
    hips = rec[f]["hips"]
    pivot = hips.translation.copy()
    m = Matrix.Translation(Vector((0, 0, -drop))) @ hips
    m = rotate_about(m, pivot - Vector((0, 0, drop)), "Z", curve(CFG.get("hips_yaw"), f))
    set_world(arm, P["mixamorig:Hips"], m)
    key(P["mixamorig:Hips"], f)
    bpy.context.view_layer.update()
    sy = curve(CFG.get("spine_yaw"), f)
    if sy:
        s2 = world(arm, P["mixamorig:Spine2"])
        set_world(arm, P["mixamorig:Spine2"], rotate_about(s2, s2.translation.copy(), "Z", sy))
        key(P["mixamorig:Spine2"], f)
    reach = curve(CFG.get("arm_reach"), f)
    if reach:
        bpy.context.view_layer.update()
        sh = world(arm, P["mixamorig:RightArm"])
        fwd = (world(arm, P["mixamorig:Hips"]).to_3x3() @ Vector((0, 0, 1))).normalized()
        axis = fwd.cross(Vector((0, 0, 1))).normalized()
        set_world(arm, P["mixamorig:RightArm"], rotate_about(sh, sh.translation.copy(), axis, -reach))
        key(P["mixamorig:RightArm"], f)

# 4) Hornear (pasar todo a fotogramas clave normales) y quitar las restricciones
bpy.context.view_layer.objects.active = arm
arm.select_set(True)
bpy.ops.object.mode_set(mode="POSE")
bpy.ops.pose.select_all(action="SELECT")
bpy.ops.nla.bake(frame_start=f_start, frame_end=f_end, only_selected=False, visual_keying=True,
                 clear_constraints=True, use_current_action=True, bake_types={"POSE"})
bpy.ops.object.mode_set(mode="OBJECT")

# Comprobación: error de los pies respecto al original (debería ser ~0)
err = knee_err = 0.0
for f in range(f_start, f_end + 1, 3):
    scene.frame_set(f)
    for side, up, low, foot in LEGS:
        err = max(err, (world(arm, P[foot]).translation - rec[f][foot].translation).length)
        knee_err = max(knee_err, (world(arm, P[low]).translation - rec[f][low].translation).length)
print("POLISH pies_error_max=%.4f m rodillas_desvio_max=%.4f m" % (err, knee_err))

# 5) Exportar solo el esqueleto con la animación
for o in list(bpy.data.objects):
    if o.type == "EMPTY":
        bpy.data.objects.remove(o)
bpy.ops.export_scene.fbx(filepath=DST, object_types={"ARMATURE"}, add_leaf_bones=False, bake_anim=True,
                         bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False,
                         bake_anim_simplify_factor=0.0)
print("POLISH ok ->", DST, "fotogramas", f_start, f_end)
