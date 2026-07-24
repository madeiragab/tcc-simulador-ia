# Simulador Tático para Avaliação de IA

Ambiente de simulação tática por turnos construído para **medir a qualidade
estratégica de agentes de IA** — não apenas se ganham, mas quanto processamento
gastam para ganhar.

> Trabalho de Conclusão de Curso — Ciência da Computação, IFSulDeMinas.
> Autor: **Gabriel Madeira**.

## O problema

Comparar modelos de IA em jogos costuma parar no WinRate. Isso esconde duas
coisas: um agente pode vencer por sorte do cenário, e pode vencer gastando um
custo computacional que o tornaria inviável na prática.

Este trabalho propõe um ambiente **neutro, determinístico e reprodutível** onde
eficácia e custo são medidos lado a lado, e usa essa base para especificar um
**modelo híbrido de decisão** que equilibra os dois:

```text
ScoreAção = ValorEstratégico − λ × CustoComputacional
```

## O ambiente

- Grid tático por turnos, **3 agentes** simultâneos, limite de 100 turnos.
- Mapas **gerados proceduralmente por seed** (4 setores, spawn sorteado,
  conectividade validada) — bancos fixos de 1000 seeds de benchmark e 200 de
  tuning garantem que todos os modelos enfrentem exatamente os mesmos cenários.
- Percepção limitada por **cone de visão de 120°**, tiro em linha reta,
  **cobertura direcional** e combate determinístico (sem dados).
- **Rotação de iniciativa**: a partida *i* começa pelo jogador *i* mod 3,
  eliminando vantagem de ordem.
- Execução **headless em lote** com exportação CSV.

A neutralidade do ambiente foi validada empiricamente: 1000 partidas com três
IAs idênticas produziram WinRates estatisticamente equivalentes
(0,231 / 0,232 / 0,225 — diferença máxima de 0,7 pp).

## Os modelos comparados

| Modelo | Descrição |
|---|---|
| **Aleatória** | Piso absoluto de referência |
| **Reativa** | Responde ao estado imediato |
| **Heurística** | Utility AI com pesos calibráveis + hill-climbing entre partidas |
| **Híbrida** | Modelo proposto — heurística penalizada pelo custo (Fase 4) |

## Resultados até aqui

Campanha de **4.000 partidas × 3 agentes = 12.000 registros**, sob as regras
finais. No confronto misto (uma IA de cada na mesma arena, 1000 partidas):

| Métrica | Aleatória | Reativa | Heurística |
|---|---|---|---|
| Pontuação média | −1,57 | −0,83 | **−0,59** |
| WinRate | 0,027 | 0,150 | **0,190** |
| DamageRatio | 0,11 | 11,17 | **13,08** |
| StrategicScore | 0,04 | 2,29 | **2,69** |
| Custo computacional | 1520 | 1358 | 1811 |

O gradiente de inteligência aparece em **todas** as métricas de eficácia na
ordem esperada — e expõe o trade-off central do trabalho: a heurística vence
27% mais que a reativa, mas custa **33% mais operações**.

A decomposição do custo mostra exatamente onde: o diferencial da heurística
está no loop de avaliação posicional (180 cálculos de linha de visão contra 12
da reativa). É esse loop que o modelo híbrido precisa disciplinar.

Análise completa: [docs/resultados_campanha.md](docs/resultados_campanha.md).

## Como executar

Requer [Godot 4](https://godotengine.org/).

Modo visual (assistir uma partida):

```bash
godot --path simulator
```

Modo headless em lote (coleta de dados):

```bash
godot --headless --path simulator -- batch 1000 benchmark verde=aleatoria vermelho=reativa azul=heuristica
```

Argumentos: `batch <N> <banco>` onde `banco` é `benchmark` (1000 seeds) ou
`tuning` (200 seeds), seguido da escalação `<cor>=<modelo>` para
`verde`, `vermelho` e `azul`. Modelos: `aleatoria`, `reativa`, `heuristica`.

Cada execução grava uma pasta em `data/runs/<timestamp>_<banco>_<N>/` com
`partidas.csv` (uma linha por jogador por partida), `resumo.csv`,
`aprendizado.csv` e um `manifest.txt` com a configuração exata.

**As execuções são determinísticas**: os mesmos comandos reproduzem os mesmos
resultados.

## Documentação

A pasta [`docs/`](docs) contém a base teórica e metodológica completa —
[índice comentado aqui](docs/README.md). Os principais:

| Doc | Assunto |
|---|---|
| [problema.md](docs/problema.md) | Contexto, questão de pesquisa e hipótese |
| [contribuicao.md](docs/contribuicao.md) | A contribuição central do trabalho |
| [arquitetura.md](docs/arquitetura.md) | Separação entre Core, Mapa, Agentes, IA, Turnos e Coleta |
| [regras.md](docs/regras.md) | Regras do mundo simulado |
| [geracao_mapas.md](docs/geracao_mapas.md) | Geração procedural por seed |
| [ia.md](docs/ia.md) | Paradigma de Utility AI adotado |
| [baseline.md](docs/baseline.md) | Modelos de referência |
| [modelo_proposto.md](docs/modelo_proposto.md) | Especificação do modelo híbrido |
| [metricas.md](docs/metricas.md) | Fórmulas das métricas e do StrategicScore |
| [metodologia.md](docs/metodologia.md) | Configuração experimental |
| [resultados_validacao.md](docs/resultados_validacao.md) | Validação da neutralidade do ambiente |
| [resultados_campanha.md](docs/resultados_campanha.md) | Resultados da campanha de coleta |
| [roadmap_implementacao.md](docs/roadmap_implementacao.md) | Fases e status |

## Estrutura do repositório

```text
/
├─ simulator/               → projeto Godot 4
│  ├─ core/                 → simulação, turnos, lote, métricas, custo
│  ├─ ai/                   → ai_base, ai_random, ai_reactive, ai_heuristic
│  ├─ agents/               → estado e atributos dos agentes
│  ├─ map/                  → grid e geração procedural
│  └─ tools/                → geradores auxiliares da monografia
├─ docs/                    → base teórica, metodologia e resultados
├─ diagrams/                → arquitetura, fluxo, decisão e métricas
├─ experiments/configs/     → bancos de seeds (benchmark e tuning)
├─ data/runs/               → saídas das execuções (CSV + manifest)
├─ monografia/              → texto do TCC
└─ presentation/            → apresentação de banca
```

## Status

Fases 1 a 3 concluídas (ambiente, infraestrutura experimental e as três IAs
base, com campanha de coleta completa). **Fase 4 em andamento**: implementação
e calibração do modelo híbrido. Detalhes em
[roadmap_implementacao.md](docs/roadmap_implementacao.md).

## Tecnologias

- **Godot 4** / GDScript — simulação e execução headless em lote
- **Python** — análise dos dados coletados
- CSV como formato de intercâmbio
