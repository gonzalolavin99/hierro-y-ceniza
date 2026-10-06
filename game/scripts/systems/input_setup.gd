extends Node
## Registra los controles del juego al iniciar.
## Mando Xbox como control principal; teclado solo como respaldo para pruebas.

const DEADZONE: float = 0.2


func _ready() -> void:
	# Movimiento (stick izquierdo)
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0, KEY_A)
	_axis("move_right", JOY_AXIS_LEFT_X, 1.0, KEY_D)
	_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0, KEY_W)
	_axis("move_back", JOY_AXIS_LEFT_Y, 1.0, KEY_S)
	# Cámara (stick derecho)
	_axis("cam_left", JOY_AXIS_RIGHT_X, -1.0, KEY_LEFT)
	_axis("cam_right", JOY_AXIS_RIGHT_X, 1.0, KEY_RIGHT)
	_axis("cam_up", JOY_AXIS_RIGHT_Y, -1.0, KEY_UP)
	_axis("cam_down", JOY_AXIS_RIGHT_Y, 1.0, KEY_DOWN)
	# Acciones
	_button("jump", JOY_BUTTON_A, KEY_SPACE)
	_button("dodge", JOY_BUTTON_B, KEY_SHIFT)        # Tocar = paso rápido · Mantener = correr
	_button("heal", JOY_BUTTON_X, KEY_R)
	_button("interact", JOY_BUTTON_Y, KEY_E)
	_button("attack", JOY_BUTTON_RIGHT_SHOULDER, KEY_J)
	_button("block", JOY_BUTTON_LEFT_SHOULDER, KEY_K)   # Mantener = bloquear · Tocar a tiempo = desviar
	_button("lock_on", JOY_BUTTON_RIGHT_STICK, KEY_TAB) # Sin objetivo: recentra la cámara
	_button("crouch", JOY_BUTTON_LEFT_STICK, KEY_C)
	_button("pause", JOY_BUTTON_START, KEY_ESCAPE)
	_axis("item", JOY_AXIS_TRIGGER_RIGHT, 1.0, KEY_Q)


func _ensure(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)


func _axis(action: StringName, axis: JoyAxis, value: float, key: Key) -> void:
	_ensure(action)
	var motion := InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = value
	InputMap.action_add_event(action, motion)
	_add_key(action, key)


func _button(action: StringName, button: JoyButton, key: Key) -> void:
	_ensure(action)
	var pad := InputEventJoypadButton.new()
	pad.button_index = button
	InputMap.action_add_event(action, pad)
	_add_key(action, key)


func _add_key(action: StringName, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)
