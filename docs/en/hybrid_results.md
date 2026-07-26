> 🇧🇷 [Português](../resultados_hibrido.md) · 🇬🇧 **English**

# Calibration of the Proposed Model

Calibration was conducted exclusively on the **200 tuning seeds**, isolated from the 1000 benchmark seeds — during tuning the model never saw the scenarios on which it would later be evaluated.

Comparison baseline, measured on the same 200 seeds and the same confrontation (evaluated model against two reactive AIs): **Heuristic AI — points −0.74; win rate 0.255; cost 1298 operations/match**.

## 1. First formulation: penalizing the cost of each action

The direct reading of `ActionScore = StrategicValue − λ × ComputationalCost(action)` — subtracting from each candidate action the cost of evaluating it — was implemented and swept over λ ∈ {0.005; 0.01; 0.02; 0.05; 0.1}.

| λ | Points | Win rate | Cost |
|---|---|---|---|
| 0.005 | −0.85 | 0.240 | 1287 |
| 0.01 | −0.86 | 0.235 | 1305 |
| 0.02 | −0.88 | 0.235 | 1308 |

**The formulation produced no saving at all** (cost statistically identical to the heuristic's) and lost effectiveness. Investigation identified two causes, both measured:

### 1.1 The target of the penalty is a minority of the cost

Cost decomposition of the Heuristic AI (200 tuning matches):

| Component | Operations/match | Share |
|---|---|---|
| **Pathfinding nodes** | **1086** | **84%** |
| Line-of-sight computations | 109 | 8% |
| Actions evaluated | 103 | 8% |

The positional evaluation loop, which the penalty targets, accounts for only 16% of spending. Pathfinding — executed every turn, including the many turns without visual contact when the agent is merely exploring — dominates consumption. No adjustment of λ could save more than 16%.

### 1.2 Uniform costs make the term inert

Evaluating any candidate position costs practically the same (one line-of-sight check per visible enemy). With Cost(A) ≈ k for every action A, the term `−λ × k` is a **constant added to all candidates** and does not change which one has the highest score:

argmax[ Value(A) − λ·k ] = argmax[ Value(A) ]

This explains why λ = 0 and λ = 0.005 produced identical results. **Per-action penalization only discriminates when actions differ from one another in cost** — a condition this domain does not satisfy.

This negative result is a contribution of the work: it delimits the applicability condition of the naive formulation of the trade-off. See [theoretical_foundation.md](theoretical_foundation.md) §4 for why the metareasoning literature predicts it.

## 2. Reformulation: the trade-off decides *whether* to deliberate

If cost does not distinguish actions from one another, it distinguishes **decision procedures**. The reformulation applies the same trade-off one level up: before evaluating, the agent decides whether the analysis is justified.

It deliberates (full positional evaluation) if and only if:

**ValueAtStake − λ × EstimatedCost > 0**

where **ValueAtStake** = *n* × (Proximity + Vulnerability), with *n* visible enemies, Proximity the inverse of the distance to the nearest, and Vulnerability the fraction of health lost; and **EstimatedCost** = candidate cells × (visible enemies + 1).

With no enemies in sight, value at stake is zero and the economic regime is always chosen. The parameter spans the whole spectrum: **λ = 0 always deliberates** (equivalent to the pure heuristic); **high λ never deliberates** (equivalent to the reactive).

### 2.1 Economic regime

When deliberating is not worthwhile, the agent moves by **greedy stepping**: it walks up to 3 cells toward the objective checking only the cells on its own path (3 to 6 operations), instead of expanding the whole reachable neighbourhood (~25 nodes). If the greedy path stalls against an obstacle that search would circumvent, the agent **falls back to full search** — the expensive path is reserved for when the cheap one fails. Hunting a known position also keeps full search, since purposeful approach justifies the expense.

The saving is measured, not presumed: every greedy-step check is counted by the same meter (`grid.check_walkable`), and the traced path is validated in constant time per step (`agent.move_along`), without redoing the search.

### 2.2 λ sweep

| λ | Points | Win rate | Cost | Efficiency (wins/1k ops) |
|---|---|---|---|---|
| 0 (always deliberates) | −0.98 | 0.235 | 749 | 0.314 |
| 0.002 | −0.97 | 0.235 | 752 | 0.313 |
| **0.005** | **−1.01** | **0.235** | **636** | **0.369** |
| 0.01 | −1.14 | 0.220 | 570 | 0.386 |
| 0.02 (almost never) | −1.20 | 0.215 | 526 | 0.409 |
| *Heuristic (baseline)* | *−0.74* | *0.255* | *1298* | *0.196* |

The behaviour is monotonic and consistent with the theory: **increasing λ buys economy with effectiveness**. The value **λ = 0.005** is the knee of the curve — it preserves the maximum effectiveness observed for the model (win rate 0.235, identical to λ = 0) while already cutting 15% of the cost relative to always deliberating. Beyond that, each operation saved costs victories.

### 2.3 Budget pruning: discarded

Limiting the number of candidates evaluated per turn (ordered by promise) was tested at budgets of 45 and 75 operations. Effectiveness dropped (points −1.17 at budget 45, against −0.97 without pruning) with no relevant saving, since the economic regime had already eliminated the bulk of the cost. The mechanism was kept in the code, disabled by default (`budget = 0`), and the finding recorded.

## 3. Final configuration

| Parameter | Value | Origin |
|---|---|---|
| λ | 0.005 | Sweep over the 200 tuning seeds (§2.2) |
| budget | 0 (no pruning) | Sweep (§2.3) |
| Weights | 0.092 / 0.307 / 0.495 / −0.228 | Best configuration learned in the campaign's mixed confrontation |

Calibration performance against the pure heuristic: **51% fewer operations (636 against 1298) while retaining 92% of effectiveness** (win rate 0.235 against 0.255). In strategic efficiency — victories obtained per operation spent — the model exceeds the heuristic by **88%**.

## 4. Reproduction

```bash
# Baseline
godot --headless --path simulator -- batch 200 tuning verde=heuristica

# λ sweep
godot --headless --path simulator -- batch 200 tuning verde=art3miz lambda=0.005 budget=0
```
