extends Area3D
## Placa de prueba: mientras el jugador está encima, su postura sube.
## Sirve para ver la barra de postura y el aturdimiento antes de tener enemigos.

@export var posture_per_second: float = 35.0

var _player: Player


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if _player:
		_player.posture.add(posture_per_second * delta)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_player = body


func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_player = null
