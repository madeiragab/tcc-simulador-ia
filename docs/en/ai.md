> 🇧🇷 [Português](../ia.md) · 🇬🇧 **English**

# AI Decision Model

## 1. Overview

The AI is responsible for selecting the best possible action each turn, based on a strategic evaluation function.

The model follows the reactive decision paradigm, in which actions are evaluated considering only the current state of the environment, without multi-turn planning.

This approach draws on Utility AI techniques, widely used in digital games for multi-criteria decision-making (MARK; DILL, 2010; MILLINGTON; FUNGE, 2016).

---

## 2. Action generation

Each turn the agent generates a set of possible actions:

- Moves to reachable positions (up to 3 cells)
- Attacks, when a valid line of fire exists

Each action represents a possible state transition within the environment.

---

## 3. Action filtering

To reduce computational complexity, irrelevant actions are discarded before evaluation:

- positions without line of sight to enemies
- positions with elevated risk (multiple exposure)
- redundant or equivalent positions

This step is essential to avoid combinatorial explosion, a common problem in decision systems (RUSSELL; NORVIG, 2010).

---

## 4. Action evaluation (Heuristic AI)

Each action is judged purely by an empirical strategic-value function reflecting tactical benefits based on game state:

StrategicValue =
w1 × Health +
w2 × Cover +
w3 × Proximity +
w4 × Risk +
Movement

Where:

- **Health**: proportion of the agent's current HP
- **Cover**: protection level of the position (0, 1 or 2)
- **Proximity**: inverse of the distance to the enemy
- **Risk**: number of enemies with line of sight (negative impact)
- **Movement**: fixed displacement incentive — **+0.2 per cell travelled** to the evaluated position and **−0.2 if the position was already visited this match** (holding still repeats one's own cell). It guarantees constant movement even during combat, preventing passive entrenchment.

The weights (w1–w4) are defined empirically in an isolated validation space (tuning run), preventing overfitting before the Heuristic AI is validated in the official benchmark.

This modelling is consistent with multi-criteria decision approaches used in game AI systems (MILLINGTON; FUNGE, 2016). It defines the *Heuristic AI* in this study, whose computational cost does not structurally penalize the action it proposes.

---

## 5. Action selection

The AI selects the action with the highest strategic value:

ChosenAction = argmax(StrategicValue)

This characterizes a local optimization process, common in advanced reactive agents.

---

## 6. Model extension (Art3miz 0.1 — hybrid)

Distinguishing itself methodologically from the standard Heuristic AI, the proposed model adds an abstract algorithmic-effort constraint. Full specification, including why the direct formulation is inert and how the reformulation works, in [proposed_model.md](proposed_model.md).

---

## 6.5 Between-match learning

In batch mode, the same AI instance plays every match and receives, after each one, the points obtained (+3 victory, −1 draw, −3 defeat). The Heuristic AI uses that signal to calibrate its weights via *hill-climbing*: it plays a window of 25 matches with one configuration, measures the mean points and adopts the configuration if it beat the best known mean (otherwise reverting); the next window tests a perturbation of the best configuration (seeded RNG — the whole process is reproducible).

At the end of the batch, the full evolution (weights tested, mean per window, adopted/reverted) is written to `aprendizado.csv` in the run folder, and the instances are discarded — each batch starts from scratch. The Random and Reactive models have no adjustable parameters and serve as static contrast.

## 7. Limitations

- The model does not consider long-term planning
- Decisions are based only on the current state
- Quality depends on the choice of weights
- There is no lookahead over future scenarios

---

## 8. Rationale

The choice of an action-evaluation model is due to its:

- implementation simplicity
- computational efficiency
- ability to handle multiple factors simultaneously

Compared with approaches such as Monte Carlo Tree Search, the adopted model has lower computational cost, making it more suitable for large-scale multiple simulations (BROWNE et al., 2012). MCTS is implemented in this work as the high-cost reference point — see [baselines.md](baselines.md).
