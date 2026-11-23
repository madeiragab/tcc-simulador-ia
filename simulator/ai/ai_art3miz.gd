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

# Variantes da revisão pós-banca (desligadas por padrão, para que o
# benchmark oficial continue reprodutível bit a bit):
#   fix_alvo=1       — no regime econômico, o alvo do ataque é escolhido
#                      a partir da posição de CHEGADA (antes era a de
#                      partida, e o disparo podia perder o alinhamento).
#   gatilho=exposicao — o valor em jogo soma a fração de inimigos à vista
#                      que têm linha de tiro para a posição atual, de modo
#                      que entrar no alcance de tiro dispara a deliberação.
static var fix_alvo = false
static var gatilho_exposicao = false
#   pesos=padrao     — usa os pesos-padrão da heurística (definidos no
#                      banco de calibração) em vez dos herdados do lote
#                      misto, eliminando o contato com o banco de avaliação.
static var pesos_padrao = false

# Pesos iniciais aprendidos no confronto misto de 1000 partidas.
const W_VIDA_INICIAL = 0.092
const W_COBERTURA_INICIAL = 0.307
const W_PROXIMIDADE_INICIAL = 0.495
const W_RISCO_INICIAL = -0.228

func _init():
	weights = [W_VIDA_INICIAL, W_COBERTURA_INICIAL, W_PROXIMIDADE_INICIAL, W_RISCO_INICIAL]
	if pesos_padrao:
		weights = [W_VIDA, W_COBERTURA, W_PROXIMIDADE, W_RISCO]
	best_weights = weights.duplicate()

# Regime do último turno (só para o registro turno a turno; não afeta a decisão).
var regime = ""

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
		var stakes = tactical_stakes(agent, enemies, sim)
		var estimated_cost = candidate_estimate(enemies)
		if stakes - lambda_atual * estimated_cost > 0.0:
			regime = "deliberou"
			return super.decide(agent, sim)

	# Regime econômico: deslocamento sem análise fina.
	regime = "economico_sem_contato" if enemies.is_empty() else "economico_contato"
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
		var dest = step_towards(agent, sim, goal)
		return {"move_to": dest, "attack_target": attack_from_arrival(agent, sim, dest, enemies, attack)}

	var path = cheap_path_towards(agent, sim, goal)
	# Recuo: o passo guloso trava diante de obstáculos que a busca
	# completa contornaria. Só então se paga pela busca — o custo alto
	# fica reservado às situações em que o caminho barato falha.
	if path.size() < 3:
		var dest2 = step_towards(agent, sim, goal)
		return {"move_to": dest2, "attack_target": attack_from_arrival(agent, sim, dest2, enemies, attack)}
	return {"move_path": path, "attack_target": attack_from_arrival(agent, sim, path[path.size() - 1], enemies, attack)}

# Com fix_alvo desligado, mantém o comportamento original (alvo escolhido
# na posição de partida). Ligado, escolhe o alvo a partir da posição de
# chegada, onde o disparo é de fato validado.
func attack_from_arrival(agent, sim, dest, enemies, original):
	if not fix_alvo or enemies.is_empty():
		return original
	var cell = dest if dest != null else Vector2i(agent.x, agent.y)
	return best_attack_from(agent, sim, cell, enemies)

# Valor estratégico em jogo no turno: cresce com o número de inimigos
# à vista, com a proximidade do mais próximo e com a própria
# vulnerabilidade — as situações em que decidir bem importa mais.
func tactical_stakes(agent, enemies, sim = null):
	var nearest = INF
	for enemy in enemies:
		nearest = minf(nearest, maxi(absi(enemy.x - agent.x), absi(enemy.y - agent.y)))
	var proximidade = 1.0 / maxf(nearest, 1.0)
	var vulnerabilidade = 1.0 - float(agent.hp) / agent.max_hp
	var stakes = enemies.size() * (proximidade + vulnerabilidade)
	if gatilho_exposicao and sim != null:
		var expostos = 0
		for enemy in enemies:
			var dx = agent.x - enemy.x
			var dy = agent.y - enemy.y
			if maxi(absi(dx), absi(dy)) <= enemy.vision_range and agent.is_straight_line(dx, dy) 					and sim.grid.has_line_of_sight(enemy.x, enemy.y, agent.x, agent.y):
				expostos += 1
		stakes += float(expostos) / enemies.size()
	return stakes

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
