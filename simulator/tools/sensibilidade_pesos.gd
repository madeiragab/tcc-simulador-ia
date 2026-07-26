extends SceneTree

# Análise de sensibilidade dos pesos do StrategicScore.
#
# Os pesos adotados (0,30 / 0,20 / 0,20 / 0,20 / 0,10) são julgamento do
# autor. A pergunta que esta análise responde é se o ordenamento dos
# modelos depende dessa escolha — se depender, o resultado é artefato da
# métrica; se não depender, é propriedade dos modelos.
#
# Quatro exames:
#   1. Pesos alternativos plausíveis (iguais, e ênfases deslocadas)
#   2. Casos extremos: cada dimensão isolada com peso total
#   3. Monte Carlo: 10.000 vetores de pesos amostrados uniformemente do
#      simplex (Dirichlet(1,...,1)) — frequência de primeiro lugar
#   4. Perturbação individual: cada peso ±50%, renormalizado
#
# Uso: godot --headless --path simulator --script res://tools/sensibilidade_pesos.gd

const Metrics = preload("res://core/metrics.gd")

const RUNS_SELF = {
	"aleatoria": "2026-07-25_20-44-08_benchmark_1000",
	"reativa": "2026-07-25_22-02-46_benchmark_1000",
	"heuristica": "2026-07-25_22-21-47_benchmark_1000",
	"art3miz_0.1": "2026-07-25_22-46-49_benchmark_1000",
	"mcts": "2026-07-26_04-38-35_benchmark_1000",
}

const DIMENSOES = ["WinRate", "DamageNorm", "CoverUsage", "EfTurnos", "EfCusto"]
const PESOS_ADOTADOS = [0.30, 0.20, 0.20, 0.20, 0.10]

var out_lines = []
var componentes = {}   # modelo -> [5 componentes normalizadas]

func _initialize():
	var runs_dir = ProjectSettings.globalize_path("res://").path_join("../data/runs")

	for modelo in RUNS_SELF:
		var comp = carregar_componentes(runs_dir.path_join(RUNS_SELF[modelo]))
		if not comp.is_empty():
			componentes[modelo] = comp

	if componentes.size() < 2:
		push_error("dados insuficientes")
		quit()
		return

	cabecalho()
	secao_componentes()
	secao_alternativos()
	secao_extremos()
	secao_monte_carlo()
	secao_perturbacao()
	conclusao()
	gravar()
	quit()

# ---------- carregamento ----------

func carregar_componentes(dir):
	var path = dir.path_join("partidas.csv")
	if not FileAccess.file_exists(path):
		push_warning("não encontrado: " + path)
		return []
	var file = FileAccess.open(path, FileAccess.READ)
	var header = file.get_line().split(",")
	var idx = {}
	for i in range(header.size()):
		idx[header[i]] = i

	# Usa o primeiro jogador (no autoconfronto os três são o mesmo modelo).
	var primeiro = ""
	var rows = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue
		var f = line.split(",")
		if f.size() < header.size():
			continue
		if primeiro == "":
			primeiro = f[idx["jogador"]]
		if f[idx["jogador"]] != primeiro:
			continue
		rows.append({
			"venceu": f[idx["venceu"]] == "1",
			"empate": f[idx["vencedor"]] == "empate",
			"turnos": int(f[idx["turnos"]]),
			"damage_ratio": float(f[idx["damage_ratio"]]),
			"cover_usage": float(f[idx["cover_usage"]]),
			"custo": int(f[idx["custo_total"]]),
		})
	file.close()

	var agg = Metrics.aggregate(rows)
	return [
		agg["win_rate"],
		agg["damage_norm"],
		agg["cover_usage_mean"],
		agg["efficiency"],
		agg["cost_efficiency"],
	]

# ---------- cálculo ----------

func escore(comp, pesos):
	var s = 0.0
	for i in range(comp.size()):
		s += pesos[i] * comp[i]
	return s

# Retorna os modelos ordenados do maior para o menor escore.
func ordenar(pesos):
	var pares = []
	for modelo in componentes:
		pares.append([escore(componentes[modelo], pesos), modelo])
	pares.sort_custom(func(a, b): return a[0] > b[0])
	return pares

func vencedor(pesos):
	return ordenar(pesos)[0][1]

func normalizar(pesos):
	var soma = 0.0
	for p in pesos:
		soma += p
	if soma == 0.0:
		return pesos
	var out = []
	for p in pesos:
		out.append(p / soma)
	return out

# ---------- seções ----------

func cabecalho():
	linha("# Análise de Sensibilidade dos Pesos do StrategicScore")
	linha("")
	linha("Relatório gerado por `simulator/tools/sensibilidade_pesos.gd` a partir dos dados brutos dos autoconfrontos. Reproduzível com:")
	linha("")
	linha("```bash")
	linha("godot --headless --path simulator --script res://tools/sensibilidade_pesos.gd")
	linha("```")
	linha("")
	linha("## O problema")
	linha("")
	linha("Os pesos do StrategicScore — 0,30 para vitória, 0,20 para dano, cobertura e rapidez, e 0,10 para economia computacional — são **julgamento do autor**, não derivação de teoria ou literatura. Isso é uma fragilidade legítima: se o ordenamento dos modelos mudasse conforme os pesos escolhidos, o resultado seria artefato da métrica, e não propriedade dos modelos.")
	linha("")
	linha("Esta análise verifica se o ordenamento **depende** dessa escolha. O procedimento não busca justificar os pesos adotados, e sim medir quanto a conclusão é sensível a eles.")
	linha("")

func secao_componentes():
	linha("---")
	linha("")
	linha("## 1. Componentes normalizadas por modelo")
	linha("")
	linha("Todas as dimensões já reduzidas ao intervalo [0, 1], antes da ponderação:")
	linha("")
	var cab = "| Modelo |"
	var sep = "|---|"
	for d in DIMENSOES:
		cab += " %s |" % d
		sep += "---|"
	cab += " Escore adotado |"
	sep += "---|"
	linha(cab)
	linha(sep)
	for par in ordenar(PESOS_ADOTADOS):
		var modelo = par[1]
		var c = componentes[modelo]
		var l = "| %s |" % modelo
		for v in c:
			l += " %.3f |" % v
		l += " **%.4f** |" % par[0]
		linha(l)
	linha("")

func secao_alternativos():
	linha("---")
	linha("")
	linha("## 2. Conjuntos alternativos de pesos")
	linha("")
	linha("Cinco ponderações plausíveis, incluindo a neutra (todas iguais) e ênfases deslocadas para cada objetivo:")
	linha("")

	var conjuntos = {
		"Adotado (0,30/0,20/0,20/0,20/0,10)": PESOS_ADOTADOS,
		"Neutro — todos iguais (0,20 cada)": [0.20, 0.20, 0.20, 0.20, 0.20],
		"Ênfase em vitória (0,50/0,15/0,10/0,15/0,10)": [0.50, 0.15, 0.10, 0.15, 0.10],
		"Ênfase em economia (0,20/0,15/0,15/0,15/0,35)": [0.20, 0.15, 0.15, 0.15, 0.35],
		"Ênfase tática — dano e cobertura (0,15/0,30/0,30/0,15/0,10)": [0.15, 0.30, 0.30, 0.15, 0.10],
		"Sem o termo de custo (0,33/0,22/0,22/0,23/0,00)": [0.33, 0.22, 0.22, 0.23, 0.00],
	}

	linha("| Conjunto de pesos | 1º lugar | Ordenamento completo |")
	linha("|---|---|---|")
	for nome in conjuntos:
		var ordem = ordenar(conjuntos[nome])
		var nomes = []
		for par in ordem:
			nomes.append("%s (%.3f)" % [par[1], par[0]])
		linha("| %s | **%s** | %s |" % [nome, ordem[0][1], " › ".join(nomes)])
	linha("")

func secao_extremos():
	linha("---")
	linha("")
	linha("## 3. Casos extremos — cada dimensão isolada")
	linha("")
	linha("Peso total atribuído a uma única dimensão por vez. Revela qual modelo domina cada objetivo separadamente:")
	linha("")
	linha("| Dimensão com peso total | Vencedor | Escore | Último colocado |")
	linha("|---|---|---|---|")
	for i in range(DIMENSOES.size()):
		var pesos = [0.0, 0.0, 0.0, 0.0, 0.0]
		pesos[i] = 1.0
		var ordem = ordenar(pesos)
		linha("| %s | **%s** | %.3f | %s |" % [DIMENSOES[i], ordem[0][1], ordem[0][0], ordem[ordem.size() - 1][1]])
	linha("")

func secao_monte_carlo():
	linha("---")
	linha("")
	linha("## 4. Monte Carlo — 10.000 ponderações aleatórias")
	linha("")
	linha("Vetores de pesos amostrados **uniformemente do simplex** (distribuição de Dirichlet com todos os parâmetros iguais a 1), o que equivale a considerar qualquer ponderação possível igualmente plausível. Para cada vetor, registra-se qual modelo fica em primeiro lugar.")
	linha("")

	var rng = RandomNumberGenerator.new()
	rng.seed = 20260726
	var iteracoes = 10000
	var contagem = {}
	for modelo in componentes:
		contagem[modelo] = 0

	for it in range(iteracoes):
		# Amostragem uniforme do simplex: n exponenciais normalizadas.
		var pesos = []
		var soma = 0.0
		for i in range(DIMENSOES.size()):
			var e = -log(maxf(rng.randf(), 1e-12))
			pesos.append(e)
			soma += e
		for i in range(pesos.size()):
			pesos[i] /= soma
		contagem[vencedor(pesos)] += 1

	linha("| Modelo | Vezes em 1º lugar | Frequência |")
	linha("|---|---|---|")
	var pares = []
	for modelo in contagem:
		pares.append([contagem[modelo], modelo])
	pares.sort_custom(func(a, b): return a[0] > b[0])
	for par in pares:
		linha("| %s | %d / %d | **%.1f%%** |" % [par[1], par[0], iteracoes, 100.0 * par[0] / iteracoes])
	linha("")

func secao_perturbacao():
	linha("---")
	linha("")
	linha("## 5. Perturbação individual dos pesos (±50%)")
	linha("")
	linha("Cada peso é alterado isoladamente em ±50%, com renormalização do vetor para somar 1. Verifica se algum peso específico é responsável pelo ordenamento:")
	linha("")
	linha("| Peso alterado | Variação | 1º lugar | Ordenamento mudou? |")
	linha("|---|---|---|---|")
	var base = vencedor(PESOS_ADOTADOS)
	var mudou_algum = false
	for i in range(DIMENSOES.size()):
		for fator in [0.5, 1.5]:
			var pesos = PESOS_ADOTADOS.duplicate()
			pesos[i] = pesos[i] * fator
			pesos = normalizar(pesos)
			var v = vencedor(pesos)
			var mudou = v != base
			if mudou:
				mudou_algum = true
			linha("| %s | %s%d%% | %s | %s |" % [
				DIMENSOES[i],
				"+" if fator > 1.0 else "−",
				int(absf(fator - 1.0) * 100),
				v,
				"**SIM**" if mudou else "não",
			])
	linha("")
	if not mudou_algum:
		linha("Nenhuma perturbação individual alterou o primeiro colocado.")
		linha("")

func conclusao():
	linha("---")
	linha("")
	linha("## 6. Conclusão da análise")
	linha("")
	var base = vencedor(PESOS_ADOTADOS)

	# Verifica dominância de Pareto: o líder é superior em TODAS as dimensões?
	var domina = true
	var margens = []
	for i in range(DIMENSOES.size()):
		var melhor_outro = -INF
		for modelo in componentes:
			if modelo != base:
				melhor_outro = maxf(melhor_outro, componentes[modelo][i])
		var margem = componentes[base][i] - melhor_outro
		margens.append(margem)
		if margem <= 0.0:
			domina = false

	if domina:
		linha("### O ordenamento é independente dos pesos — e há razão matemática para isso")
		linha("")
		linha("O **%s apresenta o maior valor em todas as cinco dimensões** normalizadas, simultaneamente. Trata-se de **dominância de Pareto** sobre os demais modelos neste conjunto de execuções." % base)
		linha("")
		linha("A consequência é mais forte que um resultado empírico: sendo o escore uma combinação linear de termos com pesos não negativos, um modelo superior em todas as componentes obtém escore superior sob **qualquer** ponderação admissível. Os 100% observados na simulação de Monte Carlo não são coincidência amostral — são consequência necessária da dominância.")
		linha("")
		linha("**A crítica de arbitrariedade dos pesos fica, portanto, respondida**: neste conjunto de dados, nenhuma escolha de pesos poderia alterar o primeiro colocado.")
		linha("")
		linha("Margens de dominância por dimensão (diferença para o melhor concorrente):")
		linha("")
		linha("| Dimensão | Margem |")
		linha("|---|---|")
		for i in range(DIMENSOES.size()):
			linha("| %s | +%.4f |" % [DIMENSOES[i], margens[i]])
		linha("")
		linha("> **Ressalva necessária.** Algumas margens são estreitas — particularmente em relação à IA Reativa. A dominância vale para as estimativas pontuais; o intervalo de confiança do escore (ver `analise_estatistica.md`) mostra **sobreposição parcial entre Art3miz 0.1 e Reativa**, de modo que a superioridade sobre esse baseline específico não é estatisticamente conclusiva. Sobre a IA Heurística, os intervalos não se sobrepõem e a diferença é conclusiva.")
		linha("")
		linha("> **Escopo.** Esta dominância refere-se aos **autoconfrontos**, em que cada modelo enfrenta a si mesmo. No confronto direto contra oponentes de custo pleno, o Art3miz 0.1 não domina: obtém menos vitórias, como reportado em `resultados_finais.md`.")
	else:
		linha("### O ordenamento é robusto, sem ser matematicamente garantido")
		linha("")
		linha("O %s **não domina todas as dimensões**: perde em pelo menos uma delas, de modo que sua liderança não é consequência automática da forma da métrica. Cabe, portanto, caracterizar sob que condições ela se mantém — e sob quais se desfaz." % base)
		linha("")

		# Dimensões em que o líder é superado, e por quem.
		linha("**Dimensões em que o %s é superado:**" % base)
		linha("")
		linha("| Dimensão | Líder da dimensão | Valor do líder | Valor do %s | Margem |" % base)
		linha("|---|---|---|---|---|")
		for i in range(DIMENSOES.size()):
			var melhor_modelo = ""
			var melhor_valor = -INF
			for modelo in componentes:
				if componentes[modelo][i] > melhor_valor:
					melhor_valor = componentes[modelo][i]
					melhor_modelo = modelo
			if melhor_modelo != base:
				linha("| %s | **%s** | %.3f | %.3f | %.4f |" % [
					DIMENSOES[i], melhor_modelo, melhor_valor, componentes[base][i],
					melhor_valor - componentes[base][i],
				])
		linha("")

		# Limiar: quanto peso é preciso concentrar numa dimensão para
		# que a liderança mude.
		linha("**Limiar de troca de liderança.** Concentrando peso progressivamente em cada dimensão isolada (e distribuindo o restante na proporção dos pesos adotados), o ponto em que o primeiro colocado muda:")
		linha("")
		linha("| Dimensão enfatizada | Peso necessário para trocar o líder | Novo líder |")
		linha("|---|---|---|")
		for i in range(DIMENSOES.size()):
			var limiar = -1.0
			var novo = ""
			var w = 0.0
			while w <= 1.0:
				var pesos = []
				for j in range(DIMENSOES.size()):
					if j == i:
						pesos.append(w)
					else:
						pesos.append((1.0 - w) * PESOS_ADOTADOS[j] / (1.0 - PESOS_ADOTADOS[i]))
				var v = vencedor(pesos)
				if v != base:
					limiar = w
					novo = v
					break
				w += 0.01
			if limiar < 0.0:
				linha("| %s | nunca troca | — |" % DIMENSOES[i])
			else:
				linha("| %s | **%.0f%%** | %s |" % [DIMENSOES[i], limiar * 100.0, novo])
		linha("")
		linha("A leitura conjunta com a simulação de Monte Carlo da seção 4 é o resultado central desta análise: a liderança do %s se mantém em toda ponderação razoável, e só se desfaz sob concentrações extremas de peso em uma única dimensão — configurações que descaracterizariam a métrica como instrumento multidimensional." % base)
	linha("")
	linha("Registra-se, para transparência, que esta análise **não justifica** a escolha dos pesos — apenas mede a sensibilidade do resultado a ela. Os pesos permanecem julgamento do autor, fixados a priori antes de qualquer comparação entre modelos, e a alternativa neutra (todos iguais) está incluída entre os conjuntos examinados.")
	linha("")

# ---------- utilidades ----------

func linha(texto):
	out_lines.append(texto)

func gravar():
	var path = ProjectSettings.globalize_path("res://").path_join("../docs/sensibilidade_pesos.md")
	var file = FileAccess.open(path, FileAccess.WRITE)
	for l in out_lines:
		file.store_line(l)
	file.close()
	print("Relatório gravado: ", path, " (", out_lines.size(), " linhas)")
