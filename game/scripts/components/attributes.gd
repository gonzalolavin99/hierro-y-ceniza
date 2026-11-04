class_name Attributes
extends Node
## Atributos del jugador, que se suben en el campamento gastando experiencia:
## - Vigor: vida máxima.          - Temple: postura máxima (tarda más en romperse).
## - Fuerza: daño de tus golpes.   - Destreza: daño de tus golpes a la postura del enemigo.
## El nivel del personaje es la suma de los cuatro menos 3 (empieza en 1). Cada nivel cuesta un poco más.

signal changed

const MAX_VALUE: int = 10
const ORDER: Array[StringName] = [&"vigor", &"temple", &"strength", &"dexterity"]
const NAMES: Dictionary[StringName, String] = {
	&"vigor": "Vigor", &"temple": "Temple", &"strength": "Fuerza", &"dexterity": "Destreza",
}
const DESCRIPTIONS: Dictionary[StringName, String] = {
	&"vigor": "Más vida",
	&"temple": "Más postura: tarda más en romperse",
	&"strength": "Tus golpes hacen más daño",
	&"dexterity": "Tus golpes rompen antes la postura enemiga",
}
## Lo que suma cada punto por encima de 1.
const HEALTH_PER_POINT: float = 10.0
const POSTURE_PER_POINT: float = 8.0
const DAMAGE_PER_POINT: float = 0.06
const POSTURE_DAMAGE_PER_POINT: float = 0.06
## Coste: base + paso × (nivel − 1).
const COST_BASE: int = 60
const COST_STEP: int = 20

var _values: Dictionary[StringName, int] = {&"vigor": 1, &"temple": 1, &"strength": 1, &"dexterity": 1}


func get_value(attribute: StringName) -> int:
	return _values.get(attribute, 1)


func level() -> int:
	var total: int = 0
	for key in _values:
		total += _values[key]
	return total - 3


func next_cost() -> int:
	return COST_BASE + COST_STEP * (level() - 1)


func can_raise(attribute: StringName, xp: int) -> bool:
	return _values.has(attribute) and _values[attribute] < MAX_VALUE and xp >= next_cost()


## Sube un punto (sin cobrar: eso lo hace Player.raise_attribute).
func raise(attribute: StringName) -> void:
	_values[attribute] = mini(_values[attribute] + 1, MAX_VALUE)
	changed.emit()


func max_health(base: float) -> float:
	return base + HEALTH_PER_POINT * (get_value(&"vigor") - 1)


func max_posture(base: float) -> float:
	return base + POSTURE_PER_POINT * (get_value(&"temple") - 1)


func damage_scale() -> float:
	return 1.0 + DAMAGE_PER_POINT * (get_value(&"strength") - 1)


func posture_scale() -> float:
	return 1.0 + POSTURE_DAMAGE_PER_POINT * (get_value(&"dexterity") - 1)


## Lo que da el siguiente punto, en texto (para el menú).
func next_bonus_text(attribute: StringName) -> String:
	match attribute:
		&"vigor":
			return "+%d vida" % int(HEALTH_PER_POINT)
		&"temple":
			return "+%d postura" % int(POSTURE_PER_POINT)
		&"strength":
			return "+%d %% daño" % int(DAMAGE_PER_POINT * 100.0)
		_:
			return "+%d %% a la postura" % int(POSTURE_DAMAGE_PER_POINT * 100.0)


## Para el guardado (más adelante).
func to_dict() -> Dictionary:
	return _values.duplicate()


func from_dict(data: Dictionary) -> void:
	for key in ORDER:
		_values[key] = clampi(int(data.get(key, 1)), 1, MAX_VALUE)
	changed.emit()
