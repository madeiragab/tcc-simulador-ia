extends Node

var agents = []
var current_index = 0
var turn_count = 0

# start_index define quem inicia a partida (rotação de iniciativa entre
# simulações — docs/turnos.md).
func setup(agents_array, start_index = 0):
	agents = agents_array
	current_index = start_index
	turn_count = 0

func get_current_agent():
	if agents.is_empty():
		return null
	return agents[current_index]

# Avança para o próximo agente vivo. Ao completar uma volta pela lista de
# agentes, incrementa a contagem de turnos.
func advance():
	if agents.is_empty():
		return

	var start_index = current_index
	var wrapped = false

	while true:
		current_index += 1
		if current_index >= agents.size():
			current_index = 0
			if not wrapped:
				turn_count += 1
				wrapped = true

		if agents[current_index].is_alive:
			break
		if current_index == start_index:
			break

const TURN_LIMIT = 100

func is_turn_limit_reached():
	return turn_count >= TURN_LIMIT
