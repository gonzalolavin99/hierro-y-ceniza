class_name PlayerState
extends State
## Base de los estados del jugador: da acceso tipado a `player`.

var player: Player:
	get:
		return actor as Player
