extends EnemyState
## Sospecha ("?"): vio o oyó algo. Se para, se gira hacia allí, va a mirar con cautela y busca a su
## alrededor. Si no encuentra nada, vuelve a su ronda. Si te descubre, Enemy.alert() lo pasa a Chase.

enum Phase { TURN, GO, LOOK }

const TURN_TIME: float = 0.7
## Tiempo máximo yendo hacia el punto (por si no puede llegar).
const GO_TIME: float = 6.0
const LOOK_TIME: float = 3.0
const ARRIVE: float = 1.0

var _phase: Phase
var _timer: float
var _point: Vector3
var _look_side: float


func enter(msg: Dictionary) -> void:
	_point = msg.get("at", enemy.global_position)
	_set_phase(Phase.TURN)
	_look_side = 1.0 if randf() < 0.5 else -1.0
	enemy.body.set_blocking(true)  # Con cautela: espada lista.
	enemy.body.stop_action(0.3)


func physics_update(delta: float) -> void:
	_timer += delta
	# Si vuelve a verte u oírte, mira hacia el nuevo sitio.
	if enemy.last_known.distance_to(_point) > 1.5 and _phase != Phase.TURN:
		_point = enemy.last_known
		_set_phase(Phase.TURN)
	var to: Vector3 = _point - enemy.global_position
	to.y = 0.0
	match _phase:
		Phase.TURN:
			enemy.move_horizontal(Vector3.ZERO, 0.0, delta, 8.0)
			enemy.face_direction(to, delta, 0.9)
			if _timer >= TURN_TIME:
				_set_phase(Phase.GO)
		Phase.GO:
			enemy.face_direction(to, delta, 0.6)
			if to.length() <= ARRIVE or _timer >= GO_TIME:
				_set_phase(Phase.LOOK)
			else:
				enemy.move_horizontal(to.normalized(), enemy.patrol_speed * 0.9, delta, 6.0)
		Phase.LOOK:
			# Mira a un lado y a otro buscando.
			enemy.move_horizontal(Vector3.ZERO, 0.0, delta, 8.0)
			if _timer > LOOK_TIME * 0.5 and _look_side > 0.0:
				_look_side = -1.0
			var look: Vector3 = enemy.get_facing().rotated(Vector3.UP, _look_side * 0.6)
			enemy.face_direction(look, delta, 0.15)
			if _timer >= LOOK_TIME:
				_give_up()


func _give_up() -> void:
	enemy.awareness = minf(enemy.awareness, enemy.SUSPICIOUS_AT * 0.6)
	machine.transition_to(&"Patrol")


func _set_phase(phase: Phase) -> void:
	_phase = phase
	_timer = 0.0
