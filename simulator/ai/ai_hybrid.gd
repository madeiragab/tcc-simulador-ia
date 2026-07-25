extends "res://ai/ai_heuristic.gd"

# Modelo Proposto — IA Híbrida (docs/modelo_proposto.md).
#
#   ScoreAção = ValorEstratégico − λ × CustoComputacional(ação)
#
# Estende a IA Heurística penalizando cada ação candidata pelo custo,
# em operações contadas, de avaliá-la (docs/resultados_campanha.md §3:
# o custo marginal da heurística concentra-se no loop de avaliação
# posicional — LOS de risco por célula candidata).
#
# CustoComputacional(ação) é o delta do medidor durante a avaliação
# daquela ação: avaliações caras precisam valer mais para vencer.
#
# Dois mecanismos derivados da campanha (docs/resultados_campanha.md):
#   1. Pesos iniciais = melhor configuração aprendida no confronto misto
#   2. Poda por orçamento: candidatas são avaliadas em ordem de
#      promessa e o loop encerra quando o orçamento de operações acaba,
#      convertendo a penalidade em economia real de processamento.

# λ converte operações em unidades de valor estratégico. Calibrado no
# banco de tuning (200 seeds), nunca no benchmark. Sobrescrevível pela
# linha de comando (-- lambda=0.02) para a varredura de calibração.
const LAMBDA_PADRAO = 0.02
static var lambda_atual = LAMBDA_PADRAO

# Orçamento de operações de avaliação por turno (0 = sem poda).
const BUDGET_PADRAO = 120
static var budget_atual = BUDGET_PADRAO

# Pesos iniciais aprendidos no confronto misto de 1000 partidas.
const W_VIDA_INICIAL = 0.092
const W_COBERTURA_INICIAL = 0.307
const W_PROXIMIDADE_INICIAL = 0.495
const W_RISCO_INICIAL = -0.228

func _init():
	weights = [W_VIDA_INICIAL, W_COBERTURA_INICIAL, W_PROXIMIDADE_INICIAL, W_RISCO_INICIAL]
	best_weights = weights.duplicate()

# Pontua a candidata e desconta o custo de tê-la avaliado.
func score_action(agent, sim, cell, enemies):
	var meter = sim.grid.cost_meter
	var before = meter.total() if meter != null else 0

	note_action_evaluated(sim)
	var value = strategic_value(agent, sim, cell, enemies)

	var cost = (meter.total() - before) if meter != null else 0
	return value - lambda_atual * cost

# Ordena as candidatas por promessa (proximidade do inimigo mais
# próximo, barato de calcular) e avalia dentro do orçamento: o que
# sobrar fica sem avaliar, poupando operações de verdade.
func candidate_cells(agent, sim, enemies):
	var cells = super.candidate_cells(agent, sim, enemies)
	if budget_atual <= 0:
		return cells

	var target = closest_of(agent, enemies)
	var scored = []
	for cell in cells:
		scored.append([abs(cell.x - target.x) + abs(cell.y - target.y), cell])
	scored.sort_custom(func(a, b): return a[0] < b[0])

	# Cada avaliação custa ~1 LOS por inimigo visível + 1 ação contada.
	var per_action = max(enemies.size() + 1, 1)
	var limit = max(int(budget_atual / float(per_action)), 1)

	var pruned = []
	for i in range(min(limit, scored.size())):
		pruned.append(scored[i][1])
	return pruned
