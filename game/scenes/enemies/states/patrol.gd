extends EnemyState
## Sin saber que estás ahí: hace su ronda caminando entre sus puntos y se para un momento en cada uno
## (o vigila quieto en su puesto). Guardia baja y paso tranquilo. Lo que ve y oye lo decide Enemy
## (_update_awareness): si sospecha pasa a Suspicious, y si te descubre, a Chase.

## Segundos que se queda en cada punto de la ronda.
const WAIT_AT_POINT: float = 2.5
## A esta distancia del punto, ya ha llegado.
const ARRIVE: float = 0.35

var _index: int
var _wait: float


func enter(_msg: Dictionary) -> void:
	enemy.body.set_blocking(false)
	enemy.body.stop_action(0.3)
	_wait = 0.0
	# Sigue por el punto de la ronda más cercano (al volver de buscarte, no desde el principio).
	var route: PackedVector3Array = enemy.patrol_route()
	_index = 0
	var best: float = INF
	for i in route.size():
		var d: float = enemy.global_position.distance_to(route[i])
		if d < best:
			best = d
			_index = i


func physics_update(delta: float) -> void:
	var route: PackedVector3Array = enemy.patrol_route()
	var to: Vector3 = route[_index] - enemy.global_position
	to.y = 0.0
	if to.length() > ARRIVE:
		var dir: Vector3 = to.normalized()
		enemy.face_direction(dir, delta, 0.6)
		# Camina hacia donde mira: si el punto queda a su espalda, primero se gira.
		var ahead: float = clampf(enemy.get_facing().dot(dir), 0.0, 1.0)
		enemy.move_horizontal(dir, enemy.patrol_speed * ahead, delta, 6.0)
		return
	enemy.move_horizontal(Vector3.ZERO, 0.0, delta, 6.0)
	if route.size() == 1:
		enemy.face_direction(enemy.post_facing(), delta, 0.4)
		return
	_wait += delta
	if _wait >= WAIT_AT_POINT:
		_wait = 0.0
		_index = (_index + 1) % route.size()
