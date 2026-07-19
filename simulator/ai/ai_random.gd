extends "res://ai/ai_base.gd"

# IA Aleatória (docs/baseline.md): escolhe uma ação válida ao acaso.
# Usa um RNG próprio semeado pela seed do mapa + id do jogador, mantendo
# cada partida reprodutível (a aleatoriedade da decisão fica atrelada à
# seed, nunca ao relógio).

var rng = null

func decide(agent, sim):
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = sim.map_seed * 10 + agent.team_id

	var options = []
	for target in get_attackable_enemies(agent, sim):
		options.append({"move_to": null, "attack_target": target})
	for cell in sim.grid.get_reachable_cells(agent.x, agent.y, 3):
		options.append({"move_to": cell, "attack_target": null})
	options.append({"move_to": null, "attack_target": null})  # esperar

	return options[rng.randi_range(0, options.size() - 1)]
