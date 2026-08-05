extends SceneTree

# Regressão de core/stats.gd — os testes de significância em que a monografia
# inteira se apoia.
#
# Uso: godot --headless --path simulator --script res://tests/test_stats.gd
#
# Por que estes testes existem: os p-valores publicados nos resultados vêm
# daqui. Se a aproximação da função erro, a correção de continuidade do
# binomial ou o desvio pareado saírem errados, nada quebra e nada avisa — a
# monografia só passa a afirmar coisa que os dados não sustentam. Cada caso
# abaixo tem valor de referência conhecido, calculado fora deste código.

const Stats = preload("res://core/stats.gd")

var falhas := 0
var total := 0


func _initialize() -> void:
	testar_erf()
	testar_normal()
	testar_qui_quadrado()
	testar_wilson()
	testar_aderencia_uniforme()
	testar_binomial_pareado()
	testar_t_pareado()
	testar_formatacao()

	print("")
	if falhas == 0:
		print("%d verificações, todas passaram" % total)
		quit(0)
	else:
		print("%d verificações, %d FALHARAM" % [total, falhas])
		quit(1)


# ---------- infraestrutura mínima ----------

func perto(nome: String, obtido: float, esperado: float, tolerancia := 1e-6) -> void:
	total += 1
	if absf(obtido - esperado) <= tolerancia:
		print("  OK   %s" % nome)
	else:
		falhas += 1
		print("  FALHA %s: esperado %.9f, obtido %.9f" % [nome, esperado, obtido])


func verdade(nome: String, condicao: bool) -> void:
	total += 1
	if condicao:
		print("  OK   %s" % nome)
	else:
		falhas += 1
		print("  FALHA %s" % nome)


func igual_texto(nome: String, obtido: String, esperado: String) -> void:
	total += 1
	if obtido == esperado:
		print("  OK   %s" % nome)
	else:
		falhas += 1
		print("  FALHA %s: esperado \"%s\", obtido \"%s\"" % [nome, esperado, obtido])


# ---------- função erro ----------

func testar_erf() -> void:
	print("erf (Abramowitz & Stegun 7.1.26, erro absoluto < 1,5e-7):")
	# A aproximação promete 1,5e-7. A tolerância aqui é essa, não mais folgada:
	# se alguém trocar os coeficientes por uma aproximação pior, o teste tem
	# que reclamar.
	perto("erf(0) = 0", Stats.erf(0.0), 0.0, 3e-7)
	perto("erf(1) = 0,8427008", Stats.erf(1.0), 0.842700793, 3e-7)
	perto("erf(2) = 0,9953223", Stats.erf(2.0), 0.995322265, 3e-7)
	perto("erf(0,5) = 0,5204999", Stats.erf(0.5), 0.520499878, 3e-7)
	# Função ímpar: erf(-x) = -erf(x). O sinal é tratado à mão no código.
	perto("erf(-1) = -erf(1)", Stats.erf(-1.0), -Stats.erf(1.0), 1e-12)
	perto("erf(-2,5) = -erf(2,5)", Stats.erf(-2.5), -Stats.erf(2.5), 1e-12)


func testar_normal() -> void:
	print("normal padrão:")
	perto("normal_sf(0) = 0,5", Stats.normal_sf(0.0), 0.5, 1e-7)
	perto("normal_sf(1,959964) = 0,025", Stats.normal_sf(Stats.Z_95), 0.025, 1e-6)
	perto("normal_sf(1,644854) = 0,05", Stats.normal_sf(1.6448536), 0.05, 1e-6)
	# O quantil de 95% bicaudal precisa devolver exatamente 0,05 — é ele que
	# define o corte de significância usado no texto todo.
	perto("p_from_z(Z_95) = 0,05", Stats.p_from_z(Stats.Z_95), 0.05, 1e-6)
	perto("p_from_z(0) = 1", Stats.p_from_z(0.0), 1.0, 1e-7)
	perto("p_from_z é simétrico no sinal", Stats.p_from_z(-2.3), Stats.p_from_z(2.3), 1e-12)
	verdade("p_from_z(4) < 0,001", Stats.p_from_z(4.0) < 0.001)


func testar_qui_quadrado() -> void:
	print("qui-quadrado:")
	perto("chi2_sf(0, df=1) = 1", Stats.chi2_sf(0.0, 1), 1.0, 1e-12)
	perto("chi2_sf(-1, df=1) = 1", Stats.chi2_sf(-1.0, 1), 1.0, 1e-12)
	# df=1: forma fechada 2·normal_sf(√x). O valor crítico de 5% é 3,841459.
	perto("chi2_sf(3,841459, df=1) = 0,05", Stats.chi2_sf(3.841459, 1), 0.05, 1e-6)
	# df=2: forma fechada exp(-x/2). O crítico de 5% é 5,991465.
	perto("chi2_sf(2, df=2) = e^-1", Stats.chi2_sf(2.0, 2), exp(-1.0), 1e-12)
	perto("chi2_sf(5,991465, df=2) = 0,05", Stats.chi2_sf(5.991465, 2), 0.05, 1e-6)
	# df=3 cai na aproximação de Wilson–Hilferty, que é bem mais grosseira que
	# as formas fechadas acima: no crítico de 5% (7,814728) ela erra por volta
	# de 8e-4. A tolerância aqui documenta esse erro em vez de escondê-lo.
	perto("chi2_sf(7,814728, df=3) ≈ 0,05", Stats.chi2_sf(7.814728, 3), 0.05, 2e-3)


func testar_wilson() -> void:
	print("intervalo de Wilson:")
	var meio = Stats.wilson_ci(50, 100)
	perto("p = 0,5 em 50/100", meio["p"], 0.5, 1e-12)
	perto("limite inferior = 0,403832", meio["low"], 0.403832, 1e-5)
	perto("limite superior = 0,596168", meio["high"], 0.596168, 1e-5)
	verdade("o intervalo contém a proporção", meio["low"] < meio["p"] and meio["p"] < meio["high"])

	# Nas pontas o intervalo normal simples vaza para fora de [0,1]. O de
	# Wilson é usado justamente para não vazar — e o código ainda ceifa.
	var zero = Stats.wilson_ci(0, 30)
	verdade("0/30 não produz limite negativo", zero["low"] >= 0.0)
	var cheio = Stats.wilson_ci(30, 30)
	verdade("30/30 não passa de 1", cheio["high"] <= 1.0)

	var vazio = Stats.wilson_ci(0, 0)
	verdade("n = 0 não divide por zero", vazio["p"] == 0.0 and vazio["low"] == 0.0)

	# Mais amostra, intervalo mais estreito, mesma proporção.
	var largo = Stats.wilson_ci(50, 100)
	var estreito = Stats.wilson_ci(500, 1000)
	verdade(
		"o intervalo encolhe quando N cresce",
		(estreito["high"] - estreito["low"]) < (largo["high"] - largo["low"])
	)


func testar_aderencia_uniforme() -> void:
	print("qui-quadrado de aderência:")
	var uniforme = Stats.chi2_goodness_uniform([25, 25, 25, 25])
	perto("distribuição perfeita dá chi2 = 0", uniforme["chi2"], 0.0, 1e-12)
	perto("p = 1 quando não há diferença", uniforme["p"], 1.0, 1e-12)
	verdade("df = k - 1", uniforme["df"] == 3)
	perto("esperado = total/k", uniforme["esperado"], 25.0, 1e-12)

	var desigual = Stats.chi2_goodness_uniform([90, 10])
	verdade("90 contra 10 é significativo", desigual["p"] < 0.001)
	# chi2 = (90-50)²/50 + (10-50)²/50 = 32 + 32 = 64
	perto("chi2 = 64 em [90, 10]", desigual["chi2"], 64.0, 1e-9)

	var nada = Stats.chi2_goodness_uniform([0, 0, 0])
	verdade("contagem toda zerada não estoura", nada["p"] == 1.0 and nada["df"] == 0)


func testar_binomial_pareado() -> void:
	print("binomial condicional (par a par):")
	var empate = Stats.binomial_pairwise(50, 50)
	perto("50 contra 50 dá proporção 0,5", empate["prop_a"], 0.5, 1e-12)
	verdade("empate NÃO é significativo", empate["p"] > 0.05)
	verdade("n é a soma das vitórias", empate["n"] == 100)

	var goleada = Stats.binomial_pairwise(90, 10)
	perto("90 contra 10 dá proporção 0,9", goleada["prop_a"], 0.9, 1e-12)
	# z = (|90 - 50| - 0,5) / (0,5·√100) = 39,5 / 5 = 7,9
	perto("z = 7,9 com correção de continuidade", goleada["z"], 7.9, 1e-9)
	verdade("goleada é altamente significativa", goleada["p"] < 0.001)

	# A correção de continuidade só faz sentido se realmente puxar o z para
	# baixo: sem ela, z seria 40/5 = 8,0.
	verdade("a correção reduz o z", goleada["z"] < 8.0)

	# O teste é sobre a divisão, não sobre quem está na frente: 90x10 e 10x90
	# têm o mesmo p.
	var invertida = Stats.binomial_pairwise(10, 90)
	perto("o p não depende da ordem", invertida["p"], goleada["p"], 1e-12)
	perto("mas a proporção sim", invertida["prop_a"], 0.1, 1e-12)

	var sem_partida = Stats.binomial_pairwise(0, 0)
	verdade("nenhuma partida decidida devolve p = 1", sem_partida["p"] == 1.0)
	verdade("nenhuma partida decidida devolve n = 0", sem_partida["n"] == 0)

	# 60x40 em 100 partidas fica no limiar: a diferença existe mas não passa
	# no corte de 5%. Vale fixar porque é o caso em que arredondar errado
	# viraria uma afirmação forte demais no texto.
	var limiar = Stats.binomial_pairwise(60, 40)
	perto("z = 1,9 em 60 contra 40", limiar["z"], 1.9, 1e-9)
	verdade("60 contra 40 NÃO passa em 5%", limiar["p"] > 0.05)


func testar_t_pareado() -> void:
	print("teste t pareado:")
	# a - b = [1, 2, 3, 4]; média 2,5; desvio amostral √(5/3) = 1,290994
	# t = 2,5 / (1,290994/√4) = 3,872983; d de Cohen = 2,5/1,290994 = 1,936492
	var caso = Stats.paired_t_test([2, 4, 6, 8], [1, 2, 3, 4])
	verdade("n é o menor dos dois vetores", caso["n"] == 4)
	perto("diferença média = 2,5", caso["diff_mean"], 2.5, 1e-12)
	perto("desvio da diferença = 1,290994", caso["diff_sd"], 1.290994449, 1e-9)
	perto("t = 3,872983", caso["t"], 3.872983346, 1e-9)
	perto("d de Cohen = 1,936492", caso["cohen_d"], 1.936491673, 1e-9)
	verdade("o intervalo contém a média", caso["ci_low"] < 2.5 and 2.5 < caso["ci_high"])

	# Trocar a ordem inverte o sinal de t e mantém o p.
	var trocado = Stats.paired_t_test([1, 2, 3, 4], [2, 4, 6, 8])
	perto("t troca de sinal", trocado["t"], -caso["t"], 1e-9)
	perto("p não muda", trocado["p"], caso["p"], 1e-12)

	# Vetores de tamanhos diferentes: o menor manda, sem estourar índice.
	var desigual = Stats.paired_t_test([2, 4, 6, 8, 10, 12], [1, 2, 3, 4])
	verdade("vetores desiguais usam o menor n", desigual["n"] == 4)
	perto("e dão o mesmo resultado", desigual["t"], caso["t"], 1e-9)

	# Diferença constante: desvio zero. Não pode virar divisão por zero.
	var constante = Stats.paired_t_test([2, 3, 4, 5], [1, 2, 3, 4])
	verdade("diferença constante não divide por zero", constante["diff_sd"] == 0.0)
	verdade("e é reportada como certeza", constante["p"] == 0.0 and is_inf(constante["t"]))

	# Vetores idênticos: nenhuma diferença, nada a afirmar.
	var identico = Stats.paired_t_test([1, 2, 3], [1, 2, 3])
	perto("vetores idênticos dão média zero", identico["diff_mean"], 0.0, 1e-12)
	verdade("e p = 1", identico["p"] == 1.0)

	# Amostra pequena demais para estimar desvio.
	var curto = Stats.paired_t_test([1], [2])
	verdade("n = 1 devolve p = 1 em vez de estourar", curto["p"] == 1.0 and curto["n"] == 1)
	var nenhum = Stats.paired_t_test([], [])
	verdade("vetor vazio devolve p = 1", nenhum["p"] == 1.0)


func testar_formatacao() -> void:
	print("formatação do relatório:")
	igual_texto("p muito pequeno vira \"p < 0,001\"", Stats.p_texto(0.0001), "p < 0,001")
	igual_texto("p normal sai com 4 casas", Stats.p_texto(0.0432), "p = 0.0432")

	igual_texto("p = 0,0005", Stats.significancia(0.0005), "altamente significativo")
	igual_texto("p = 0,005", Stats.significancia(0.005), "muito significativo")
	igual_texto("p = 0,03", Stats.significancia(0.03), "significativo")
	igual_texto("p = 0,20", Stats.significancia(0.20), "NÃO significativo")
	# Exatamente no corte: 0,05 NÃO é significativo (o teste é `< 0.05`).
	igual_texto("p = 0,05 fica de fora", Stats.significancia(0.05), "NÃO significativo")

	igual_texto("d = 0,1", Stats.efeito_texto(0.1), "desprezível")
	igual_texto("d = 0,3", Stats.efeito_texto(0.3), "pequeno")
	igual_texto("d = 0,6", Stats.efeito_texto(0.6), "médio")
	igual_texto("d = 1,2", Stats.efeito_texto(1.2), "grande")
	# O tamanho de efeito é sobre magnitude: o sinal não muda a leitura.
	igual_texto("d negativo lê pela magnitude", Stats.efeito_texto(-1.2), "grande")
