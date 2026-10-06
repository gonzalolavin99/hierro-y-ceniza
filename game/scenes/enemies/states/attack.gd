class_name EnemyAttackState
extends EnemyState
## Ataque del enemigo: una secuencia de tajos. Antes de cada uno brilla el filo (aviso).
## Si el jugador desvía el ÚLTIMO tajo, el enemigo retrocede expuesto (Recoil).

## Cada tajo: preparación (windup), tajo activo, pausa tras el tajo, posturas del arma.
const PATTERNS: Dictionary[StringName, Array] = {
	&"single": [
		{"windup": 0.65, "active": 0.14, "after": 0.7, "from": &"windup_high", "to": &"end_low", "lunge": 4.0},
	],
	&"double": [
		{"windup": 0.55, "active": 0.14, "after": 0.3, "from": &"windup_right", "to": &"end_left", "lunge": 3.5},
		{"windup": 0.28, "active": 0.14, "after": 0.7, "from": &"windup_left", "to": &"end_right", "lunge": 3.0},
	],
	&"thrust_combo": [
		{"windup": 0.5, "active": 0.14, "after": 0.25, "from": &"windup_right", "to": &"end_left", "lunge": 3.0},
		{"windup": 0.45, "active": 0.12, "after": 0.8, "from": &"windup_high", "to": &"thrust", "lunge": 6.0},
	],
	# Contraataque tras bloquear varios golpes: más rápido.
	&"counter": [
		{"windup": 0.3, "active": 0.12, "after": 0.25, "from": &"windup_right", "to": &"end_left", "lunge": 3.5},
		{"windup": 0.3, "active": 0.12, "after": 0.7, "from": &"windup_left", "to": &"end_right", "lunge": 3.5},
	],
}

const DAMAGE: float = 20.0
const POSTURE_DAMAGE: float = 22.0
## Postura que sufre este enemigo cuando le desvían un tajo.
const DEFLECT_POSTURE: float = 24.0

enum Phase { WINDUP, ACTIVE, AFTER }

var _swings: Array
var _index: int
var _phase: Phase
var _timer: float
var _deflected_last: bool


func enter(msg: Dictionary) -> void:
	_swings = PATTERNS[msg.get("pattern", &"single")]
	_index = 0
	_set_phase(Phase.WINDUP)


func exit() -> void:
	enemy.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var swing: Dictionary = _swings[_index]
	_timer += delta

	match _phase:
		Phase.WINDUP:
			# Sigue al jugador mientras se prepara; se lanza al final de la preparación.
			enemy.face_target(delta, 1.5)
			var lunging: bool = _timer > swing["windup"] * 0.6 and enemy.distance_to_target() > 1.6
			enemy.move_horizontal(enemy.get_facing() * (swing["lunge"] if lunging else 0.0), swing["lunge"], delta, 60.0)
			if _timer >= swing["windup"]:
				_set_phase(Phase.ACTIVE)
		Phase.ACTIVE:
			var lunging: bool = enemy.distance_to_target() > 1.4
			enemy.move_horizontal(enemy.get_facing() * (swing["lunge"] if lunging else 0.0), swing["lunge"], delta, 60.0)
			if _timer >= swing["active"]:
				_set_phase(Phase.AFTER)
		Phase.AFTER:
			enemy.move_horizontal(Vector3.ZERO, 0.0, delta)
			var last: bool = _index == _swings.size() - 1
			if last and _deflected_last:
				machine.transition_to(&"Recoil")
			elif _timer >= swing["after"]:
				if last:
					machine.transition_to(&"Idle")
				else:
					_index += 1
					_set_phase(Phase.WINDUP)


## Lo llama Enemy cuando el jugador desvía este tajo.
func on_deflected() -> void:
	enemy.posture.add(DEFLECT_POSTURE)
	enemy.hitbox.deactivate()
	if state_is_active():
		enemy.weapon.bounce(&"end_right", &"block", 0.06, 0.2)
		_deflected_last = _index == _swings.size() - 1


func state_is_active() -> bool:
	return machine.current == self


func _set_phase(phase: Phase) -> void:
	var swing: Dictionary = _swings[_index]
	_phase = phase
	_timer = 0.0
	match phase:
		Phase.WINDUP:
			_deflected_last = false
			enemy.weapon.go(swing["from"], swing["windup"] * 0.8)
			enemy.weapon.glint()
		Phase.ACTIVE:
			enemy.weapon.go(swing["to"], swing["active"], Tween.EASE_IN_OUT)
			enemy.hitbox.activate(HitData.create(enemy, DAMAGE, POSTURE_DAMAGE, DEFLECT_POSTURE))
		Phase.AFTER:
			enemy.hitbox.deactivate()
