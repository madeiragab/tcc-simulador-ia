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
		
func is_valid_position(x, y):
	if x < 0 or y < 0:
		return false
	if x >= width or y >= height:
		return false

	var cell = grid[x][y]

	if cell["type"] == "wall":
		return false
	return true
