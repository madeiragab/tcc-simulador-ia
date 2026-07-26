# Art3miz 0.1 — Modelo Proposto

Contribuição central do trabalho: um modelo híbrido de decisão que pondera valor estratégico contra custo computacional.

Implementação: `simulator/ai/ai_art3miz.gd` · Identificador na linha de comando: `art3miz`
Calibração e evidências: `resultados_hibrido.md` · Resultados: `resultados_finais.md`

O sufixo de versão é intencional: registra que os resultados reportados correspondem a esta configuração específica (λ = 0,005, pesos calibrados, regime econômico com recuo). Ajustes futuros no mecanismo produzem versões subsequentes, mantendo cada conjunto de dados rastreável à versão que o gerou.

## 1. Formulação inicial e por que ela não funciona

A leitura direta do compromisso entre valor e custo penaliza cada ação candidata pelo custo de avaliá-la:

Score(A) = ValorEstratégico(A) − λ × CustoComputacional(A)

Implementada e submetida a varredura de λ, **essa formulação mostrou-se inócua neste domínio**. O resultado negativo é uma contribuição do trabalho, pois delimita a condição de aplicabilidade da forma ingênua do compromisso. Duas causas, ambas medidas:

**1.1 O alvo da penalização é minoria do custo.** A decomposição do custo da IA Heurística mostrou que o loop de avaliação posicional responde por 16% do consumo (cálculos de linha de visão e ações avaliadas), enquanto 84% concentra-se na busca de caminho, executada em todo turno — inclusive nos muitos turnos sem contato visual. Nenhum valor de λ poderia economizar além dessa fração minoritária.

**1.2 Custos uniformes tornam o termo inerte.** Avaliar qualquer posição custa praticamente o mesmo. Sendo Custo(A) ≈ k para toda ação A, o termo −λk é uma constante somada a todas as candidatas e não altera qual delas tem o maior score:

argmax[ Valor(A) − λk ] = argmax[ Valor(A) ]

Experimentalmente, λ = 0 e λ = 0,005 produziram resultados idênticos. **A penalização por ação só discrimina quando as ações diferem entre si em custo** — condição que este domínio não satisfaz.

## 2. Reformulação: o compromisso decide *se* deliberar

Se o custo não distingue ações entre si, ele distingue **procedimentos de decisão**. A reformulação aplica o mesmo compromisso um nível acima: antes de avaliar, o agente decide se a análise se justifica.

O agente delibera — executa a avaliação posicional completa — se, e somente se:

**ValorEmJogo − λ × CustoEstimado > 0**

**ValorEmJogo** = n × (Proximidade + Vulnerabilidade), onde n é o número de inimigos visíveis, Proximidade é o inverso da distância ao mais próximo e Vulnerabilidade é a fração de vida perdida. Cresce nas situações em que decidir bem tem maior consequência.

**CustoEstimado** = células candidatas × (inimigos visíveis + 1), o custo previsto da avaliação completa.

Sem inimigos à vista, o valor em jogo é nulo e o regime econômico é sempre escolhido. O parâmetro percorre todo o espectro: **λ = 0 delibera sempre** (equivale à IA Heurística pura); **λ alto nunca delibera** (equivale à IA Reativa).

## 3. Regime econômico

Quando não compensa deliberar, o agente se desloca por **passo guloso**: caminha até 3 células na direção do objetivo verificando apenas as células do próprio caminho (3 a 6 operações), em vez de expandir toda a vizinhança alcançável (~25 nós).

Duas salvaguardas preservam a qualidade:

- **Caça mantém a busca completa.** Aproximar-se de uma posição onde um inimigo foi visto é aproximação com propósito e justifica o gasto; apenas a exploração às cegas usa o passo guloso.
- **Recuo por obstáculo.** Se o caminho guloso trava diante de um obstáculo que a busca contornaria, o agente recorre à busca completa.

A economia é **medida, não presumida**: cada verificação do passo guloso é contabilizada pelo mesmo medidor de custo (`grid.check_walkable`), e o caminho traçado é validado em tempo constante por passo (`agent.move_along`), sem refazer a busca.

## 4. Parâmetros

| Parâmetro | Valor | Origem |
|---|---|---|
| λ | 0,005 | Varredura em {0; 0,002; 0,005; 0,01; 0,02} nas 200 seeds de tuning — joelho da curva de compromisso |
| budget | 0 (desativado) | Poda de candidatas testada e descartada: reduziu eficácia sem economia relevante |
| Pesos | 0,092 / 0,307 / 0,495 / −0,228 | Melhor configuração aprendida no confronto misto da campanha |

Os pesos continuam sendo refinados pelo aprendizado entre partidas (`ia.md` §6.5), herdado da heurística.

## 5. Resultados

Em autoconfronto (1000 partidas), o Art3miz 0.1 obtém o **maior StrategicScore do estudo (0,497)**, contra 0,473 da reativa e 0,438 da heurística, exigindo **379 operações por partida — 51% menos que a heurística**. É também o mais decisivo (5,7% de empates) e o mais rápido a vencer (29,3 turnos).

Em confronto direto contra oponentes de custo pleno, vence menos (0,225 contra ~0,33). A hipótese de eficiência confirma-se; a de superioridade competitiva, não. Análise completa em `resultados_finais.md`.

## 6. Uso

```bash
# Benchmark oficial com o Art3miz 0.1
godot --headless --path simulator -- batch 1000 benchmark verde=art3miz

# Calibração (λ e orçamento ajustáveis por linha de comando)
godot --headless --path simulator -- batch 200 tuning verde=art3miz lambda=0.005 budget=0
```
