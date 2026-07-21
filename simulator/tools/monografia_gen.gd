extends SceneTree

# Gera o Projeto de TCC em .docx seguindo o MODELO INSTITUCIONAL do
# IFSULDEMINAS (docs/monograma/Mod1_LucasMatthes_ProfaAline.pdf):
# capa institucional, Informações Gerais, seções numeradas 1-9,
# cronograma mensal, número de página no rodapé.
#
# Fórmulas ficam no texto como $$...$$ (LaTeX) para serem renderizadas
# como imagem pela extensão Auto-LaTeX Equations do Google Docs.
#
# Uso:
#   godot --headless --path simulator --script res://tools/monografia_gen.gd
# Saída: monografia/Monografia_TCC_Gabriel_Madeira.docx (raiz do repo).

const CM = 567  # twips por cm
const INDENT = 709  # 1,25 cm

func _initialize():
	build()
	quit()

# ---------- helpers XML ----------

func esc(t):
	return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

func run(text, opts = {}):
	var pr = ""
	if opts.get("b", false):
		pr += '<w:b/>'
	if opts.get("i", false):
		pr += '<w:i/>'
	pr += '<w:sz w:val="%d"/><w:szCs w:val="%d"/>' % [opts.get("sz", 24), opts.get("sz", 24)]
	if opts.get("hl", false):
		pr += '<w:highlight w:val="yellow"/>'
	return '<w:r><w:rPr>%s</w:rPr><w:t xml:space="preserve">%s</w:t></w:r>' % [pr, esc(text)]

func par(runs, opts = {}):
	var pr = ""
	if opts.has("style"):
		pr += '<w:pStyle w:val="%s"/>' % opts["style"]
	if opts.get("pagebreak", false):
		pr += '<w:pageBreakBefore/>'
	var spacing = '<w:spacing w:line="%d" w:lineRule="auto"' % opts.get("line", 360)
	if opts.has("before"):
		spacing += ' w:before="%d"' % opts["before"]
	if opts.has("after"):
		spacing += ' w:after="%d"' % opts["after"]
	spacing += '/>'
	pr += spacing
	var ind = ""
	if opts.has("first"):
		ind += ' w:firstLine="%d"' % opts["first"]
	if opts.has("left"):
		ind += ' w:left="%d"' % opts["left"]
	if ind != "":
		pr += '<w:ind%s/>' % ind
	pr += '<w:jc w:val="%s"/>' % opts.get("align", "both")
	# sectPr deve ser o último filho de pPr (ordem do schema OOXML)
	if opts.has("sectpr"):
		pr += opts["sectpr"]
	var body = runs if runs is String else "".join(runs)
	return '<w:p><w:pPr>%s</w:pPr>%s</w:p>' % [pr, body]

func p(text_or_runs, opts = {}):
	var o = opts.duplicate()
	if not o.has("first"):
		o["first"] = INDENT
	var runs = text_or_runs if not (text_or_runs is String) else [run(text_or_runs)]
	return par(runs, o)

func pc(text, opts = {}):
	var o = opts.duplicate()
	o["align"] = "center"
	var runs = text if not (text is String) else [run(text)]
	return par(runs, o)

# seção principal do modelo: "1. ANTECEDENTES..." em caixa alta e negrito
func h1(text, pagebreak = false):
	return par([run(text.to_upper(), {"b": true})], {"style": "Heading1", "pagebreak": pagebreak, "before": 240, "after": 240})

# subseção: "2.1. Título" em negrito
func h2(text):
	return par([run(text, {"b": true})], {"style": "Heading2", "before": 240, "after": 120})

func h3(text):
	return par([run(text, {"b": true})], {"style": "Heading3", "before": 240, "after": 120})

# fórmula em notação LaTeX $$...$$ (renderizada pela extensão Auto-LaTeX)
func formula(latex):
	return par([run(latex)], {"align": "center", "before": 120, "after": 120})

func refp(runs):
	return par(runs, {"align": "left", "line": 240, "after": 240})

func ph(text):
	return run(text, {"hl": true})

func table(caption, headers, rows, widths_cm, caption_above = true):
	var widths = []
	for w in widths_cm:
		widths.append(int(round(w * CM)))
	var total = 0
	for w in widths:
		total += w
	var xml = ""
	if caption != "" and caption_above:
		xml += par([run(caption, {"sz": 20})], {"align": "center", "line": 240, "before": 240})
	var borders = '<w:tblBorders><w:top w:val="single" w:sz="4" w:color="000000"/><w:left w:val="single" w:sz="4" w:color="000000"/><w:bottom w:val="single" w:sz="4" w:color="000000"/><w:right w:val="single" w:sz="4" w:color="000000"/><w:insideH w:val="single" w:sz="4" w:color="000000"/><w:insideV w:val="single" w:sz="4" w:color="000000"/></w:tblBorders>'
	xml += '<w:tbl><w:tblPr><w:tblW w:w="%d" w:type="dxa"/><w:jc w:val="center"/>%s</w:tblPr><w:tblGrid>' % [total, borders]
	for w in widths:
		xml += '<w:gridCol w:w="%d"/>' % w
	xml += '</w:tblGrid>'
	xml += table_row(headers, widths, true)
	for row in rows:
		xml += table_row(row, widths, false)
	xml += '</w:tbl>'
	if caption != "" and not caption_above:
		xml += par([run(caption, {"sz": 20})], {"align": "center", "line": 240})
	xml += par([run("Fonte: elaborado pelo autor (2026).", {"sz": 20})], {"align": "center", "line": 240, "after": 240})
	return xml

func table_row(cells, widths, header):
	var xml = "<w:tr>"
	for i in range(cells.size()):
		var shade = '<w:shd w:val="clear" w:fill="E8E8E8"/>' if header else ""
		var cell_par = par([run(str(cells[i]), {"b": header, "sz": 20})], {"align": "center", "line": 240})
		xml += '<w:tc><w:tcPr><w:tcW w:w="%d" w:type="dxa"/>%s</w:tcPr>%s</w:tc>' % [widths[i], shade, cell_par]
	xml += "</w:tr>"
	return xml

# ---------- conteúdo ----------

func build():
	var parts = []

	# ===== CAPA (modelo institucional) =====
	parts.append(pc([ph("[Inserir brasão da República]")], {"line": 240}))
	parts.append(pc([run("MINISTÉRIO DA EDUCAÇÃO", {"b": true, "sz": 20})], {"line": 240}))
	parts.append(pc([run("SECRETARIA DE EDUCAÇÃO PROFISSIONAL E TECNOLÓGICA", {"b": true, "sz": 20})], {"line": 240}))
	parts.append(pc([run("INSTITUTO FEDERAL DE EDUCAÇÃO, CIÊNCIA E TECNOLOGIA DO SUL DE MINAS GERAIS", {"b": true, "sz": 20})], {"line": 240}))
	parts.append(pc([run("CIÊNCIA DA COMPUTAÇÃO", {"b": true, "sz": 20})], {"line": 240}))
	for i in range(6):
		parts.append(pc(""))
	parts.append(pc([run("Projeto de Trabalho de Conclusão de Curso", {"b": true})]))
	for i in range(6):
		parts.append(pc(""))
	parts.append(pc("Simulador Tático para Avaliação de Inteligência Artificial: equilíbrio entre qualidade estratégica e custo computacional na tomada de decisão de agentes autônomos"))
	for i in range(6):
		parts.append(pc(""))
	parts.append(pc("Ciências Exatas e da Terra, Ciência da Computação e Metodologia e Técnicas da Computação"))
	for i in range(6):
		parts.append(pc(""))
	parts.append(pc("2026"))
	parts.append(pc([ph("Muzambinho – MG")]))

	# quebra de seção: capa sem rodapé numerado
	parts.append(par([run("")], {"sectpr": sect_pr(false), "line": 240}))

	# ===== INFORMAÇÕES GERAIS =====
	parts.append(par([run("INFORMAÇÕES GERAIS", {"b": true})], {"style": "Heading1", "after": 240}))
	parts.append(p([run("Título do projeto: ", {"b": true}), run("Simulador Tático para Avaliação de Inteligência Artificial: equilíbrio entre qualidade estratégica e custo computacional na tomada de decisão de agentes autônomos")], {"first": 0}))
	parts.append(p("", {"first": 0}))
	parts.append(p([run("Orientador - Nome: ", {"b": true}), run("Ricardo Martins")], {"first": 0, "line": 240}))
	parts.append(p([run("E-mail: "), ph("[e-mail do orientador]")], {"first": 0, "line": 240}))
	parts.append(p([run("Endereço no Lattes: "), ph("[Lattes do orientador]")], {"first": 0, "line": 240}))
	parts.append(p("", {"first": 0}))
	parts.append(p([run("Discente - Nome: ", {"b": true}), run("Gabriel Madeira")], {"first": 0, "line": 240}))
	parts.append(p([run("E-mail: "), run("gabrielmadeira1504@gmail.com")], {"first": 0, "line": 240}))
	parts.append(p([run("Endereço no Lattes: "), ph("[Lattes do discente]")], {"first": 0, "line": 240}))
	parts.append(p("", {"first": 0}))
	parts.append(p([run("Membros do projeto:", {"b": true})], {"first": 0}))
	parts.append(table("", ["Nome", "Titulação máxima", "Instituição Pertencente", "Função", "E-mail"],
		[
			["Gabriel Madeira", "Graduando em Ciência da Computação", "IFSULDEMINAS - Campus Muzambinho", "Autor", "gabrielmadeira1504@gmail.com"],
			["Ricardo Martins", "[Titulação]", "IFSULDEMINAS - Campus Muzambinho", "Orientador", "[e-mail]"],
			["Diego Penha", "[Titulação]", "IFSULDEMINAS - Campus Muzambinho", "Coorientador", "[e-mail]"],
		], [3.4, 3.2, 3.6, 2.4, 4.0]))
	parts.append(p([run("Local de Execução: ", {"b": true}), run("IFSULDEMINAS – Campus Muzambinho.")], {"first": 0, "line": 240}))
	parts.append(p([run("Período de Execução: ", {"b": true}), run("Início: Fevereiro/2026 — Término: Dezembro/2026")], {"first": 0, "line": 240}))

	# ===== 1. ANTECEDENTES, PROBLEMA E JUSTIFICATIVA =====
	parts.append(h1("1. Antecedentes, Caracterização do Problema e Justificativa", true))
	parts.append(p("A tomada de decisão é um dos problemas centrais da Inteligência Artificial. Segundo Russell e Norvig (2010), um agente inteligente é aquele que seleciona, a cada instante, a ação que maximiza sua medida de desempenho no ambiente em que atua. Em ambientes táticos — caracterizados por adversários, terreno com obstáculos, informação imperfeita e recursos limitados — essa seleção envolve equilibrar objetivos conflitantes: agredir e proteger-se, avançar e manter posição, decidir rápido e decidir bem."))
	parts.append(p("Jogos digitais consolidaram-se como plataforma privilegiada para o estudo desses problemas. Técnicas de IA desenvolvidas para jogos servem de base para sistemas reais de decisão (MILLINGTON; FUNGE, 2016), e ambientes simulados permitem testes controlados, repetíveis e de baixo custo para a avaliação de agentes (PÉREZ-LIÉBANA et al., 2019). Abordagens como a Utility AI, que avalia ações candidatas por funções de utilidade multicritério, são amplamente empregadas na indústria (MARK; DILL, 2010)."))
	parts.append(p("Entretanto, a literatura e a prática de avaliação de agentes concentram-se, em geral, no resultado final das partidas: um agente é considerado melhor que outro se vence mais. Pouco se mede sobre como vence — se usa o terreno a seu favor, se troca dano de forma eficiente, se decide em tempo hábil e, sobretudo, quanto processamento consome para cada decisão. Essa avaliação baseada apenas em métricas finais limita a análise do comportamento estratégico, pois não captura posicionamento, uso de cobertura, eficiência das ações nem o custo de produzir as decisões."))
	parts.append(p([run("Disso decorre a questão central deste trabalho: "), run("como avaliar de forma eficaz a qualidade estratégica de agentes de IA em ambientes táticos controlados, considerando simultaneamente o valor das decisões e o custo computacional de produzi-las?", {"i": true})]))
	parts.append(p("A hipótese investigada é a de que a utilização de métricas compostas, aliada a um modelo de decisão que considera simultaneamente valor estratégico e custo computacional, permite uma avaliação mais precisa do comportamento dos agentes e produz decisões mais eficientes do que abordagens que otimizam apenas o valor estratégico. Em síntese: busca-se verificar se é possível, com uma fórmula explícita de compromisso, chegar a um modelo de decisão mais eficiente."))
	parts.append(p("O trabalho justifica-se em duas frentes. Do ponto de vista científico, contribui com uma metodologia de avaliação que enxerga além da vitória, incorporando dimensões de qualidade decisória e de custo — lacuna apontada na literatura de avaliação de agentes (PÉREZ-LIÉBANA et al., 2019). Do ponto de vista prático, decisões computacionalmente baratas e estrategicamente boas interessam a qualquer sistema embarcado ou de tempo real: jogos comerciais com orçamento de CPU por quadro, robótica móvel e sistemas autônomos em geral. A opção por medir o custo por contagem de operações, e não por tempo de relógio, torna os resultados independentes do hardware utilizado e diretamente comparáveis entre pesquisadores."))

	# ===== 2. REFERENCIAL TEÓRICO =====
	parts.append(h1("2. Referencial Teórico"))
	parts.append(h2("2.1. Agentes inteligentes e ambientes"))
	parts.append(p("Russell e Norvig (2010) definem agente como qualquer entidade capaz de perceber seu ambiente por meio de sensores e de agir sobre ele por meio de atuadores; um agente racional escolhe ações que maximizam sua medida de desempenho esperada. O ambiente construído neste trabalho classifica-se, na taxonomia dos autores, como parcialmente observável (o agente enxerga apenas o interior do seu cone de visão), multiagente competitivo, determinístico nas transições, sequencial e discreto. A observabilidade parcial é decisiva para o realismo do experimento: agentes oniscientes convergem para comportamentos degenerados que não transferem para problemas reais."))
	parts.append(h2("2.2. Inteligência artificial para jogos"))
	parts.append(p("Millington e Funge (2016) sistematizam o arsenal clássico da IA para jogos: máquinas de estados, árvores de comportamento (MARCOTTE; HAMILTON, 2017), sistemas de utilidade, pathfinding e táticas de posicionamento. Os autores destacam que a IA de jogos opera sob restrições severas de orçamento computacional — tipicamente uma fração de milissegundo por agente por quadro — o que torna o custo de cada decisão um critério de projeto de primeira ordem."))
	parts.append(h2("2.3. Utility AI e decisão multicritério"))
	parts.append(p("A abordagem de Utility AI (MARK; DILL, 2010) avalia cada ação candidata por uma função de utilidade que combina múltiplos fatores normalizados e ponderados, arbitrando entre objetivos conflitantes de forma contínua e ajustável. A IA heurística deste trabalho é uma instância direta dessa técnica: cada posição alcançável recebe um valor estratégico multicritério, e a de maior valor é escolhida."))
	parts.append(h2("2.4. Avaliação de agentes em ambientes simulados"))
	parts.append(p("Pérez-Liébana et al. (2019) consolidaram, com o framework GVGAI, a prática de avaliar agentes de IA em baterias padronizadas com condições idênticas para todos os competidores. Três princípios dessa tradição são incorporados integralmente a este trabalho: bancos fixos de cenários (aqui, sementes de geração procedural), separação estrita entre conjunto de calibração e conjunto de teste, e métricas agregadas sobre grandes quantidades de partidas."))
	parts.append(h2("2.5. Custo computacional e o espectro de sofisticação"))
	parts.append(p("No extremo sofisticado do espectro de decisão está o Monte Carlo Tree Search (MCTS), que estima o valor de ações explorando árvores de futuros possíveis (BROWNE et al., 2012), alcançando alta qualidade estratégica ao custo de milhares de simulações por decisão. O MCTS é adotado aqui como referência teórica de teto de qualidade, e não como modelo implementado. O modelo híbrido proposto ataca exatamente o eixo que o MCTS ilustra — quanto vale cada unidade adicional de processamento — formalizando o compromisso com um parâmetro explícito de troca, em linha com a discussão de trade-offs de Browne et al. (2012)."))

	# ===== 3. OBJETIVOS =====
	parts.append(h1("3. Objetivos"))
	parts.append(h2("3.1. Objetivo Geral"))
	parts.append(p("Desenvolver um simulador tático bidimensional para avaliação sistemática de estratégias de IA em ambiente controlado, e propor um modelo híbrido de tomada de decisão que equilibre qualidade estratégica e custo computacional, medido de forma independente de hardware por contagem de operações."))
	parts.append(h2("3.2. Objetivos Específicos"))
	parts.append(p("● Construir um ambiente de simulação em grade com mecânicas de combate, cobertura direcional, percepção limitada e geração procedural de mapas por sementes;", {"first": 0, "left": INDENT}))
	parts.append(p("● Implementar quatro modelos de tomada de decisão com níveis crescentes de sofisticação — aleatório, reativo, heurístico e híbrido — sob um contrato de software comum que garanta comparação justa;", {"first": 0, "left": INDENT}))
	parts.append(p("● Coletar métricas de desempenho estratégico e de custo computacional em larga escala, com documentação completa e reprodutível de cada execução;", {"first": 0, "left": INDENT}))
	parts.append(p("● Analisar comparativamente os modelos e verificar se o modelo híbrido proposto supera os demais em eficiência estratégica global.", {"first": 0, "left": INDENT}))

	# ===== 4. METODOLOGIA =====
	parts.append(h1("4. Metodologia e Estratégia de Ação"))
	parts.append(p("Optou-se por desenvolver um jogo novo, construído especificamente para a pesquisa, em vez de instrumentar um jogo existente — decisão que garante controle total sobre regras, determinismo e instrumentação de medição. O gênero é o combate tático por turnos em grade, no formato todos-contra-todos com três agentes autônomos. O simulador foi implementado no motor Godot 4.7 e executa em modo visual (inspeção e demonstração) e em modo headless (lotes experimentais sem renderização). A metodologia organiza-se nas subseções seguintes: o ambiente (4.1), os agentes e sua percepção (4.2), as regras de combate (4.3), a medição de custo (4.4), o aprendizado entre partidas (4.5), os modelos comparados (4.6), as métricas (4.7), o protocolo experimental (4.8) e a infraestrutura (4.9)."))
	parts.append(h2("4.1. Ambiente: grade, geração procedural e setores"))
	parts.append(p("O mapa é uma grade bidimensional de 40x40 células de quatro tipos: vazia, parede (bloqueia movimento e visão), cobertura leve e cobertura pesada (transponíveis, não bloqueiam visão, reduzem dano). A dimensão 40x40 foi validada empiricamente: com alcance de visão 8 e movimento de 3 células por turno, produz partidas com duração média observada entre 30 e 90 turnos conforme os modelos — longas o bastante para manobra e curtas o bastante para caber no limite de 100 turnos e viabilizar lotes de 1000 partidas em minutos."))
	parts.append(p("Cada mapa é gerado proceduralmente a partir de uma semente inteira que alimenta um gerador congruente determinístico: a mesma semente produz sempre o mesmo mapa, os mesmos pontos de nascimento e, dadas as mesmas IAs, exatamente a mesma partida. O gerador posiciona segmentos de parede e blocos de cobertura respeitando uma zona de segurança ao redor dos nascimentos, e valida por busca em largura que todos os agentes podem se alcançar. Para impedir vantagem de terreno, o mapa é dividido em quatro setores de 20x20 e cada um dos três agentes nasce em um setor distinto, sorteado pela semente."))
	parts.append(h2("4.2. Agentes e percepção"))
	parts.append(p("Cada agente possui posição, pontos de vida (100), alcance de visão (8 células, distância de Chebyshev), orientação, estado vivo/morto e identificador de cor (verde, vermelho ou azul). São três agentes independentes — não há equipes — e o controle é estritamente um por vez, em turnos sequenciais."))
	parts.append(p("A percepção é deliberadamente limitada: um agente conhece a posição de um inimigo apenas se ele estiver dentro do seu cone de visão de 120 graus, centrado na orientação, a até 8 células, com linha de visão desobstruída — paredes bloqueiam a visão; coberturas, não. A orientação acompanha a última ação: mover vira o agente para a direção do deslocamento; atacar, para o alvo. Completam o modelo perceptivo a memória tática (o agente guarda a última posição em que viu cada inimigo e investiga a mais próxima, esquecendo-a ao chegar lá e nada encontrar) e a revelação por dano (receber um tiro revela a posição do atirador mesmo fora do cone). Sem informação alguma, o agente explora destinos sorteados por gerador semeado pela semente da partida, preservando o determinismo."))
	parts.append(h2("4.3. Regras de combate"))
	parts.append(p("O sistema é de turnos sequenciais: a cada turno completo, cada agente vivo age exatamente uma vez, um após o outro, em ordem fixa dentro da partida. Não há simultaneidade a resolver — quando um agente decide, o estado que observa já incorpora as ações dos que agiram antes no turno — nem disputa por alvo: os agentes são adversários independentes e cada um decide em seu próprio momento. Para anular o viés de agir primeiro, a ordem inicial é rotacionada entre as partidas do lote: a partida i inicia pelo agente i mod 3, de modo que cada agente inicia exatamente um terço das simulações."))
	parts.append(p("No seu turno, o agente pode mover-se até 3 células (caminho validado por busca em largura em 4 direções, respeitando paredes) e executar uma ação: atacar ou permanecer. O ataque exige alvo dentro do alcance (igual ao de visão), linha de visão desobstruída e alinhamento em linha reta — horizontal, vertical ou diagonal perfeita. A restrição de linha reta é necessária para que a cobertura direcional seja efetiva; sem ela, ângulos arbitrários contornariam qualquer defesa. A cobertura é direcional e automática: um defensor está protegido quando existe célula de cobertura ortogonalmente adjacente a ele na direção do atacante. O dano é determinístico:"))
	parts.append(formula("$$\\text{Dano} = 30 - \\text{Redução}, \\quad \\text{Redução} \\in \\{0, 10, 20\\}$$"))
	parts.append(p("com redução 10 para cobertura leve e 20 para pesada. Não há qualquer sorteio em combate: toda a aleatoriedade do experimento está confinada à geração dos mapas. A partida termina quando resta um único agente vivo (vencedor) ou ao atingir o limite de 100 turnos, caso em que é declarado empate. O valor 100 foi definido empiricamente como teto de segurança: as durações médias observadas ficam entre 30 e 90 turnos, de modo que o limite raramente interrompe partidas que convergiriam, mas impede laços infinitos de perseguição."))
	parts.append(h2("4.4. Custo computacional abstrato"))
	parts.append(p("O custo computacional de uma decisão é medido por contagem de operações elementares, e não por tempo de relógio. Três contadores são mantidos por agente: cálculos de linha de visão executados, nós visitados nas buscas de caminho e ações geradas e avaliadas pela IA; o custo total é a soma dos três. A medição é ativada exclusivamente durante a fase de decisão do agente da vez — mede-se o custo de decidir, não o de executar. Operações contadas são invariantes: o mesmo experimento produz exatamente os mesmos custos em qualquer computador, tornando os resultados auditáveis e comparáveis."))
	parts.append(h2("4.5. Aprendizado entre partidas"))
	parts.append(p("Dentro de um lote, a mesma instância de IA disputa todas as partidas e recebe, ao final de cada uma, a pontuação obtida (+3 vitória, -1 empate, -3 derrota). A IA heurística usa esse sinal para calibrar seus pesos por subida de encosta: joga uma janela de 25 partidas com uma configuração, mede a média de pontos e a adota se superar a melhor média conhecida, revertendo caso contrário; a janela seguinte testa uma perturbação da melhor configuração, com gerador semeado — todo o processo é reprodutível. Ao final do lote, a evolução completa é gravada em arquivo próprio (aprendizado.csv), apresentado junto aos resultados, e as instâncias são descartadas: cada lote parte do zero. Os modelos aleatório e reativo não possuem parâmetros ajustáveis e servem de contraste estático."))
	parts.append(h2("4.6. Modelos de tomada de decisão"))
	parts.append(p("Quatro modelos são comparados, em níveis crescentes de uso de informação, conforme a Tabela 1."))
	parts.append(table("Tabela 1: Comparativo dos modelos de tomada de decisão",
		["Modelo", "Usa o estado?", "Mecanismo", "Aprende?", "Papel"],
		[
			["Aleatório", "Não", "Sorteia uma ação válida", "Não", "Piso de desempenho"],
			["Reativo", "Parcial", "Regras fixas: atacar se vê; senão caçar/explorar", "Não", "Adversário padrão"],
			["Heurístico", "Sim", "Argmax do valor estratégico multicritério", "Pesos (hill-climbing)", "Estratégia sem custo"],
			["Híbrido (proposto)", "Sim", "Valor estratégico menos custo ponderado", "Pesos e lambda", "Contribuição da pesquisa"],
		], [3.2, 2.6, 5.6, 3.0, 3.4], false))
	parts.append(p("A IA aleatória enumera as ações válidas do turno e sorteia uma (gerador semeado — mesmo o acaso é reprodutível). A IA reativa segue três regras em cascata: se há inimigo com linha de tiro reta, ataca o mais próximo; se vê inimigo sem linha de tiro, aproxima-se para alinhar; se não vê ninguém, dirige-se à última posição conhecida ou explora — e cumpre também o papel de adversário padrão contra o qual os modelos avaliados jogam. A IA heurística, instância de Utility AI, avalia a cada turno com contato visual todas as posições alcançáveis pela função:"))
	parts.append(formula("$$\\text{ValorEstratégico} = w_1 \\cdot \\text{Vida} + w_2 \\cdot \\text{Cobertura} + w_3 \\cdot \\text{Proximidade} + w_4 \\cdot \\text{Risco} + \\text{Movimentação}$$"))
	parts.append(p("onde Vida é a proporção de pontos de vida do agente; Cobertura é a proteção potencial da posição (0; 0,5 leve; 1 pesada); Proximidade é o inverso da distância ao inimigo visível mais próximo; Risco é a fração de inimigos visíveis com linha de visão para a posição (impacto negativo); e Movimentação é um incentivo fixo de deslocamento — +0,2 por célula percorrida e -0,2 se a posição já foi visitada na partida — que garante manobra constante e impede o entrincheiramento passivo. Os pesos atuais (w1 = 0,1; w2 = 0,3; w3 = 0,5; w4 = -0,2) não são arbitrários: foram selecionados por varredura comparativa no banco de calibração de 200 sementes, isolado do banco de teste, e são continuamente refinados pelo aprendizado entre partidas (Seção 4.5), cujo histórico integral acompanha os resultados."))
	parts.append(p("O modelo híbrido proposto — contribuição central da pesquisa — estende a avaliação heurística com a penalização explícita do custo computacional:"))
	parts.append(formula("$$\\text{ScoreAção} = \\text{ValorEstratégico} - \\lambda \\cdot \\text{CustoComputacional}$$"))
	parts.append(p("onde CustoComputacional é o custo, em operações contadas, de avaliar a própria ação, e lambda é o parâmetro de compromisso que converte operações em unidades de valor estratégico: com lambda igual a zero o modelo colapsa no heurístico puro; com lambda grande, aproxima-se do reativo. Seguindo o protocolo experimental (Seção 4.8), o modelo híbrido será construído somente após a análise da campanha de caracterização dos modelos básicos — a solução é derivada dos dados —, com lambda calibrado no banco de 200 sementes."))
	parts.append(h2("4.7. Métricas de avaliação"))
	parts.append(p("Para cada modelo, sobre o conjunto de partidas de um lote, calculam-se: WinRate (fração de vitórias); DamageRatio, com limitador contra divisão por zero:"))
	parts.append(formula("$$\\text{DamageRatio} = \\frac{\\text{dano causado}}{\\max(\\text{dano recebido},\\ \\varepsilon)}, \\quad \\varepsilon = 1$$"))
	parts.append(p("CoverUsage (fração dos turnos em que o agente terminou em posição com cobertura adjacente); TurnsToVictory (média de turnos para vencer, com empates penalizados pelo valor máximo de 100 e derrotas excluídas); e CustoComputacionalMedio (média por partida das operações contadas na decisão). Cada partida atribui ainda uma pontuação: +3 por vitória, -1 por empate e -3 por derrota. O empate é deliberadamente penalizado porque um modelo que apenas sobrevive sem decidir a partida não demonstra eficácia estratégica; a média de pontos por partida (faixa -3 a +3) mostrou-se a métrica mais legível para comparação direta. As dimensões individuais são agregadas no escore composto:"))
	parts.append(formula("$$\\text{StrategicScore} = 0{,}3 \\cdot \\text{WinRate} + 0{,}2 \\cdot \\text{DamageRatio} + 0{,}2 \\cdot \\text{CoverUsage} + 0{,}2 \\cdot \\text{Efficiency} + 0{,}1 \\cdot \\frac{1}{\\max(\\text{Custo},\\ \\varepsilon)}$$"))
	parts.append(formula("$$\\text{Efficiency} = \\frac{1}{\\max(\\text{TurnsToVictory},\\ 1)}$$"))
	parts.append(p("Na prática, a fórmula é uma definição operacional de jogar bem: vencer (30%), causar mais dano do que receber (20%), usar o terreno (20%), vencer rápido (20%) e decidir barato (10%) — pesos fixados a priori, antes de qualquer comparação entre modelos, para que não possam favorecer o modelo proposto. Uma limitação conhecida é registrada com transparência: o DamageRatio não é normalizado à faixa das demais componentes e pode dominar o escore quando um modelo vence sem receber dano; a adoção de um teto está em avaliação com a orientação, e qualquer alteração será aplicada uniformemente a todos os modelos. Por essa razão, as análises reportam sempre as métricas individuais ao lado do escore composto."))
	parts.append(h2("4.8. Protocolo experimental"))
	parts.append(p("Dois bancos congelados e disjuntos de sementes foram gerados uma única vez por um gerador congruente linear documentado: 200 sementes de calibração, usadas exclusivamente para ajuste de pesos e de lambda, e 1000 sementes de benchmark, reservadas à avaliação — a separação previne sobreajuste e os arquivos são imutáveis e versionados. Três mecanismos garantem que diferenças de desempenho sejam atribuíveis aos modelos: sorteio de setores de nascimento (vantagem de terreno), rotação uniforme de iniciativa (vantagem de primeiro turno) e combate determinístico (variância de sorte)."))
	parts.append(p("A campanha de coleta segue etapas ordenadas, cada uma com 1000 partidas documentadas: (1) autoconfronto por modelo — três instâncias do mesmo modelo por partida —, caracterizando o comportamento decisório de cada um isoladamente; (2) confronto misto, com um agente de cada modelo; (3) análise das métricas decisórias e identificação dos melhores comportamentos; (4) construção do modelo híbrido a partir do que os dados mostrarem; (5) avaliação final do híbrido contra cada modelo e contra os melhores identificados, verificando a hipótese de superioridade em eficácia e custo. Todas as execuções usam o mesmo banco de 1000 sementes, garantindo comparabilidade integral. O pipeline é determinístico de ponta a ponta — mesma semente, mesmos modelos, mesmos parâmetros produzem partidas byte a byte idênticas, propriedade verificada por reexecução integral de lotes."))
	parts.append(h2("4.9. Arquitetura e infraestrutura experimental"))
	parts.append(p("O software separa estritamente as responsabilidades: o núcleo de simulação não conhece a lógica das IAs; cada IA implementa um contrato único — receber o estado e devolver uma ação — e a simulação valida e aplica a ação devolvida. Trocar o modelo de um jogador é uma operação de um argumento de linha de comando, garantindo que todos os modelos joguem exatamente o mesmo jogo. Cada lote gera uma pasta autodocumentada e imutável contendo o manifesto da execução (condições completas), o registro por partida (uma linha por jogador, com métricas brutas, derivadas e custo aberto por tipo de operação), o resumo agregado (médias, desvios-padrão e escore), o registro do aprendizado janela a janela e, opcionalmente, o registro turno a turno. Um lote de 1000 partidas executa em 70 a 120 segundos em modo headless. O código, os bancos de sementes e as execuções oficiais são versionados em repositório público."))

	# ===== 5. RESULTADOS =====
	parts.append(h1("5. Resultados e Impactos Esperados"))
	parts.append(p("Espera-se demonstrar que o modelo híbrido proposto alcança eficácia estratégica igual ou superior à do modelo heurístico puro com custo computacional significativamente menor, validando a hipótese de que a formalização explícita do compromisso qualidade-custo produz agentes mais eficientes. Como impactos, o trabalho entrega uma metodologia de avaliação reprodutível e independente de hardware, um simulador aberto reutilizável por outras pesquisas e evidências quantitativas sobre o valor marginal do processamento na tomada de decisão tática."))
	parts.append(h2("5.1. Resultados Preliminares (Parciais)"))
	parts.append(h3("5.1.1. Validação da neutralidade do ambiente"))
	parts.append(p("Antes de comparar modelos, validou-se o instrumento: 1000 partidas do banco de benchmark foram executadas com os três agentes controlados pela mesma IA reativa. Em ambiente neutro, as taxas de vitória devem ser estatisticamente indistinguíveis — qualquer assimetria sistemática denunciaria viés de terreno, cor ou iniciativa. A Tabela 2 apresenta o resultado."))
	parts.append(table("Tabela 2: Validação de neutralidade — 3 agentes idênticos (IA reativa), 1000 partidas",
		["Agente", "WinRate", "DamageRatio (média ± dp)", "CoverUsage (média ± dp)"],
		[
			["Verde", "0,297", "5,32 ± 12,03", "0,058 ± 0,152"],
			["Vermelho", "0,298", "6,24 ± 13,38", "0,055 ± 0,145"],
			["Azul", "0,310", "6,48 ± 13,81", "0,053 ± 0,147"],
		], [3.0, 2.6, 5.6, 5.6], false))
	parts.append(p("Com N = 1000 e probabilidade de referência de 1/3, a flutuação estatística esperada é de aproximadamente 1,5 ponto percentual; a maior diferença observada foi de 1,3 ponto — dentro do ruído. Conclui-se que o sorteio de setores e a rotação de iniciativa neutralizam os vieses com sucesso, e que diferenças observadas doravante são atribuíveis aos modelos. Esta validação foi executada na versão inicial das mecânicas e será reexecutada como primeira etapa da campanha definitiva, sob o conjunto final de regras."))
	parts.append(h3("5.1.2. Efeito da percepção limitada"))
	parts.append(p("A introdução do campo de visão produziu um resultado metodologicamente relevante: sob onisciência, a IA heurística vencia com folga a reativa; com percepção limitada, a vantagem praticamente desapareceu (WinRate de 0,30 para todas em lote de calibração). A avaliação posicional só agrega valor durante o contato visual, e partidas com busca às cegas comprimem a diferença entre modelos — achado que reforça a motivação do modelo híbrido: concentrar o gasto computacional nos momentos em que a avaliação de fato informa a decisão."))
	parts.append(h3("5.1.3. Efeito da linha de tiro reta e do incentivo de movimentação"))
	parts.append(p("Duas regras subsequentes recuperaram e ampliaram a diferenciação estratégica: a restrição de tiro em linha reta tornou a cobertura direcional efetiva, e o incentivo de movimentação eliminou o entrincheiramento passivo. A Tabela 3 apresenta o lote de calibração mais recente (30 partidas, banco de calibração), com a heurística enfrentando duas reativas."))
	parts.append(table("Tabela 3: Lote de calibração — heurística vs. duas reativas (30 partidas, regras completas)",
		["Métrica", "Heurística", "Reativa (1)", "Reativa (2)"],
		[
			["Pontuação média", "-0,20", "-1,20", "-1,60"],
			["WinRate", "0,333", "0,167", "0,100"],
			["DamageRatio médio", "6,60", "2,82", "1,93"],
			["CoverUsage médio", "0,128", "0,071", "0,106"],
			["Custo computacional médio", "1401,1", "884,7", "989,6"],
			["StrategicScore", "1,448", "0,630", "0,440"],
		], [4.6, 3.4, 3.4, 3.4], false))
	parts.append(p("A heurística lidera todas as dimensões de eficácia — vence o dobro da melhor reativa — ao custo de cerca de 50% mais operações por partida. Esse retrato quantifica exatamente o eixo da pesquisa: qualidade estratégica custa processamento, e o modelo híbrido buscará o ponto ótimo dessa troca."))
	parts.append(h3("5.1.4. Aprendizado registrado"))
	parts.append(p("O mecanismo de aprendizado entre partidas produz registro auditável. Em lote ilustrativo de 60 partidas, a primeira janela (pesos iniciais) obteve média de -0,84 pontos e foi adotada como referência; a perturbação testada na segunda janela piorou a média para -1,00 e foi revertida, com o modelo retornando à melhor configuração conhecida — comportamento esperado da subida de encosta, visível no arquivo de aprendizado que acompanha cada execução. No momento da escrita, a etapa 1 da campanha definitiva (autoconfrontos de 1000 partidas por modelo) está em execução."))

	# ===== 6. CRONOGRAMA =====
	parts.append(h1("6. Cronograma"))
	parts.append(table("",
		["Atividade", "Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"],
		[
			["Projeto e revisão de literatura", "X", "X", "X", "X", "", "", "", "", "", "", "", ""],
			["Simulador (Fases 1-2)", "", "", "X", "X", "X", "X", "X", "", "", "", "", ""],
			["Modelos básicos de IA", "", "", "", "", "", "X", "X", "", "", "", "", ""],
			["Campanha de coleta", "", "", "", "", "", "", "X", "X", "", "", "", ""],
			["Análise intermediária", "", "", "", "", "", "", "", "X", "", "", "", ""],
			["Modelo híbrido e calibração", "", "", "", "", "", "", "", "", "X", "", "", ""],
			["Avaliação final (benchmark)", "", "", "", "", "", "", "", "", "X", "X", "", ""],
			["Escrita do TCC e artigos", "", "", "", "", "", "", "X", "X", "X", "X", "X", "X"],
		], [4.6, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85]))

	# ===== 7. ORÇAMENTO =====
	parts.append(h1("7. Orçamento Financeiro"))
	parts.append(p("Este trabalho utiliza exclusivamente ferramentas gratuitas e de código aberto (motor Godot, linguagem GDScript, Python para análise, Git para versionamento) e equipamentos já disponíveis, não sendo necessário orçamento extra."))

	# ===== 8. DISSEMINAÇÃO =====
	parts.append(h1("8. Disseminação dos Resultados"))
	parts.append(p("Este trabalho poderá ser publicado pelo menos na Jornada Científica e Tecnológica do IFSULDEMINAS. Adicionalmente, o simulador, os bancos de sementes, as execuções oficiais e toda a documentação são mantidos em repositório público (github.com/madeiragab/tcc-simulador-ia), permitindo verificação independente e reutilização por outras pesquisas."))

	# ===== 9. REFERÊNCIAS =====
	parts.append(h1("9. Referências Bibliográficas"))
	parts.append(refp([run("BROWNE, C. B. et al. "), run("A Survey of Monte Carlo Tree Search Methods", {"b": true}), run(". IEEE Transactions on Computational Intelligence and AI in Games, v. 4, n. 1, p. 1-43, 2012.")]))
	parts.append(refp([run("GODOT ENGINE. "), run("Godot Engine Documentation", {"b": true}), run(". 2026. Disponível em: <https://docs.godotengine.org>. Acesso em: 21/07/2026.")]))
	parts.append(refp([run("MARCOTTE, R.; HAMILTON, H. J. "), run("Behavior Trees for Modelling Artificial Intelligence in Games: A Tutorial", {"b": true}), run(". The Computer Games Journal, v. 6, p. 171-184, 2017.")]))
	parts.append(refp([run("MARK, D.; DILL, K. "), run("Improving AI Decision Modeling Through Utility Theory", {"b": true}), run(". In: Game Developers Conference, 2010, São Francisco. GDC Vault, 2010.")]))
	parts.append(refp([run("MILLINGTON, I.; FUNGE, J. "), run("Artificial Intelligence for Games", {"b": true}), run(". 2. ed. Boca Raton: CRC Press, 2016.")]))
	parts.append(refp([run("PÉREZ-LIÉBANA, D. et al. "), run("General Video Game AI: A Multitrack Framework for Evaluating Agents, Games, and Content Generation Algorithms", {"b": true}), run(". IEEE Transactions on Games, v. 11, n. 3, p. 195-214, 2019.")]))
	parts.append(refp([run("RUSSELL, S.; NORVIG, P. "), run("Artificial Intelligence: A Modern Approach", {"b": true}), run(". 3. ed. Upper Saddle River: Pearson, 2010.")]))
	parts.append(pc(""))
	parts.append(pc([run("Muzambinho, 21 de julho de 2026.")]))

	# ===== APÊNDICES =====
	parts.append(h1("Apêndice A – Estrutura dos Dados Coletados", true))
	parts.append(p("Cada execução de lote gera uma pasta imutável com carimbo de data e hora contendo os arquivos descritos a seguir, todos em formatos abertos (texto e CSV)."))
	parts.append(p([run("manifest.txt", {"b": true}), run(" — condições da execução: data e hora, versão do motor, banco e faixa de sementes, regra de rotação de iniciativa, modelo de IA de cada jogador, constantes de jogo (dano base 30; reduções 10/20; limite 100 turnos; movimento 3; vida 100; visão 8; cone 120 graus), parâmetros de IA e duração.")]))
	parts.append(p([run("partidas.csv", {"b": true}), run(" — uma linha por jogador por partida: identificador, semente, jogador que iniciou, jogador, modelo, vencedor, indicador de vitória, pontos (+3/-1/-3), turnos, dano causado e recebido, DamageRatio, CoverUsage, custo total e custo aberto por tipo de operação (linha de visão, nós de busca, ações avaliadas).")]))
	parts.append(p([run("resumo.csv", {"b": true}), run(" — agregados por jogador: partidas, pontuação total e média, WinRate, DamageRatio e CoverUsage (média e desvio-padrão), TurnsToVictory, Efficiency, custo médio e desvio, StrategicScore.")]))
	parts.append(p([run("aprendizado.csv", {"b": true}), run(" — evolução do aprendizado janela a janela: pesos testados, média de pontos da janela e decisão (adotado/revertido).")]))
	parts.append(p([run("turnos.csv", {"b": true}), run(" (opcional) — registro fino turno a turno: ação escolhida, posição, proteção por cobertura e inimigos visíveis de cada agente.")]))

	parts.append(h1("Apêndice B – Correspondência com os Apontamentos da Banca", true))
	parts.append(p("O quadro abaixo mapeia cada apontamento da banca de qualificação para a seção deste documento que o responde."))
	parts.append(table("Quadro 1: Apontamentos da banca e seções correspondentes",
		["Apontamento", "Resposta"],
		[
			["Não seguiu o modelo padrão de pré-projeto da instituição", "Documento reestruturado integralmente conforme o modelo institucional (capa, Informações Gerais, seções 1-9, cronograma mensal)"],
			["Ausência de resultados parciais", "Seção 5.1 (neutralidade validada com 1000 partidas; calibração; aprendizado)"],
			["Como será medido o custo computacional abstrato", "Seção 4.4 (contagem de operações: linha de visão, nós de busca, ações avaliadas)"],
			["Jogo existente ou novo? Que gênero?", "Seção 4, abertura (jogo novo em Godot; tático por turnos em grade, 3 agentes)"],
			["Diferença prática entre os quatro modelos", "Tabela 1 e Seção 4.6"],
			["O que significa resolução sequencial", "Seção 4.3 (um agente por vez sobre estado atualizado; sem simultaneidade)"],
			["Como funciona a ordem alternada entre rodadas", "Seção 4.3 (rotação determinística: partida i inicia pelo agente i mod 3)"],
			["Como foi definido o limite de 100 turnos", "Seção 4.3 (empírico: durações médias de 30-90 turnos; teto de segurança)"],
			["O que conta como cobertura", "Seção 4.3 (célula de cobertura; proteção direcional; leve -10, pesada -20)"],
			["Quantos agentes por equipe; controle por turno", "Seções 4.2 e 4.3 (3 agentes independentes, sem equipes; um por vez)"],
			["Dois agentes podem atacar o mesmo alvo?", "Seção 4.3 (adversários independentes; cada um decide em seu turno)"],
			["Há aprendizado entre partidas?", "Seção 4.5 (subida de encosta por janelas; registro em arquivo; reset por lote)"],
			["Origem dos pesos da heurística (w1..w4)", "Seção 4.6 (varredura no banco de calibração + aprendizado; valores atuais)"],
			["O que o Strategic Score representa; por que esses pesos", "Seção 4.7 (definição operacional de jogar bem; pesos a priori; limitação registrada)"],
			["O mapa 40x40 foi testado?", "Seções 4.1 e 5.1 (validado: durações, neutralidade, escala de lote)"],
		], [6.4, 8.4], false))

	write_docx(parts)

# ---------- seções e pacote ----------

func sect_pr(with_footer):
	var footer_ref = '<w:footerReference w:type="default" r:id="rIdFtr"/>' if with_footer else ""
	return '<w:sectPr>%s<w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1701" w:right="1134" w:bottom="1134" w:left="1701" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>' % footer_ref

func write_docx(parts):
	var body = "".join(parts)
	body += sect_pr(true)

	var document = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><w:body>%s</w:body></w:document>' % body

	var styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/><w:sz w:val="24"/><w:szCs w:val="24"/><w:lang w:val="pt-BR"/></w:rPr></w:rPrDefault></w:docDefaults><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:pPr><w:outlineLvl w:val="0"/><w:spacing w:line="360" w:lineRule="auto"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:pPr><w:outlineLvl w:val="1"/><w:spacing w:line="360" w:lineRule="auto"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/><w:pPr><w:outlineLvl w:val="2"/><w:spacing w:line="360" w:lineRule="auto"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/></w:rPr></w:style></w:styles>'

	var settings = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"></w:settings>'

	var footer1 = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r><w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:fldChar w:fldCharType="end"/></w:r></w:p></w:ftr>'

	var content_types = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/></Types>'

	var rels_root = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'

	var rels_doc = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rIdSettings" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/><Relationship Id="rIdFtr" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/></Relationships>'

	var out_dir = ProjectSettings.globalize_path("res://").path_join("../monografia")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var out_path = out_dir.path_join("Monografia_TCC_Gabriel_Madeira.docx")

	var zip = ZIPPacker.new()
	var err = zip.open(out_path)
	if err != OK:
		push_error("Falha ao abrir zip: %s" % out_path)
		return
	var files = {
		"[Content_Types].xml": content_types,
		"_rels/.rels": rels_root,
		"word/document.xml": document,
		"word/styles.xml": styles,
		"word/settings.xml": settings,
		"word/footer1.xml": footer1,
		"word/_rels/document.xml.rels": rels_doc,
	}
	for fname in files:
		zip.start_file(fname)
		zip.write_file(files[fname].to_utf8_buffer())
		zip.close_file()
	zip.close()
	print("OK: ", out_path)
