extends Node

func _ready():
	print("Simulador iniciado")

	var grid = preload("res://map/grid.gd").new()
	add_child(grid)

	var agent = preload("res://agents/agent.gd").new()
	agent.x = 5
	agent.y = 5
	agent.grid = grid
	add_child(agent)

	# TESTE DE MOVIMENTO
	agent.move(1, 0)
	agent.move(0, 1)
	agent.move(-1, 0)
