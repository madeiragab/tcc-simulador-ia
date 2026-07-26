> 🇧🇷 [Português](../metricas.md) · 🇬🇧 **English**

# Evaluation Metrics

## Purpose

Define quantitative metrics to evaluate agents' performance and strategic quality in the simulated environment.

## Individual metrics

### Win rate
Percentage of victories by the agent across multiple simulations.

### Damage ratio
Total damage dealt by the evaluated agent divided by total damage taken. The divide-by-zero guard follows the project's ε convention:

DamageRatio = damage_dealt / max(damage_taken, ε), with ε = 1

### Cover usage
Percentage of turns in which the evaluated agent ended the turn in a protected position (with an adjacent cover cell, offering potential protection in at least one direction).

### Turns to victory
Mean number of turns the evaluated agent needed to win. To penalize inertia and passive-survival loops, a match ending in a draw at the 100-turn limit assigns the model the maximum penalty value (100).

### Match points

Each match awards points according to the outcome:

- Victory: **+3**
- Draw: **−1**
- Defeat: **−3**

The draw is deliberately penalized (not treated as neutral): a model that merely survives without deciding the match — for instance by entrenching until the turn limit — does not demonstrate strategic effectiveness. Aggregation uses the total and mean points per match (range −3 to +3).

### Mean computational cost
Mean algorithmic effort, measured by abstract counting of code operations: cumulative line-of-sight computations, generated actions and filtered search nodes. This metric replaces wall-clock millisecond measurement, avoiding dependence on the evaluator's hardware. An ε constant (= 1) provides a logical floor in ratio formulas and prevents division by zero.

## Composite metric

### Strategic Score

The linear composition weighs five performance dimensions. So that the weights genuinely correspond to the intended importance, **all terms are normalized to [0, 1]** before weighting, so the final score also lies in [0, 1]:

StrategicScore =
0.30 × WinRate +
0.20 × DamageNorm +
0.20 × CoverUsage +
0.20 × TurnEfficiency +
0.10 × CostEfficiency

Where:

- **WinRate** ∈ [0, 1] — fraction of victories (already normalized by definition).
- **DamageNorm** = DamageRatio / (1 + DamageRatio) ∈ [0, 1) — smooth saturation of the damage ratio. It equals 0.5 when the agent deals exactly the damage it takes, tends to 1 as it dominates the exchange, and to 0 when it only takes hits. It avoids an arbitrary cap and preserves the ordering among models.
- **CoverUsage** ∈ [0, 1] — fraction of turns in a protected position (already normalized).
- **TurnEfficiency** = (TurnLimit − min(TurnsToVictory, TurnLimit)) / TurnLimit ∈ [0, 1] — fraction of the turn budget saved. Equals 1 for an immediate win and 0 for a draw by exhaustion (TurnLimit = 100).
- **CostEfficiency** = ReferenceCost / (ReferenceCost + MeanComputationalCost) ∈ (0, 1) — equals 0.5 when the model spends exactly the reference cost (ReferenceCost = 1000 operations, the typical order of magnitude observed), tends to 1 as it decides more cheaply and to 0 as it becomes more expensive.

#### Rationale for normalization

The original formulation summed quantities on incompatible scales, making the nominal weights diverge radically from their actual effect. Measured in the official benchmark's three-way confrontation, the damage term — nominally 20% — contributed 0.85 to 1.12 of the score, while win rate — nominally 30% — contributed 0.07 to 0.10, and cost — nominally 10% — contributed 0.0002, roughly four thousand times less than intended. In practice the score measured almost exclusively the damage ratio and was blind to computational efficiency, precisely the dimension central to this research.

The correction acts **only on the scale of the terms**: the weights remain exactly as originally defined (0.30 / 0.20 / 0.20 / 0.20 / 0.10), preserving the research project's intent and dispelling any suspicion that the metric was tuned in favour of Art3miz 0.1. Since the change affects aggregation rather than collection, the scores of all completed runs were recomputed from the preserved raw data, with no need to repeat simulations.

The robustness of the resulting ranking to the choice of weights is examined in [weight_sensitivity.md](weight_sensitivity.md).

- ε = 1 remains the floor against division by zero in the individual DamageRatio computation.

### Official aggregation

After the 1000 scenarios defined in the methodology, the output evaluated in the thesis consists of the individual metrics' **exact means per parameter**, contrasted against their **standard deviations** (to audit anomalous behaviour against linear trends), plus the significance tests reported in [statistical_analysis.md](statistical_analysis.md).

## Notes

The composite metric allows evaluating an agent more comprehensively, considering not only the final outcome but also the efficiency and quality of its decisions.
