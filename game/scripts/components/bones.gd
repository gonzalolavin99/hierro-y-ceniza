class_name Bones
extends RefCounted
## Esqueleto común (Cimientos, revisión del estudio: animación y programación). El código nunca escribe el
## nombre de un hueso del modelo: pide el hueso por su nombre común ("Hips", "LeftFoot"…) y esta tabla dice
## cómo se llama en el esqueleto actual. Hoy es el Y Bot de Mixamo ("mixamorig_Hips"); cuando llegue el Kael
## definitivo (u otro cuerpo, como un aldeano o Bram), solo cambia esta tabla, no el resto del juego.
## Uso: Bones.name(&"Hips") → "mixamorig_Hips" · Bones.path(&"Hips") → NodePath("Skeleton3D:mixamorig_Hips")

## Prefijo de los huesos del esqueleto actual (el Y Bot de Mixamo).
const RIG_PREFIX: String = "mixamorig_"
## Huesos que usa el juego: nombre común → nombre en el esqueleto actual. Un hueso que no esté aquí se
## busca como RIG_PREFIX + nombre común.
const NAMES: Dictionary = {
	&"Hips": "mixamorig_Hips",
	&"Spine": "mixamorig_Spine",
	&"Spine1": "mixamorig_Spine1",
	&"Spine2": "mixamorig_Spine2",
	&"Neck": "mixamorig_Neck",
	&"Head": "mixamorig_Head",
	&"LeftShoulder": "mixamorig_LeftShoulder",
	&"LeftArm": "mixamorig_LeftArm",
	&"LeftForeArm": "mixamorig_LeftForeArm",
	&"LeftHand": "mixamorig_LeftHand",
	&"RightShoulder": "mixamorig_RightShoulder",
	&"RightArm": "mixamorig_RightArm",
	&"RightForeArm": "mixamorig_RightForeArm",
	&"RightHand": "mixamorig_RightHand",
	&"LeftUpLeg": "mixamorig_LeftUpLeg",
	&"LeftLeg": "mixamorig_LeftLeg",
	&"LeftFoot": "mixamorig_LeftFoot",
	&"RightUpLeg": "mixamorig_RightUpLeg",
	&"RightLeg": "mixamorig_RightLeg",
	&"RightFoot": "mixamorig_RightFoot",
}


## Nombre del hueso en el esqueleto actual.
static func name(bone: StringName) -> String:
	return NAMES.get(bone, RIG_PREFIX + String(bone))


## Ruta de animación del hueso (pista de un clip o filtro del árbol de animación).
static func path(bone: StringName) -> NodePath:
	return NodePath("Skeleton3D:" + name(bone))


## Nombre común de un hueso del esqueleto actual ("mixamorig_Hips" → "Hips").
static func common(rig_name: String) -> String:
	for key in NAMES:
		if NAMES[key] == rig_name:
			return String(key)
	return rig_name.trim_prefix(RIG_PREFIX)
