class_name State
extends Node
## Estado base de una máquina de estados. Los estados concretos sobrescriben lo que necesiten.

var machine: StateMachine
var actor: Node


func enter(_msg: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
