class_name StateMachine
extends Node
## Máquina de estados: el personaje está en UN estado a la vez (sus hijos son los estados).

signal state_changed(state_name: StringName)

@export var initial_state: State

var current: State
var _states: Dictionary[StringName, State] = {}


func setup(actor: Node) -> void:
	for child in get_children():
		var state := child as State
		if state:
			state.machine = self
			state.actor = actor
			_states[state.name] = state
	current = initial_state if initial_state else get_child(0) as State
	current.enter({})


func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	var next: State = _states.get(state_name)
	assert(next != null, "Estado inexistente: %s" % state_name)
	current.exit()
	current = next
	current.enter(msg)
	state_changed.emit(state_name)


func physics_update(delta: float) -> void:
	current.physics_update(delta)
