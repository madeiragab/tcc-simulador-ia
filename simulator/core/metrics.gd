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
# Agregado sobre N partidas (docs/metricas.md). Todos os termos são
# normalizados a [0,1] antes da ponderação, para que os pesos
# correspondam à importância pretendida — o escore final também fica
# em [0,1]:
#   WinRate          = vitórias / N
#   DamageNorm       = DR / (1 + DR)
#   CoverUsage       = fração de turnos protegido
#   EficienciaTurnos = (LIMITE - min(TTV, LIMITE)) / LIMITE
#   EficienciaCusto  = CUSTO_REF / (CUSTO_REF + custo médio)
#   StrategicScore   = 0.30*WinRate + 0.20*DamageNorm + 0.20*CoverUsage
#                    + 0.20*EficienciaTurnos + 0.10*EficienciaCusto

const EPSILON = 1
const TURN_LIMIT_PENALTY = 100

# Custo de referência da normalização: ordem de grandeza típica
# observada. EficienciaCusto vale 0,5 quando o modelo gasta exatamente
# este valor.
const CUSTO_REFERENCIA = 1000.0

# Pontuação de partida (docs/metricas.md): empate é penalizado de
# propósito — sobreviver sem decidir a partida não é eficácia.
const POINTS_WIN = 3
const POINTS_DRAW = -1
const POINTS_LOSS = -3

# ---------- valores por partida ----------

static func match_points(venceu, empate):
	if venceu:
		return POINTS_WIN
	if empate:
		return POINTS_DRAW
	return POINTS_LOSS

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
	var points_total = 0
	var ttv_values = []       # turnos p/ vencer (vitórias) + penalidade (empates)
	var dr_values = []
	var cu_values = []
	var cost_values = []

	for row in rows:
		points_total += match_points(row["venceu"], row["empate"])
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
	var dr_mean = mean(dr_values)
	var cu_mean = mean(cu_values)
	var cost_mean = mean(cost_values)

	# Normalizações para [0,1] (docs/metricas.md).
	var damage_norm = dr_mean / (1.0 + dr_mean)
	var efficiency = (TURN_LIMIT_PENALTY - minf(ttv_mean, TURN_LIMIT_PENALTY)) / float(TURN_LIMIT_PENALTY)
	var cost_efficiency = CUSTO_REFERENCIA / (CUSTO_REFERENCIA + maxf(cost_mean, 0.0))

	var strategic_score = (
		0.30 * win_rate +
		0.20 * damage_norm +
		0.20 * cu_mean +
		0.20 * efficiency +
		0.10 * cost_efficiency
	)

	return {
		"n": n,
		"points_total": points_total,
		"points_mean": float(points_total) / max(n, 1),
		"win_rate": win_rate,
		"damage_ratio_mean": dr_mean,
		"damage_ratio_std": std_dev(dr_values),
		"cover_usage_mean": cu_mean,
		"cover_usage_std": std_dev(cu_values),
		"turns_to_victory_mean": ttv_mean,
		"damage_norm": damage_norm,
		"efficiency": efficiency,
		"cost_efficiency": cost_efficiency,
		"custo_mean": cost_mean,
		"custo_std": std_dev(cost_values),
		"strategic_score": strategic_score,
	}
