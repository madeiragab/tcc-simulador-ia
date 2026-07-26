# Calibração do Modelo Híbrido (Fase 4)

Calibração conduzida exclusivamente no banco de **200 seeds de tuning**, isolado das 1000 seeds do benchmark — o modelo nunca viu, durante o ajuste, os cenários em que seria avaliado.

Referência de comparação, medida nas mesmas 200 seeds e no mesmo confronto (modelo avaliado contra duas IAs reativas): **IA Heurística — pontuação −0,74; WinRate 0,255; custo 1298 operações/partida**.

## 1. Primeira formulação: penalizar o custo de cada ação

A leitura direta de `ScoreAção = ValorEstratégico − λ × CustoComputacional(ação)` — descontar de cada ação candidata o custo de avaliá-la — foi implementada e varrida em λ ∈ {0,005; 0,01; 0,02; 0,05; 0,1}.

| λ | Pontuação | WinRate | Custo |
|---|---|---|---|
| 0,005 | −0,85 | 0,240 | 1287 |
| 0,01 | −0,86 | 0,235 | 1305 |
| 0,02 | −0,88 | 0,235 | 1308 |

**A formulação não produziu economia alguma** (custo estatisticamente igual ao da heurística) e ainda perdeu eficácia. A investigação identificou duas causas, ambas mensuradas:

### 1.1 O alvo da penalização é minoria do custo

Decomposição do custo da IA Heurística (200 partidas de tuning):

| Componente | Operações/partida | Participação |
|---|---|---|
| **Nós de busca de caminho** | **1086** | **84%** |
| Cálculos de linha de visão | 109 | 8% |
| Ações avaliadas | 103 | 8% |

O loop de avaliação posicional, que a penalização atinge, responde por apenas 16% do gasto. A busca de caminho — executada em todo turno, inclusive nos muitos turnos sem contato visual, quando o agente apenas explora — domina o consumo. Nenhum ajuste de λ poderia economizar mais que 16%.

### 1.2 Custos uniformes tornam o termo inerte

Avaliar qualquer posição candidata custa praticamente o mesmo (uma verificação de linha de visão por inimigo visível). Sendo `Custo(A) ≈ k` para toda ação A, o termo `− λ × k` é uma **constante somada a todas as candidatas** e não altera qual delas tem o maior score:

argmax[ Valor(A) − λ·k ] = argmax[ Valor(A) ]

Isso explica por que λ = 0 e λ = 0,005 produziram resultados idênticos. **A penalização por ação só discrimina quando as ações têm custos diferentes entre si** — condição que este domínio não satisfaz.

Este resultado negativo é uma contribuição do trabalho: delimita a condição de aplicabilidade da formulação ingênua do compromisso.

## 2. Reformulação: o compromisso decide *se* deliberar

Se o custo não distingue ações entre si, ele distingue **procedimentos de decisão**. A reformulação aplica o mesmo compromisso um nível acima: antes de avaliar, o agente decide se a análise se justifica.

Delibera (avaliação posicional completa) se, e somente se:

**ValorEmJogo − λ × CustoEstimado > 0**

onde:

- **ValorEmJogo** = *n* × (Proximidade + Vulnerabilidade), com *n* = inimigos visíveis, Proximidade = inverso da distância ao mais próximo e Vulnerabilidade = fração de vida perdida. Cresce nas situações em que decidir bem importa mais.
- **CustoEstimado** = células candidatas × (inimigos visíveis + 1), o custo previsto da avaliação completa.

Não havendo inimigos à vista, o valor em jogo é nulo e o regime econômico é sempre escolhido. O parâmetro percorre todo o espectro descrito na fundamentação do trabalho: **λ = 0 delibera sempre (equivale à heurística pura); λ alto nunca delibera (equivale à reativa)**.

### 2.1 Regime econômico

Quando não compensa deliberar, o agente se desloca por **passo guloso**: caminha até 3 células na direção do objetivo verificando apenas as células do próprio caminho (3 a 6 operações), em vez de expandir toda a vizinhança alcançável (~25 nós). Se o caminho barato trava diante de um obstáculo que a busca completa contornaria, o agente **recua para a busca completa** — o gasto alto fica reservado às situações em que o barato falha.

A economia é medida, não presumida: cada verificação do passo guloso é contabilizada pelo mesmo medidor (`grid.check_walkable`), e o caminho traçado é validado em tempo constante por passo (`agent.move_along`), sem refazer a busca.

### 2.2 Varredura de λ

| λ | Pontuação | WinRate | Custo | Eficiência (WR/1000 ops) |
|---|---|---|---|---|
| 0 (delibera sempre) | −0,98 | 0,235 | 749 | 0,314 |
| 0,002 | −0,97 | 0,235 | 752 | 0,313 |
| **0,005** | **−1,01** | **0,235** | **636** | **0,369** |
| 0,01 | −1,14 | 0,220 | 570 | 0,386 |
| 0,02 (quase nunca delibera) | −1,20 | 0,215 | 526 | 0,409 |
| *Heurística (referência)* | *−0,74* | *0,255* | *1298* | *0,196* |

O comportamento é monotônico e coerente com a teoria: **λ crescente compra economia com eficácia**. O valor **λ = 0,005** é o joelho da curva — preserva a eficácia máxima observada no modelo (WinRate 0,235, idêntico a λ = 0) já reduzindo 15% do custo em relação a deliberar sempre. Acima disso, cada operação economizada custa vitórias.

### 2.3 Poda por orçamento: descartada

Limitar o número de candidatas avaliadas por turno (ordenadas por promessa) foi testado em orçamentos de 45 e 75 operações. A eficácia caiu (pontuação −1,17 com orçamento 45, contra −0,97 sem poda) sem economia relevante, já que o regime econômico havia eliminado o grosso do custo. O mecanismo foi mantido no código, desligado por padrão (`budget = 0`), e o achado registrado.

## 3. Configuração final

| Parâmetro | Valor | Origem |
|---|---|---|
| λ | 0,005 | Varredura nas 200 seeds de tuning (§2.2) |
| budget | 0 (sem poda) | Varredura (§2.3) |
| Pesos | 0,092 / 0,307 / 0,495 / −0,228 | Aprendizado do confronto misto da campanha |

Desempenho na calibração, contra a heurística pura: **51% menos operações (636 contra 1298) mantendo 92% da eficácia (WinRate 0,235 contra 0,255)**. Em eficiência estratégica — vitórias obtidas por operação gasta — o híbrido supera a heurística em **88%**.

## 4. Nota sobre o StrategicScore

O escore composto definido em `metricas.md` atribui 10% do peso ao termo `1/max(Custo, ε)`. Com custos da ordem de centenas de operações, esse termo contribui com cerca de 0,0002 para o escore, enquanto o DamageRatio contribui com valores próximos de 1,0 — ou seja, **a métrica composta é praticamente cega à eficiência computacional**, justamente a dimensão que o modelo proposto otimiza.

Por essa razão, os resultados desta etapa foram reportados também em **eficiência estratégica** (WinRate por mil operações), que expressa diretamente o compromisso investigado.

> **Correção aplicada posteriormente.** A normalização do StrategicScore foi implementada: todos os termos passaram a ser reduzidos ao intervalo [0, 1] antes da ponderação, preservando os pesos originais. Ver `metricas.md` para a fórmula corrigida e `resultados_finais.md` para os escores recalculados. Os valores de escore citados nas tabelas acima seguem a fórmula antiga e devem ser lidos apenas em comparação relativa dentro desta seção.

## 5. Reprodução

```bash
# Referência
godot --headless --path simulator -- batch 200 tuning verde=heuristica

# Varredura de λ
godot --headless --path simulator -- batch 200 tuning verde=hibrida lambda=0.005 budget=0
```
