extends Node
## Prueba automática: Kael no atraviesa los muros del camino del Paso (aviso del jugador, 2026-11-11: al inicio
## acabó dentro de la pared de roca). Lo empuja contra la pared oeste y la este en varios puntos, andando,
## corriendo, rodando, saltando y atacando, y comprueba que su centro nunca entra en la roca.
## Ejecutar: Godot --headless --path game res://tests/walls_test.tscn

## La pared oeste del camino va de x = −6 a −5 y la este de 5 a 6; el cuerpo de Kael mide ~0,35 m de radio.
const WEST_FACE: float = -5.0
const EAST_FACE: float = 5.0
const MARGIN: float = 0.2

var _player: Player
var _failures: int = 0


func _ready() -> void:
	add_child(load("res://scenes/levels/iron_pass.tscn").instantiate())
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).aggro_range = 0.0
	await _wait(1.0)
	_player = get_tree().get_first_node_in_group("player") as Player
	for z: float in [138.0, 127.0, 126.4, 120.0, 114.0]:
		for side: float in [-1.0, 1.0]:
			for how: String in ["andar", "correr", "rodar", "saltar", "atacar"]:
				await _push(z, side, how)
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _push(z: float, side: float, how: String) -> void:
	for action in ["move_left", "move_right", "dodge", "jump", "attack"]:
		Input.action_release(action)
	_player.state_machine.transition_to(&"Ground")
	_player.set_spawn(Vector3(side * 2.5, 0.0, z), 180.0)
	_player.respawn()
	await _wait(0.3)
	var move: String = "move_left" if side < 0.0 else "move_right"
	Input.action_press(move)
	var worst: float = 0.0
	var t: float = 0.0
	while t < 2.0:
		match how:
			"correr":
				Input.action_press("dodge")
			"rodar", "saltar", "atacar":
				var action: String = {"rodar": "dodge", "saltar": "jump", "atacar": "attack"}[how]
				if fmod(t, 0.5) < 0.05:
					Input.action_press(action)
				else:
					Input.action_release(action)
		await get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		var x: float = _player.global_position.x
		worst = maxf(worst, (WEST_FACE + MARGIN) - x if side < 0.0 else x - (EAST_FACE - MARGIN))
	for action in [move, "dodge", "jump", "attack"]:
		Input.action_release(action)
	if worst > 0.0:
		_check("z %.1f, pared %s, %s: entra %.2f m en la roca" % [z, "oeste" if side < 0.0 else "este", how, worst], false)
	else:
		_check("z %.1f, pared %s, %s: no la atraviesa" % [z, "oeste" if side < 0.0 else "este", how], true)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
