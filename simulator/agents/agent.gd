extends Node

var x = 0
var y = 0
var hp = 100

var grid = null

func _ready():
	print("Agente criado em: ", x, ", ", y)

func move(dx, dy):
	var new_x = x + dx
	var new_y = y + dy

	if grid != null and grid.is_valid_position(new_x, new_y):
		x = new_x
		y = new_y
		print("Agente moveu para: ", x, ", ", y)
	else:
		print("Movimento inválido")
