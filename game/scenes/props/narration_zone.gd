class_name NarrationZone
extends Area3D
## Zona invisible: cuando Kael entra, el anciano narra (una sola vez por partida) y, si `act` > 0, el
## relato pasa a ese acto. Se coloca en el nivel con su tamaño; la forma se crea sola.

## Evento del narrador en VoiceLines (por ejemplo &"story_pass_village").
@export var event: StringName = &""
@export var size: Vector3 = Vector3(8.0, 4.0, 8.0)
## Si es mayor que 0, al entrar el relato pasa a este acto (1–4).
@export var act: int = 0


func _ready() -> void:
	add_to_group("narration_zones")
	collision_layer = 0
	collision_mask = 2  # Capa del jugador.
	monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y * 0.5
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	if act > 0:
		Story.act = act
	if event != &"":
		Story.narrate(event)
