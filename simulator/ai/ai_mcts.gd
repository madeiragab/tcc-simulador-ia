extends "res://ai/ai_base.gd"

# Monte Carlo Tree Search (BROWNE et al., 2012) — baseline de alto custo.
#
# Ancora o extremo caro do espectro de compromisso: representa o que se
# obtém quando a qualidade da decisão é buscada sem restrição de
# processamento. Serve de contraponto superior aos modelos avaliados,
# assim como a IA Aleatória ancora o extremo inferior.
#
# Implementação padrão de quatro fases (seleção por UCT, expansão,
# simulação e retropropagação), adaptada ao domínio:
#
# - Estado do nó: posição do agente e vidas dos inimigos percebidos.
#   Como a percepção é limitada, a busca opera sobre o modelo de mundo
#   do agente, não sobre o estado real — evita onisciência.
# - Simulação (rollout): política aleatória por MAX_ROLLOUT_TURNS
#   turnos, com recompensa por dano causado e penalidade por exposição.
# - Cada operação da busca é contabilizada no medidor de custo, nos
#   mesmos termos dos demais modelos, mantendo a comparação justa.

const ITERATIONS_PADRAO = 60      # simulações por decisão
const MAX_ROLLOUT_TURNS = 6       # profundidade do rollout
const UCT_C = 1.414               # constante de exploração (√2)

static var iterations_atual = ITERATIONS_PADRAO

var rng = null

func decide(agent, sim):
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = sim.map_seed * 7919 + agent.team_id

	var enemies = get_visible_enemies(agent, sim)

	# Sem contato visual não há árvore a explorar: o MCTS não tem o que
	# avaliar e recorre ao deslocamento, como os demais modelos.
	if enemies.is_empty():
		var goal = pursuit_position(agent, sim)
		if goal == null:
			return {"move_to": null, "attack_target": null}
		return {"move_to": step_towards(agent, sim, goal), "attack_target": null}

	var candidatas = sim.grid.get_reachable_cells(agent.x, agent.y, 3)
	candidatas.append(Vector2i(agent.x, agent.y))

	# Estatísticas por candidata (nós filhos da raiz).
	var visitas = []
	var recompensas = []
	for i in range(candidatas.size()):
		visitas.append(0)
		recompensas.append(0.0)

	var total_visitas = 0
	for it in range(iterations_atual):
		var idx = selecionar_uct(sim, visitas, recompensas, total_visitas)
		var r = simular(agent, sim, candidatas[idx], enemies)
		visitas[idx] += 1
		recompensas[idx] += r
		total_visitas += 1

	# Escolhe a candidata mais visitada (critério robusto padrão).
	var melhor = 0
	for i in range(candidatas.size()):
		if visitas[i] > visitas[melhor]:
			melhor = i

	var destino = candidatas[melhor]
	var move_to = null
	if destino != Vector2i(agent.x, agent.y):
		move_to = destino

	return {"move_to": move_to, "attack_target": melhor_alvo(agent, sim, destino, enemies)}

# Seleção por UCT: equilibra exploração e aproveitamento.
func selecionar_uct(sim, visitas, recompensas, total):
	note_action_evaluated(sim)
	var melhor = 0
	var melhor_valor = -INF
	for i in range(visitas.size()):
		var valor
		if visitas[i] == 0:
			valor = INF   # nós não visitados têm prioridade
		else:
			var media = recompensas[i] / visitas[i]
			valor = media + UCT_C * sqrt(log(maxf(total, 1.0)) / visitas[i])
		if valor > melhor_valor:
			melhor_valor = valor
			melhor = i
	return melhor

# Rollout: a partir da célula candidata, simula turnos com política
# aleatória e acumula recompensa. Opera sobre o modelo de mundo
# percebido (posições conhecidas dos inimigos), não sobre o estado real.
func simular(agent, sim, cell, enemies):
	var pos = cell
	var recompensa = 0.0
	var vidas = {}
	for e in enemies:
		vidas[e] = e.hp

	for turno in range(MAX_ROLLOUT_TURNS):
		# Ataque disponível a partir da posição atual do rollout?
		var alvo = null
		for e in enemies:
			if vidas[e] <= 0:
				continue
			var dx = e.x - pos.x
			var dy = e.y - pos.y
			if maxi(absi(dx), absi(dy)) > agent.vision_range:
				continue
			if not agent.is_straight_line(dx, dy):
				continue
			if sim.grid.has_line_of_sight(pos.x, pos.y, e.x, e.y):
				alvo = e
				break

		if alvo != null:
			var reducao = sim.grid.get_cover_reduction(alvo.x, alvo.y, pos.x, pos.y)
			var dano = maxi(agent.BASE_DAMAGE - reducao, 0)
			vidas[alvo] -= dano
			recompensa += dano / 100.0
			if vidas[alvo] <= 0:
				recompensa += 1.0   # eliminação vale um bônus
		else:
			# Sem tiro disponível: passo aleatório na vizinhança.
			var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			var d = dirs[rng.randi_range(0, 3)]
			var nova = pos + d
			if sim.grid.check_walkable(nova.x, nova.y):
				pos = nova

		# Penalidade por exposição: inimigos vivos com linha de visão.
		var expostos = 0
		for e in enemies:
			if vidas[e] > 0 and sim.grid.has_line_of_sight(e.x, e.y, pos.x, pos.y):
				expostos += 1
		recompensa -= 0.05 * expostos

	# Bônus por cobertura na posição final do rollout.
	if sim.grid.has_adjacent_cover(pos.x, pos.y):
		recompensa += 0.2

	return recompensa

func melhor_alvo(agent, sim, cell, enemies):
	var atacaveis = []
	for e in enemies:
		var dx = e.x - cell.x
		var dy = e.y - cell.y
		if maxi(absi(dx), absi(dy)) > agent.vision_range:
			continue
		if not agent.is_straight_line(dx, dy):
			continue
		if sim.grid.has_line_of_sight(cell.x, cell.y, e.x, e.y):
			atacaveis.append(e)
	if atacaveis.is_empty():
		return null
	var melhor = atacaveis[0]
	var menor = INF
	for e in atacaveis:
		var dist = absi(e.x - cell.x) + absi(e.y - cell.y)
		if dist < menor:
			menor = dist
			melhor = e
	return melhor
