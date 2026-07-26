# Resultados Finais — Benchmark Oficial (Fase 5)

Execução final sobre o banco oficial de 1000 *seeds* de benchmark, sob o conjunto definitivo de regras (percepção por cone de 120°, sensor de proximidade, tiro em linha reta, cobertura direcional, pontuação +3/−1/−3, aprendizado entre partidas). **7.000 partidas** em 7 lotes, todos documentados em `data/runs/`.

Configuração do Art3miz 0.1: λ = 0,005, pesos herdados do aprendizado da campanha (ver `resultados_hibrido.md`).

## 1. Caracterização por autoconfronto

Três instâncias do mesmo modelo por partida. Em condições simétricas, a taxa de vitória converge para ~1/3 em qualquer modelo funcional — o que a comparação revela é **o preço pago por esse desempenho** e a capacidade de decidir a partida.

| Modelo | WinRate | DamageRatio | CoverUsage | Turnos p/ vitória | Empates | **Custo** | **StrategicScore** |
|---|---|---|---|---|---|---|---|
| Aleatória | 0,000 | 1,14 | 0,051 | 100,0 | **1000 (100%)** | 2323 | 0,145 |
| Reativa | 0,312 | 5,71 | 0,052 | 35,5 | 65 (6,5%) | 437 | 0,473 |
| Heurística | 0,295 | 4,55 | 0,096 | 45,1 | 116 (11,6%) | 777 | 0,438 |
| **Art3miz 0.1** | **0,314** | 5,18 | **0,104** | **29,3** | **57 (5,7%)** | **379** | **0,497** |

Achados:

- **O Art3miz 0.1 obtém o maior StrategicScore (0,497)**, à frente da reativa (0,473) e da heurística (0,438). Vence em quatro das cinco dimensões da métrica: taxa de vitória, uso de cobertura, rapidez para decidir a partida e economia computacional.
- **É o mais econômico entre todos os modelos funcionais**: 379 operações por partida, contra 437 da reativa (−13%) e 777 da heurística (−51%).
- **É o mais decisivo**: apenas 5,7% de empates, contra 11,6% da heurística — que, sendo mutuamente cautelosa, frequentemente se anula até o limite de turnos. Também vence mais rápido (29,3 turnos contra 35,5 e 45,1).
- Em eficiência estratégica (vitórias por mil operações), a ordem é **Art3miz 0.1 com 0,829 > reativa 0,714 > heurística 0,380**: mais de **duas vezes** a eficiência da heurística.
- A IA Aleatória confirma-se como piso absoluto: nenhuma vitória em 1000 partidas, pagando o **maior custo de todos** (2323) — enumera todas as opções e descarta a informação. Seu escore (0,145) a separa nitidamente dos modelos funcionais (0,438–0,497).

## 2. Confronto direto

O modelo avaliado contra oponentes de custo pleno.

### 2.1 Confronto triplo (decisivo)

| | Art3miz 0.1 | Heurística | Reativa |
|---|---|---|---|
| Pontuação média | −1,44 | −0,75 | −0,81 |
| **WinRate** | 0,225 | **0,339** | 0,330 |
| DamageRatio | 4,23 ± 10,38 | 5,21 ± 10,64 | 5,61 ± 11,07 |
| CoverUsage | **0,096** | 0,095 | 0,074 |
| TurnsToVictory | 44,4 | 39,8 | 39,3 |
| **Custo** | **510** | 719 | 484 |
| Eficiência (vit./1000 ops) | 0,441 | 0,472 | **0,682** |
| **StrategicScore** | 0,426 | 0,467 | **0,472** |

### 2.2 Contra dois oponentes idênticos

| Confronto | Art3miz 0.1 | Oponentes |
|---|---|---|
| vs 2 heurísticas | WR 0,232 · custo 492 · score 0,426 | WR 0,332 / 0,329 · custo ~700 · score ~0,470 |
| vs 2 reativas | WR 0,248 · custo 505 · score 0,433 | WR 0,332 / 0,329 · custo ~457 · score ~0,477 |

**Em competição direta o Art3miz 0.1 vence menos** (0,225–0,248 contra ~0,33 dos dois baselines), ainda que mantendo o menor custo entre os modelos analíticos e o maior uso de cobertura do confronto triplo.

## 2.3 Significância estatística

Todas as afirmações comparativas desta seção foram submetidas a teste formal. O relatório completo, com os testes escolhidos e sua justificativa, está em `analise_estatistica.md`; os resultados essenciais:

| Comparação | Teste | Resultado |
|---|---|---|
| As três taxas de vitória diferem entre si? | Qui-quadrado (df = 2) | χ² = 26,96 · **p < 0,001** · significativo |
| Art3miz 0.1 vs Heurística (vitórias) | Binomial condicional | **p < 0,001** · a heurística vence mais |
| Art3miz 0.1 vs Reativa (vitórias) | Binomial condicional | **p < 0,001** · a reativa vence mais |
| **Heurística vs Reativa (vitórias)** | Binomial condicional | **p = 0,757 · NÃO significativo** |
| Custo: Art3miz 0.1 vs Heurística | t pareado por *seed* | −208,5 ops · **p < 0,001** · efeito pequeno (d = −0,39) |
| Custo: Art3miz 0.1 vs Reativa | t pareado por *seed* | +26,0 ops · p = 0,082 · **sem diferença detectável** |

Dois desses resultados exigem revisão de afirmações que os dados brutos sugeriam:

**O "gradiente de inteligência" entre heurística e reativa não se sustenta.** A diferença de 0,339 contra 0,330 nas taxas de vitória é compatível com flutuação amostral (p = 0,757). Não há evidência de que a avaliação multicritério da heurística produza mais vitórias que as regras simples da reativa — apenas de que custa significativamente mais (+234,5 operações, p < 0,001, efeito médio). É um resultado desfavorável à sofisticação analítica, e deve ser reportado como tal.

**No confronto direto, o custo do Art3miz 0.1 não difere do da reativa** (p = 0,082). Sua economia é demonstrável em relação à heurística e ao MCTS, não em relação ao baseline mais simples.

### 2.4 StrategicScore com intervalo de confiança

Intervalos obtidos por *bootstrap* percentílico (2000 reamostragens) sobre os autoconfrontos:

| Modelo | StrategicScore | IC 95% |
|---|---|---|
| Aleatória | 0,134 | [0,114; 0,150] |
| Heurística | 0,438 | [0,421; 0,454] |
| Reativa | 0,469 | [0,453; 0,484] |
| **Art3miz 0.1** | **0,494** | **[0,479; 0,509]** |

O intervalo do Art3miz 0.1 **não se sobrepõe** ao da heurística — a superioridade no escore composto é estatisticamente distinguível. Já a sobreposição com a reativa (0,479–0,484) indica que, entre esses dois, **a diferença não é conclusiva**.

## 2.5 O espectro completo — confronto com o MCTS

Com o MCTS implementado, o extremo de alta qualidade e alto custo deixa de ser referência teórica e passa a ser ponto medido. Confronto de mil partidas entre MCTS, Art3miz 0.1 e IA Heurística:

| Métrica | MCTS | Heurística | Art3miz 0.1 |
|---|---|---|---|
| WinRate | **0,379** | 0,292 | 0,236 |
| Custo computacional | 2794,5 | 680,8 | **471,0** |
| **Eficiência** (vitórias/mil ops) | 0,136 | 0,429 | **0,501** |

O ordenamento inverte-se conforme a dimensão observada, e é exatamente esse contraste que o trabalho investiga: **o MCTS vence mais, o Art3miz 0.1 vence mais barato**.

### 2.5.1 O valor marginal da computação

A comparação permite quantificar diretamente o conceito central da fundamentação teórica — quanto vale cada unidade adicional de processamento:

| Passagem | Vitórias adicionais | Custo adicional | **Custo por vitória adicional** |
|---|---|---|---|
| Art3miz 0.1 → Heurística | +56 | +209.800 ops | ≈ 3.750 operações |
| Heurística → MCTS | +87 | +2.113.700 ops | ≈ 24.300 operações |

O retorno é **fortemente decrescente**: a primeira parcela de sofisticação analítica custa cerca de 3.750 operações por vitória adicional; a segunda, mais de seis vezes isso. Em termos do arcabouço de Russell e Wefald (1991), o valor marginal da computação cai rapidamente à medida que se sobe no espectro — e o ponto em que deixa de compensar depende do orçamento de processamento disponível, que é precisamente o que o parâmetro λ do modelo proposto torna explícito.

Este é o resultado que sustenta a tese do trabalho: **não existe um modelo melhor em absoluto; existe um compromisso, e ele pode ser medido, quantificado e controlado.**

## 3. Interpretação

Os resultados sustentam três conclusões, e é importante enunciá-las com precisão.

**A hipótese de eficiência confirma-se.** O Art3miz 0.1 reduz o custo computacional em 51% em relação à heurística pura e é o modelo funcional mais barato do estudo. Em condições simétricas, entrega desempenho equivalente ou superior aos demais (WinRate 0,314; menor taxa de empates; menor número de turnos até a vitória) por uma fração do processamento, alcançando o **maior StrategicScore do estudo (0,497)** e mais que o dobro da eficiência estratégica da heurística. A formalização do compromisso entre valor e custo produz, portanto, um agente mensuravelmente mais eficiente.

**A hipótese de superioridade competitiva não se confirma.** Quando enfrenta oponentes que pagam o custo pleno da análise, o Art3miz 0.1 vence menos (≈0,23 contra ≈0,33). A economia obtida ao deliberar seletivamente tem preço: nos turnos em que opta pelo regime econômico, o agente ocasionalmente perde a posição que a avaliação completa teria encontrado, e adversários que sempre deliberam exploram essa diferença.

**A IA Reativa revela-se um baseline notavelmente forte.** Com 484 operações e WinRate 0,330 no confronto triplo, apresenta a maior eficiência do confronto direto (0,682 vitórias por mil operações). O teste formal reforça a conclusão: **a heurística não vence significativamente mais que a reativa** (p = 0,757), embora gaste 48% mais operações (p < 0,001). Em ambientes táticos com percepção limitada e horizonte curto, regras simples e bem escolhidas são difíceis de superar — a sofisticação analítica precisa justificar seu custo, e neste domínio não justificou.

**A vantagem tem faixa de aplicabilidade, e ela foi delimitada.** A replicação em três escalas de mapa (`generalizacao.md`) mostra que a economia sobre a heurística **cresce com o tamanho do ambiente** — de 16% em 25×25 para 49% em 60×60 —, o que confirma o mecanismo: quanto maior o mapa, mais turnos sem contato visual, mais oportunidades de dispensar a deliberação. Em contrapartida, em mapas pequenos a IA Reativa **domina** o modelo proposto, sendo simultaneamente mais barata e mais eficaz. O modelo compensa em ambientes que ofereçam períodos de baixa criticidade; onde toda situação é crítica, não há o que economizar.

### 3.1 Síntese

O trabalho não demonstra que o modelo híbrido é o melhor jogador; demonstra, com evidência quantitativa sobre 7.000 partidas, que **existe um compromisso mensurável e controlável entre qualidade estratégica e custo computacional**, e que o parâmetro λ permite navegá-lo de forma monotônica e previsível (ver curva em `resultados_hibrido.md` §2.2). Para aplicações com orçamento de processamento restrito — jogos comerciais com limite de tempo por quadro, robótica embarcada, simulações em larga escala — o Art3miz 0.1 oferece um controle explícito que os modelos de referência não possuem: é possível escolher, por projeto, quanto desempenho se está disposto a trocar por economia.

## 4. Correção da métrica composta

A formulação original do StrategicScore somava grandezas em escalas incompatíveis, o que fazia os pesos nominais divergirem radicalmente do efeito real. Medido neste mesmo confronto triplo, o termo de dano — nominalmente 20% — contribuía com 0,85 a 1,12 do escore; o WinRate — nominalmente 30% — contribuía com 0,07 a 0,10; e o custo — nominalmente 10% — contribuía com 0,0002, cerca de quatro mil vezes menos que o previsto. A métrica media, na prática, quase somente a razão de dano, e era cega à eficiência computacional.

A correção (documentada em `metricas.md`) normaliza todos os termos ao intervalo [0, 1] antes da ponderação, **preservando exatamente os pesos originais** (0,30 / 0,20 / 0,20 / 0,20 / 0,10). Atua sobre a escala, não sobre a intenção do projeto de pesquisa, afastando qualquer suspeita de ajuste em favor do Art3miz 0.1.

Como a alteração incide sobre a agregação e não sobre a coleta, **os escores de todas as execuções foram recalculados a partir dos dados brutos preservados**, sem repetir simulações (`simulator/tools/recalcular_resumos.gd`). Os dados de cada partida permanecem intactos e auditáveis.

## 5. Reprodução

```bash
# Confronto decisivo
godot --headless --path simulator -- batch 1000 benchmark verde=art3miz vermelho=heuristica azul=reativa

# Autoconfrontos
godot --headless --path simulator -- batch 1000 benchmark verde=art3miz vermelho=art3miz azul=art3miz
godot --headless --path simulator -- batch 1000 benchmark verde=heuristica vermelho=heuristica azul=heuristica
godot --headless --path simulator -- batch 1000 benchmark verde=reativa vermelho=reativa azul=reativa
godot --headless --path simulator -- batch 1000 benchmark verde=aleatoria vermelho=aleatoria azul=aleatoria
```

Execuções determinísticas: os mesmos comandos reproduzem os mesmos resultados byte a byte.
