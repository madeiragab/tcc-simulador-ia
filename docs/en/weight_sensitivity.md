> 🇧🇷 [Português](../sensibilidade_pesos.md) · 🇬🇧 **English**

> ⚠️ **Translated report.** The Portuguese version is **auto-generated** from raw data by `simulator/tools/sensibilidade_pesos.gd`. This English version is a maintained translation: if the data are recollected, regenerate the Portuguese report and update this file.

# Sensitivity Analysis of the StrategicScore Weights

Reproduce the source report with:

```bash
godot --headless --path simulator --script res://tools/sensibilidade_pesos.gd
```

## The problem

The StrategicScore weights — 0.30 for victory, 0.20 for damage, cover and speed, and 0.10 for computational economy — are **the author's judgement**, not a derivation from theory or literature. That is a legitimate weakness: if the ranking of models changed with the chosen weights, the result would be an artefact of the metric rather than a property of the models.

This analysis checks whether the ranking **depends** on that choice. The procedure does not seek to justify the adopted weights, but to measure how sensitive the conclusion is to them.

---

## 1. Normalized components per model

All dimensions already reduced to [0, 1], before weighting:

| Model | WinRate | DamageNorm | CoverUsage | TurnEff | CostEff | Adopted score |
|---|---|---|---|---|---|---|
| art3miz_0.1 | 0.308 | 0.845 | 0.101 | 0.702 | 0.723 | **0.4942** |
| reactive | 0.306 | 0.843 | 0.053 | 0.642 | 0.695 | **0.4689** |
| heuristic | 0.296 | 0.827 | 0.097 | 0.542 | 0.559 | **0.4380** |
| mcts | 0.311 | 0.826 | 0.064 | 0.659 | 0.303 | **0.4334** |
| random | 0.000 | 0.468 | 0.051 | 0.000 | 0.302 | **0.1340** |

---

## 2. Alternative weight sets

Six plausible weightings, including the neutral one (all equal) and emphases shifted toward each objective:

| Weight set | 1st place |
|---|---|
| Adopted (0.30/0.20/0.20/0.20/0.10) | **art3miz_0.1** |
| Neutral — all equal (0.20 each) | **art3miz_0.1** |
| Victory emphasis (0.50/0.15/0.10/0.15/0.10) | **art3miz_0.1** |
| Economy emphasis (0.20/0.15/0.15/0.15/0.35) | **art3miz_0.1** |
| Tactical emphasis — damage and cover (0.15/0.30/0.30/0.15/0.10) | **art3miz_0.1** |
| Without the cost term (0.33/0.22/0.22/0.23/0.00) | **art3miz_0.1** |

---

## 3. Extreme cases — each dimension in isolation

Full weight assigned to a single dimension at a time:

| Dimension with full weight | Winner | Last place |
|---|---|---|
| WinRate | **mcts** | random |
| DamageNorm | **art3miz_0.1** | random |
| CoverUsage | **art3miz_0.1** | random |
| TurnEfficiency | **art3miz_0.1** | random |
| CostEfficiency | **art3miz_0.1** | random |

---

## 4. Monte Carlo — 10,000 random weightings

Weight vectors sampled **uniformly from the simplex** (Dirichlet with all parameters equal to 1), which amounts to treating every possible weighting as equally plausible. For each vector, the first-place model is recorded.

| Model | Times in 1st place | Frequency |
|---|---|---|
| art3miz_0.1 | 10000 / 10000 | **100.0%** |
| random | 0 / 10000 | 0.0% |
| reactive | 0 / 10000 | 0.0% |
| heuristic | 0 / 10000 | 0.0% |
| mcts | 0 / 10000 | 0.0% |

---

## 5. Individual weight perturbation (±50%)

Each weight is altered in isolation by ±50%, with the vector renormalized to sum to 1. **No individual perturbation changed the first-place model.**

---

## 6. Conclusion

### The ranking is robust, without being mathematically guaranteed

Art3miz 0.1 **does not dominate every dimension**: it is beaten on at least one, so its lead is not an automatic consequence of the metric's form. It is therefore worth characterizing the conditions under which the lead holds — and under which it breaks.

**Dimension where Art3miz 0.1 is beaten:**

| Dimension | Dimension leader | Leader's value | Art3miz value | Margin |
|---|---|---|---|---|
| WinRate | **mcts** | 0.311 | 0.308 | 0.0030 |

**Lead-switch threshold.** Concentrating weight progressively on each dimension (distributing the remainder in proportion to the adopted weights), the point at which the first place changes:

| Emphasized dimension | Weight needed to switch the leader | New leader |
|---|---|---|
| WinRate | **97%** | mcts |
| DamageNorm | never switches | — |
| CoverUsage | never switches | — |
| TurnEfficiency | never switches | — |
| CostEfficiency | never switches | — |

Read together with the Monte Carlo simulation in section 4, this is the analysis's central result: Art3miz 0.1's lead holds under every reasonable weighting, and only breaks under extreme concentration of weight on a single dimension — configurations that would strip the metric of its multidimensional character.

Recorded for transparency: this analysis **does not justify** the choice of weights — it only measures how sensitive the result is to them. The weights remain the author's judgement, fixed a priori before any comparison among models, and the neutral alternative (all equal) is included among the sets examined.
