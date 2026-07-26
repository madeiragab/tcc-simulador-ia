> 🇧🇷 [Português](../modelo_proposto.md) · 🇬🇧 **English**

# Art3miz 0.1 — The Proposed Model

Central contribution of this work: a hybrid decision model weighing strategic value against computational cost.

Implementation: `simulator/ai/ai_art3miz.gd` · Command-line identifier: `art3miz`
Calibration and evidence: [hybrid_results.md](hybrid_results.md) · Results: [final_results.md](final_results.md)

The version suffix is intentional: it records that the reported results correspond to this specific configuration (λ = 0.005, calibrated weights, economic regime with fallback). Future adjustments to the mechanism produce subsequent versions, keeping each dataset traceable to the version that generated it.

## 1. Initial formulation and why it fails

The direct reading of the value-versus-cost trade-off penalizes each candidate action by the cost of evaluating it:

Score(A) = StrategicValue(A) − λ × ComputationalCost(A)

Implemented and subjected to a λ sweep, **this formulation proved inert in this domain**. The negative result is a contribution of the work, since it delimits the applicability condition of the naive form of the trade-off. Two causes, both measured:

**1.1 The target of the penalty is a minority of the cost.** Cost decomposition of the Heuristic AI showed that the positional evaluation loop accounts for 16% of consumption (line-of-sight checks and evaluated actions), while 84% concentrates in pathfinding, executed every turn — including the many turns without visual contact, when the agent is merely exploring. No value of λ could save beyond that minority fraction.

**1.2 Uniform costs make the term inert.** Evaluating any position costs practically the same. With Cost(A) ≈ k for every action A, the term −λk is a constant added to all candidates and does not change which one scores highest:

argmax[ Value(A) − λk ] = argmax[ Value(A) ]

Experimentally, λ = 0 and λ = 0.005 produced identical results. **Per-action penalization only discriminates when actions differ from one another in cost** — a condition this domain does not satisfy.

**1.3 The theory anticipates this result.** The finding is not anomalous: it is a corollary of the central principle of metareasoning. Russell and Wefald (1991) establish that *a computation has value only insofar as it changes the external action the agent would take*. Subtracting a uniform cost from all candidates does not change which one is chosen and therefore cannot produce any effect — neither on decision quality nor on processing, since the cost was paid before the subtraction. See [theoretical_foundation.md](theoretical_foundation.md).

## 2. Reformulation: the trade-off decides *whether* to deliberate

If cost does not distinguish among actions, it distinguishes among **decision procedures**. The reformulation applies the same trade-off one level up: before evaluating, the agent decides whether the analysis is justified.

This is the classical formulation of **rational metareasoning** (RUSSELL; WEFALD, 1991): deciding whether to deliberate by comparing the expected value of deliberation to its cost. Art3miz 0.1 implements a **myopic approximation** of that stopping rule — it estimates value at stake through a situational heuristic rather than computing an expectation over the distribution of possible outcomes.

The agent deliberates — runs full positional evaluation — if and only if:

**ValueAtStake − λ × EstimatedCost > 0**

**ValueAtStake** = n × (Proximity + Vulnerability), where n is the number of visible enemies, Proximity is the inverse of the distance to the nearest one, and Vulnerability is the fraction of health lost. It grows in situations where deciding well matters more.

**EstimatedCost** = candidate cells × (visible enemies + 1), the predicted cost of full evaluation.

With no enemies in sight, value at stake is zero and the economic regime is always chosen. The parameter spans the whole spectrum: **λ = 0 always deliberates** (equivalent to the pure Heuristic AI); **high λ never deliberates** (equivalent to the Reactive AI).

## 3. Economic regime

When deliberating is not worthwhile, the agent moves by **greedy stepping**: it walks up to 3 cells toward the objective checking only the cells on its own path (3 to 6 operations), instead of expanding the entire reachable neighbourhood (~25 nodes).

Two safeguards preserve quality:

- **Hunting keeps full search.** Approaching a position where an enemy was seen is purposeful approach and justifies the expense; only blind exploration uses greedy stepping.
- **Obstacle fallback.** If the greedy path stalls against an obstacle that search would circumvent, the agent falls back to full search.

The saving is **measured, not presumed**: every greedy-step check is counted by the same cost meter (`grid.check_walkable`), and the traced path is validated in constant time per step (`agent.move_along`), without redoing the search.

## 4. Parameters

| Parameter | Value | Origin |
|---|---|---|
| λ | 0.005 | Sweep over {0; 0.002; 0.005; 0.01; 0.02} on the 200 tuning seeds — knee of the trade-off curve |
| budget | 0 (disabled) | Candidate pruning tested and discarded: reduced effectiveness without relevant savings |
| Weights | 0.092 / 0.307 / 0.495 / −0.228 | Best configuration learned in the campaign's mixed confrontation |

Weights continue to be refined by between-match learning ([ai.md](ai.md) §6.5), inherited from the heuristic.

## 5. Results

In self-play (1000 matches), Art3miz 0.1 obtains the **highest StrategicScore in the study (0.497)**, against 0.473 for the reactive and 0.438 for the heuristic, requiring **379 operations per match — 51% less than the heuristic**. It is also the most decisive (5.7% draws) and the fastest to win (29.3 turns).

In direct confrontation against full-cost opponents, it wins less (0.225 against ~0.33). The efficiency hypothesis is confirmed; competitive superiority is not. Full analysis in [final_results.md](final_results.md).

Its advantage has a **range of applicability**: the saving grows with map size (−16% at 25×25, −49% at 60×60), but on small maps the Reactive AI dominates the proposed model. See [generalization.md](generalization.md).

## 6. Usage

```bash
# Official benchmark with the proposed model
godot --headless --path simulator -- batch 1000 benchmark verde=art3miz

# Calibration (λ and budget adjustable from the command line)
godot --headless --path simulator -- batch 200 tuning verde=art3miz lambda=0.005 budget=0
```
