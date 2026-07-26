# Banca 6 — Passo 03: Finalização e Resultados

**Roteiro de apresentação final** · Simulador Tático para Avaliação de IA
Gabriel Madeira · Orientador: Ricardo Martins · Coorientador: Diego Penha

> **Identidade visual**: manter o template das bancas anteriores.

> **Mensagem central**: o Art3miz 0.1 foi construído a partir dos dados,
> calibrado e avaliado em 7.000 partidas. A hipótese de eficiência confirma-se;
> a de superioridade competitiva, não. E essa distinção é o que dá seriedade ao
> trabalho.

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

*Fala*: 30 segundos. A banca precisa ver o fio, não reouvir o detalhe.

---

## Slide 3 — O ponto de partida herdado da Banca 5

Dois achados que orientaram o desenho do modelo:

1. **84% do custo está na busca de caminho**, executada em todo turno — não na
   avaliação estratégica, que é apenas 16%.
2. A avaliação só agrega valor **durante o contato visual**; nos demais turnos, o
   agente apenas se desloca.

**Consequência**: penalizar a avaliação não economizaria mais que 16%. O desenho
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
significativamente melhor que a reativa — apenas mais cara.

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
