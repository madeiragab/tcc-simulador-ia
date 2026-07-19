extends RefCounted

# Cálculo das métricas de avaliação — implementação LITERAL de
# docs/metricas.md. Qualquer mudança de fórmula deve ser feita primeiro
# lá e replicada aqui.
#
# Por partida (valores crus por jogador):
#   DamageRatio  = dano_causado / max(dano_recebido, EPSILON)
#                  (limitador de docs/metricas.md quando nada é recebido)
#   CoverUsage   = turnos_em_cobertura / max(turnos_agidos, 1)
#   TurnsToVictory: turnos da partida se venceu; 100 (penalidade máxima)
#                  se empate; derrotas não entram (a métrica é "turnos
#                  necessários para vencer").
#
# Agregado sobre N partidas (docs/metricas.md, "Agregação Oficial"):
#   WinRate    = vitórias / N
#   Efficiency = 1 / max(TurnsToVictory médio, 1)
#   StrategicScore =
#       0.3 * WinRate +
#       0.2 * DamageRatio médio +
#       0.2 * CoverUsage médio +
#       0.2 * Efficiency +
#       0.1 * (1 / max(CustoComputacionalMedio, EPSILON))

const EPSILON = 1
const TURN_LIMIT_PENALTY = 100

# ---------- valores por partida ----------

static func damage_ratio(dano_causado, dano_recebido):
	return float(dano_causado) / max(dano_recebido, EPSILON)

static func cover_usage(turnos_em_cobertura, turnos_agidos):
	return float(turnos_em_cobertura) / max(turnos_agidos, 1)

# ---------- agregação sobre uma lista de partidas ----------

static func mean(values):
	if values.is_empty():
		return 0.0
	var total = 0.0
	for v in values:
		total += v
	return total / values.size()

static func std_dev(values):
	if values.size() < 2:
		return 0.0
	var m = mean(values)
	var acc = 0.0
	for v in values:
		acc += (v - m) * (v - m)
	return sqrt(acc / values.size())

# rows: lista de dicionários por partida com as chaves
#   venceu (bool), empate (bool), turnos, damage_ratio, cover_usage, custo
static func aggregate(rows):
	var n = rows.size()
	var wins = 0
	var ttv_values = []       # turnos p/ vencer (vitórias) + penalidade (empates)
	var dr_values = []
	var cu_values = []
	var cost_values = []

	for row in rows:
		if row["venceu"]:
			wins += 1
			ttv_values.append(float(row["turnos"]))
		elif row["empate"]:
			ttv_values.append(float(TURN_LIMIT_PENALTY))
		dr_values.append(row["damage_ratio"])
		cu_values.append(row["cover_usage"])
		cost_values.append(float(row["custo"]))

	var win_rate = float(wins) / max(n, 1)
	var ttv_mean = mean(ttv_values) if not ttv_values.is_empty() else float(TURN_LIMIT_PENALTY)
	var efficiency = 1.0 / max(ttv_mean, 1.0)
	var dr_mean = mean(dr_values)
	var cu_mean = mean(cu_values)
	var cost_mean = mean(cost_values)

	var strategic_score = (
		0.3 * win_rate +
		0.2 * dr_mean +
		0.2 * cu_mean +
		0.2 * efficiency +
		0.1 * (1.0 / max(cost_mean, EPSILON))
	)

	return {
		"n": n,
		"win_rate": win_rate,
		"damage_ratio_mean": dr_mean,
		"damage_ratio_std": std_dev(dr_values),
		"cover_usage_mean": cu_mean,
		"cover_usage_std": std_dev(cu_values),
		"turns_to_victory_mean": ttv_mean,
		"efficiency": efficiency,
		"custo_mean": cost_mean,
		"custo_std": std_dev(cost_values),
		"strategic_score": strategic_score,
	}
