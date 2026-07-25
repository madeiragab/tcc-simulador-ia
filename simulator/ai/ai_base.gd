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

# ---------- Aprendizado entre partidas ----------
# No modo lote a MESMA instância de IA joga todas as partidas: após cada
# uma, learn() recebe a pontuação (+3/-1/-3). Modelos estáticos ignoram;
# quem aprende registra a evolução para o aprendizado.csv da run.
# Ao fim do lote as instâncias são descartadas (o aprendizado reseta).

var player_id = -1  # preenchido pelo batch_runner

func learn(_points):
	pass

# Linhas para o aprendizado.csv: [{janela, pesos, pontos_media, decisao}].
func learning_log():
	return []

# Estado de percepção zerado entre partidas (memória e exploração são
# da partida; só o que learn() consolidou atravessa o lote).
func reset_match_state():
	last_known = {}
	patrol_target = null
	patrol_rng = null

# ---------- Percepção (campo de visão) ----------
# Um agente NÃO é onisciente: só conhece inimigos dentro do alcance de
# visão e com linha de visão livre — paredes bloqueiam a visão,
# coberturas não. Sem ninguém à vista, a IA caça a última posição onde
# viu um inimigo; sem memória alguma, explora o mapa (determinístico,
# semeado pela seed da partida).

var last_known = {}       # inimigo -> última posição vista (Vector2i)
var patrol_target = null  # destino de exploração
var patrol_rng = null

# Inimigos vivos que o agente percebe: dentro do cone de visão
# direcional (agent.can_see) OU revelados por terem atirado nele.
func get_visible_enemies(agent, sim):
	var visible = []
	for enemy in sim.get_enemies(agent):
		if agent.can_see(enemy.x, enemy.y):
			visible.append(enemy)
			last_known[enemy] = Vector2i(enemy.x, enemy.y)
	# Levar tiro revela o atirador (o agente "ouve" o disparo), mesmo
	# fora do cone — senão morreria sem reagir a ataques pelas costas.
	if agent.last_hit_from != null:
		for enemy in sim.get_enemies(agent):
			if Vector2i(enemy.x, enemy.y) == agent.last_hit_from and not visible.has(enemy):
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

# Inimigos que o agente pode atacar agora: percebidos, em alcance, em
# linha reta e com linha de visão livre.
func get_attackable_enemies(agent, sim):
	return filter_attackable(agent, sim, get_visible_enemies(agent, sim))

# Dentre uma lista já percebida, os que têm linha de tiro reta e livre.
func filter_attackable(agent, sim, visible):
	var targets = []
	for enemy in visible:
		var dx = enemy.x - agent.x
		var dy = enemy.y - agent.y
		if max(abs(dx), abs(dy)) > agent.vision_range:
			continue
		if not agent.is_straight_line(dx, dy):
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

# Passo guloso na direção do alvo: caminha até max_steps células
# verificando apenas as do caminho (~3-6 verificações), em vez de
# expandir a vizinhança inteira por busca em largura (~25 nós).
# Retorna o caminho percorrido (lista de células) ou vazio.
func cheap_path_towards(agent, sim, target, max_steps = 3):
	var pos = Vector2i(agent.x, agent.y)
	var path = []
	for step in range(max_steps):
		var dx = signi(target.x - pos.x)
		var dy = signi(target.y - pos.y)
		if dx == 0 and dy == 0:
			break

		# Tenta primeiro o eixo com maior distância a cobrir.
		var options = []
		if absi(target.x - pos.x) >= absi(target.y - pos.y):
			if dx != 0:
				options.append(Vector2i(pos.x + dx, pos.y))
			if dy != 0:
				options.append(Vector2i(pos.x, pos.y + dy))
		else:
			if dy != 0:
				options.append(Vector2i(pos.x, pos.y + dy))
			if dx != 0:
				options.append(Vector2i(pos.x + dx, pos.y))

		var moved = false
		for opt in options:
			if sim.grid.check_walkable(opt.x, opt.y):
				pos = opt
				path.append(pos)
				moved = true
				break
		if not moved:
			break
	return path

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
