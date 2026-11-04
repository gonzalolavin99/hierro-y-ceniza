extends Node
## Prueba automática del sigilo: patrulla, vista (cono, distancia, obstáculos, agachado), oído (correr
## hace ruido, agachado no), sospecha, alerta que se contagia, golpe mortal por la espalda y volver a
## patrullar si te pierde. El soldado de práctica de siempre sigue empezando alerta.
## Ejecutar: Godot --headless --path game res://tests/stealth_test.tscn

const SOLDIER: PackedScene = preload("res://scenes/enemies/training_soldier.tscn")

var _player: Player
var _level: Node
var _failures: int = 0


func _ready() -> void:
	_level = load("res://scenes/levels/test_level.tscn").instantiate()
	add_child(_level)
	_player = get_tree().get_first_node_in_group("player") as Player
	# Los soldados del escenario se apartan: aquí actúan solo los de la prueba.
	var practice: Enemy = null
	for node in get_tree().get_nodes_in_group("enemies"):
		var other := node as Enemy
		if practice == null:
			practice = other
		other.aggro_range = 0.0
		other.global_position += Vector3(0.0, 0.0, -90.0)
		other.reset_physics_interpolation()
	_check("El soldado de práctica empieza alerta (como siempre)", practice.alerted)
	await _run()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _run() -> void:
	# 0. Agacharse: el botón lo activa y desactiva; agachado se va despacio y casi sin ruido.
	_place_player(Vector3(0.0, 0.0, 20.0))
	await _wait(0.2)
	await _tap("crouch")
	await get_tree().physics_frame
	_check("El botón de agacharse agacha", _player.crouching and _player.body.is_crouching())
	Input.action_press("move_right")
	await _wait(1.0)
	var speed: float = Vector2(_player.velocity.x, _player.velocity.z).length()
	_check("Agachado va despacio (%.1f m/s) y casi sin ruido (%.1f m)" % [speed, _player.noise_radius()],
		speed <= _player.crouch_speed + 0.05 and _player.noise_radius() <= 1.0)
	Input.action_release("move_right")
	await _tap("crouch")
	await get_tree().physics_frame
	_check("Pulsar otra vez lo levanta", not _player.crouching)

	# 1. Patrulla entre puntos sin enterarse de un jugador lejano a su espalda.
	var guard := _spawn_guard(Vector3(0.0, 0.0, -10.0), [Vector3(0.0, 0.0, -10.0), Vector3(0.0, 0.0, -16.0)])
	_place_player(Vector3(0.0, 0.0, 6.0))
	await _wait(0.5)
	_check("Empieza sin enterarse (patrulla)", not guard.alerted and guard.state_name() == &"Patrol")
	var start: Vector3 = guard.global_position
	await _wait(5.0)
	_check("Patrulla: camina por su ruta (%.1f m)" % guard.global_position.distance_to(start), guard.global_position.distance_to(start) > 2.0)
	_check("No ve a quien está lejos a su espalda", not guard.alerted)
	guard.queue_free()
	await _wait(0.1)

	# 2. Vista: de pie y delante, a 7 m, te descubre en pocos segundos (y sube la sospecha antes).
	guard = _spawn_guard(Vector3(0.0, 0.0, -7.0), [])
	_face(guard, Vector3.ZERO)
	_place_player(Vector3.ZERO)
	await _wait(0.6)
	_check("Antes de alertarse, sospecha (%.2f)" % guard.awareness, guard.awareness > 0.1)
	await _wait(2.5)
	_check("De pie y delante, te descubre", guard.alerted)
	guard.queue_free()
	await _wait(0.1)

	# 3. Agachado detrás de un muro bajo: no te ve aunque estés delante.
	guard = _spawn_guard(Vector3(0.0, 0.0, -7.0), [])
	_face(guard, Vector3.ZERO)
	var wall := CSGBox3D.new()
	wall.size = Vector3(3.0, 1.1, 0.4)
	wall.use_collision = true
	wall.position = Vector3(0.0, 0.55, -1.2)
	_level.add_child(wall)
	_place_player(Vector3.ZERO)
	_player.crouching = true
	await _wait(3.0)
	_check("Agachado tras un muro bajo, no te ve (%.2f)" % guard.awareness, not guard.alerted and guard.awareness < 0.35)
	_player.crouching = false
	await _wait(2.0)
	_check("De pie, el muro bajo ya no te tapa", guard.alerted)
	wall.queue_free()
	guard.queue_free()
	await _wait(0.1)

	# 4. Oído: agachado a su espalda no te oye; corriendo a su espalda, sí, y se gira a mirar.
	guard = _spawn_guard(Vector3(0.0, 0.0, -3.0), [])
	_face(guard, Vector3(0.0, 0.0, -10.0))
	_place_player(Vector3(0.0, 0.0, 0.0))
	_player.crouching = true
	await _walk(Vector3.RIGHT, 1.5)
	_check("Agachado a su espalda, no te oye (%.2f)" % guard.awareness, guard.awareness < 0.1)
	_player.crouching = false
	var seen: Array[StringName] = []
	guard.state_machine.state_changed.connect(func(s: StringName) -> void: seen.append(s))
	await _walk(Vector3.LEFT, 1.2)
	# Al oírte se gira a mirar; como sigues de pie y cerca, después te ve (eso ya es correcto).
	_check("Corriendo a su espalda, te oye: primero sospecha %s" % str(seen),
		not seen.is_empty() and seen[0] == &"Suspicious")
	await _wait(0.8)
	var to_player: Vector3 = (_player.global_position - guard.global_position)
	to_player.y = 0.0
	_check("Se gira hacia el ruido", guard.get_facing().dot(to_player.normalized()) > 0.5)
	guard.queue_free()
	await _wait(0.1)

	# 5. Golpe mortal por sorpresa: agachado por la espalda, un ataque lo mata de una vez.
	guard = _spawn_guard(Vector3(0.0, 0.0, -2.0), [])
	_face(guard, Vector3(0.0, 0.0, -10.0))
	_place_player(Vector3.ZERO)
	_player.crouching = true
	await _wait(0.4)
	_check("Por la espalda y sin que te vea, se puede rematar", guard.can_be_stealth_killed(_player))
	await _tap("attack")
	await _wait(1.0)
	_check("Golpe mortal por sorpresa: muere de una vez (%s)" % guard.state_name(), guard.state_name() == &"Dead")
	_check("…y el jugador no recibe daño", _player.health.current == _player.health.max_health)
	guard.queue_free()
	await _wait(0.1)

	# 6. De frente o ya alerta, no hay golpe mortal por sorpresa.
	guard = _spawn_guard(Vector3(0.0, 0.0, -2.0), [])
	_face(guard, Vector3.ZERO)
	_place_player(Vector3.ZERO)
	await _wait(0.1)
	_check("De frente no se puede rematar por sorpresa", not guard.can_be_stealth_killed(_player))
	guard.queue_free()
	await _wait(0.1)

	# 7. La alarma se contagia: si uno te descubre, avisa a los compañeros cercanos.
	var a := _spawn_guard(Vector3(0.0, 0.0, -6.0), [])
	var b := _spawn_guard(Vector3(6.0, 0.0, -9.0), [])
	_face(a, Vector3.ZERO)
	_face(b, Vector3(20.0, 0.0, -9.0))
	_place_player(Vector3.ZERO)
	await _wait(0.1)
	a.alert()
	await _wait(0.8)
	_check("La alarma se contagia al compañero cercano", b.alerted)

	# 8. Si te pierde, busca un rato y vuelve a patrullar.
	_place_player(Vector3(0.0, 0.0, 60.0))
	await _wait(14.0)
	_check("Te pierde de vista y vuelve a patrullar (%s)" % a.state_name(), not a.alerted and a.state_name() == &"Patrol")
	a.queue_free()
	b.queue_free()


func _spawn_guard(at: Vector3, route: Array) -> Enemy:
	var g := SOLDIER.instantiate() as Enemy
	g.position = at
	g.starts_unaware = true
	g.respawn_delay = 0.0
	g.patrol_points = PackedVector3Array(route)
	_level.add_child(g)
	g.mind.predictable = true
	return g


func _face(enemy: Enemy, point: Vector3) -> void:
	var dir: Vector3 = point - enemy.global_position
	dir.y = 0.0
	enemy.model.rotation.y = atan2(-dir.x, -dir.z)
	enemy.post_direction = dir.normalized()


func _place_player(at: Vector3) -> void:
	_player.state_machine.transition_to(&"Ground")
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	_player.health.heal(_player.health.max_health)
	_player.crouching = false
	Squad.reset()


## Camina (o corre, si no va agachado) en una dirección durante unos segundos.
func _walk(direction: Vector3, seconds: float) -> void:
	var action: String = "move_right" if direction.x > 0.0 else "move_left"
	Input.action_press(action)
	await _wait(seconds)
	Input.action_release(action)
	await get_tree().physics_frame


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
