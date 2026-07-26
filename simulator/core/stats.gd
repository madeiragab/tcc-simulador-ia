extends RefCounted

# Testes de significância estatística (docs/analise_estatistica.md).
#
# O delineamento experimental é PAREADO: todos os modelos enfrentam
# exatamente as mesmas seeds, e no confronto direto disputam a mesma
# partida. Isso permite testes mais potentes que os de amostras
# independentes, pois a variabilidade do cenário é controlada.
#
# Implementado sem dependências externas (o projeto roda em GDScript).
# As aproximações usadas são justificadas pelo tamanho amostral
# (N = 1000): pelo Teorema Central do Limite, a distribuição t com
# ~999 graus de liberdade é indistinguível da normal padrão.

const Z_95 = 1.959964   # quantil normal bicaudal para 95%

# ---------- funções de distribuição ----------

# Função erro por aproximação de Abramowitz & Stegun (7.1.26),
# erro absoluto < 1.5e-7.
static func erf(x):
	var sign = 1.0 if x >= 0.0 else -1.0
	x = absf(x)
	var t = 1.0 / (1.0 + 0.3275911 * x)
	var y = 1.0 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * exp(-x * x)
	return sign * y

# P(Z > z) para a normal padrão (cauda superior).
static func normal_sf(z):
	return 0.5 * (1.0 - erf(z / sqrt(2.0)))

# p-valor bicaudal a partir de um escore z.
static func p_from_z(z):
	return 2.0 * normal_sf(absf(z))

# P(X² > x) para qui-quadrado. Forma fechada para os graus de
# liberdade usados aqui: df=1 e df=2.
static func chi2_sf(x, df):
	if x <= 0.0:
		return 1.0
	if df == 2:
		return exp(-x / 2.0)
	if df == 1:
		return 2.0 * normal_sf(sqrt(x))
	# Aproximação de Wilson–Hilferty para df > 2.
	var d = float(df)
	var z = (pow(x / d, 1.0 / 3.0) - (1.0 - 2.0 / (9.0 * d))) / sqrt(2.0 / (9.0 * d))
	return normal_sf(z)

# ---------- intervalos de confiança ----------

# Intervalo de Wilson para uma proporção — preferível ao intervalo
# normal simples por manter cobertura adequada mesmo com p distante
# de 0,5 ou amostras menores.
static func wilson_ci(successes, n):
	if n == 0:
		return {"low": 0.0, "high": 0.0, "p": 0.0}
	var p = float(successes) / n
	var z2 = Z_95 * Z_95
	var denom = 1.0 + z2 / n
	var centro = (p + z2 / (2.0 * n)) / denom
	var margem = (Z_95 * sqrt(p * (1.0 - p) / n + z2 / (4.0 * n * n))) / denom
	return {"low": maxf(centro - margem, 0.0), "high": minf(centro + margem, 1.0), "p": p}

# ---------- testes ----------

# Qui-quadrado de aderência: as contagens observadas diferem de uma
# distribuição uniforme? Responde "há alguma diferença entre os
# modelos?" antes de comparações par a par.
static func chi2_goodness_uniform(counts):
	var total = 0
	for c in counts:
		total += c
	if total == 0:
		return {"chi2": 0.0, "df": 0, "p": 1.0}
	var esperado = float(total) / counts.size()
	var chi2 = 0.0
	for c in counts:
		var d = c - esperado
		chi2 += (d * d) / esperado
	var df = counts.size() - 1
	return {"chi2": chi2, "df": df, "p": chi2_sf(chi2, df), "esperado": esperado}

# Teste binomial condicional para comparação par a par no confronto
# direto: entre as partidas decididas por A ou por B, a divisão é
# equilibrada? Como só um agente vence cada partida, as vitórias são
# mutuamente excludentes e este é o teste adequado (equivalente ao
# teste de McNemar para o caso de discordâncias).
static func binomial_pairwise(wins_a, wins_b):
	var n = wins_a + wins_b
	if n == 0:
		return {"n": 0, "p": 1.0, "z": 0.0, "prop_a": 0.0}
	var prop = float(wins_a) / n
	# Aproximação normal com correção de continuidade.
	var z = (absf(wins_a - n / 2.0) - 0.5) / (0.5 * sqrt(float(n)))
	return {
		"n": n,
		"prop_a": prop,
		"z": z,
		"p": p_from_z(z),
		"ci": wilson_ci(wins_a, n),
	}

# Teste t pareado: cada par é a mesma seed jogada pelos dois modelos.
# Controla a variabilidade do cenário, aumentando a potência.
static func paired_t_test(values_a, values_b):
	var n = mini(values_a.size(), values_b.size())
	if n < 2:
		return {"n": n, "p": 1.0, "t": 0.0, "diff_mean": 0.0}
	var diffs = []
	var soma = 0.0
	for i in range(n):
		var d = float(values_a[i]) - float(values_b[i])
		diffs.append(d)
		soma += d
	var media = soma / n
	var var_soma = 0.0
	for d in diffs:
		var_soma += (d - media) * (d - media)
	var desvio = sqrt(var_soma / (n - 1))
	if desvio == 0.0:
		return {"n": n, "p": 0.0 if media != 0.0 else 1.0, "t": INF if media != 0.0 else 0.0, "diff_mean": media, "diff_sd": 0.0, "cohen_d": 0.0}
	var t = media / (desvio / sqrt(float(n)))
	return {
		"n": n,
		"diff_mean": media,
		"diff_sd": desvio,
		"t": t,
		"p": p_from_z(t),            # n grande: t ≈ z
		"cohen_d": media / desvio,   # d de Cohen para amostras pareadas
		"ci_low": media - Z_95 * desvio / sqrt(float(n)),
		"ci_high": media + Z_95 * desvio / sqrt(float(n)),
	}

# Intervalo de confiança por reamostragem (bootstrap percentílico) para
# estatísticas sem forma fechada, como o StrategicScore, que combina
# cinco agregados. Reamostra partidas com reposição.
static func bootstrap_ci(rows, metrics_script, iterations = 2000, seed_value = 20260726):
	if rows.is_empty():
		return {"low": 0.0, "high": 0.0, "mean": 0.0}
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var n = rows.size()
	var scores = []
	for it in range(iterations):
		var sample = []
		for i in range(n):
			sample.append(rows[rng.randi_range(0, n - 1)])
		scores.append(metrics_script.aggregate(sample)["strategic_score"])
	scores.sort()
	var idx_low = int(floor(0.025 * iterations))
	var idx_high = mini(int(floor(0.975 * iterations)), iterations - 1)
	var soma = 0.0
	for s in scores:
		soma += s
	return {
		"low": scores[idx_low],
		"high": scores[idx_high],
		"mean": soma / iterations,
		"iterations": iterations,
	}

# ---------- formatação ----------

static func p_texto(p):
	if p < 0.001:
		return "p < 0,001"
	return "p = %.4f" % p

static func significancia(p):
	if p < 0.001:
		return "altamente significativo"
	if p < 0.01:
		return "muito significativo"
	if p < 0.05:
		return "significativo"
	return "NÃO significativo"

# Interpretação convencional do d de Cohen (1988).
static func efeito_texto(d):
	var a = absf(d)
	if a < 0.2:
		return "desprezível"
	if a < 0.5:
		return "pequeno"
	if a < 0.8:
		return "médio"
	return "grande"
