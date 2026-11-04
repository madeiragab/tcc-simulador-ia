# Banca 6 — Passo 03: Finalização e Resultados

**Roteiro de apresentação final** · Simulador Tático para Avaliação de IA
Gabriel Madeira · Orientador: Ricardo Martins · Coorientador: Diego Penha

> **Identidade visual**: manter o template das bancas anteriores.

> **Mensagem central**: o Art3miz 0.1 foi construído a partir dos dados,
> calibrado e avaliado em 7.000 partidas. A hipótese de eficiência confirma-se;
> a de superioridade competitiva, não. E essa distinção é o que dá seriedade ao
> trabalho.

> **Público desta banca**: um dos avaliadores **nunca viu o trabalho**. Regra de
> ouro: **nenhum termo é usado sem ser explicado na primeira vez que aparece** —
> em uma frase simples, de preferência com um exemplo do próprio jogo. Não
> pressupor nada das bancas anteriores. O glossário no fim deste roteiro tem a
> frase pronta para cada termo, e a seção "Termos por slide" diz onde cada um
> precisa ser definido.

> **Correções obrigatórias da Banca 5**: ver `banca_5_registro.md`. Os resultados
> mostrados na Banca 5 eram de uma campanha sem o sensor de proximidade, e o
> p-valor do roteiro vinha de outra execução. O Slide 3 abaixo trata disso.

---

## Slide 1 — Capa

**Avaliação Experimental de um Modelo Híbrido para Decisão Estratégica em
Simulações de Combate Baseadas em Turnos**

Subtítulo: *Passo 03 — Art3miz 0.1 e Resultados Finais*

---

## Slide 2 — O percurso

| Etapa | Entrega |
|---|---|
| Banca 3 | Protótipo e protocolo experimental proposto |
| Banca 4 | Ambiente completo, instrumentação e **neutralidade validada** |
| Banca 5 | Modelos de referência caracterizados e **o custo localizado** |
| **Banca 6** | **Art3miz 0.1, calibração e resultados finais** |

*Fala*: 1 minuto. Para quem já acompanhou, é só o fio; para o avaliador novo, é o
mapa da apresentação — dizer em uma frase o que cada banca entregou.

---

## Slide 2.5 — O trabalho explicado do zero

Para o avaliador que chega agora. Um slide, quatro blocos, cada um com uma imagem
do simulador:

- **O ambiente**: um jogo de combate por turnos num mapa quadriculado de 40 × 40
  células, com paredes. Três agentes (jogadores controlados por IA) se enfrentam;
  vence quem sobrar. Cada um vê só o que está à frente (cone de 120°, alcance de 8
  células). Se ninguém vencer em 100 turnos, é empate.
- **Os jogadores**: quatro "cérebros" diferentes — a IA Aleatória (sorteia uma
  jogada), a Reativa (segue regras fixas do tipo "se vê inimigo, atira"), a
  Heurística (dá nota a cada posição possível e escolhe a melhor) e o Art3miz 0.1,
  o modelo proposto.
- **O que se mede**: a qualidade da decisão (quem vence, quanto dano causa) e o
  **custo** de decidir, contado em operações — quantas verificações o agente faz
  para escolher a jogada. Contar operações, e não segundos, torna a medida
  independente do computador.
- **A pergunta**: dá para decidir quase tão bem gastando bem menos?

*Fala*: devagar. Se o avaliador novo entender este slide, entende o resto.

---

## Slide 3 — Correção da Banca 5 e o ponto de partida

**Primeiro, uma correção** (apresentar de frente, sem minimizar):

Os resultados mostrados na Banca 5 vinham de uma campanha rodada **antes** de o
ambiente ganhar o **sensor de proximidade** — uma "pista" que diz ao agente a
direção aproximada do inimigo mais próximo, sem dar a posição exata. Sem essa
pista, os agentes se perdiam no mapa e muitas partidas acabavam empatadas no
limite de turnos (63% no confronto misto). Com o sensor, os empates caem para
6,5% (Reativa) e 11,6% (Heurística). **Todos os números desta banca são do
ambiente com sensor**, que é o oficial.

Também corrigido: o p-valor citado na Banca 5 (0,034) era da campanha sem sensor;
no ambiente oficial a heurística **não** vence significativamente mais que a
reativa (p = 0,757). Explicar o que é p-valor antes de mostrar o número (ver
glossário).

**O achado que sobrevive à correção** e orientou o desenho do modelo:

1. **76% do custo da heurística está na busca de caminho** (calcular por onde
   andar), executada em todo turno — não na avaliação estratégica, que fica com
   os outros 24% (sem sensor eram 84%; a conclusão é a mesma).
2. A avaliação só agrega valor **durante o contato visual**; nos demais turnos, o
   agente apenas se desloca.

**Consequência**: penalizar a avaliação não economizaria quase nada. O desenho
precisa atacar outro ponto.

---

## Slide 4 — A formulação original e seu limite

A função proposta na Banca 3:

**Score(A) = Valor(A) − λ × OperationCount(A)**

Foi implementada e submetida a varredura de λ. **Resultado: nenhuma economia.**
Custo estatisticamente igual ao da heurística, e eficácia um pouco pior.

**Por quê** — e este é um resultado da pesquisa:

Como avaliar qualquer posição custa praticamente o mesmo, sendo Custo(A) ≈ k para
toda ação:

**argmax[ Valor(A) − λk ] = argmax[ Valor(A) ]**

O termo vira uma **constante somada a todas as candidatas** e não altera a
escolha. Experimentalmente: λ = 0 e λ = 0,005 produziram resultados idênticos.

**A penalização por ação só discrimina quando as ações diferem em custo entre si**
— condição que este domínio não satisfaz.

*Fala*: apresentar com confiança. Um resultado negativo bem demonstrado é
contribuição científica: delimita a condição de aplicabilidade da formulação.

---

## Slide 4.5 — Isso tem nome na literatura: metarraciocínio

O resultado do slide anterior **não é uma anomalia — é uma predição da teoria**.

Russell e Wefald, em *Principles of Metareasoning* (1991), estabelecem o
princípio central:

> Uma computação só tem valor na medida em que **altera a ação externa** que o
> agente executaria.

Descontar um custo uniforme de todas as candidatas não muda qual delas vence o
*argmax* — logo, não pode ter efeito algum. O que medimos empiricamente é o que
o arcabouço prevê analiticamente.

**Linhagem teórica do trabalho**: Simon (1955) e a racionalidade limitada →
Russell & Wefald (1991) e o valor da computação → Zilberstein (1996) e os
algoritmos *anytime* → racionalidade computacional (Gershman, Horvitz e
Tenenbaum, 2015).

*Fala*: mencionar que Russell é o mesmo autor do livro-texto já citado no
referencial. A reformulação do modelo não foi improviso — reencontrou um
problema clássico.

---

## Slide 5 — A reformulação

Se o custo não distingue *ações*, ele distingue **procedimentos de decisão**.

O agente delibera — executa a avaliação completa — se, e somente se:

**ValorEmJogo − λ × CustoEstimado > 0**

- **ValorEmJogo** = nº de inimigos visíveis × (Proximidade + Vulnerabilidade)
- **CustoEstimado** = candidatas × custo unitário de avaliação

Sem inimigos à vista, o valor em jogo é nulo: nunca compensa deliberar.

**O parâmetro percorre todo o espectro**:
λ = 0 → delibera sempre (≡ Heurística) · λ alto → nunca delibera (≡ Reativa)

---

## Slide 6 — O regime econômico

Quando não compensa deliberar, o agente se desloca por **passo guloso**:
verifica apenas as células do próprio caminho (~4 operações) em vez de expandir
toda a vizinhança alcançável (~25 nós).

Duas salvaguardas preservam a qualidade:

- **Caçar posição conhecida mantém a busca completa** — aproximação com propósito
  justifica o gasto
- **Recuo por obstáculo** — se o caminho barato trava, paga-se pela busca

A economia é **medida, não presumida**: cada verificação do passo guloso é
contabilizada pelo mesmo instrumento.

---

## Slide 7 — Calibração de λ

Varredura no banco de **200 sementes de calibração**, isolado do de avaliação:

| λ | Taxa de vitória | Custo |
|---|---|---|
| 0 (delibera sempre) | 0,235 | 749 |
| 0,002 | 0,235 | 752 |
| **0,005** | **0,235** | **636** |
| 0,01 | 0,220 | 570 |
| 0,02 (quase nunca) | 0,215 | 526 |

Comportamento **monotônico**: λ crescente compra economia com eficácia.

**λ = 0,005 é o joelho da curva** — preserva a eficácia máxima já reduzindo 15%
do custo. Acima disso, cada operação economizada custa vitórias.

*Fala*: bom slide para gráfico de linha (custo e vitória em eixos opostos).

---

## Slide 8 — Correção da métrica composta

Durante a análise, detectou-se um defeito no **Strategic Score**: somava
grandezas em escalas incompatíveis.

Contribuição real de cada termo, medida:

| Termo | Peso nominal | Contribuição real |
|---|---|---|
| Razão de dano | 20% | **0,85 – 1,12** |
| Taxa de vitória | 30% | 0,07 – 0,10 |
| **Custo** | **10%** | **0,0002** |

A métrica media quase só razão de dano e era **cega à eficiência computacional** —
justamente a dimensão central da pesquisa.

**Correção**: todos os termos normalizados a [0,1] antes da ponderação,
**preservando exatamente os pesos originais**. Atua sobre a escala, não sobre a
intenção — o que afasta qualquer suspeita de ajuste em favor do Art3miz 0.1.

Como a mudança recai sobre a agregação e não sobre a coleta, **todos os escores
foram recalculados a partir dos dados brutos preservados**, sem repetir
simulações.

---

## Slide 9 — RESULTADO 1: autoconfronto

Mil partidas por modelo, três instâncias iguais por partida:

| Modelo | Vitórias | Empates | Custo | **Strategic Score** |
|---|---|---|---|---|
| Aleatória | 0,000 | 100% | 2323 | 0,145 |
| Reativa | 0,312 | 6,5% | 437 | 0,473 |
| Heurística | 0,295 | 11,6% | 777 | 0,438 |
| **Art3miz 0.1** | **0,314** | **5,7%** | **379** | **0,497** |

**O Art3miz 0.1 obtém o maior escore do estudo**, liderando quatro das cinco
dimensões: vence mais, usa mais cobertura, decide mais rápido (29 turnos contra
45 da heurística) e gasta **51% menos** que ela.

Em eficiência — vitórias por mil operações — entrega **0,829 contra 0,380** da
heurística: mais que o dobro.

---

## Slide 10 — RESULTADO 2: confronto direto

| Métrica | Art3miz 0.1 | Heurística | Reativa |
|---|---|---|---|
| Taxa de vitória | 0,225 | **0,339** | 0,330 |
| Custo | **510** | 719 | 484 |
| Strategic Score | 0,426 | 0,467 | **0,472** |

**Contra adversários que pagam o custo pleno da análise, o Art3miz 0.1 vence
menos.**

A economia tem preço: ao pular a deliberação, o agente ocasionalmente deixa de
encontrar a posição que a avaliação completa identificaria, e quem sempre delibera
explora essa diferença ao longo da partida.

*Fala*: apresentar sem hesitação. Omitir este slide seria o erro; apresentá-lo com
clareza é o que dá credibilidade a todo o resto.

---

## Slide 11 — Conclusões

**1. A hipótese de eficiência confirma-se.**
O Art3miz 0.1 opera com pouco mais da metade do custo da heurística e obtém o
maior escore composto em condições simétricas. A formalização explícita do
compromisso produz um agente mensuravelmente mais eficiente, e λ permite percorrer
esse compromisso de forma previsível.

**2. A hipótese de superioridade competitiva não se confirma.**
Em confronto direto, vence menos que os modelos de referência.

**3. A IA Reativa é um baseline notavelmente robusto.**
Maior eficiência do confronto direto. Em ambientes com percepção limitada e
horizonte curto, regras simples bem escolhidas são difíceis de superar — a
sofisticação analítica precisa justificar o custo que impõe.

---

## Slide 11.5 — Rigor estatístico

Todas as afirmações comparativas foram submetidas a teste formal. O delineamento
é **pareado** — todos os modelos enfrentam as mesmas *seeds* —, o que permite
testes mais potentes que os de amostras independentes.

| Afirmação | Teste | Resultado |
|---|---|---|
| O ambiente é neutro | Qui-quadrado | χ² = 1,32 · p = 0,516 · **sem viés detectável** |
| As taxas de vitória diferem | Qui-quadrado | χ² = 26,96 · **p < 0,001** |
| Art3miz supera a heurística no escore | *Bootstrap* (IC 95%) | [0,479; 0,509] vs [0,421; 0,454] · **não se sobrepõem** |
| Art3miz é mais barato que a heurística | t pareado | −208,5 ops · **p < 0,001** |
| Heurística vence mais que a reativa | Binomial | p = 0,757 · **NÃO significativo** |

*Fala*: dois pontos merecem destaque. A neutralidade do ambiente deixou de ser
"os números parecem próximos" e passou a ser um teste com resultado. E a última
linha corrige uma expectativa nossa: a heurística **não** se mostrou
significativamente melhor que a reativa — apenas mais cara. Lembrar que na
Banca 5 foi mostrado p = 0,034 para essa mesma comparação: aquele número era do
ambiente sem sensor (ver Slide 3).

Antes da tabela, explicar em uma frase cada teste (ver glossário): o que é
p-valor, por que 0,05 é o limite, o que é um intervalo de confiança.

---

## Slide 11.6 — O espectro completo e o valor marginal da computação

Com o MCTS implementado, o extremo caro deixa de ser teórico. Confronto de mil
partidas:

| | MCTS | Heurística | Art3miz 0.1 |
|---|---|---|---|
| WinRate | **0,379** | 0,292 | 0,236 |
| Custo | 2794 | 681 | **471** |
| Eficiência (vit./mil ops) | 0,136 | 0,429 | **0,501** |

**Quanto custa cada vitória adicional:**

- Art3miz → Heurística: ≈ **3.750 operações**
- Heurística → MCTS: ≈ **24.300 operações**

Retorno fortemente decrescente. Este número é a tese do trabalho em uma linha:
não existe modelo melhor em absoluto — existe um compromisso, e ele é mensurável.

---

## Slide 11.7 — Generalização e a faixa de aplicabilidade

Replicação em três escalas de mapa:

| Escala | Economia sobre a Heurística |
|---|---|
| 25×25 | −16% |
| 40×40 | −29% |
| **60×60** | **−49%** |

**A economia triplica com a escala** — coerente com o mecanismo: mapas maiores
têm mais turnos sem contato, e é aí que a deliberação é dispensada.

**Mas há um limite honesto**: em 25×25 a IA Reativa é *simultaneamente* mais
barata e mais eficaz que o modelo proposto. Em ambientes pequenos, onde toda
situação é crítica, não há o que economizar.

*Fala*: apresentar a limitação de frente. Delimitar a faixa de aplicabilidade de
um modelo é resultado, não fraqueza — e mostra domínio sobre o próprio trabalho.

---

## Slide 11.8 — Os pesos da métrica são arbitrários?

Crítica legítima: por que 30/20/20/20/10? Resposta empírica, não retórica.

| Exame | Resultado |
|---|---|
| 6 ponderações alternativas (incl. todas iguais) | Art3miz lidera em **todas** |
| 10.000 vetores aleatórios do simplex | Art3miz lidera em **100%** |
| Perturbação de cada peso em ±50% | Liderança **não muda** |
| Peso necessário para trocar o líder | **97%** concentrado em vitória |

A liderança só se desfaz sob concentração extrema de peso numa única dimensão —
configuração que descaracterizaria a métrica como instrumento multidimensional.

---

## Slide 12 — Contribuições do trabalho

1. **Um ambiente de avaliação** determinístico, reprodutível e com neutralidade
   comprovada — reutilizável por outras pesquisas, publicamente disponível.
2. **Uma metodologia de medição de custo** independente de hardware, por contagem
   de operações.
3. **Um resultado negativo bem delimitado**: a formulação direta do compromisso é
   inerte quando as ações têm custo uniforme.
4. **Um modelo de decisão com controle explícito** do compromisso qualidade-custo,
   que os modelos de referência não oferecem.
5. **Evidência quantitativa** sobre o valor marginal do processamento em decisão
   tática, obtida em 7.000 partidas controladas.

---

## Slide 13 — Trabalhos futuros

- **λ adaptativo**: ajustar o parâmetro ao longo da partida conforme a fase do
  confronto, em vez de mantê-lo fixo.
- **Ambientes de maior escala**: onde o custo da busca cresce e a economia do
  regime econômico tende a se ampliar.
- **Comparação com MCTS**: usado aqui apenas como referência teórica; incluí-lo
  estenderia a curva de compromisso à região de alto custo e alta qualidade.

---

## Slide 14 — Encerramento

> O trabalho não demonstra que o Art3miz 0.1 seja o melhor jogador.
> Demonstra que o compromisso entre qualidade estratégica e custo computacional
> é **mensurável, controlável e explicitável como decisão de projeto** — e que,
> sob avaliação multidimensional, o Art3miz 0.1 apresenta o melhor
> desempenho global do conjunto avaliado.

Repositório público: `github.com/madeiragab/tcc-simulador-ia`

---

## Slide 15 — Perguntas

---

## Antecipação de perguntas da banca

**"Então o Art3miz 0.1 falhou?"**
Não. A hipótese central — eficiência — confirmou-se: maior escore composto, metade
do custo, menor taxa de empates. O que não se confirmou foi a superioridade em
confronto direto, que era secundária. A hipótese registrada no projeto falava em
*evitar escolhas excessivamente complexas mantendo bom nível estratégico* — foi
exatamente o que ocorreu.

**"Por que mudou a fórmula no meio do trabalho?"**
Não mudei por conveniência: medi que a original era inerte e demonstrei
formalmente por quê. A reformulação mantém o mesmo princípio — valor contra custo
— aplicado no nível onde ele de fato discrimina.

**"A correção da métrica não favoreceu seu modelo?"**
A correção alterou apenas a escala dos termos; **os pesos permaneceram os
originais**. E foi motivada por um defeito objetivo: o termo de custo contribuía
com 0,0002 quando deveria valer 10%. Todos os modelos foram recalculados com a
mesma fórmula, a partir dos mesmos dados brutos.

**"Como garante que não houve sobreajuste na calibração?"**
Bancos de sementes disjuntos: 200 para calibrar, 1000 para avaliar. O modelo nunca
viu, durante o ajuste, os cenários em que foi medido.

**"Qual a aplicação prática disso?"**
Qualquer sistema com orçamento de processamento restrito: jogos comerciais com
limite de tempo por quadro, robótica embarcada, simulações em larga escala. O
modelo oferece um controle de projeto — escolher deliberadamente quanto
desempenho se troca por economia — que os modelos de referência não têm.

**"Por que os resultados mudaram desde a Banca 5?"**
Porque a Banca 5 usou, por engano, uma campanha anterior ao sensor de
proximidade. Os números corretos são os do ambiente oficial, com sensor. A
conclusão central não mudou: o custo da heurística está na busca de caminho, e
ela não vence significativamente mais que a reativa. Detalhes em
`banca_5_registro.md`.

---

## Termos por slide (o que definir antes de usar)

| Slide | Definir antes de usar |
|---|---|
| 2.5 | agente, turno, empate, cone de visão, operação / Operation Count |
| 3 | sensor de proximidade, busca de caminho, p-valor |
| 4 | função de pontuação, λ (lambda), argmax |
| 4.5 | metarraciocínio, racionalidade limitada |
| 5 | deliberar, ValorEmJogo, CustoEstimado |
| 6 | passo guloso, regime econômico |
| 7 | *seed* e banco de calibração × banco de avaliação, "joelho da curva" |
| 8 | Strategic Score, normalização |
| 9 | autoconfronto, taxa de vitória, eficiência (vitórias por mil operações) |
| 10 | confronto direto |
| 11.5 | teste pareado, qui-quadrado, binomial, t pareado, *bootstrap*, intervalo de confiança |
| 11.6 | MCTS, valor marginal |
| 11.7 | generalização / escala de mapa |
| 11.8 | simplex (pesos aleatórios que somam 1) |

---

## Glossário — a frase pronta para cada termo

- **Agente**: um jogador controlado por uma IA. Cada partida tem três.
- **Turno**: uma rodada em que cada agente faz uma jogada (mover, atirar). Uma
  partida tem no máximo 100.
- **Empate**: a partida chega ao turno 100 com mais de um agente vivo.
- **Cone de visão**: o agente só enxerga um leque de 120° à sua frente, até 8
  células, e paredes bloqueiam.
- **Sensor de proximidade**: uma pista grosseira — a direção aproximada (uma de
  oito) e se o inimigo mais próximo está perto, médio ou longe (até 15 células).
  Nunca a posição exata. Atravessa paredes. Igual para todas as IAs.
- **Operation Count (custo)**: a soma de três contadores — verificações de linha
  de visão, células examinadas para calcular caminhos e posições avaliadas.
  Mede o "esforço de pensar" sem depender da velocidade do computador.
- **Busca de caminho**: o cálculo de por onde o agente pode andar até um destino
  desviando das paredes. É a parte mais cara da decisão.
- **IA Aleatória / Reativa / Heurística**: sorteia uma jogada válida / segue
  regras fixas em ordem (atirar, aproximar, procurar) / dá uma nota a cada
  posição alcançável e escolhe a maior.
- **Art3miz 0.1**: o modelo proposto. Decide, a cada turno, se vale a pena pensar
  a fundo (como a Heurística) ou agir barato (como a Reativa).
- **λ (lambda)**: o "preço" que o modelo atribui a cada operação. λ = 0: pensar é
  de graça, sempre pensa. λ alto: pensar é caro, quase nunca pensa.
- **argmax**: "escolher a opção de maior nota".
- **Deliberar**: rodar a avaliação completa de todas as posições antes de agir.
- **Passo guloso**: andar uma casa na direção do objetivo sem calcular o caminho
  inteiro — barato, mas pode travar em parede.
- **Metarraciocínio**: pensar sobre o próprio pensar — decidir se vale a pena
  gastar processamento numa decisão.
- **Seed (semente)**: o número que gera um mapa. A mesma semente sempre gera o
  mesmo mapa, então todas as IAs jogam exatamente os mesmos cenários.
- **Banco de calibração × banco de avaliação**: 200 mapas usados para ajustar
  parâmetros e 1.000 mapas, diferentes, usados para medir. Evita "decorar a
  prova".
- **Autoconfronto**: três cópias da mesma IA jogando entre si. Mostra o
  comportamento e o custo de cada modelo em condições iguais.
- **Confronto direto**: IAs diferentes na mesma partida. Mostra quem vence quem.
- **Taxa de vitória**: fração das partidas que aquele agente venceu.
- **Strategic Score**: nota única de 0 a 1 que combina vitória (30%), dano,
  cobertura, rapidez (20% cada) e custo (10%).
- **Normalização**: colocar cada termo na mesma escala (0 a 1) antes de somar,
  para que os pesos valham o que dizem.
- **p-valor**: a chance de ver uma diferença desse tamanho só por sorte, se na
  verdade não houvesse diferença nenhuma. Abaixo de 0,05 (5%), considera-se que
  a diferença é real ("significativa").
- **Teste pareado**: compara os modelos nos mesmos mapas, partida a partida, o
  que elimina a sorte do cenário.
- **Qui-quadrado**: testa se vitórias estão distribuídas de forma diferente do
  esperado (por exemplo, se uma cor de jogador vence mais).
- **Binomial condicional**: olhando só as partidas em que A ou B venceu, testa se
  A venceu mais que metade delas.
- **t pareado**: testa se a diferença média de custo entre dois modelos, mapa a
  mapa, é diferente de zero.
- **Bootstrap e intervalo de confiança (IC 95%)**: reamostrar os resultados
  milhares de vezes para obter a faixa onde o valor real provavelmente está. Se
  as faixas de dois modelos não se sobrepõem, a diferença é real.
- **MCTS (Monte Carlo Tree Search)**: técnica que simula muitos futuros possíveis
  antes de jogar. Joga melhor, mas custa muito mais.
- **Valor marginal**: quanto se ganha a mais por cada unidade a mais de esforço.
- **Simplex**: o conjunto de todas as combinações de pesos que somam 100%.
