> 🇧🇷 [Português](../baseline.md) · 🇬🇧 **English**

# Reference Models (Baselines)

## 1. Purpose

Define AI models with different levels of complexity for experimental comparison with the proposed model.

Together they let us analyse the impact of strategy and computational cost on performance, and they anchor both ends of the spectrum: the Random AI establishes the performance floor, MCTS the quality ceiling.

---

## 2. Models defined

### 2.1 Random AI (lower baseline)

**Description.** Selects an action at random among the valid ones. Uses its own RNG seeded by the map seed plus the player id, keeping each match reproducible.

**Characteristics**
- No strategy
- Consistently poor outcomes
- **Surprisingly high computational cost**: it enumerates every valid option before sampling, and discards the information obtained

**Purpose.** Serve as the lower performance bound.

### 2.2 Reactive AI (attack or approach)

**Description.** Model based on simple rules in cascade:

- If there is a straight line of fire to an enemy → attack the nearest one
- If an enemy is visible but without a line of fire → approach to align
- Otherwise → hunt the last known position, or explore

**Characteristics**
- Immediate decision
- No strategic evaluation
- Low complexity and low cost

**Purpose.** Represent a basic functional agent. It also serves as the standard opponent in evaluations.

> **Empirical note.** The Reactive AI proved a considerably stronger baseline than anticipated: the Heuristic AI does **not** win significantly more than it (p = 0.757) despite spending 48% more operations. See [final_results.md](final_results.md).

### 2.3 Heuristic AI (local evaluation)

**Description.** Uses an evaluation function to select actions based on multiple factors: health, cover, proximity and risk. The highest-valued action is chosen.

**Characteristics**
- Considers multiple scenario criteria
- Strictly local decision focused on pure tactical gain
- Moderate complexity

**Purpose.** Represent an agent with basic strategic behaviour, and serve as the comparison point for the proposed model — which is precisely the same evaluation constrained by computational cost.

---

## 3. Advanced model

### 3.1 Monte Carlo Tree Search (MCTS)

**Description.** MCTS is a simulation-based search algorithm that evaluates actions by exploring multiple future scenarios, balancing exploration and exploitation (BROWNE et al., 2012). Implementation: `simulator/ai/ai_mcts.gd`.

**Role in the study.** **Anchors the upper end of the trade-off spectrum.** Just as the Random AI establishes the performance floor, MCTS establishes the reference for what is achievable when decision quality is pursued without processing constraints. Without that point, the quality-cost curve would be open at one end.

**Implementation.** Four standard phases — UCT selection (constant √2), expansion, simulation and backpropagation — with 60 simulations per decision and rollouts 6 turns deep.

Two domain adaptations are worth recording:

- **It operates on the perceived world model**, not the real state. Since perception is limited, the search considers only enemies the agent can see — otherwise MCTS would be omniscient and the comparison unfair.
- **Every search operation is counted** by the same cost meter as the other models, on the same terms.

**Observed characteristics**
- Considers multiple future turns
- Highest win rate among the models evaluated
- **Much higher computational cost** — about six times that of Art3miz 0.1

Quantitative results in [final_results.md](final_results.md).

---

## 4. Experimental execution

All implemented models are evaluated under identical conditions:

- 1000 simulations per configuration
- Same seed bank
- Controlled initial conditions

---

## 5. Metrics collected

- Win rate
- Damage ratio
- Cover usage
- Turns to victory
- Mean computational cost
- Strategic Score

---

## 6. Analysis

The results allow us to:

- compare different levels of intelligence
- evaluate strategic efficiency
- analyse computational cost

---

## 7. Relation to the proposed model

The hybrid model was compared against the baseline models (see [final_results.md](final_results.md)) to verify:

- performance gains
- computational efficiency
- decision quality
