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

# ---------- Percepção (campo de visão) ----------
# Um agente NÃO é onisciente: só conhece inimigos dentro do alcance de
# visão e com linha de visão livre — paredes bloqueiam a visão,
# coberturas não. Sem ninguém à vista, a IA caça a última posição onde
# viu um inimigo; sem memória alguma, explora o mapa (determinístico,
# semeado pela seed da partida).

var last_known = {}       # inimigo -> última posição vista (Vector2i)
var patrol_target = null  # destino de exploração
var patrol_rng = null

# Inimigos vivos dentro do campo de visão. Como o alcance de ataque é
# igual ao de visão, todo inimigo visível é também atacável.
func get_visible_enemies(agent, sim):
	var visible = []
	for enemy in sim.get_enemies(agent):
		var dist = max(abs(enemy.x - agent.x), abs(enemy.y - agent.y))
		if dist > agent.vision_range:
			continue
		if sim.grid.has_line_of_sight(agent.x, agent.y, enemy.x, enemy.y):
			visible.append(enemy)
			last_known[enemy] = Vector2i(enemy.x, enemy.y)
	return visible

# Posição a perseguir quando nada está visível: a memória mais próxima,
# ou um destino de exploração. Retorna null se não houver o que fazer.
func pursuit_position(agent, sim):
	var here = Vector2i(agent.x, agent.y)

	# Chegou onde viu alguém e não há mais nada ali: esquece.
	for enemy in last_known.keys().duplicate():
		if last_known[enemy] == here:
			last_known.erase(enemy)

	if not last_known.is_empty():
		var best = null
		var best_dist = INF
		for enemy in last_known:
			var pos = last_known[enemy]
			var dist = abs(pos.x - here.x) + abs(pos.y - here.y)
			if dist < best_dist:
				best_dist = dist
				best = pos
		return best

	# Exploração: sorteia destinos válidos com RNG atrelado à seed.
	if patrol_rng == null:
		patrol_rng = RandomNumberGenerator.new()
		patrol_rng.seed = sim.map_seed * 31 + agent.team_id
	if patrol_target == null or patrol_target == here:
		for i in range(50):
			var cand = Vector2i(
				patrol_rng.randi_range(0, sim.grid.width - 1),
				patrol_rng.randi_range(0, sim.grid.height - 1)
			)
			if sim.grid.is_valid_position(cand.x, cand.y):
				patrol_target = cand
				break
	return patrol_target

# ---------- Helpers compartilhados entre as IAs ----------

# IAs que geram e pontuam ações (heurística, híbrida) devem chamar isto
# uma vez por ação avaliada, para o custo entrar no medidor do agente.
func note_action_evaluated(sim):
	if sim.grid.cost_meter != null:
		sim.grid.cost_meter.actions_evaluated += 1

# Mantido como sinônimo de get_visible_enemies (ataque exige visão).
func get_attackable_enemies(agent, sim):
	return get_visible_enemies(agent, sim)

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
