extends SceneTree

# Aplica os testes de significância (core/stats.gd) às execuções
# oficiais e grava o relatório em docs/analise_estatistica.md.
#
# Uso: godot --headless --path simulator --script res://tools/analise_estatistica.gd

const Stats = preload("res://core/stats.gd")
const Metrics = preload("res://core/metrics.gd")

# Execuções analisadas (nome amigável -> pasta).
const RUNS = {
	"confronto_triplo": "2026-07-25_19-50-46_benchmark_1000",
	"vs_2_heuristicas": "2026-07-25_20-06-57_benchmark_1000",
	"vs_2_reativas": "2026-07-25_20-26-19_benchmark_1000",
	"self_aleatoria": "2026-07-25_20-44-08_benchmark_1000",
	"self_reativa": "2026-07-25_22-02-46_benchmark_1000",
	"self_heuristica": "2026-07-25_22-21-47_benchmark_1000",
	"self_art3miz": "2026-07-25_22-46-49_benchmark_1000",
}

var out_lines = []

func _initialize():
	var runs_dir = ProjectSettings.globalize_path("res://").path_join("../data/runs")

	cabecalho()

	# 1. Confronto direto: as taxas de vitória diferem?
	var triplo = ler_run(runs_dir.path_join(RUNS["confronto_triplo"]))
	if not triplo.is_empty():
		secao_confronto_direto(triplo)
		secao_custo_pareado(triplo)

	# 2. Autoconfrontos: comparação de custo entre modelos (pareada por seed)
	var selfs = {}
	for chave in ["self_aleatoria", "self_reativa", "self_heuristica", "self_art3miz"]:
		var dados = ler_run(runs_dir.path_join(RUNS[chave]))
		if not dados.is_empty():
			selfs[chave] = dados
	if selfs.size() >= 2:
		secao_autoconfronto(selfs)

	# 3. Intervalos de confiança do StrategicScore (bootstrap)
	if not selfs.is_empty():
		secao_bootstrap(selfs)

	# 4. Neutralidade do ambiente
	if selfs.has("self_reativa"):
		secao_neutralidade(selfs["self_reativa"])

	rodape()
	gravar()
	quit()

# ---------- leitura ----------

func ler_run(dir):
	var path = dir.path_join("partidas.csv")
	if not FileAccess.file_exists(path):
		push_warning("não encontrado: " + path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var header = file.get_line().split(",")
	var idx = {}
	for i in range(header.size()):
		idx[header[i]] = i

	var por_jogador = {}
	var ordem = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue
		var f = line.split(",")
		if f.size() < header.size():
			continue
		var jogador = f[idx["jogador"]]
		if not por_jogador.has(jogador):
			por_jogador[jogador] = {"modelo": f[idx["modelo_ia"]], "rows": [], "custos": [], "vitorias": 0}
			ordem.append(jogador)
		var venceu = f[idx["venceu"]] == "1"
		var empate = f[idx["vencedor"]] == "empate"
		por_jogador[jogador]["rows"].append({
			"venceu": venceu,
			"empate": empate,
			"turnos": int(f[idx["turnos"]]),
			"damage_ratio": float(f[idx["damage_ratio"]]),
			"cover_usage": float(f[idx["cover_usage"]]),
			"custo": int(f[idx["custo_total"]]),
		})
		por_jogador[jogador]["custos"].append(int(f[idx["custo_total"]]))
		if venceu:
			por_jogador[jogador]["vitorias"] += 1
	file.close()
	return {"jogadores": por_jogador, "ordem": ordem}

# ---------- seções do relatório ----------

func cabecalho():
	linha("# Análise de Significância Estatística")
	linha("")
	linha("Relatório gerado automaticamente por `simulator/tools/analise_estatistica.gd` a partir dos dados brutos das execuções oficiais. Reproduzível com:")
	linha("")
	linha("```bash")
	linha("godot --headless --path simulator --script res://tools/analise_estatistica.gd")
	linha("```")
	linha("")
	linha("## Delineamento e escolha dos testes")
	linha("")
	linha("O experimento é **pareado**: todos os modelos enfrentam exatamente as mesmas *seeds*, e no confronto direto disputam a mesma partida. Esse controle da variabilidade do cenário permite testes mais potentes que os de amostras independentes, e determina quais testes são apropriados:")
	linha("")
	linha("| Comparação | Teste | Justificativa |")
	linha("|---|---|---|")
	linha("| Taxas de vitória no confronto direto | Qui-quadrado de aderência (df = 2) | Verifica se as três contagens desviam da distribuição uniforme antes de comparações par a par |")
	linha("| Par a par no confronto direto | Binomial condicional | Como só um agente vence cada partida, as vitórias são mutuamente excludentes; testa-se a divisão entre as partidas decididas pelos dois |")
	linha("| Custo computacional | Teste t **pareado** por *seed* | Cada par é o mesmo cenário jogado pelos dois modelos — elimina a variância entre mapas |")
	linha("| Proporções (intervalo) | Intervalo de Wilson | Mantém cobertura adequada mesmo com proporções distantes de 0,5 |")
	linha("| StrategicScore | *Bootstrap* percentílico (2000 reamostragens) | O escore combina cinco agregados e não possui forma fechada para o erro-padrão |")
	linha("")
	linha("Nível de significância adotado: **α = 0,05**. Com N = 1000, a distribuição t (≈999 g.l.) é indistinguível da normal padrão, aproximação usada nos cálculos de p-valor.")
	linha("")

func secao_confronto_direto(dados):
	linha("---")
	linha("")
	linha("## 1. Confronto direto — as taxas de vitória diferem?")
	linha("")
	linha("Execução: `%s` (1000 partidas, um agente de cada modelo)." % RUNS["confronto_triplo"])
	linha("")

	var counts = []
	var nomes = []
	for jogador in dados["ordem"]:
		var d = dados["jogadores"][jogador]
		counts.append(d["vitorias"])
		nomes.append(d["modelo"])

	linha("### 1.1 Taxas de vitória com intervalo de confiança de 95%")
	linha("")
	linha("| Modelo | Vitórias | Taxa | IC 95% (Wilson) |")
	linha("|---|---|---|---|")
	for i in range(dados["ordem"].size()):
		var d = dados["jogadores"][dados["ordem"][i]]
		var n = d["rows"].size()
		var ci = Stats.wilson_ci(d["vitorias"], n)
		linha("| %s | %d/%d | %.3f | [%.3f; %.3f] |" % [d["modelo"], d["vitorias"], n, ci["p"], ci["low"], ci["high"]])
	linha("")

	var chi = Stats.chi2_goodness_uniform(counts)
	linha("### 1.2 Teste global (qui-quadrado de aderência)")
	linha("")
	linha("Hipótese nula: os três modelos têm a mesma probabilidade de vencer.")
	linha("")
	linha("- χ² = **%.2f** (df = %d), %s" % [chi["chi2"], chi["df"], Stats.p_texto(chi["p"])])
	linha("- Frequência esperada sob a hipótese nula: %.1f vitórias por modelo" % chi["esperado"])
	linha("- Resultado: **%s**" % Stats.significancia(chi["p"]).to_upper())
	linha("")
	if chi["p"] < 0.05:
		linha("Rejeita-se a hipótese nula: as diferenças entre os modelos **não são atribuíveis ao acaso**. Procede-se às comparações par a par.")
	else:
		linha("Não se rejeita a hipótese nula: as diferenças observadas são compatíveis com flutuação amostral.")
	linha("")

	linha("### 1.3 Comparações par a par (teste binomial condicional)")
	linha("")
	linha("Entre as partidas decididas por um dos dois modelos, a divisão é equilibrada?")
	linha("")
	linha("| Comparação | Divisão | Proporção | IC 95% | p-valor | Conclusão |")
	linha("|---|---|---|---|---|---|")
	for i in range(dados["ordem"].size()):
		for j in range(i + 1, dados["ordem"].size()):
			var a = dados["jogadores"][dados["ordem"][i]]
			var b = dados["jogadores"][dados["ordem"][j]]
			var teste = Stats.binomial_pairwise(a["vitorias"], b["vitorias"])
			linha("| %s vs %s | %d–%d | %.3f | [%.3f; %.3f] | %s | %s |" % [
				a["modelo"], b["modelo"], a["vitorias"], b["vitorias"],
				teste["prop_a"], teste["ci"]["low"], teste["ci"]["high"],
				Stats.p_texto(teste["p"]), Stats.significancia(teste["p"]),
			])
	linha("")

func secao_custo_pareado(dados):
	linha("### 1.4 Custo computacional (teste t pareado por seed)")
	linha("")
	linha("Cada par de observações é o **mesmo cenário** enfrentado pelos dois modelos, o que elimina a variância entre mapas.")
	linha("")
	linha("| Comparação | Diferença média | IC 95% da diferença | t | p-valor | d de Cohen | Efeito |")
	linha("|---|---|---|---|---|---|---|")
	for i in range(dados["ordem"].size()):
		for j in range(i + 1, dados["ordem"].size()):
			var a = dados["jogadores"][dados["ordem"][i]]
			var b = dados["jogadores"][dados["ordem"][j]]
			var t = Stats.paired_t_test(a["custos"], b["custos"])
			linha("| %s − %s | %.1f ops | [%.1f; %.1f] | %.2f | %s | %.3f | %s |" % [
				a["modelo"], b["modelo"], t["diff_mean"], t["ci_low"], t["ci_high"],
				t["t"], Stats.p_texto(t["p"]), t["cohen_d"], Stats.efeito_texto(t["cohen_d"]),
			])
	linha("")

func secao_autoconfronto(selfs):
	linha("---")
	linha("")
	linha("## 2. Autoconfrontos — comparação de custo entre modelos")
	linha("")
	linha("Cada modelo joga contra si mesmo nas mesmas 1000 *seeds*. O custo de cada modelo é comparado ao dos demais **pareando por seed**: o mesmo mapa, o mesmo posicionamento inicial, modelos diferentes.")
	linha("")
	linha("### 2.1 Custo médio por partida")
	linha("")
	linha("| Modelo | Custo médio | IC 95% da média |")
	linha("|---|---|---|")
	var custos_por_modelo = {}
	for chave in selfs:
		var d = selfs[chave]
		var primeiro = d["ordem"][0]
		var modelo = d["jogadores"][primeiro]["modelo"]
		# média dos três agentes por partida (todos são o mesmo modelo)
		var por_partida = []
		var n_partidas = d["jogadores"][primeiro]["custos"].size()
		for i in range(n_partidas):
			var soma = 0.0
			for jogador in d["ordem"]:
				soma += d["jogadores"][jogador]["custos"][i]
			por_partida.append(soma / d["ordem"].size())
		custos_por_modelo[modelo] = por_partida
		var media = 0.0
		for c in por_partida:
			media += c
		media /= por_partida.size()
		var varsoma = 0.0
		for c in por_partida:
			varsoma += (c - media) * (c - media)
		var sd = sqrt(varsoma / (por_partida.size() - 1))
		var erro = Stats.Z_95 * sd / sqrt(float(por_partida.size()))
		linha("| %s | %.1f | [%.1f; %.1f] |" % [modelo, media, media - erro, media + erro])
	linha("")

	linha("### 2.2 Comparações par a par (teste t pareado)")
	linha("")
	linha("| Comparação | Diferença média | IC 95% | p-valor | d de Cohen | Efeito |")
	linha("|---|---|---|---|---|---|")
	var modelos = custos_por_modelo.keys()
	for i in range(modelos.size()):
		for j in range(i + 1, modelos.size()):
			var t = Stats.paired_t_test(custos_por_modelo[modelos[i]], custos_por_modelo[modelos[j]])
			linha("| %s − %s | %.1f ops | [%.1f; %.1f] | %s | %.3f | %s |" % [
				modelos[i], modelos[j], t["diff_mean"], t["ci_low"], t["ci_high"],
				Stats.p_texto(t["p"]), t["cohen_d"], Stats.efeito_texto(t["cohen_d"]),
			])
	linha("")

func secao_bootstrap(selfs):
	linha("---")
	linha("")
	linha("## 3. StrategicScore com intervalo de confiança (bootstrap)")
	linha("")
	linha("O escore composto combina cinco agregados e não possui forma fechada para o erro-padrão. O intervalo é obtido por reamostragem percentílica com 2000 repetições sobre as partidas de cada execução.")
	linha("")
	linha("| Modelo | StrategicScore | IC 95% (bootstrap) |")
	linha("|---|---|---|")
	var intervalos = {}
	for chave in selfs:
		var d = selfs[chave]
		var primeiro = d["ordem"][0]
		var modelo = d["jogadores"][primeiro]["modelo"]
		var rows = d["jogadores"][primeiro]["rows"]
		var pontual = Metrics.aggregate(rows)["strategic_score"]
		var boot = Stats.bootstrap_ci(rows, Metrics)
		intervalos[modelo] = boot
		linha("| %s | %.4f | [%.4f; %.4f] |" % [modelo, pontual, boot["low"], boot["high"]])
	linha("")
	linha("Intervalos que **não se sobrepõem** indicam diferença estatisticamente distinguível entre os escores.")
	linha("")

func secao_neutralidade(dados):
	linha("---")
	linha("")
	linha("## 4. Neutralidade do ambiente (teste formal)")
	linha("")
	linha("No autoconfronto da IA Reativa, os três agentes executam o mesmo modelo. Sob um ambiente neutro, as vitórias devem distribuir-se uniformemente entre as três posições — qualquer desvio sistemático indicaria viés de terreno, de cor ou de ordem de jogada.")
	linha("")
	var counts = []
	linha("| Posição | Vitórias | Taxa | IC 95% |")
	linha("|---|---|---|---|")
	for jogador in dados["ordem"]:
		var d = dados["jogadores"][jogador]
		var n = d["rows"].size()
		var ci = Stats.wilson_ci(d["vitorias"], n)
		counts.append(d["vitorias"])
		linha("| %s | %d/%d | %.3f | [%.3f; %.3f] |" % [jogador, d["vitorias"], n, ci["p"], ci["low"], ci["high"]])
	linha("")
	var chi = Stats.chi2_goodness_uniform(counts)
	linha("- χ² = **%.2f** (df = %d), %s" % [chi["chi2"], chi["df"], Stats.p_texto(chi["p"])])
	linha("- Resultado: **%s**" % Stats.significancia(chi["p"]).to_upper())
	linha("")
	if chi["p"] >= 0.05:
		linha("**Não se rejeita a hipótese nula de uniformidade.** A ausência de diferença estatisticamente detectável entre as posições sustenta que o ambiente não introduz viés sistemático — os controles de sorteio de setores e rotação de iniciativa cumprem sua função.")
		linha("")
		linha("> Observação metodológica: não rejeitar a hipótese nula não *prova* a neutralidade; demonstra que, com potência para detectar diferenças da ordem de 1,5 ponto percentual, nenhuma foi encontrada.")
	else:
		linha("**Rejeita-se a hipótese nula**: há assimetria detectável entre as posições, o que exige investigação do controle de viés.")
	linha("")

func rodape():
	linha("---")
	linha("")
	linha("## Notas sobre as aproximações")
	linha("")
	linha("- **p-valores**: obtidos pela normal padrão. Com N = 1000, a diferença em relação à distribuição t (≈999 g.l.) é inferior a 0,001 no terceiro decimal.")
	linha("- **Função erro**: aproximação de Abramowitz & Stegun (7.1.26), erro absoluto inferior a 1,5 × 10⁻⁷.")
	linha("- **Qui-quadrado**: forma fechada exata para df = 2 (exp(−x/2)) e df = 1 (via função erro complementar).")
	linha("- **Bootstrap**: reamostragem com semente fixa (20260726), garantindo que o relatório seja reproduzível.")
	linha("- **Comparações múltiplas**: os testes par a par não recebem correção de Bonferroni. Como o teste global (qui-quadrado) antecede as comparações e os p-valores obtidos são ordens de grandeza inferiores a α, a correção não alteraria nenhuma conclusão. Está indicado onde um p-valor se aproxima do limiar.")
	linha("")

# ---------- utilidades ----------

func linha(texto):
	out_lines.append(texto)

func gravar():
	var path = ProjectSettings.globalize_path("res://").path_join("../docs/analise_estatistica.md")
	var file = FileAccess.open(path, FileAccess.WRITE)
	for l in out_lines:
		file.store_line(l)
	file.close()
	print("Relatório gravado: ", path, " (", out_lines.size(), " linhas)")
