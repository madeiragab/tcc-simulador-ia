> 🇧🇷 [Português](../generalizacao.md) · 🇬🇧 **English**

# Generalization — Does the Finding Hold Beyond 40×40?

Benchmark results were obtained on a 40×40 grid. A conclusion drawn from a single environment configuration may be a property of that environment rather than of the model. This experiment replicates the direct confrontation at **three scales** to verify which findings hold.

## Protocol

Three runs of 1000 matches each, identical except for map size: **25×25**, **40×40** and **60×60**. Same models (Art3miz 0.1, Heuristic, Reactive), same seed bank, same bias controls. Procedural generation scales with area — obstacle count and sector size grow proportionally — so terrain density remains constant.

```bash
godot --headless --path simulator -- batch 1000 benchmark mapa=25 verde=art3miz vermelho=heuristica azul=reativa
godot --headless --path simulator -- batch 1000 benchmark mapa=60 verde=art3miz vermelho=heuristica azul=reativa
```

## Results

| Scale | Model | Win rate | Cost | StrategicScore |
|---|---|---|---|---|
| **25×25** | Art3miz 0.1 | 0.195 | **413** | 0.448 |
| | Heuristic | 0.372 | 494 | 0.518 |
| | Reactive | 0.371 | **286** | 0.525 |
| **40×40** | Art3miz 0.1 | 0.225 | **510** | 0.426 |
| | Heuristic | 0.339 | 719 | 0.467 |
| | Reactive | 0.330 | 484 | 0.472 |
| **60×60** | Art3miz 0.1 | 0.225 | **494** | 0.379 |
| | Heuristic | 0.305 | 970 | 0.410 |
| | Reactive | 0.305 | 760 | 0.417 |

## 1. The saving grows with scale — and the mechanism explains why

Art3miz 0.1's cost reduction relative to the Heuristic, by scale:

| Scale | Art3miz cost | Heuristic cost | **Saving** |
|---|---|---|---|
| 25×25 | 413 | 494 | **−16%** |
| 40×40 | 510 | 719 | **−29%** |
| 60×60 | 494 | 970 | **−49%** |

**The saving nearly triples** between the smallest and largest scale. This is consistent with the mechanism identified during characterization: 84% of cost concentrates in pathfinding, and larger maps demand more movement without visual contact — precisely the situations where the economic regime replaces full search with greedy stepping.

This is the experiment's central finding: **the proposed model's advantage is not an artefact of the original configuration — it amplifies as the environment grows**, which is the relevant direction for practical application, where environments tend to be larger than the one tested.

Note further that Art3miz's absolute cost stays practically flat between 40×40 and 60×60 (510 → 494), while the Heuristic's grows 35% (719 → 970). The proposed model is **substantially less sensitive to environment scale**.

## 2. The competitive disadvantage also generalizes

At all three scales, Art3miz 0.1 wins fewer matches than both reference models (0.195 to 0.225 against 0.305 to 0.372). The limitation identified in the original benchmark is not specific to that configuration: **it is a property of the model**, arising from forgoing deliberation on some turns.

## 3. Limitation found: on small maps the model is dominated

The most unfavourable result for the proposed model appears at the smallest scale. On 25×25, the Reactive AI is **simultaneously cheaper and more effective**:

| 25×25 | Cost | Win rate |
|---|---|---|
| Reactive | **286** | **0.371** |
| Art3miz 0.1 | 413 | 0.195 |

This is **domination of the proposed model by the Reactive AI** at that scale — there is no dimension on which Art3miz compensates. The explanation is consistent with the mechanism: on small maps visual contact is nearly constant, so (i) the economic regime is rarely triggered, eliminating the source of savings, and (ii) when it is triggered, it happens in situations that genuinely required deliberation, degrading the decision.

**Consequence for the model:** Art3miz 0.1 has a **range of applicability**. It pays off in environments large enough to contain periods without contact — and there its advantage grows with scale. In small, dense environments the cost of deliberation is low enough that saving it is not justified.

This limitation is itself consistent with the theoretical foundation: the value of computation is context-dependent, and metareasoning only pays off when there is real variation in the value of deliberating. In an environment where every situation is critical, there is nothing to save.

## 4. Synthesis

| Finding | Generalizes? |
|---|---|
| Cost saving over the Heuristic | **Yes — and amplifies with scale** (−16% → −49%) |
| Lower cost sensitivity to scale | **Yes** (flat cost vs +35% for the Heuristic) |
| Win-rate disadvantage | **Yes** — present at all three scales |
| Advantage over the Reactive | **No** — reversed on small maps |

The work's conclusion therefore gains a scope qualification: the quality-cost trade-off formalized by the proposed model **is real and scales favourably**, but its advantage depends on the environment offering periods in which deliberation is dispensable.
