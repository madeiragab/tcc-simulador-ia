extends Node

var width = 40
var height = 40

var grid = []

func _ready():
	create_grid()
	print("Grid criado: ", width, "x", height)

func create_grid():
	for x in range(width):
		var row = []
		for y in range(height):
			row.append({
				"type": "empty"
			})
		grid.append(row)
