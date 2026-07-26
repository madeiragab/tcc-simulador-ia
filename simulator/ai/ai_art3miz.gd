extends "res://ai/ai_heuristic.gd"

# Art3miz 0.1 — modelo híbrido proposto (docs/modelo_proposto.md).
#
#   ScoreAção = ValorEstratégico − λ × CustoComputacional(ação)
#
# Princípio: investir processamento na proporção do que está em jogo.
# A campanha de coleta (docs/resultados_campanha.md) mostrou que 84% do
# custo da IA Heurística está na busca de caminho executada em TODO
# turno — inclusive nos muitos turnos sem contato visual, quando o
# agente apenas explora e a análise fina é desperdiçada.
#
# O modelo opera em dois regimes:
#
#   Econômico (sem contato visual): passo guloso na direção do objetivo,
#   verificando apenas as células do caminho (~3-6 operações) em vez de
#   expandir a vizinhança inteira (~25 nós de busca).
#
#   Tático (com contato visual): avaliação posicional completa, com as
#   candidatas ordenadas por promessa, penalizadas pelo custo de avaliá-
#   las (λ) e limitadas por um orçamento de operações do turno.

# λ converte operações em unidades de valor estratégico. Calibrado no
# banco de tuning (200 seeds), nunca no benchmark. Sobrescrevível pela
# linha de comando (-- lambda=0.02) para a varredura de calibração.
# Calibrado em 0,005 pela varredura nas 200 seeds de tuning: mantém a
# eficácia máxima observada (WinRate 0,235, igual a λ=0) com 15% menos
# operações; acima disso a eficácia começa a cair.
const LAMBDA_PADRAO = 0.005
static var lambda_atual = LAMBDA_PADRAO

# Orçamento de operações de avaliação por turno. A varredura mostrou
# que podar candidatas prejudica a eficácia sem economia relevante
# (o regime econômico já elimina o grosso do custo), então 0 = sem poda.
const BUDGET_PADRAO = 0
static var budget_atual = BUDGET_PADRAO

# Pesos iniciais aprendidos no confronto misto de 1000 partidas.
const W_VIDA_INICIAL = 0.092
const W_COBERTURA_INICIAL = 0.307
const W_PROXIMIDADE_INICIAL = 0.495
const W_RISCO_INICIAL = -0.228

func _init():
	weights = [W_VIDA_INICIAL, W_COBERTURA_INICIAL, W_PROXIMIDADE_INICIAL, W_RISCO_INICIAL]
	best_weights = weights.duplicate()

func decide(agent, sim):
	visited[Vector2i(agent.x, agent.y)] = true

	var enemies = get_visible_enemies(agent, sim)

	# Decisão de deliberar: a avaliação completa só se justifica quando
	# o valor estratégico em jogo supera o custo de obtê-lo.
	#   ValorEmJogo − λ × CustoEstimado > 0
	# Sem inimigos à vista o valor em jogo é nulo e o regime econômico
	# é sempre escolhido; com λ = 0 a avaliação é sempre feita
	# (equivale à heurística pura); com λ alto, nunca (equivale à
	# reativa). O parâmetro percorre todo o espectro.
	if not enemies.is_empty():
		var stakes = tactical_stakes(agent, enemies)
		var estimated_cost = candidate_estimate(enemies)
		if stakes - lambda_atual * estimated_cost > 0.0:
			return super.decide(agent, sim)

	# Regime econômico: deslocamento sem análise fina.
	var goal = pursuit_position(agent, sim) if enemies.is_empty() else Vector2i(closest_of(agent, enemies).x, closest_of(agent, enemies).y)
	if goal == null:
		return {"move_to": null, "attack_target": null}

	var attack = null
	if not enemies.is_empty():
		var reachable = filter_attackable(agent, sim, enemies)
		if not reachable.is_empty():
			attack = closest_of(agent, reachable)

	# Caçar uma posição já vista é aproximação com propósito e merece a
	# busca completa. Seguir indício de sensor ou vagar, não — aí o
	# passo guloso basta. (Estender a busca ao indício foi testado e
	# custou 22% mais operações sem ganho de eficácia.)
	if not last_known.is_empty():
		return {"move_to": step_towards(agent, sim, goal), "attack_target": attack}

	var path = cheap_path_towards(agent, sim, goal)
	# Recuo: o passo guloso trava diante de obstáculos que a busca
	# completa contornaria. Só então se paga pela busca — o custo alto
	# fica reservado às situações em que o caminho barato falha.
	if path.size() < 3:
		return {"move_to": step_towards(agent, sim, goal), "attack_target": attack}
	return {"move_path": path, "attack_target": attack}

# Valor estratégico em jogo no turno: cresce com o número de inimigos
# à vista, com a proximidade do mais próximo e com a própria
# vulnerabilidade — as situações em que decidir bem importa mais.
func tactical_stakes(agent, enemies):
	var nearest = INF
	for enemy in enemies:
		nearest = minf(nearest, maxi(absi(enemy.x - agent.x), absi(enemy.y - agent.y)))
	var proximidade = 1.0 / maxf(nearest, 1.0)
	var vulnerabilidade = 1.0 - float(agent.hp) / agent.max_hp
	return enemies.size() * (proximidade + vulnerabilidade)

# Custo estimado da avaliação completa: uma verificação de linha de
# visão por inimigo, mais a ação, para cada célula candidata.
func candidate_estimate(enemies):
	return CANDIDATAS_TIPICAS * (enemies.size() + 1)

const CANDIDATAS_TIPICAS = 25

# Pontua a candidata e desconta o custo de tê-la avaliado.
func score_action(agent, sim, cell, enemies):
	var meter = sim.grid.cost_meter
	var before = meter.total() if meter != null else 0

	note_action_evaluated(sim)
	var value = strategic_value(agent, sim, cell, enemies)

	var cost = (meter.total() - before) if meter != null else 0
	return value - lambda_atual * cost

# Ordena as candidatas por promessa (distância ao inimigo mais próximo,
# cálculo barato) e avalia dentro do orçamento: o excedente fica sem
# avaliar, poupando operações de verdade.
func candidate_cells(agent, sim, enemies):
	var cells = super.candidate_cells(agent, sim, enemies)
	if budget_atual <= 0:
		return cells

	var target = closest_of(agent, enemies)
	var scored = []
	for cell in cells:
		scored.append([absi(cell.x - target.x) + absi(cell.y - target.y), cell])
	scored.sort_custom(func(a, b): return a[0] < b[0])

	# Cada avaliação custa ~1 verificação de linha de visão por inimigo
	# visível, mais a própria ação contabilizada.
	var per_action = maxi(enemies.size() + 1, 1)
	var limit = maxi(int(budget_atual / float(per_action)), 1)

	var pruned = []
	for i in range(mini(limit, scored.size())):
		pruned.append(scored[i][1])
	return pruned
