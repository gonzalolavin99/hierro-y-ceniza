class_name BramYard
extends Node3D
## El patio del lazareto con Bram, el Carcelero (Hito 9, paso 5.1): de pie, quieto y sin ataques.
## Aún no es un duelo: sin música, sin rastrillo, sin marca en la historia ni recompensa (llegan en 5.2).
## El origen del nodo es donde está Bram, y su orientación es hacia donde mira.

const BRAM: PackedScene = preload("res://scenes/enemies/bram.tscn")
## La zona delante del lazareto donde Kael ve la barra del jefe.
const TRIGGER_SIZE: Vector3 = Vector3(20.0, 4.0, 16.0)
const TRIGGER_OFFSET: Vector3 = Vector3(0.0, 2.0, 3.0)
## Estados en los que se le deja: quieto, de rodillas por la postura rota, o muerto.
const CALM_STATES: Array[StringName] = [&"Scripted", &"Broken", &"Dead"]

var bram: Enemy
var _bar: BossBar


func _ready() -> void:
	bram = BRAM.instantiate() as Enemy
	add_child(bram)
	bram.state_machine.transition_to(&"Scripted")
	_bar = BossBar.new()
	add_child(_bar)
	var trigger := Area3D.new()
	trigger.name = "BramTrigger"
	trigger.collision_layer = 0
	trigger.collision_mask = 2  # Jugador.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = TRIGGER_SIZE
	shape.shape = box
	shape.position = TRIGGER_OFFSET
	trigger.add_child(shape)
	add_child(trigger)
	trigger.body_entered.connect(_on_entered)
	trigger.body_exited.connect(_on_exited)
	bram.died.connect(func() -> void: _bar.hide_boss(2.5))


func _physics_process(_delta: float) -> void:
	# Tras un golpe, una bomba de humo, la pólvora o el reinicio al morir Kael, vuelve a quedarse quieto.
	if is_instance_valid(bram) and not bram.is_dead() and not CALM_STATES.has(bram.state_name()):
		bram.state_machine.transition_to(&"Scripted")


func _on_entered(body: Node3D) -> void:
	if body is Player and is_instance_valid(bram) and not bram.is_dead():
		_bar.show_boss(bram)


func _on_exited(body: Node3D) -> void:
	if body is Player:
		_bar.hide_boss()
