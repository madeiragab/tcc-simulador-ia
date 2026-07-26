# Atualizações para colar no Google Docs

O documento no Google Docs é a fonte da verdade (tem as fórmulas renderizadas e o brasão). Este arquivo traz os textos novos para você colar nas seções indicadas, sem precisar regenerar o .docx e perder as imagens.

---

## ▸ SUBSTITUIR o parágrafo do modelo híbrido na Seção 4.6

*(o parágrafo que hoje começa em "O modelo híbrido proposto — contribuição central da pesquisa — estende a avaliação heurística...")*

O modelo híbrido proposto — contribuição central da pesquisa — parte da formulação de compromisso entre valor estratégico e custo computacional:

$$\text{ScoreAção} = \text{ValorEstratégico} - \lambda \cdot \text{CustoComputacional}$$

A implementação inicial aplicou essa expressão no nível das ações: cada posição candidata teria descontado o custo, em operações contadas, de avaliá-la. Os experimentos de calibração mostraram que essa aplicação é inócua neste domínio, por duas razões mensuradas. Primeiro, a decomposição do custo revelou que o loop de avaliação posicional responde por apenas 16% do consumo total do agente heurístico, enquanto 84% concentra-se na busca de caminho executada a cada turno — de modo que nenhum valor de λ poderia economizar mais que a fração minoritária atingida. Segundo, e mais fundamental: como avaliar qualquer posição custa praticamente o mesmo, o termo subtraído torna-se uma constante idêntica para todas as candidatas e, portanto, não altera qual delas apresenta o maior score. Formalmente, sendo o custo aproximadamente uniforme e igual a k, tem-se que o argumento máximo de (Valor − λk) coincide com o argumento máximo de Valor. Esse resultado negativo delimita a condição de aplicabilidade da formulação: a penalização por ação só discrimina quando as ações diferem entre si em custo.

A partir dessa constatação, o modelo foi reformulado aplicando o mesmo compromisso um nível acima, na decisão sobre o próprio procedimento de decisão. O agente delibera — isto é, executa a avaliação posicional completa — se, e somente se, o valor estratégico em jogo compensar o custo previsto da análise:

$$\text{ValorEmJogo} - \lambda \cdot \text{CustoEstimado} > 0$$

O ValorEmJogo é estimado por n × (Proximidade + Vulnerabilidade), onde n é o número de inimigos visíveis, Proximidade é o inverso da distância ao mais próximo e Vulnerabilidade é a fração de vida já perdida — grandezas que crescem justamente nas situações em que decidir bem tem maior consequência. O CustoEstimado é o produto do número de posições candidatas pelo custo unitário de avaliação. Quando não há inimigos à vista, o valor em jogo é nulo e a análise nunca se justifica.

Essa formulação confere ao parâmetro λ o comportamento de espectro previsto na fundamentação teórica: com λ igual a zero o agente delibera sempre, reproduzindo a IA Heurística pura; com λ suficientemente alto nunca delibera, aproximando-se da IA Reativa; e valores intermediários percorrem o compromisso entre ambos.

Quando a deliberação não se justifica, o agente opera em regime econômico: desloca-se por passo guloso na direção do objetivo, verificando apenas as células do próprio caminho — três a seis operações — em vez de expandir toda a vizinhança alcançável, o que exige cerca de vinte e cinco. Caso o caminho guloso seja bloqueado por um obstáculo que a busca completa contornaria, o agente recorre à busca, reservando o gasto elevado às situações em que a alternativa barata falha. A economia é efetivamente medida, e não presumida: cada verificação do passo guloso é contabilizada pelo mesmo instrumento que mede as demais operações, e o caminho traçado é validado em tempo constante por passo, sem repetição da busca.

---

## ▸ ACRESCENTAR ao final da Seção 4.8 (Protocolo experimental)

A calibração do modelo híbrido foi conduzida exclusivamente sobre o banco de 200 sementes reservado a esse fim, com varredura do parâmetro λ nos valores 0; 0,002; 0,005; 0,01 e 0,02. O valor adotado, λ = 0,005, corresponde ao joelho da curva de compromisso: preserva a eficácia máxima observada no modelo enquanto reduz o consumo em quinze por cento relativamente à deliberação irrestrita. Um mecanismo adicional de poda — limitar o número de candidatas avaliadas por turno — foi testado e descartado por reduzir a eficácia sem economia correspondente; permanece implementado, porém desativado por padrão, e o resultado está registrado.

---

## ▸ ACRESCENTAR à Seção 4.2 (Agentes e percepção)

Completa o modelo perceptivo um sensor de proximidade, inspirado no detector de movimento do jogo *Alien Isolation*: fora do campo de visão, o agente capta um indício grosseiro do inimigo mais próximo situado a até quinze células — a direção aproximada, discretizada em oito octantes, e a faixa de distância, classificada em próximo, médio ou distante. O sensor não revela a posição exata nem é bloqueado por paredes, representando ruído e não visão. Trata-se de mecânica do ambiente, disponível igualmente a todos os modelos, de modo que a equidade da comparação se preserva; cada consulta é contabilizada no custo computacional. Sua introdução tornou as partidas mais decisivas e menos custosas para todos os modelos, ao substituir a exploração aleatória por busca orientada.

---

## ▸ SUBSTITUIR integralmente a Seção 5 (Resultados)

### 5. RESULTADOS

Esta seção apresenta os resultados do benchmark oficial, conduzido sobre o banco de mil sementes reservado à avaliação, totalizando sete mil partidas distribuídas em sete execuções: quatro autoconfrontos, em que os três agentes de uma mesma partida executam o mesmo modelo, e três confrontos diretos, em que o modelo proposto enfrenta oponentes de custo pleno. Todas as execuções são determinísticas e estão integralmente documentadas.

#### 5.1 Validação da neutralidade do ambiente

Antes de comparar modelos, validou-se o instrumento de medição. Executando mil partidas com os três agentes controlados pelo mesmo modelo, um ambiente neutro deve produzir taxas de vitória estatisticamente indistinguíveis, pois qualquer assimetria sistemática denunciaria viés de terreno, de cor ou de ordem de jogada. No autoconfronto da IA Reativa as taxas observadas foram de 0,306, 0,328 e 0,301. Com mil observações e probabilidade de referência de um terço, a flutuação estatística esperada é de aproximadamente um ponto e meio percentual, e a maior diferença observada situa-se nessa faixa. Conclui-se que o sorteio de setores de nascimento e a rotação de iniciativa neutralizam com sucesso os vieses previstos, e que diferenças de desempenho observadas adiante são atribuíveis aos modelos.

#### 5.2 Caracterização por autoconfronto

Em condições simétricas, a taxa de vitória converge para aproximadamente um terço em qualquer modelo funcional; o que a comparação revela é o preço computacional pago por esse desempenho e a capacidade de conduzir a partida a uma decisão. A Tabela X apresenta os resultados.

**Tabela X — Autoconfronto: mil partidas por modelo**

| Modelo | WinRate | Empates | Custo médio | Eficiência* |
|---|---|---|---|---|
| Aleatória | 0,000 | 1000 (100%) | 2323 | 0,000 |
| Reativa | 0,312 | 65 (6,5%) | 437 | 0,714 |
| Heurística | 0,295 | 116 (11,6%) | 777 | 0,380 |
| Modelo Proposto | 0,314 | 57 (5,7%) | 379 | 0,829 |

*Eficiência: vitórias por mil operações.

A IA Aleatória confirma-se como piso absoluto de desempenho: não venceu uma única das mil partidas, encerrando todas por esgotamento do limite de turnos, e o fez pagando o maior custo computacional de todo o estudo. Enumera exaustivamente as ações disponíveis a cada turno e descarta a informação obtida — custo sem benefício, que a pontuação de partida capta corretamente ao penalizar o empate.

O modelo proposto apresenta o menor custo computacional entre todos os modelos funcionais, exigindo 379 operações por partida contra 437 da IA Reativa e 777 da IA Heurística, uma redução de cinquenta e um por cento em relação a esta última. É também o modelo mais decisivo, com apenas 5,7% de empates, contra 11,6% da heurística — modelos mutuamente cautelosos tendem a se anular até o limite de turnos. Sua taxa de vitória, 0,314, é a maior das observadas. Em eficiência estratégica, entrega mais que o dobro do rendimento da heurística por unidade de processamento.

#### 5.3 Confronto direto

A Tabela Y apresenta o confronto entre os três modelos analíticos na mesma partida, disputado ao longo de mil cenários.

**Tabela Y — Confronto direto: modelo proposto, heurística e reativa**

| Métrica | Modelo Proposto | Heurística | Reativa |
|---|---|---|---|
| Pontuação média | −1,44 | −0,75 | −0,81 |
| WinRate | 0,225 | 0,339 | 0,330 |
| DamageRatio | 4,23 ± 10,38 | 5,21 ± 10,64 | 5,61 ± 11,07 |
| CoverUsage | 0,096 | 0,095 | 0,074 |
| Turnos até a vitória | 44,4 | 39,8 | 39,3 |
| Custo médio | 510 | 719 | 484 |
| Eficiência | 0,441 | 0,472 | 0,682 |

O padrão repete-se nos confrontos contra dois oponentes idênticos: diante de duas instâncias da heurística, o modelo proposto obtém taxa de vitória de 0,232 com custo de 492 operações, contra 0,332 e 0,329 dos adversários, que gastam cerca de setecentas; diante de duas instâncias da reativa, obtém 0,248 com custo de 505.

Em competição direta, portanto, o modelo proposto vence menos que ambos os modelos de referência, ainda que preserve o menor custo entre os modelos analíticos e registre o maior aproveitamento de cobertura do confronto triplo.

#### 5.4 Discussão

Os resultados sustentam três conclusões, que convém enunciar com precisão.

A hipótese de eficiência confirma-se. O modelo proposto reduz o custo computacional em mais da metade em relação à heurística pura e constitui o modelo funcional mais econômico do estudo. Em condições simétricas entrega desempenho equivalente ou superior ao dos demais modelos por uma fração do processamento, com a menor taxa de empates observada. A formalização explícita do compromisso entre valor estratégico e custo computacional produz, portanto, um agente mensuravelmente mais eficiente, e o parâmetro λ permite percorrer esse compromisso de forma monotônica e previsível, conforme a curva de calibração apresentada na metodologia.

A hipótese de superioridade competitiva não se confirma. Quando enfrenta adversários que pagam integralmente o custo da análise, o modelo proposto obtém taxas de vitória próximas de 0,23, contra aproximadamente 0,33 dos modelos de referência. A economia obtida ao deliberar seletivamente tem preço: nos turnos em que opta pelo regime econômico, o agente ocasionalmente deixa de encontrar a posição que a avaliação completa teria identificado, e oponentes que deliberam sempre exploram essa diferença ao longo da partida.

A IA Reativa revela-se um modelo de referência notavelmente robusto. Com 484 operações e taxa de vitória de 0,330 no confronto triplo, apresenta a maior eficiência entre os modelos em competição direta. Este é um resultado relevante em si mesmo: em ambientes táticos caracterizados por percepção limitada e horizonte curto de consequências, regras simples e bem escolhidas mostram-se difíceis de superar, e a sofisticação analítica precisa justificar o custo que impõe — o que nem sempre ocorre.

Em síntese, o trabalho não demonstra que o modelo proposto seja o melhor jogador do conjunto avaliado; demonstra, com evidência quantitativa obtida em sete mil partidas controladas, que existe um compromisso mensurável e controlável entre qualidade estratégica e custo computacional, e que esse compromisso pode ser explicitado como parâmetro de projeto. Para aplicações submetidas a orçamento de processamento restrito — jogos comerciais com limite de tempo por quadro, robótica embarcada ou simulações em larga escala — o modelo proposto oferece um controle que os modelos de referência não possuem: a possibilidade de escolher, deliberadamente, quanto desempenho se está disposto a trocar por economia.

#### 5.5 Limitação metodológica

O Strategic Score, tal como definido na metodologia, atribui dez por cento do peso ao inverso do custo computacional médio. Com custos da ordem de centenas de operações, esse termo contribui com cerca de dois milésimos para o escore composto, enquanto o Damage Ratio contribui com valores próximos de cinco unidades. A métrica composta é, por conseguinte, praticamente insensível à dimensão que o modelo proposto otimiza, razão pela qual os resultados foram reportados também em termos de eficiência estratégica, expressa em vitórias por mil operações. A revisão dos pesos da métrica composta permanece registrada como ajuste pendente, a ser discutido com a orientação e aplicado uniformemente a todos os modelos caso adotado.

---

## ▸ ACRESCENTAR como Seção 6 (renumerar as seguintes)

### 6. CONCLUSÃO

Este trabalho desenvolveu um simulador tático bidimensional para avaliação sistemática de estratégias de inteligência artificial e propôs um modelo híbrido de tomada de decisão que equilibra valor estratégico e custo computacional, medido de forma independente de hardware por contagem de operações.

Do ponto de vista do instrumento, o resultado é um ambiente controlado, determinístico e integralmente reprodutível, cuja neutralidade foi empiricamente verificada, acompanhado de uma infraestrutura experimental capaz de executar e documentar mil partidas em poucos minutos. Todo o material — código, bancos de sementes, execuções e dados brutos — encontra-se publicamente disponível, permitindo verificação independente.

Do ponto de vista do modelo, verificou-se que a formulação direta do compromisso, aplicada à escolha entre ações, é inócua neste domínio: como avaliar posições distintas custa aproximadamente o mesmo, o termo de penalização torna-se constante e não altera a decisão. A reformulação que se mostrou produtiva desloca o compromisso para a decisão sobre o próprio procedimento — deliberar ou não deliberar —, conferindo ao parâmetro de troca um comportamento de espectro entre a heurística completa e a reação simples.

Quanto à hipótese, os resultados confirmam o ganho de eficiência e não confirmam o ganho de eficácia competitiva. O modelo proposto opera com pouco mais da metade do custo da heurística e apresenta a maior eficiência estratégica em condições simétricas, mas obtém menos vitórias quando enfrenta adversários que pagam integralmente o custo da análise. A contribuição científica do trabalho reside, assim, menos na superioridade de um modelo particular e mais na demonstração quantitativa de que o compromisso entre qualidade e custo é mensurável, controlável e explicitável como decisão de projeto.

Como trabalhos futuros, apontam-se três direções. A primeira é a revisão da métrica composta, de modo que a dimensão de eficiência receba peso compatível com sua relevância. A segunda é a investigação de critérios adaptativos para o parâmetro de troca, ajustando-o ao longo da partida conforme a fase do confronto, em vez de mantê-lo fixo. A terceira é a comparação com modelos de busca em profundidade, como o Monte Carlo Tree Search, empregado neste trabalho apenas como referência teórica, o que permitiria estender a curva de compromisso à região de alto custo e alta qualidade.
