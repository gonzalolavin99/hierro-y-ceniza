# Inspecciona cómo importa Blender un FBX de Mixamo (escala, nombres, acción).
import bpy, sys
path = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=path, automatic_bone_orientation=False)
for o in bpy.data.objects:
    print("OBJ", o.name, o.type, "scale", tuple(round(s, 4) for s in o.scale), "rot", tuple(round(r, 3) for r in o.rotation_euler))
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
print("BONES", len(arm.data.bones), [b.name for b in arm.data.bones][:5])
act = arm.animation_data.action if arm.animation_data else None
print("ACTION", act.name if act else None, act.frame_range if act else None, bpy.context.scene.render.fps)
hips = arm.pose.bones[0]
bpy.context.scene.frame_set(1)
print("HIPS world", (arm.matrix_world @ hips.matrix).translation)
