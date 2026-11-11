extends Node
## Registra los controles del juego al iniciar.
## Mando Xbox como control principal; teclado solo como respaldo para pruebas.

const DEADZONE: float = 0.2
## Cuánto hay que mover un stick para que cuente como "está usando el mando" (evita la deriva del stick).
const PAD_SWITCH: float = 0.5
## Cómo se llama cada control en pantalla: [mando, teclado].
const LABELS: Dictionary = {
	&"move": ["Stick izq.", "WASD"], &"camera": ["Stick der.", "Flechas"],
	&"jump": ["A", "Espacio"], &"dodge": ["B", "Shift"], &"heal": ["X", "R"], &"interact": ["Y", "E"],
	&"kick": ["Y", "F"], &"attack": ["RB", "J"], &"block": ["LB", "K"], &"lock_on": ["R3", "Tab"],
	&"crouch": ["L3", "C"], &"heavy_attack": ["RT", "L"], &"item": ["LT", "Q"], &"art": ["LB+RB", "K+J"],
	&"frank_throw": ["Cruceta ↓", "G"], &"pause": ["Start", "Esc"],
}

## Cambia cuando el jugador pasa del mando al teclado o al revés (para los carteles y avisos).
signal device_changed(pad: bool)

## ¿Está usando el mando? (Si no, el teclado.) Al empezar: sí, si hay un mando conectado.
var using_pad: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Que note el cambio de mando a teclado también en pausa.
	using_pad = not Input.get_connected_joypads().is_empty()
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
	_button("kick", JOY_BUTTON_Y, KEY_F)                  # Patada: rompe la guardia (Y en combate)
	_button("attack", JOY_BUTTON_RIGHT_SHOULDER, KEY_J)
	_button("block", JOY_BUTTON_LEFT_SHOULDER, KEY_K)   # Mantener = bloquear · Tocar a tiempo = desviar
	_button("lock_on", JOY_BUTTON_RIGHT_STICK, KEY_TAB) # Sin objetivo: recentra la cámara
	_button("crouch", JOY_BUTTON_LEFT_STICK, KEY_C)
	_button("pause", JOY_BUTTON_START, KEY_ESCAPE)
	# Menús: Godot no trae A / B del mando en "aceptar" / "volver"; se añaden aquí.
	_pad("ui_accept", JOY_BUTTON_A)
	_pad("ui_cancel", JOY_BUTTON_B)
	_axis("heavy_attack", JOY_AXIS_TRIGGER_RIGHT, 1.0, KEY_L)  # Golpe pesado
	_axis("item", JOY_AXIS_TRIGGER_LEFT, 1.0, KEY_Q)           # Usar el arma secundaria
	_button("item_next", JOY_BUTTON_DPAD_RIGHT, KEY_2)        # Cambiar de arma secundaria
	_button("item_prev", JOY_BUTTON_DPAD_LEFT, KEY_1)
	_button("art_next", JOY_BUTTON_DPAD_UP, KEY_3)            # Cambiar de técnica (LB + RB)
	_button("frank_throw", JOY_BUTTON_DPAD_DOWN, KEY_G)       # Frank lanza una fruta (distrae)


func _input(event: InputEvent) -> void:
	var pad: bool = using_pad
	if event is InputEventJoypadButton and event.pressed:
		pad = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > PAD_SWITCH:
		pad = true
	elif (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		pad = false
	if pad != using_pad:
		using_pad = pad
		device_changed.emit(pad)


## Nombre en pantalla de un control (del mando o del teclado, según lo que use el jugador).
func label(action: StringName) -> String:
	var names: Array = LABELS.get(action, ["?", "?"])
	return names[0] if using_pad else names[1]


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


func _pad(action: StringName, button: JoyButton) -> void:
	_ensure(action)
	var pad := InputEventJoypadButton.new()
	pad.button_index = button
	InputMap.action_add_event(action, pad)


func _add_key(action: StringName, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)
