extends RefCounted

# Contrato base de IA (diagrams/ia_decisao.png e docs/arquitetura.md):
# a IA recebe o estado atual e RETORNA uma ação — quem aplica é a Simulation.
#
# Uma ação é um Dictionary com dois campos (qualquer um pode ser null):
#   "move_to":       Vector2i com o destino do movimento (até 3 células)
#   "attack_target": referência ao agente inimigo a atacar
#
# Para criar uma IA nova: crie um script em res://ai/ que estenda este
# arquivo e implemente decide(). Depois aponte o jogador para ela na
# constante PLAYER_AI_SCRIPTS em res://core/simulation.gd.

func decide(_agent, _sim):
	return {"move_to": null, "attack_target": null}

# ---------- Helpers compartilhados entre as IAs ----------

# IAs que geram e pontuam ações (heurística, híbrida) devem chamar isto
# uma vez por ação avaliada, para o custo entrar no medidor do agente.
func note_action_evaluated(sim):
	if sim.grid.cost_meter != null:
		sim.grid.cost_meter.actions_evaluated += 1

# Inimigos vivos que o agente consegue atacar agora (alcance + LOS).
func get_attackable_enemies(agent, sim):
	var targets = []
	for enemy in sim.get_enemies(agent):
		var dist = max(abs(enemy.x - agent.x), abs(enemy.y - agent.y))
		if dist > agent.vision_range:
			continue
		if sim.grid.has_line_of_sight(agent.x, agent.y, enemy.x, enemy.y):
			targets.append(enemy)
	return targets

# O mais próximo (distância Manhattan) dentre os candidatos.
func closest_of(agent, candidates):
	var best = null
	var best_dist = INF
	for candidate in candidates:
		var dist = abs(candidate.x - agent.x) + abs(candidate.y - agent.y)
		if dist < best_dist:
			best_dist = dist
			best = candidate
	return best

func closest_enemy(agent, sim):
	return closest_of(agent, sim.get_enemies(agent))

# Melhor célula alcançável neste turno na direção do alvo (ou null).
func step_towards(agent, sim, target):
	var reachable = sim.grid.get_reachable_cells(agent.x, agent.y, 3)
	var best = null
	var best_dist = INF
	for cell in reachable:
		var dist = abs(cell.x - target.x) + abs(cell.y - target.y)
		if dist < best_dist:
			best_dist = dist
			best = cell
	return best
