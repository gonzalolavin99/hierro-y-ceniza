class_name EnemyState
extends State
## Base de los estados de enemigo: da acceso tipado a `enemy`.

var enemy: Enemy:
	get:
		return actor as Enemy
