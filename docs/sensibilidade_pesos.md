# Análise de Sensibilidade dos Pesos do StrategicScore

Relatório gerado por `simulator/tools/sensibilidade_pesos.gd` a partir dos dados brutos dos autoconfrontos. Reproduzível com:

```bash
godot --headless --path simulator --script res://tools/sensibilidade_pesos.gd
```

## O problema

Os pesos do StrategicScore — 0,30 para vitória, 0,20 para dano, cobertura e rapidez, e 0,10 para economia computacional — são **julgamento do autor**, não derivação de teoria ou literatura. Isso é uma fragilidade legítima: se o ordenamento dos modelos mudasse conforme os pesos escolhidos, o resultado seria artefato da métrica, e não propriedade dos modelos.

Esta análise verifica se o ordenamento **depende** dessa escolha. O procedimento não busca justificar os pesos adotados, e sim medir quanto a conclusão é sensível a eles.

---

## 1. Componentes normalizadas por modelo

Todas as dimensões já reduzidas ao intervalo [0, 1], antes da ponderação:

| Modelo | WinRate | DamageNorm | CoverUsage | EfTurnos | EfCusto | Escore adotado |
|---|---|---|---|---|---|---|
| art3miz_0.1 | 0.308 | 0.845 | 0.101 | 0.702 | 0.723 | **0.4942** |
| reativa | 0.306 | 0.843 | 0.053 | 0.642 | 0.695 | **0.4689** |
| heuristica | 0.296 | 0.827 | 0.097 | 0.542 | 0.559 | **0.4380** |
| mcts | 0.311 | 0.826 | 0.064 | 0.659 | 0.303 | **0.4334** |
| aleatoria | 0.000 | 0.468 | 0.051 | 0.000 | 0.302 | **0.1340** |

---

## 2. Conjuntos alternativos de pesos

Cinco ponderações plausíveis, incluindo a neutra (todas iguais) e ênfases deslocadas para cada objetivo:

| Conjunto de pesos | 1º lugar | Ordenamento completo |
|---|---|---|
| Adotado (0,30/0,20/0,20/0,20/0,10) | **art3miz_0.1** | art3miz_0.1 (0.494) › reativa (0.469) › heuristica (0.438) › mcts (0.433) › aleatoria (0.134) |
| Neutro — todos iguais (0,20 cada) | **art3miz_0.1** | art3miz_0.1 (0.536) › reativa (0.508) › heuristica (0.464) › mcts (0.433) › aleatoria (0.164) |
| Ênfase em vitória (0,50/0,15/0,10/0,15/0,10) | **art3miz_0.1** | art3miz_0.1 (0.468) › reativa (0.451) › heuristica (0.419) › mcts (0.415) › aleatoria (0.106) |
| Ênfase em economia (0,20/0,15/0,15/0,15/0,35) | **art3miz_0.1** | art3miz_0.1 (0.562) › reativa (0.535) › heuristica (0.475) › mcts (0.401) › aleatoria (0.183) |
| Ênfase tática — dano e cobertura (0,15/0,30/0,30/0,15/0,10) | **art3miz_0.1** | art3miz_0.1 (0.508) › reativa (0.481) › heuristica (0.459) › mcts (0.443) › aleatoria (0.186) |
| Sem o termo de custo (0,33/0,22/0,22/0,23/0,00) | **art3miz_0.1** | art3miz_0.1 (0.471) › mcts (0.450) › reativa (0.446) › heuristica (0.426) › aleatoria (0.114) |

---

## 3. Casos extremos — cada dimensão isolada

Peso total atribuído a uma única dimensão por vez. Revela qual modelo domina cada objetivo separadamente:

| Dimensão com peso total | Vencedor | Escore | Último colocado |
|---|---|---|---|
| WinRate | **mcts** | 0.311 | aleatoria |
| DamageNorm | **art3miz_0.1** | 0.845 | aleatoria |
| CoverUsage | **art3miz_0.1** | 0.101 | aleatoria |
| EfTurnos | **art3miz_0.1** | 0.702 | aleatoria |
| EfCusto | **art3miz_0.1** | 0.723 | aleatoria |

---

## 4. Monte Carlo — 10.000 ponderações aleatórias

Vetores de pesos amostrados **uniformemente do simplex** (distribuição de Dirichlet com todos os parâmetros iguais a 1), o que equivale a considerar qualquer ponderação possível igualmente plausível. Para cada vetor, registra-se qual modelo fica em primeiro lugar.

| Modelo | Vezes em 1º lugar | Frequência |
|---|---|---|
| art3miz_0.1 | 10000 / 10000 | **100.0%** |
| aleatoria | 0 / 10000 | **0.0%** |
| reativa | 0 / 10000 | **0.0%** |
| heuristica | 0 / 10000 | **0.0%** |
| mcts | 0 / 10000 | **0.0%** |

---

## 5. Perturbação individual dos pesos (±50%)

Cada peso é alterado isoladamente em ±50%, com renormalização do vetor para somar 1. Verifica se algum peso específico é responsável pelo ordenamento:

| Peso alterado | Variação | 1º lugar | Ordenamento mudou? |
|---|---|---|---|
| WinRate | −50% | art3miz_0.1 | não |
| WinRate | +50% | art3miz_0.1 | não |
| DamageNorm | −50% | art3miz_0.1 | não |
| DamageNorm | +50% | art3miz_0.1 | não |
| CoverUsage | −50% | art3miz_0.1 | não |
| CoverUsage | +50% | art3miz_0.1 | não |
| EfTurnos | −50% | art3miz_0.1 | não |
| EfTurnos | +50% | art3miz_0.1 | não |
| EfCusto | −50% | art3miz_0.1 | não |
| EfCusto | +50% | art3miz_0.1 | não |

Nenhuma perturbação individual alterou o primeiro colocado.

---

## 6. Conclusão da análise

### O ordenamento é robusto, sem ser matematicamente garantido

O art3miz_0.1 **não domina todas as dimensões**: perde em pelo menos uma delas, de modo que sua liderança não é consequência automática da forma da métrica. Cabe, portanto, caracterizar sob que condições ela se mantém — e sob quais se desfaz.

**Dimensões em que o art3miz_0.1 é superado:**

| Dimensão | Líder da dimensão | Valor do líder | Valor do art3miz_0.1 | Margem |
|---|---|---|---|---|
| WinRate | **mcts** | 0.311 | 0.308 | 0.0030 |

**Limiar de troca de liderança.** Concentrando peso progressivamente em cada dimensão isolada (e distribuindo o restante na proporção dos pesos adotados), o ponto em que o primeiro colocado muda:

| Dimensão enfatizada | Peso necessário para trocar o líder | Novo líder |
|---|---|---|
| WinRate | **97%** | mcts |
| DamageNorm | nunca troca | — |
| CoverUsage | nunca troca | — |
| EfTurnos | nunca troca | — |
| EfCusto | nunca troca | — |

A leitura conjunta com a simulação de Monte Carlo da seção 4 é o resultado central desta análise: a liderança do art3miz_0.1 se mantém em toda ponderação razoável, e só se desfaz sob concentrações extremas de peso em uma única dimensão — configurações que descaracterizariam a métrica como instrumento multidimensional.

Registra-se, para transparência, que esta análise **não justifica** a escolha dos pesos — apenas mede a sensibilidade do resultado a ela. Os pesos permanecem julgamento do autor, fixados a priori antes de qualquer comparação entre modelos, e a alternativa neutra (todos iguais) está incluída entre os conjuntos examinados.

