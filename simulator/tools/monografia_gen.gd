extends SceneTree

# Gera a monografia do TCC em formato .docx (OOXML montado à mão e
# empacotado com ZIPPacker). Uso:
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

# run de texto; opts: b (negrito), i (itálico), sz (half-points), hl (highlight)
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

# parágrafo; opts: style, align, first (recuo 1a linha), line, before, after,
# left (recuo esquerdo), pagebreak, sectpr (xml de quebra de seção embutida)
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
	# sectPr deve ser o último filho de pPr (ordem exigida pelo schema OOXML)
	if opts.has("sectpr"):
		pr += opts["sectpr"]
	var body = runs if runs is String else "".join(runs)
	return '<w:p><w:pPr>%s</w:pPr>%s</w:p>' % [pr, body]

# corpo justificado com recuo
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

func h1(text):
	return par([run(text.to_upper(), {"b": true})], {"style": "Heading1", "pagebreak": true, "after": 240})

func h2(text):
	return par([run(text, {"b": true})], {"style": "Heading2", "before": 240, "after": 120})

func h3(text):
	return par([run(text)], {"style": "Heading3", "before": 240, "after": 120})

func formula(text):
	return par([run(text, {"i": true})], {"align": "center", "before": 120, "after": 120})

func refp(runs):
	return par(runs, {"align": "left", "line": 240, "after": 240})

func ph(text):
	return run(text, {"hl": true})

# tabela ABNT: legenda acima, fonte abaixo
func table(caption, headers, rows, widths_cm):
	var widths = []
	for w in widths_cm:
		widths.append(int(round(w * CM)))
	var total = 0
	for w in widths:
		total += w
	var xml = par([run(caption, {"sz": 20})], {"align": "center", "line": 240, "before": 240})
	var borders = '<w:tblBorders><w:top w:val="single" w:sz="4" w:color="000000"/><w:left w:val="single" w:sz="4" w:color="000000"/><w:bottom w:val="single" w:sz="4" w:color="000000"/><w:right w:val="single" w:sz="4" w:color="000000"/><w:insideH w:val="single" w:sz="4" w:color="000000"/><w:insideV w:val="single" w:sz="4" w:color="000000"/></w:tblBorders>'
	xml += '<w:tbl><w:tblPr><w:tblW w:w="%d" w:type="dxa"/><w:jc w:val="center"/>%s</w:tblPr><w:tblGrid>' % [total, borders]
	for w in widths:
		xml += '<w:gridCol w:w="%d"/>' % w
	xml += '</w:tblGrid>'
	xml += table_row(headers, widths, true)
	for row in rows:
		xml += table_row(row, widths, false)
	xml += '</w:tbl>'
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

	# ===== PRÉ-TEXTUAL =====
	# capa
	parts.append(pc([ph("NOME DA INSTITUIÇÃO DE ENSINO")]))
	parts.append(pc([ph("NOME DO CURSO")]))
	for i in range(5):
		parts.append(pc(""))
	parts.append(pc([run("GABRIEL MADEIRA", {"b": true})]))
	for i in range(5):
		parts.append(pc(""))
	parts.append(pc([run("SIMULADOR TÁTICO PARA AVALIAÇÃO DE INTELIGÊNCIA ARTIFICIAL:", {"b": true})]))
	parts.append(pc([run("um estudo sobre o equilíbrio entre qualidade estratégica e custo computacional na tomada de decisão de agentes autônomos", {"b": true})]))
	for i in range(10):
		parts.append(pc(""))
	parts.append(pc([ph("CIDADE")]))
	parts.append(pc("2026"))

	# folha de rosto
	parts.append(pc([run("GABRIEL MADEIRA", {"b": true})], {"pagebreak": true}))
	for i in range(5):
		parts.append(pc(""))
	parts.append(pc([run("SIMULADOR TÁTICO PARA AVALIAÇÃO DE INTELIGÊNCIA ARTIFICIAL:", {"b": true})]))
	parts.append(pc([run("um estudo sobre o equilíbrio entre qualidade estratégica e custo computacional na tomada de decisão de agentes autônomos", {"b": true})]))
	for i in range(3):
		parts.append(pc(""))
	parts.append(par([run("Trabalho de Conclusão de Curso apresentado ao curso de ", {"sz": 20}), ph("[Nome do Curso]"), run(" da ", {"sz": 20}), ph("[Nome da Instituição]"), run(", como requisito parcial para a obtenção do título de ", {"sz": 20}), ph("[Bacharel/Tecnólogo]"), run(".", {"sz": 20})], {"left": 8 * CM, "line": 240}))
	parts.append(pc(""))
	parts.append(par([run("Orientador: Prof. Ricardo Martins", {"sz": 20})], {"left": 8 * CM, "line": 240}))
	parts.append(par([run("Coorientador: Prof. Diego Penha", {"sz": 20})], {"left": 8 * CM, "line": 240}))
	for i in range(8):
		parts.append(pc(""))
	parts.append(pc([ph("CIDADE")]))
	parts.append(pc("2026"))

	# resumo
	parts.append(pc([run("RESUMO", {"b": true})], {"pagebreak": true, "after": 240}))
	parts.append(par([run("A avaliação de agentes de Inteligência Artificial (IA) em ambientes táticos frequentemente se restringe a métricas de resultado final, como vitória ou derrota, ignorando a qualidade das decisões tomadas ao longo da partida e o custo computacional necessário para produzi-las. Este trabalho desenvolve um simulador tático por turnos, construído especificamente para a pesquisa no motor Godot, no qual três agentes autônomos e independentes disputam partidas em uma grade 40x40 gerada proceduralmente a partir de sementes fixas, com percepção limitada por cone de visão, cobertura direcional e combate determinístico. Sobre esse ambiente, propõe-se uma metodologia de avaliação baseada em métricas compostas — taxa de vitória, razão de dano, uso de cobertura, eficiência, pontuação por partida e custo computacional abstrato medido por contagem de operações — agregadas em um escore estratégico único. Quatro modelos de tomada de decisão são comparados sob condições idênticas: aleatório, reativo, heurístico com aprendizado entre partidas e um modelo híbrido proposto, que pondera o valor estratégico de cada ação contra o seu custo computacional. Resultados parciais com 1000 simulações validaram a neutralidade do ambiente (taxas de vitória de 29,7%, 29,8% e 31,0% para três agentes idênticos) e demonstraram a superioridade do modelo heurístico sobre o reativo em partidas de calibração (pontuação média de -0,20 contra -1,20 e -1,60). A pesquisa investiga se é possível, por meio de uma formulação explícita de compromisso entre qualidade e custo, obter um modelo de decisão mais eficiente que as abordagens isoladas.", {"sz": 22})], {"line": 240}))
	parts.append(par([run("Palavras-chave: ", {"b": true, "sz": 22}), run("inteligência artificial; jogos digitais; simulação; tomada de decisão; custo computacional; utility AI.", {"sz": 22})], {"line": 240, "before": 240}))

	# abstract
	parts.append(pc([run("ABSTRACT", {"b": true})], {"pagebreak": true, "after": 240}))
	parts.append(par([run("The evaluation of Artificial Intelligence (AI) agents in tactical environments is often restricted to final-outcome metrics such as win or loss, ignoring both the quality of the decisions made throughout a match and the computational cost required to produce them. This work develops a turn-based tactical simulator, built specifically for this research in the Godot engine, in which three autonomous, independent agents compete on a procedurally generated 40x40 grid derived from fixed seeds, with perception limited by a vision cone, directional cover, and deterministic combat. On top of this environment, an evaluation methodology based on composite metrics is proposed — win rate, damage ratio, cover usage, efficiency, per-match scoring, and abstract computational cost measured by operation counting — aggregated into a single strategic score. Four decision-making models are compared under identical conditions: random, reactive, heuristic with between-match learning, and a proposed hybrid model that weighs the strategic value of each action against its computational cost. Partial results across 1000 simulations validated the neutrality of the environment (win rates of 29.7%, 29.8%, and 31.0% for three identical agents) and demonstrated the superiority of the heuristic model over the reactive baseline in calibration matches (average score of -0.20 versus -1.20 and -1.60). The research investigates whether an explicit quality-cost trade-off formulation can yield a more efficient decision model than isolated approaches.", {"sz": 22})], {"line": 240}))
	parts.append(par([run("Keywords: ", {"b": true, "sz": 22}), run("artificial intelligence; digital games; simulation; decision-making; computational cost; utility AI.", {"sz": 22})], {"line": 240, "before": 240}))

	# sumário (campo TOC)
	parts.append(pc([run("SUMÁRIO", {"b": true})], {"pagebreak": true, "after": 240}))
	parts.append('<w:p><w:r><w:fldChar w:fldCharType="begin" w:dirty="true"/></w:r><w:r><w:instrText xml:space="preserve"> TOC \\o "1-3" \\h \\z \\u </w:instrText></w:r><w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:t>Sumário — no Word, clique com o botão direito e escolha "Atualizar campo".</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r></w:p>')

	# quebra de seção: pré-textual sem cabeçalho
	parts.append(par([run("")], {"sectpr": sect_pr(false), "line": 240}))

	# ===== TEXTUAL =====
	# 1 INTRODUÇÃO
	parts.append(h1("1 Introdução"))
	parts.append(h2("1.1 Contextualização"))
	parts.append(p("A tomada de decisão é um dos problemas centrais da Inteligência Artificial. Segundo Russell e Norvig (2010), um agente inteligente é aquele que seleciona, a cada instante, a ação que maximiza sua medida de desempenho no ambiente em que atua. Em ambientes táticos — caracterizados por adversários, terreno com obstáculos, informação imperfeita e recursos limitados — essa seleção envolve equilibrar objetivos conflitantes: agredir e proteger-se, avançar e manter posição, decidir rápido e decidir bem."))
	parts.append(p("Jogos digitais consolidaram-se como plataforma privilegiada para o estudo desses problemas. Técnicas de IA desenvolvidas para jogos servem de base para sistemas reais de decisão (MILLINGTON; FUNGE, 2016), e ambientes simulados permitem testes controlados, repetíveis e de baixo custo para a avaliação de agentes (PÉREZ-LIÉBANA et al., 2019). Abordagens como a Utility AI, que avalia ações candidatas por funções de utilidade multicritério, são amplamente empregadas na indústria (MARK; DILL, 2010)."))
	parts.append(p("Entretanto, a literatura e a prática de avaliação de agentes concentram-se, em geral, no resultado final das partidas. Um agente é considerado melhor que outro se vence mais — pouco se mede sobre como vence: se usa o terreno a seu favor, se troca dano de forma eficiente, se decide em tempo hábil e, sobretudo, quanto processamento consome para cada decisão."))
	parts.append(h2("1.2 Problema de pesquisa"))
	parts.append(p("A avaliação baseada apenas em métricas finais limita a análise do comportamento estratégico, pois não captura aspectos como posicionamento, uso de cobertura, eficiência das ações e custo de processamento das decisões. Disso decorre a questão central deste trabalho:"))
	parts.append(p([run("Como avaliar de forma eficaz a qualidade estratégica de agentes de IA em ambientes táticos controlados, considerando simultaneamente o valor das decisões e o custo computacional de produzi-las?", {"i": true})]))
	parts.append(h2("1.3 Hipótese"))
	parts.append(p("A hipótese investigada é a de que a utilização de métricas compostas, aliada a um modelo de decisão que considera simultaneamente valor estratégico e custo computacional, permite uma avaliação mais precisa do comportamento dos agentes e produz decisões mais eficientes do que abordagens que otimizam apenas o valor estratégico. Em síntese: busca-se verificar se é possível, com uma fórmula explícita de compromisso, chegar a um modelo de decisão mais eficiente."))
	parts.append(h2("1.4 Objetivos"))
	parts.append(h3("1.4.1 Objetivo geral"))
	parts.append(p("Desenvolver um simulador tático bidimensional para avaliação sistemática de estratégias de IA em ambiente controlado, e propor um modelo híbrido de tomada de decisão que equilibre qualidade estratégica e custo computacional, medido de forma independente de hardware por contagem de operações."))
	parts.append(h3("1.4.2 Objetivos específicos"))
	parts.append(p("a) construir um ambiente de simulação em grade com mecânicas de combate, cobertura direcional, percepção limitada e geração procedural de mapas por sementes;"))
	parts.append(p("b) implementar quatro modelos de tomada de decisão com níveis crescentes de sofisticação — aleatório, reativo, heurístico e híbrido — sob um contrato de software comum que garanta comparação justa;"))
	parts.append(p("c) coletar métricas de desempenho estratégico e de custo computacional em larga escala, com documentação completa e reprodutível de cada execução;"))
	parts.append(p("d) analisar comparativamente os modelos e verificar se o modelo híbrido proposto supera os demais em eficiência estratégica global."))
	parts.append(p("A diferença prática entre os quatro modelos é detalhada no Capítulo 4 e resumida na Tabela 1: o aleatório não usa informação alguma do estado; o reativo usa regras fixas do tipo estímulo-resposta; o heurístico avalia numericamente todas as posições alcançáveis por uma função multicritério; e o híbrido acrescenta a essa avaliação a penalização explícita do custo computacional de cada análise."))
	parts.append(h2("1.5 Justificativa"))
	parts.append(p("Do ponto de vista científico, o trabalho contribui com uma metodologia de avaliação que enxerga além da vitória, incorporando dimensões de qualidade decisória e de custo — uma lacuna apontada na literatura de avaliação de agentes (PÉREZ-LIÉBANA et al., 2019). Do ponto de vista prático, decisões computacionalmente baratas e estrategicamente boas interessam a qualquer sistema embarcado ou de tempo real: jogos comerciais com orçamento de CPU por quadro, robótica móvel e sistemas autônomos em geral. O custo medido por contagem de operações, e não por tempo de relógio, torna os resultados independentes do hardware utilizado — decisão metodológica que responde diretamente à variabilidade de máquinas entre pesquisadores e avaliadores."))
	parts.append(h2("1.6 Organização do trabalho"))
	parts.append(p("O Capítulo 2 apresenta a fundamentação teórica. O Capítulo 3 descreve o simulador desenvolvido: ambiente, agentes, regras de combate, medição de custo e infraestrutura experimental. O Capítulo 4 especifica os quatro modelos de IA. O Capítulo 5 define as métricas de avaliação. O Capítulo 6 formaliza o protocolo experimental. O Capítulo 7 apresenta e discute os resultados parciais obtidos. O Capítulo 8 traz o cronograma das etapas restantes, e o Capítulo 9, as considerações parciais. O Apêndice A documenta os dados coletados e o Apêndice B mapeia, item a item, as respostas aos apontamentos da banca de qualificação."))

	# 2 FUNDAMENTAÇÃO
	parts.append(h1("2 Fundamentação Teórica"))
	parts.append(h2("2.1 Agentes inteligentes e ambientes"))
	parts.append(p("Russell e Norvig (2010) definem agente como qualquer entidade capaz de perceber seu ambiente por meio de sensores e de agir sobre ele por meio de atuadores. Um agente racional escolhe ações que maximizam sua medida de desempenho esperada, dadas as percepções acumuladas. O ambiente construído neste trabalho classifica-se, na taxonomia dos autores, como parcialmente observável (o agente enxerga apenas o interior do seu cone de visão), multiagente competitivo (três agentes disputam a mesma vitória), determinístico nas transições (não há aleatoriedade no combate), sequencial (decisões afetam estados futuros) e discreto (grade de células e turnos)."))
	parts.append(p("A observabilidade parcial é decisiva para o realismo do experimento: agentes oniscientes convergem para comportamentos degenerados que não transferem para problemas reais. A introdução de percepção limitada obriga os modelos a lidar com incerteza, memória e busca — dimensões nas quais estratégias de qualidade se diferenciam de fato."))
	parts.append(h2("2.2 Inteligência artificial para jogos"))
	parts.append(p("Millington e Funge (2016) sistematizam o arsenal clássico da IA para jogos: máquinas de estados, árvores de comportamento (MARCOTTE; HAMILTON, 2017), sistemas de utilidade, pathfinding e táticas de posicionamento. Os autores destacam que a IA de jogos opera sob restrições severas de orçamento computacional — tipicamente uma fração de milissegundo por agente por quadro — o que torna o custo de cada decisão um critério de projeto de primeira ordem, e não um detalhe de implementação."))
	parts.append(h2("2.3 Utility AI e decisão multicritério"))
	parts.append(p("A abordagem de Utility AI (MARK; DILL, 2010) avalia cada ação candidata por uma função de utilidade que combina múltiplos fatores normalizados e ponderados. Sua principal vantagem sobre regras fixas é a capacidade de arbitrar entre objetivos conflitantes de forma contínua e ajustável. A IA heurística deste trabalho é uma instância direta dessa técnica: cada posição alcançável recebe um valor estratégico que combina vida, cobertura, proximidade, risco e movimentação, e a de maior valor é escolhida (argmax)."))
	parts.append(h2("2.4 Avaliação de agentes em ambientes simulados"))
	parts.append(p("Pérez-Liébana et al. (2019) consolidaram, com o framework GVGAI, a prática de avaliar agentes de IA em baterias padronizadas de jogos com condições idênticas para todos os competidores. Três princípios dessa tradição são incorporados integralmente a este trabalho: bancos fixos de cenários (aqui, sementes de geração procedural), separação estrita entre conjunto de calibração e conjunto de teste, e métricas agregadas sobre grandes quantidades de partidas para diluir variância."))
	parts.append(h2("2.5 Custo computacional e o espectro de sofisticação"))
	parts.append(p("No extremo sofisticado do espectro de decisão está o Monte Carlo Tree Search (MCTS), que estima o valor de ações explorando árvores de futuros possíveis (BROWNE et al., 2012). O MCTS alcança alta qualidade estratégica ao custo de milhares de simulações por decisão — custo que o torna inviável para os lotes de milhares de partidas deste experimento. Ele é adotado aqui como referência teórica de teto de qualidade, e não como modelo implementado. O modelo híbrido proposto ataca exatamente o eixo que o MCTS ilustra: quanto vale cada unidade adicional de processamento em termos de qualidade de decisão? A formalização desse compromisso, com um parâmetro explícito de troca (lambda), alinha-se à discussão de trade-offs de Browne et al. (2012)."))

	# 3 SIMULADOR
	parts.append(h1("3 O Simulador Tático"))
	parts.append(p("Optou-se por desenvolver um jogo novo, construído especificamente para a pesquisa, em vez de instrumentar um jogo existente. A decisão garante controle total sobre regras, determinismo e instrumentação de medição — requisitos incompatíveis com títulos comerciais fechados. O gênero é o combate tático por turnos em grade (na tradição de jogos como XCOM), no formato todos-contra-todos com três agentes. O simulador foi implementado no motor Godot 4.7, com scripts GDScript, e é executável tanto em modo visual (para inspeção e demonstração) quanto em modo headless (sem renderização, para os lotes experimentais)."))
	parts.append(h2("3.1 Ambiente"))
	parts.append(h3("3.1.1 Grade e geração procedural por sementes"))
	parts.append(p("O mapa é uma grade bidimensional de 40x40 células, cada uma de um dentre quatro tipos: vazia, parede (bloqueia movimento e visão), cobertura leve e cobertura pesada (transponíveis; não bloqueiam visão; reduzem dano conforme a Seção 3.3). A dimensão 40x40 foi validada empiricamente: com alcance de visão 8 e movimento de 3 células por turno, produz partidas cuja duração média observada varia de 30 a 90 turnos conforme os modelos envolvidos — longas o bastante para manobra e curtas o bastante para caber no limite de 100 turnos (Seção 3.3.4) e viabilizar lotes de 1000 partidas em minutos."))
	parts.append(p("Cada mapa é gerado proceduralmente a partir de uma semente inteira que alimenta um gerador congruente determinístico: a mesma semente produz sempre o mesmo mapa, os mesmos pontos de nascimento e, dadas as mesmas IAs, exatamente a mesma partida. O gerador posiciona segmentos de parede (10 a 14, de 3 a 7 células) e blocos de cobertura (8 a 12 leves, 4 a 6 pesados), respeitando uma zona de segurança ao redor dos nascimentos, e valida por busca em largura que todos os agentes podem se alcançar; mapas inválidos são regenerados."))
	parts.append(h3("3.1.2 Setores e neutralização da vantagem de terreno"))
	parts.append(p("Para impedir que posições fixas favoreçam sistematicamente um jogador, o mapa é dividido em quatro setores de 20x20, e cada um dos três agentes nasce na região central de um setor distinto, sorteado pela semente. Ao longo de 1000 partidas, nenhuma cor de agente ocupa preferencialmente qualquer região do mapa. A validação experimental dessa neutralização é apresentada no Capítulo 7."))
	parts.append(h2("3.2 Agentes e percepção"))
	parts.append(p("Cada agente possui posição, pontos de vida (100), alcance de visão (8 células, distância de Chebyshev), orientação (direção para onde olha), estado vivo/morto e identificador de cor (verde, vermelho ou azul). São três agentes independentes — não há equipes — e o controle é estritamente um por vez, em turnos sequenciais (Seção 3.3.1)."))
	parts.append(p("A percepção é deliberadamente limitada: um agente conhece a posição de um inimigo apenas se ele estiver dentro do seu cone de visão de 120 graus, centrado na orientação, a até 8 células, com linha de visão desobstruída — paredes bloqueiam a visão; coberturas, não. A orientação acompanha a última ação: mover vira o agente para a direção do deslocamento; atacar, para o alvo. Duas regras completam o modelo perceptivo: (i) memória tática — o agente guarda a última posição em que viu cada inimigo e investiga a mais próxima, esquecendo-a ao chegar lá e nada encontrar; (ii) revelação por dano — receber um tiro revela a posição do atirador mesmo fora do cone, análogo a ouvir o disparo, o que impede que um agente seja eliminado por trás sem chance de reação. Sem informação alguma, o agente explora destinos sorteados por um gerador aleatório semeado pela semente da partida, preservando o determinismo."))
	parts.append(h2("3.3 Regras de combate"))
	parts.append(h3("3.3.1 Turnos e resolução sequencial"))
	parts.append(p("O sistema é de turnos sequenciais: a cada turno completo, cada agente vivo age exatamente uma vez, um após o outro, em ordem fixa dentro da partida; agentes mortos são pulados. Resolução sequencial significa, portanto, que não há simultaneidade a resolver: quando um agente decide, o estado que ele observa já incorpora as ações dos que agiram antes dele no turno. Não existe disputa por alvo: se dois agentes poderiam atacar o mesmo inimigo, cada um decide em seu próprio momento, sobre o estado atualizado — não há otimização conjunta nem arbitragem, pois os agentes são adversários independentes."))
	parts.append(h3("3.3.2 Iniciativa e neutralização do viés de primeiro turno"))
	parts.append(p("Agir primeiro é vantagem. Para anulá-la estatisticamente, a ordem inicial é rotacionada entre as partidas do lote: a partida i inicia pelo agente i mod 3, de modo que cada agente inicia exatamente um terço das simulações. Essa é a ordem de resolução alternada entre rodadas mencionada no pré-projeto, agora formalizada por rotação determinística uniforme."))
	parts.append(h3("3.3.3 Ações, linha de tiro e cobertura"))
	parts.append(p("No seu turno, o agente pode mover-se até 3 células (caminho validado por busca em largura em 4 direções, respeitando paredes) e executar uma ação: atacar um inimigo ou permanecer. O ataque exige três condições: alvo dentro do alcance (igual ao alcance de visão), linha de visão desobstruída e alinhamento em linha reta — horizontal, vertical ou diagonal perfeita. A restrição de linha reta é necessária para que a cobertura direcional seja efetiva; sem ela, ângulos arbitrários de tiro contornariam qualquer defesa."))
	parts.append(p("Cobertura, neste trabalho, é um tipo de célula do mapa, e a proteção que confere é direcional e automática: um defensor está protegido de um atacante quando existe célula de cobertura ortogonalmente adjacente ao defensor na direção desse atacante. O dano é determinístico: Dano = 30 - Redução, com redução de 10 para cobertura leve e 20 para pesada (prevalecendo a maior quando aplicável). Não há qualquer sorteio em combate: toda a aleatoriedade do experimento está confinada à geração dos mapas pelas sementes."))
	parts.append(h3("3.3.4 Condição de vitória e limite de turnos"))
	parts.append(p("A partida termina quando resta um único agente vivo (vencedor) ou ao atingir o limite de 100 turnos, caso em que é declarado empate independentemente dos pontos de vida restantes. O valor 100 foi definido empiricamente como teto de segurança: as durações médias observadas nos experimentos ficam entre 30 e 90 turnos conforme os modelos, de modo que o limite raramente interrompe partidas que convergiriam, mas impede laços infinitos de perseguição mútua e limita o custo dos lotes. O empate é adicionalmente penalizado na pontuação (Seção 5.2), desencorajando estratégias de sobrevivência passiva."))
	parts.append(h2("3.4 Custo computacional abstrato"))
	parts.append(p("O custo computacional de uma decisão é medido por contagem de operações elementares, e não por tempo de relógio. Três contadores são mantidos por agente: cálculos de linha de visão executados, nós visitados nas buscas de caminho (BFS) e ações geradas e avaliadas pela IA. O custo total é a soma dos três, com peso unitário. A medição é ativada exclusivamente durante a fase de decisão do agente da vez — mede-se o custo de decidir, não o de executar a ação — por um medidor acoplado ao ambiente que a infraestrutura liga e desliga a cada turno."))
	parts.append(p("A opção pela contagem abstrata responde a uma fragilidade clássica das medições em milissegundos: dependência do hardware, do sistema operacional e da carga da máquina no momento do teste. Operações contadas são invariantes: o mesmo experimento produz exatamente os mesmos custos em qualquer computador, o que torna os resultados auditáveis e comparáveis entre pesquisadores."))
	parts.append(h2("3.5 Aprendizado entre partidas"))
	parts.append(p("Os agentes não começam cada simulação do zero dentro de um lote: a mesma instância de IA disputa todas as partidas e recebe, ao final de cada uma, a pontuação obtida (+3 vitória, -1 empate, -3 derrota). A IA heurística utiliza esse sinal para calibrar seus pesos por subida de encosta (hill-climbing): joga uma janela de 25 partidas com uma configuração de pesos, mede a média de pontos e a adota se superar a melhor média conhecida, revertendo caso contrário; a janela seguinte testa uma perturbação da melhor configuração, com gerador aleatório semeado — o processo inteiro é reprodutível. Ao final do lote, a evolução completa (pesos testados, média por janela, decisão de adotar ou reverter) é gravada em arquivo próprio, apresentado junto aos resultados, e as instâncias são descartadas: cada lote parte do zero. Os modelos aleatório e reativo não possuem parâmetros ajustáveis e servem de contraste estático."))
	parts.append(h2("3.6 Arquitetura e infraestrutura experimental"))
	parts.append(p("O software separa estritamente as responsabilidades: o núcleo de simulação não conhece a lógica das IAs; cada IA implementa um contrato único — receber o estado e devolver uma ação — e a simulação valida e aplica a ação devolvida; a coleta de dados apenas observa. Trocar o modelo de um jogador é uma operação de uma linha (ou um argumento de linha de comando), o que garante que todos os modelos joguem exatamente o mesmo jogo."))
	parts.append(p("Cada lote experimental gera uma pasta autodocumentada e imutável contendo: o manifesto da execução (data, banco de sementes, modelos por jogador, todas as constantes de jogo e parâmetros de IA, duração); o registro de cada partida com uma linha por jogador (semente, iniciador, vencedor, pontos, turnos, dano causado e recebido, métricas derivadas e custo aberto por tipo de operação); o resumo agregado com médias, desvios-padrão e o escore estratégico; o registro do aprendizado janela a janela; e, opcionalmente, o registro turno a turno (ação, posição, proteção, inimigos visíveis de cada agente em cada turno). Um lote de 1000 partidas executa em cerca de 70 a 120 segundos em modo headless."))

	# 4 MODELOS
	parts.append(h1("4 Modelos de Tomada de Decisão"))
	parts.append(p("Quatro modelos são comparados, em níveis crescentes de uso de informação. A Tabela 1 resume a diferença prática entre eles."))
	parts.append(table("Tabela 1 — Comparativo dos modelos de tomada de decisão",
		["Modelo", "Usa o estado?", "Mecanismo", "Aprende?", "Papel"],
		[
			["Aleatório", "Não", "Sorteia uma ação válida", "Não", "Piso de desempenho"],
			["Reativo", "Parcial", "Regras fixas: atacar se vê; senão caçar/explorar", "Não", "Adversário padrão"],
			["Heurístico", "Sim", "Argmax do valor estratégico multicritério", "Pesos (hill-climbing)", "Estratégia sem custo"],
			["Híbrido (proposto)", "Sim", "Valor estratégico - lambda x custo", "Pesos e lambda", "Contribuição da pesquisa"],
		], [3.2, 2.6, 5.6, 3.0, 3.4]))
	parts.append(h2("4.1 IA Aleatória"))
	parts.append(p("Enumera as ações válidas do turno (ataques possíveis, movimentos alcançáveis e permanecer) e sorteia uma, com gerador semeado pela semente da partida e pelo identificador do jogador — mesmo o acaso é reprodutível. Define o piso de desempenho: qualquer modelo que use informação deve superá-la."))
	parts.append(h2("4.2 IA Reativa"))
	parts.append(p("Modelo estímulo-resposta com três regras em cascata: se há inimigo com linha de tiro reta, ataca o mais próximo; se vê inimigo mas sem linha de tiro, aproxima-se para alinhar; se não vê ninguém, dirige-se à última posição conhecida ou explora. Representa o agente funcional básico da indústria e cumpre segundo papel metodológico: é o adversário padrão contra o qual os modelos avaliados jogam, garantindo oposição idêntica para todos."))
	parts.append(h2("4.3 IA Heurística"))
	parts.append(p("Instância de Utility AI (MARK; DILL, 2010): a cada turno com contato visual, avalia todas as posições alcançáveis (incluindo permanecer) pela função:"))
	parts.append(formula("ValorEstratégico = w1.Vida + w2.Cobertura + w3.Proximidade + w4.Risco + Movimentação"))
	parts.append(p("onde Vida é a proporção de pontos de vida atual do agente; Cobertura é a proteção potencial da posição avaliada (0; 0,5 leve; 1 pesada); Proximidade é o inverso da distância ao inimigo visível mais próximo; Risco é a fração de inimigos visíveis com linha de visão para a posição (fator de impacto negativo); e Movimentação é um incentivo fixo de deslocamento: +0,2 por célula percorrida até a posição avaliada e -0,2 se a posição já foi visitada na partida (permanecer parado repete a própria célula). O termo de movimentação garante manobra constante mesmo durante o combate, impedindo o entrincheiramento passivo, e é mantido fixo — regra de comportamento — fora do vetor de pesos calibráveis."))
	parts.append(p("Os pesos iniciais adotados são w1 = 0,1, w2 = 0,3, w3 = 0,5 e w4 = -0,2. Diferentemente do pré-projeto, esses valores não são arbitrários nem definitivos: foram selecionados por varredura comparativa no banco de calibração de 200 sementes (isolado do banco de teste, prevenindo sobreajuste) e são continuamente refinados pelo aprendizado entre partidas descrito na Seção 3.5, cujo histórico integral acompanha os resultados. Escolhida a melhor posição, a IA ataca o alvo alinhado mais próximo, quando existir. Sem contato visual, recorre à caça e exploração comuns, sem pagar o custo da avaliação posicional completa."))
	parts.append(h2("4.4 Modelo Híbrido (proposto)"))
	parts.append(p("A contribuição central da pesquisa estende a avaliação heurística com a penalização explícita do custo computacional:"))
	parts.append(formula("ScoreAção = ValorEstratégico - lambda x CustoComputacional"))
	parts.append(p("onde CustoComputacional é o custo, em operações contadas (Seção 3.4), de avaliar a própria ação, e lambda é o parâmetro de compromisso que converte operações em unidades de valor estratégico. Com lambda = 0 o modelo colapsa no heurístico puro; com lambda grande, aproxima-se do reativo. O valor de lambda será calibrado no banco de 200 sementes."))
	parts.append(p("Seguindo o protocolo experimental definido (Capítulo 6), o modelo híbrido será construído somente após a análise da campanha de caracterização dos modelos básicos — a solução é derivada dos dados, e sua especificação final (incluindo a semântica exata do termo de custo) será fixada nessa etapa, com as alternativas documentadas."))

	# 5 MÉTRICAS
	parts.append(h1("5 Métricas de Avaliação"))
	parts.append(h2("5.1 Métricas individuais"))
	parts.append(p("Para cada modelo, sobre o conjunto de partidas de um lote, calculam-se: WinRate — fração de vitórias; DamageRatio — dano causado dividido por max(dano recebido, epsilon), com epsilon = 1 prevenindo divisão por zero; CoverUsage — fração dos turnos em que o agente terminou em posição com cobertura adjacente (proteção potencial); TurnsToVictory — média de turnos para vencer, computada sobre vitórias, com empates penalizados pelo valor máximo (100) e derrotas excluídas (a métrica mede turnos necessários para vencer); e CustoComputacionalMedio — média por partida das operações contadas na decisão (Seção 3.4)."))
	parts.append(h2("5.2 Pontuação de partida"))
	parts.append(p("Cada partida atribui pontos ao modelo: +3 por vitória, -1 por empate e -3 por derrota. O empate é deliberadamente penalizado — e não tratado como neutro — porque um modelo que apenas sobrevive sem decidir a partida (por exemplo, entrincheirando-se até o limite de turnos) não demonstra eficácia estratégica. A média de pontos por partida, na faixa de -3 a +3, mostrou-se na prática a métrica mais legível para comparação direta entre modelos."))
	parts.append(h2("5.3 Escore estratégico composto"))
	parts.append(p("As dimensões individuais são agregadas no Strategic Score:"))
	parts.append(formula("StrategicScore = 0,3.WinRate + 0,2.DamageRatio + 0,2.CoverUsage + 0,2.Efficiency + 0,1.(1/max(Custo, epsilon))"))
	parts.append(p("com Efficiency = 1/max(TurnsToVictory, 1) e epsilon = 1. Na prática, a fórmula representa uma definição operacional de jogar bem: vencer (30%), causar mais dano do que receber (20%), usar o terreno (20%), vencer rápido (20%) e decidir barato (10%). Os pesos expressam a prioridade da vitória sobre os demais critérios e do desempenho tático sobre o custo, e foram fixados a priori — antes de qualquer comparação entre modelos — para que não possam ser acusados de favorecer o modelo proposto."))
	parts.append(p("Uma limitação conhecida é registrada com transparência: o DamageRatio não é normalizado à faixa das demais componentes — quando um modelo vence sem receber dano, a razão assume valores altos e domina o escore. A adoção de um teto ou normalização está em avaliação com a orientação; qualquer alteração será aplicada uniformemente a todos os modelos, preservando a comparação. Por essa razão, as análises parciais reportam sempre as métricas individuais ao lado do escore composto."))

	# 6 PROTOCOLO
	parts.append(h1("6 Protocolo Experimental"))
	parts.append(h2("6.1 Bancos de sementes"))
	parts.append(p("Dois bancos congelados e disjuntos de sementes foram gerados uma única vez por um gerador congruente linear documentado (Park-Miller, semente-mestra fixa): 200 sementes de calibração (tuning), usadas exclusivamente para ajuste de pesos e de lambda, e 1000 sementes de benchmark, reservadas à avaliação. A separação previne sobreajuste; os arquivos são imutáveis e versionados — regenerá-los invalidaria a comparabilidade de resultados anteriores."))
	parts.append(h2("6.2 Neutralização de vieses"))
	parts.append(p("Três mecanismos garantem que diferenças de desempenho sejam atribuíveis aos modelos, e não ao ambiente: sorteio de setores de nascimento por semente (vantagem de terreno), rotação uniforme de iniciativa (vantagem de primeiro turno) e combate determinístico (variância de sorte). A eficácia dos mecanismos foi verificada experimentalmente (Seção 7.1)."))
	parts.append(h2("6.3 Campanha de coleta"))
	parts.append(p("A campanha segue etapas ordenadas, cada uma com 1000 partidas documentadas: (1) autoconfronto por modelo — três instâncias do mesmo modelo em cada partida (3x aleatório, 3x reativo, 3x heurístico), caracterizando o comportamento decisório de cada um isoladamente; (2) confronto misto — um agente de cada modelo na mesma partida; (3) análise das métricas de tomada de decisão e identificação dos melhores comportamentos, com rodada adicional se necessário; (4) construção do modelo híbrido a partir do que os dados mostrarem; (5) avaliação final do híbrido — 1000 partidas contra cada modelo e contra os melhores identificados, verificando a hipótese de superioridade em eficácia e custo. Todas as execuções usam o mesmo banco de 1000 sementes, garantindo comparabilidade integral entre etapas."))
	parts.append(h2("6.4 Reprodutibilidade"))
	parts.append(p("Todo o pipeline é determinístico de ponta a ponta: mesma semente, mesmos modelos e mesmos parâmetros produzem partidas byte a byte idênticas — propriedade verificada por reexecução integral de lotes. O código, os bancos de sementes, as execuções oficiais e este documento são versionados em repositório público, e cada pasta de execução carrega seu manifesto de condições (Seção 3.6)."))

	# 7 RESULTADOS PARCIAIS
	parts.append(h1("7 Resultados Parciais"))
	parts.append(h2("7.1 Validação da neutralidade do ambiente"))
	parts.append(p("Antes de comparar modelos, validou-se o instrumento: 1000 partidas do banco de benchmark foram executadas com os três agentes controlados pela mesma IA reativa. Em um ambiente neutro, as taxas de vitória devem ser estatisticamente indistinguíveis — qualquer assimetria sistemática denunciaria viés de terreno, cor ou iniciativa. A Tabela 2 apresenta o resultado."))
	parts.append(table("Tabela 2 — Validação de neutralidade: 3 agentes idênticos (IA reativa), 1000 partidas",
		["Agente", "WinRate", "DamageRatio (média ± dp)", "CoverUsage (média ± dp)"],
		[
			["Verde", "0,297", "5,32 ± 12,03", "0,058 ± 0,152"],
			["Vermelho", "0,298", "6,24 ± 13,38", "0,055 ± 0,145"],
			["Azul", "0,310", "6,48 ± 13,81", "0,053 ± 0,147"],
		], [3.0, 2.6, 5.6, 5.6]))
	parts.append(p("Com N = 1000 e probabilidade de referência de 1/3, a flutuação estatística esperada é de aproximadamente 1,5 ponto percentual; a maior diferença observada foi de 1,3 ponto (0,297 contra 0,310) — dentro do ruído. Conclui-se que o sorteio de setores e a rotação de iniciativa neutralizam os vieses com sucesso, e que diferenças observadas doravante são atribuíveis aos modelos. Os cerca de 9% de partidas restantes terminaram em empate no limite de turnos. Esta validação foi executada na versão inicial das mecânicas e será reexecutada como primeira etapa da campanha definitiva, sob o conjunto final de regras."))
	parts.append(h2("7.2 Efeito da percepção limitada"))
	parts.append(p("A introdução do campo de visão produziu um resultado metodologicamente relevante: sob onisciência, a IA heurística vencia com folga a reativa; com percepção limitada, a vantagem inicial praticamente desapareceu (WinRate de 0,30 para todas em lote de calibração). A leitura é direta: a avaliação posicional só agrega valor durante o contato visual, e partidas com busca às cegas comprimem a diferença entre modelos. O achado reforça a motivação do modelo híbrido — concentrar o gasto computacional nos momentos em que a avaliação de fato informa a decisão."))
	parts.append(h2("7.3 Efeito da linha de tiro reta e do incentivo de movimentação"))
	parts.append(p("Duas regras subsequentes recuperaram e ampliaram a diferenciação estratégica. A restrição de tiro em linha reta tornou a cobertura direcional efetiva (defesas deixaram de ser contornáveis por ângulo), beneficiando o modelo que sabe se posicionar. O incentivo de movimentação eliminou o entrincheiramento passivo. A Tabela 3 apresenta o lote de calibração mais recente (30 partidas, banco de tuning), com a heurística enfrentando duas reativas."))
	parts.append(table("Tabela 3 — Lote de calibração: heurística vs. duas reativas (30 partidas, regras completas)",
		["Métrica", "Heurística", "Reativa (1)", "Reativa (2)"],
		[
			["Pontuação média", "-0,20", "-1,20", "-1,60"],
			["WinRate", "0,333", "0,167", "0,100"],
			["DamageRatio médio", "6,60", "2,82", "1,93"],
			["CoverUsage médio", "0,128", "0,071", "0,106"],
			["Custo computacional médio", "1401,1", "884,7", "989,6"],
			["StrategicScore", "1,448", "0,630", "0,440"],
		], [4.6, 3.4, 3.4, 3.4]))
	parts.append(p("A heurística lidera todas as dimensões de eficácia — vence o dobro da melhor reativa e mantém pontuação média muito superior — ao custo de cerca de 50% mais operações por partida. Esse retrato quantifica exatamente o eixo da pesquisa: qualidade estratégica custa processamento, e o modelo híbrido buscará o ponto ótimo dessa troca."))
	parts.append(h2("7.4 Aprendizado registrado"))
	parts.append(p("O mecanismo de aprendizado entre partidas produz seu registro auditável. Em lote ilustrativo de 60 partidas, a primeira janela (pesos iniciais) obteve média de -0,84 pontos e foi adotada como referência; a perturbação testada na segunda janela piorou a média para -1,00 e foi revertida, com o modelo retornando à melhor configuração conhecida — comportamento esperado do hill-climbing e visível no arquivo de aprendizado que acompanha cada execução."))
	parts.append(h2("7.5 Estado da campanha"))
	parts.append(p("No momento da escrita, a etapa 1 da campanha definitiva (autoconfrontos de 1000 partidas por modelo) está em execução. Todos os resultados desta seção, bem como os das etapas seguintes, são publicados como pastas de execução autodocumentadas no repositório do projeto."))

	# 8 CRONOGRAMA
	parts.append(h1("8 Cronograma"))
	parts.append(p("As etapas de construção do simulador, da infraestrutura experimental e dos modelos básicos estão concluídas. A Tabela 4 apresenta o planejamento das etapas restantes."))
	parts.append(table("Tabela 4 — Cronograma das etapas restantes",
		["Etapa", "Descrição", "Período (2026)"],
		[
			["Campanha — autoconfrontos", "3x aleatória, 3x reativa, 3x heurística (1000 partidas cada)", "Julho"],
			["Campanha — confronto misto", "Um agente de cada modelo (1000 partidas)", "Agosto"],
			["Análise intermediária", "Métricas decisórias; definição final do termo de custo", "Agosto"],
			["Modelo híbrido", "Implementação e calibração de lambda (banco de tuning)", "Setembro"],
			["Avaliação final", "Híbrido vs. cada modelo e vs. melhores (1000 partidas cada)", "Setembro"],
			["Análise e redação final", "Consolidação, gráficos, revisão e depósito", "Outubro-Novembro"],
		], [4.2, 7.4, 3.2]))

	# 9 CONSIDERAÇÕES
	parts.append(h1("9 Considerações Parciais"))
	parts.append(p("O trabalho encontra-se com o instrumento de pesquisa completo e validado: um simulador tático determinístico e reprodutível, com percepção limitada, cobertura direcional efetiva, medição de custo independente de hardware, aprendizado auditável entre partidas e um pipeline experimental que documenta integralmente cada execução. Os resultados parciais estabeleceram a neutralidade do ambiente — pré-condição lógica de toda comparação — e já quantificam o compromisso central da pesquisa: o modelo heurístico supera o reativo em todas as dimensões de eficácia ao custo de cerca de 50% mais processamento por partida."))
	parts.append(p("As etapas seguintes percorrem a campanha de caracterização, a construção do modelo híbrido a partir dos dados e a verificação final da hipótese: a de que uma formulação explícita do compromisso entre valor estratégico e custo computacional produz um agente mais eficiente que as abordagens isoladas. Os riscos metodológicos conhecidos — em particular a escala do DamageRatio no escore composto — estão registrados e serão resolvidos com a orientação antes do benchmark final."))

	# REFERÊNCIAS
	parts.append(h1("Referências"))
	parts.append(refp([run("BROWNE, C. B. et al. A Survey of Monte Carlo Tree Search Methods. "), run("IEEE Transactions on Computational Intelligence and AI in Games", {"b": true}), run(", v. 4, n. 1, p. 1-43, 2012.")]))
	parts.append(refp([run("GODOT ENGINE. "), run("Godot Engine Documentation", {"b": true}), run(". 2026. Disponível em: https://docs.godotengine.org. Acesso em: 21 jul. 2026.")]))
	parts.append(refp([run("MARCOTTE, R.; HAMILTON, H. J. Behavior Trees for Modelling Artificial Intelligence in Games: A Tutorial. "), run("The Computer Games Journal", {"b": true}), run(", v. 6, p. 171-184, 2017.")]))
	parts.append(refp([run("MARK, D.; DILL, K. Improving AI Decision Modeling Through Utility Theory. In: GAME DEVELOPERS CONFERENCE, 2010, São Francisco. "), run("GDC Vault", {"b": true}), run(", 2010.")]))
	parts.append(refp([run("MILLINGTON, I.; FUNGE, J. "), run("Artificial Intelligence for Games", {"b": true}), run(". 2. ed. Boca Raton: CRC Press, 2016.")]))
	parts.append(refp([run("PÉREZ-LIÉBANA, D. et al. General Video Game AI: A Multitrack Framework for Evaluating Agents, Games, and Content Generation Algorithms. "), run("IEEE Transactions on Games", {"b": true}), run(", v. 11, n. 3, p. 195-214, 2019.")]))
	parts.append(refp([run("RUSSELL, S.; NORVIG, P. "), run("Artificial Intelligence: A Modern Approach", {"b": true}), run(". 3. ed. Upper Saddle River: Pearson, 2010.")]))

	# APÊNDICE A
	parts.append(h1("Apêndice A — Estrutura dos Dados Coletados"))
	parts.append(p("Cada execução de lote gera uma pasta imutável com carimbo de data e hora contendo os arquivos descritos a seguir, todos em formatos abertos (texto e CSV)."))
	parts.append(p([run("manifest.txt", {"b": true}), run(" — condições da execução: data e hora, versão do motor, banco e faixa de sementes, regra de rotação de iniciativa, modelo de IA de cada jogador, constantes de jogo (dano base 30; reduções 10/20; limite 100 turnos; movimento 3; vida 100; visão 8; cone 120 graus), parâmetros de IA e duração.")]))
	parts.append(p([run("partidas.csv", {"b": true}), run(" — uma linha por jogador por partida: identificador, semente, jogador que iniciou, jogador, modelo, vencedor, indicador de vitória, pontos (+3/-1/-3), turnos, dano causado e recebido, DamageRatio, CoverUsage, custo total e custo aberto por tipo de operação (linha de visão, nós de busca, ações avaliadas).")]))
	parts.append(p([run("resumo.csv", {"b": true}), run(" — agregados por jogador: partidas, pontuação total e média, WinRate, DamageRatio e CoverUsage (média e desvio-padrão), TurnsToVictory, Efficiency, custo médio e desvio, StrategicScore.")]))
	parts.append(p([run("aprendizado.csv", {"b": true}), run(" — evolução do aprendizado janela a janela: pesos testados, média de pontos da janela e decisão (adotado/revertido); modelos estáticos registram a ausência de aprendizado.")]))
	parts.append(p([run("turnos.csv", {"b": true}), run(" (opcional) — registro fino turno a turno: ação escolhida, posição, proteção por cobertura e inimigos visíveis de cada agente.")]))

	# APÊNDICE B
	parts.append(h1("Apêndice B — Correspondência com os Apontamentos da Banca"))
	parts.append(p("O quadro abaixo mapeia cada apontamento da banca de qualificação para a seção desta monografia que o responde."))
	parts.append(table("Quadro 1 — Apontamentos da banca e seções correspondentes",
		["Apontamento", "Resposta"],
		[
			["Ausência de resultados parciais", "Capítulo 7 (neutralidade validada com 1000 partidas; calibração; aprendizado)"],
			["Como será medido o custo computacional abstrato", "Seção 3.4 (contagem de operações: LOS, nós de busca, ações avaliadas)"],
			["Jogo existente ou novo? Que gênero?", "Capítulo 3, abertura (jogo novo em Godot; tático por turnos em grade, 3 agentes)"],
			["Diferença prática entre os quatro modelos", "Tabela 1 e Capítulo 4"],
			["O que significa resolução sequencial", "Seção 3.3.1 (um agente por vez sobre estado atualizado; sem simultaneidade)"],
			["Como funciona a ordem alternada entre rodadas", "Seção 3.3.2 (rotação determinística: partida i inicia pelo agente i mod 3)"],
			["Como foi definido o limite de 100 turnos", "Seção 3.3.4 (empírico: durações médias de 30-90 turnos; teto de segurança)"],
			["O que conta como cobertura", "Seção 3.3.3 (célula de cobertura; proteção direcional; leve -10, pesada -20)"],
			["Quantos agentes por equipe; controle por turno", "Seções 3.2 e 3.3.1 (3 agentes independentes, sem equipes; um por vez)"],
			["Dois agentes podem atacar o mesmo alvo?", "Seção 3.3.1 (adversários independentes; cada um decide em seu turno)"],
			["Há aprendizado entre partidas?", "Seção 3.5 (hill-climbing por janelas; registro em arquivo; reset por lote)"],
			["Origem dos pesos da heurística", "Seção 4.3 (varredura no banco de calibração + aprendizado; valores atuais)"],
			["O que o Strategic Score representa; por que esses pesos", "Seção 5.3 (definição operacional de jogar bem; pesos a priori; limitação registrada)"],
			["O mapa 40x40 foi testado?", "Seção 3.1.1 e Capítulo 7 (validado: durações, neutralidade, escala de lote)"],
		], [7.2, 7.6]))

	write_docx(parts)

# ---------- seções e pacote ----------

func sect_pr(with_header):
	var header_ref = '<w:headerReference w:type="default" r:id="rIdHdr"/>' if with_header else ""
	return '<w:sectPr>%s<w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1701" w:right="1134" w:bottom="1134" w:left="1701" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>' % header_ref

func write_docx(parts):
	var body = "".join(parts)
	# sectPr final (seção textual, com cabeçalho numerado)
	body += sect_pr(true)

	var document = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><w:body>%s</w:body></w:document>' % body

	var styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/><w:sz w:val="24"/><w:szCs w:val="24"/><w:lang w:val="pt-BR"/></w:rPr></w:rPrDefault></w:docDefaults><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:pPr><w:outlineLvl w:val="0"/><w:spacing w:line="360" w:lineRule="auto"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:pPr><w:outlineLvl w:val="1"/><w:spacing w:line="360" w:lineRule="auto"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/><w:pPr><w:outlineLvl w:val="2"/><w:spacing w:line="360" w:lineRule="auto"/></w:pPr><w:rPr><w:sz w:val="24"/></w:rPr></w:style></w:styles>'

	var settings = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:updateFields w:val="true"/></w:settings>'

	var header1 = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="20"/></w:rPr><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:rPr><w:sz w:val="20"/></w:rPr><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r><w:r><w:rPr><w:sz w:val="20"/></w:rPr><w:fldChar w:fldCharType="end"/></w:r></w:p></w:hdr>'

	var content_types = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/><Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/></Types>'

	var rels_root = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'

	var rels_doc = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rIdSettings" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/><Relationship Id="rIdHdr" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/></Relationships>'

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
		"word/header1.xml": header1,
		"word/_rels/document.xml.rels": rels_doc,
	}
	for fname in files:
		zip.start_file(fname)
		zip.write_file(files[fname].to_utf8_buffer())
		zip.close_file()
	zip.close()
	print("OK: ", out_path)
