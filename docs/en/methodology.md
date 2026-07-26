> 🇧🇷 [Português](../metodologia.md) · 🇬🇧 **English**

# Experimental Methodology

## Approach

The study is conducted through automated simulations in a controlled tactical environment.

## Environment configuration

- 40x40 two-dimensional grid with deterministic procedural map generation from seeds (see [map_generation.md](map_generation.md)).
- Standardized bank of 1000 seeds defining maps and spawn positions, faced identically by every model compared.
- Confrontation among 3 independent agents (free-for-all), identified by colour: green, red and blue.
- **Terrain-advantage control**: the map is divided into 4 sectors and each agent spawns in a distinct sector drawn by the seed — no position systematically favours any player across the 1000 simulations.
- **Turn-order bias control**: the starting order rotates uniformly among the 3 agents across simulations (each starts 1/3 of the matches).
- **Deterministic combat** (no RNG during a match): all experimental randomness is confined to map generation.

## Composition of confrontations

Two arrangements are used, each answering a different question:

- **Self-play**: three instances of the same model per match, characterizing its behaviour under symmetric conditions — draw rate, duration, cover usage and cost.
- **Direct confrontation**: different models in the same match, measuring relative effectiveness.

## Experimental procedure

1. Generate map and spawn positions from the bank seed.
2. Determine the starting agent according to the initiative rotation.
3. Run turns until a single agent remains alive (victory) or the 100-turn limit is reached (draw).
4. Record match metrics. Computational cost is measured by operation counting (line-of-sight evaluations, pathfinding, generated actions) rather than wall-clock time, removing dependence on the hardware where the experiment runs.

## Execution

- **Tuning**: 200 preliminary simulations, with exclusive seeds, for calibrating weights and λ — kept separate from the benchmark to prevent overfitting.
- **Final benchmark**: 1000 official simulations on the reserved seed bank, identical for every model.
- Automated execution without rendering, in batches.

## Models evaluated

- Random AI
- Reactive AI
- Heuristic AI
- Art3miz 0.1 (proposed hybrid model)
- MCTS (anchoring the high-cost end)

## Data collection

For each simulation the following are recorded: outcome, number of turns, damage dealt and taken by the evaluated agent, and computational cost (operation count). Full schema in [coleta_dados.md](../coleta_dados.md) (Portuguese).

## Analysis

Data are analysed quantitatively, enabling comparison among models and identification of behavioural patterns. Every comparative claim is subjected to significance testing; the experimental design is **paired** (all models face the same seeds), which permits more powerful tests than those for independent samples. See [statistical_analysis.md](statistical_analysis.md).
