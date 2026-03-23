extends Node

func _ready():
	print("Simulador iniciado")

	var grid = preload("res://map/grid.gd").new()
	add_child(grid)

	var agent = preload("res://agents/agent.gd").new()
	agent.x = 5
	agent.y = 5
	add_child(agent)
