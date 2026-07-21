extends "res://ai/ai_base.gd"

# IA Heurística (docs/ia.md §4): avalia cada posição alcançável com a
# função de valor estratégico e escolhe a melhor (argmax). O ataque é
# gerado a partir da posição escolhida quando há alvo válido.
#
#   ValorEstratégico = W_VIDA * Vida + W_COBERTURA * Cobertura +
#                      W_PROXIMIDADE * Proximidade + W_RISCO * Risco
#
# Fatores (normalizados para [0, 1]):
#   Vida         — proporção de HP atual do agente
#   Cobertura    — proteção potencial da posição (0, 0.5 leve, 1 pesada)
#   Proximidade  — inverso da distância ao inimigo mais próximo
#   Risco        — fração de inimigos com linha de visão para a posição
#
# W_RISCO é negativo: posições expostas perdem valor (docs/ia.md).
# Pesos calibrados no banco de tuning (200 seeds), nunca no benchmark.

const W_VIDA = 0.1
const W_COBERTURA = 0.3
const W_PROXIMIDADE = 0.5
const W_RISCO = -0.2

# ---------- Aprendizado entre partidas (hill-climbing nos pesos) ----------
# Joga LEARN_WINDOW partidas com os pesos atuais e mede a média de
# pontos (+3/-1/-3). Melhorou a melhor média conhecida: adota. Piorou:
# reverte. Em ambos os casos, a próxima janela testa uma perturbação da
# melhor configuração (RNG semeado -> lote reprodutível).

const LEARN_WINDOW = 25
const LEARN_STEP = 0.05

var weights = [W_VIDA, W_COBERTURA, W_PROXIMIDADE, W_RISCO]
var best_weights = [W_VIDA, W_COBERTURA, W_PROXIMIDADE, W_RISCO]
var best_avg = -INF
var window_points = []
var windows_done = 0
var learn_rng = null
var log_rows = []

func learn(points):
	window_points.append(points)
	if window_points.size() < LEARN_WINDOW:
		return

	var total = 0
	for p in window_points:
		total += p
	var avg = float(total) / window_points.size()
	windows_done += 1

	var adopted = avg > best_avg
	if adopted:
		best_avg = avg
		best_weights = weights.duplicate()

	log_rows.append({
		"janela": windows_done,
		"pesos": weights.duplicate(),
		"pontos_media": avg,
		"decisao": "adotado" if adopted else "revertido",
	})

	# Próxima tentativa: perturbação da melhor configuração conhecida.
	if learn_rng == null:
		learn_rng = RandomNumberGenerator.new()
		learn_rng.seed = 977 + player_id
	var next = best_weights.duplicate()
	for i in range(next.size()):
		next[i] = clamp(next[i] + learn_rng.randf_range(-LEARN_STEP, LEARN_STEP), -1.0, 1.0)
	weights = next
	window_points.clear()

func learning_log():
	return log_rows

func decide(agent, sim):
	# Percepção primeiro: a heurística só raciocina sobre quem enxerga.
	var enemies = get_visible_enemies(agent, sim)

	# Ninguém à vista: caça a última posição conhecida ou explora,
	# sem pagar o custo da avaliação posicional completa.
	if enemies.is_empty():
		var goal = pursuit_position(agent, sim)
		if goal == null:
			return {"move_to": null, "attack_target": null}
		return {"move_to": step_towards(agent, sim, goal), "attack_target": null}

	# Candidatos: todas as posições alcançáveis + ficar parado.
	var candidates = sim.grid.get_reachable_cells(agent.x, agent.y, 3)
	candidates.append(Vector2i(agent.x, agent.y))

	var best_cell = Vector2i(agent.x, agent.y)
	var best_score = -INF
	for cell in candidates:
		var score = score_action(agent, sim, cell, enemies)
		if score > best_score:
			best_score = score
			best_cell = cell

	var move_to = null
	if best_cell != Vector2i(agent.x, agent.y):
		move_to = best_cell

	return {"move_to": move_to, "attack_target": best_attack_from(agent, sim, best_cell, enemies)}

# Pontua uma posição candidata. A IA Híbrida sobrescreve este método
# para acrescentar a penalidade de custo computacional.
func score_action(agent, sim, cell, enemies):
	note_action_evaluated(sim)
	return strategic_value(agent, sim, cell, enemies)

func strategic_value(agent, sim, cell, enemies):
	var vida = float(agent.hp) / agent.max_hp

	var cobertura = cover_level(sim, cell)

	var nearest = INF
	for enemy in enemies:
		nearest = min(nearest, max(abs(enemy.x - cell.x), abs(enemy.y - cell.y)))
	var proximidade = 1.0 / max(nearest, 1.0)

	var exposed = 0
	for enemy in enemies:
		var dist = max(abs(enemy.x - cell.x), abs(enemy.y - cell.y))
		if dist <= enemy.vision_range and sim.grid.has_line_of_sight(enemy.x, enemy.y, cell.x, cell.y):
			exposed += 1
	var risco = float(exposed) / max(enemies.size(), 1)

	return weights[0] * vida + weights[1] * cobertura + weights[2] * proximidade + weights[3] * risco

# Proteção potencial da posição: 0 sem cobertura adjacente, 0.5 leve, 1 pesada.
func cover_level(sim, cell):
	var best = 0
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var type = sim.grid.get_cell_type(cell.x + offset.x, cell.y + offset.y)
		best = max(best, sim.grid.get_cover_reduction_for_type(type))
	return best / float(sim.grid.COVER_HEAVY_REDUCTION)

# Melhor alvo atacável a partir da célula escolhida (o mais próximo).
# Requer linha de tiro reta e livre a partir dessa célula.
func best_attack_from(agent, sim, cell, enemies):
	var attackable = []
	for enemy in enemies:
		var dx = enemy.x - cell.x
		var dy = enemy.y - cell.y
		if max(abs(dx), abs(dy)) > agent.vision_range:
			continue
		if not agent.is_straight_line(dx, dy):
			continue
		if sim.grid.has_line_of_sight(cell.x, cell.y, enemy.x, enemy.y):
			attackable.append(enemy)
	if attackable.is_empty():
		return null
	var best = attackable[0]
	var best_dist = INF
	for enemy in attackable:
		var dist = abs(enemy.x - cell.x) + abs(enemy.y - cell.y)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best
