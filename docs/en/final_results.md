> 🇧🇷 [Português](../resultados_finais.md) · 🇬🇧 **English**

# Final Results — Official Benchmark

Final execution over the official bank of 1000 benchmark seeds, under the definitive rule set (120° vision cone, proximity sensor, straight-line fire, directional cover, +3/−1/−3 scoring, between-match learning). **7,000 matches** across 7 batches, all documented under `data/runs/`, plus a further 4,000 in the MCTS and generalization experiments.

Art3miz 0.1 configuration: λ = 0.005, weights inherited from campaign learning (see [hybrid_results.md](hybrid_results.md)).

## 1. Self-play characterization

Three instances of the same model per match. Under symmetric conditions the win rate converges to ~1/3 for any functional model — what the comparison reveals is **the price paid for that performance** and the ability to bring the match to a decision.

| Model | Win rate | DamageRatio | CoverUsage | Turns to win | Draws | **Cost** | **StrategicScore** |
|---|---|---|---|---|---|---|---|
| Random | 0.000 | 1.14 | 0.051 | 100.0 | **1000 (100%)** | 2323 | 0.145 |
| Reactive | 0.312 | 5.71 | 0.052 | 35.5 | 65 (6.5%) | 437 | 0.473 |
| Heuristic | 0.295 | 4.55 | 0.096 | 45.1 | 116 (11.6%) | 777 | 0.438 |
| **Art3miz 0.1** | **0.314** | 5.18 | **0.104** | **29.3** | **57 (5.7%)** | **379** | **0.497** |

Findings:

- **Art3miz 0.1 obtains the highest StrategicScore (0.497)**, ahead of reactive (0.473) and heuristic (0.438). It leads four of the metric's five dimensions: win rate, cover usage, speed to decide the match, and computational economy.
- **It is the most economical among all functional models**: 379 operations per match, against 437 for reactive (−13%) and 777 for heuristic (−51%).
- **It is the most decisive**: only 5.7% draws, against 11.6% for the heuristic — which, being mutually cautious, frequently deadlocks to the turn limit. It also wins faster (29.3 turns against 35.5 and 45.1).
- In strategic efficiency (wins per thousand operations), the ordering is **Art3miz 0.1 at 0.829 > reactive 0.714 > heuristic 0.380**: more than **twice** the heuristic's efficiency.
- The Random AI confirms itself as the absolute floor: no wins in 1000 matches, while paying the **highest cost of all** (2323) — it enumerates every option and discards the information. Its score (0.145) separates it clearly from the functional models (0.438–0.497).

## 2. Direct confrontation

The evaluated model against full-cost opponents.

### 2.1 Three-way confrontation (decisive)

| | Art3miz 0.1 | Heuristic | Reactive |
|---|---|---|---|
| Mean points | −1.44 | −0.75 | −0.81 |
| **Win rate** | 0.225 | **0.339** | 0.330 |
| DamageRatio | 4.23 ± 10.38 | 5.21 ± 10.64 | 5.61 ± 11.07 |
| CoverUsage | **0.096** | 0.095 | 0.074 |
| Turns to victory | 44.4 | 39.8 | 39.3 |
| **Cost** | **510** | 719 | 484 |
| Efficiency (wins/1k ops) | 0.441 | 0.472 | **0.682** |
| **StrategicScore** | 0.426 | 0.467 | **0.472** |

### 2.2 Against two identical opponents

| Confrontation | Art3miz 0.1 | Opponents |
|---|---|---|
| vs 2 heuristics | WR 0.232 · cost 492 · score 0.426 | WR 0.332 / 0.329 · cost ~700 · score ~0.470 |
| vs 2 reactives | WR 0.248 · cost 505 · score 0.433 | WR 0.332 / 0.329 · cost ~457 · score ~0.477 |

**In direct competition Art3miz 0.1 wins less** (0.225–0.248 against ~0.33 for both baselines), while still holding the lowest cost among the analytical models and the highest cover usage in the three-way match.

## 2.3 Statistical significance

Every comparative claim in this section was formally tested. The full report, with the chosen tests and their justification, is in [statistical_analysis.md](statistical_analysis.md); the essentials:

| Comparison | Test | Result |
|---|---|---|
| Do the three win rates differ? | Chi-square (df = 2) | χ² = 26.96 · **p < 0.001** · significant |
| Art3miz 0.1 vs Heuristic (wins) | Conditional binomial | **p < 0.001** · the heuristic wins more |
| Art3miz 0.1 vs Reactive (wins) | Conditional binomial | **p < 0.001** · the reactive wins more |
| **Heuristic vs Reactive (wins)** | Conditional binomial | **p = 0.757 · NOT significant** |
| Cost: Art3miz 0.1 vs Heuristic | Paired t-test by seed | −208.5 ops · **p < 0.001** · small effect (d = −0.39) |
| Cost: Art3miz 0.1 vs Reactive | Paired t-test by seed | +26.0 ops · p = 0.082 · **no detectable difference** |

Two of these results require revising claims the raw data suggested:

**The "intelligence gradient" between heuristic and reactive does not hold.** The difference of 0.339 against 0.330 in win rates is consistent with sampling fluctuation (p = 0.757). There is no evidence that the heuristic's multi-criteria evaluation produces more wins than the reactive's simple rules — only that it costs significantly more (+234.5 operations, p < 0.001, medium effect). This is a result unfavourable to analytical sophistication, and is reported as such.

**In direct confrontation, Art3miz 0.1's cost does not differ from the reactive's** (p = 0.082). Its economy is demonstrable relative to the heuristic and MCTS, not relative to the simplest baseline.

### 2.4 StrategicScore with confidence intervals

Intervals obtained by percentile bootstrap (2000 resamples) over the self-play runs:

| Model | StrategicScore | 95% CI |
|---|---|---|
| Random | 0.134 | [0.114; 0.150] |
| Heuristic | 0.438 | [0.421; 0.454] |
| Reactive | 0.469 | [0.453; 0.484] |
| **Art3miz 0.1** | **0.494** | **[0.479; 0.509]** |

Art3miz 0.1's interval **does not overlap** the heuristic's — superiority in the composite score is statistically distinguishable. The overlap with the reactive (0.479–0.484), however, indicates that between those two **the difference is not conclusive**.

## 2.5 The full spectrum — confrontation with MCTS

With MCTS implemented, the high-quality, high-cost end stops being a theoretical reference and becomes a measured point. A 1000-match confrontation between MCTS, Art3miz 0.1 and the Heuristic AI:

| Metric | MCTS | Heuristic | Art3miz 0.1 |
|---|---|---|---|
| Win rate | **0.379** | 0.292 | 0.236 |
| Computational cost | 2794.5 | 680.8 | **471.0** |
| **Efficiency** (wins/1k ops) | 0.136 | 0.429 | **0.501** |

The ordering inverts depending on which dimension is observed, and that contrast is exactly what the work investigates: **MCTS wins more, Art3miz 0.1 wins cheaper**.

### 2.5.1 The marginal value of computation

The comparison allows direct quantification of the central concept of the theoretical foundation — how much each additional unit of processing is worth:

| Step | Additional wins | Additional cost | **Cost per additional win** |
|---|---|---|---|
| Art3miz 0.1 → Heuristic | +56 | +209,800 ops | ≈ 3,750 operations |
| Heuristic → MCTS | +87 | +2,113,700 ops | ≈ 24,300 operations |

Returns are **sharply diminishing**: the first slice of analytical sophistication costs about 3,750 operations per additional win; the second, more than six times that. In terms of Russell and Wefald's (1991) framework, the marginal value of computation falls rapidly as one climbs the spectrum — and the point where it stops paying off depends on the available processing budget, which is precisely what the proposed model's λ parameter makes explicit.

This is the result underpinning the work's thesis: **there is no best model in absolute terms; there is a trade-off, and it can be measured, quantified and controlled.**

## 3. Interpretation

The results support three conclusions, and stating them precisely matters.

**The efficiency hypothesis is confirmed.** Art3miz 0.1 reduces computational cost by 51% relative to the pure heuristic and is the cheapest functional model in the study. Under symmetric conditions it delivers equal or superior performance to the others (win rate 0.314; lowest draw rate; fewest turns to victory) for a fraction of the processing, reaching the **highest StrategicScore in the study (0.497)** and more than double the heuristic's strategic efficiency. Formalizing the value-versus-cost trade-off therefore produces a measurably more efficient agent.

**The competitive superiority hypothesis is not confirmed.** When facing opponents paying the full price of analysis, Art3miz 0.1 wins less (≈0.23 against ≈0.33). The economy obtained by deliberating selectively has a price: on turns when it opts for the economic regime, the agent occasionally misses the position full evaluation would have found, and opponents that always deliberate exploit that difference.

**The Reactive AI proves a remarkably strong baseline.** With 484 operations and a 0.330 win rate in the three-way confrontation, it shows the highest efficiency in direct competition (0.682 wins per thousand operations). Formal testing reinforces the conclusion: **the heuristic does not win significantly more than the reactive** (p = 0.757), despite spending 48% more operations (p < 0.001). In tactical environments with limited perception and a short horizon, simple well-chosen rules are hard to beat — analytical sophistication must justify its cost, and in this domain it did not.

**The advantage has a range of applicability, and it has been delimited.** Replication across three map scales ([generalization.md](generalization.md)) shows the saving over the heuristic **grows with environment size** — from 16% at 25×25 to 49% at 60×60 — confirming the mechanism: the larger the map, the more turns without visual contact, the more opportunities to skip deliberation. Conversely, on small maps the Reactive AI **dominates** the proposed model, being simultaneously cheaper and more effective. The model pays off in environments offering periods of low criticality; where every situation is critical, there is nothing to save.

### 3.1 Synthesis

The work does not demonstrate that the hybrid model is the best player; it demonstrates, with quantitative evidence across 7,000 matches, that **a measurable and controllable trade-off exists between strategic quality and computational cost**, and that the λ parameter allows navigating it monotonically and predictably (see the curve in [hybrid_results.md](hybrid_results.md) §2.2). For applications under restricted processing budgets — commercial games with per-frame time limits, embedded robotics, large-scale simulations — Art3miz 0.1 offers an explicit control the reference models do not possess: it is possible to choose, by design, how much performance one is willing to trade for economy.

## 4. Correction of the composite metric

The original StrategicScore formulation summed quantities on incompatible scales, making nominal weights diverge radically from actual effect. Measured in this same three-way confrontation, the damage term — nominally 20% — contributed 0.85 to 1.12 of the score; the win rate — nominally 30% — contributed 0.07 to 0.10; and cost — nominally 10% — contributed 0.0002, roughly four thousand times less than intended. In practice the metric measured almost nothing but damage ratio, and was blind to computational efficiency.

The correction (documented in [metrics.md](metrics.md)) normalizes all terms to [0, 1] before weighting, **preserving exactly the original weights** (0.30 / 0.20 / 0.20 / 0.20 / 0.10). It acts on scale, not on the research project's intent, dispelling any suspicion of tuning the metric in favour of the proposed model.

Since the change affects aggregation rather than collection, **the scores of all runs were recomputed from the preserved raw data**, without repeating simulations (`simulator/tools/recalcular_resumos.gd`). Per-match data remain intact and auditable.

## 5. Reproduction

```bash
# Decisive confrontation
godot --headless --path simulator -- batch 1000 benchmark verde=art3miz vermelho=heuristica azul=reativa

# Self-play runs
godot --headless --path simulator -- batch 1000 benchmark verde=art3miz vermelho=art3miz azul=art3miz
godot --headless --path simulator -- batch 1000 benchmark verde=heuristica vermelho=heuristica azul=heuristica
godot --headless --path simulator -- batch 1000 benchmark verde=reativa vermelho=reativa azul=reativa
godot --headless --path simulator -- batch 1000 benchmark verde=aleatoria vermelho=aleatoria azul=aleatoria
```

Runs are deterministic: the same commands reproduce the same results byte for byte.
