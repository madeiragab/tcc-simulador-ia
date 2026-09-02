> 🇧🇷 [Português](README.md) · 🇬🇧 **English**

# Tactical Simulator for AI Evaluation

[![ci](https://github.com/madeiragab/tcc-simulador-ia/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/madeiragab/tcc-simulador-ia/actions/workflows/ci.yml)

[![demo](https://img.shields.io/badge/demo-watch%20a%20match-f0a830?style=for-the-badge&logo=godotengine&logoColor=white)](https://madeiragab.github.io/tcc-simulador-ia/)

> A real match playing in the browser, with the benchmark numbers beside it.

A turn-based tactical simulation environment built to **measure the strategic
quality of AI agents** — not just whether they win, but how much computation
they spend to win.

> Undergraduate thesis — Computer Science, IFSulDeMinas.
> Author: **Gabriel Madeira**.

## The problem

Comparing AI models in games usually stops at win rate. That hides two things:
an agent may win by luck of the scenario, and it may win at a computational
cost that would make it impractical in production.

This work builds a **neutral, deterministic and reproducible** environment where
effectiveness and cost are measured side by side, and uses it to investigate a
**hybrid decision model** balancing the two.

## The environment

- 40x40 turn-based grid, **3 independent agents**, 100-turn cap.
- Maps **procedurally generated from seeds** (4 sectors, drawn spawn points,
  validated connectivity) — frozen banks of 1000 benchmark seeds and 200 tuning
  seeds ensure every model faces exactly the same scenarios.
- **Limited perception**: 120° vision cone blocked by walls, memory of last seen
  position, shooter revealed on taking damage, and a **proximity sensor**
  (inspired by the motion tracker in *Alien Isolation*) giving direction and
  distance band of the nearest enemy — never its exact position.
- **Directional cover** (protects only toward the attacker) and **straight-line
  fire**, without which cover could be bypassed by angle.
- **Deterministic combat**: all randomness is confined to map generation.
- **Initiative rotation**: match *i* starts with player *i* mod 3.
- **Headless batch execution** with self-documenting CSV export.

Neutrality was empirically validated: 1000 matches with three identical AIs
produced statistically equivalent win rates (0.306 / 0.328 / 0.301 — within the
±1.5 pp fluctuation expected at N=1000, formally confirmed by chi-square,
p = 0.516).

## Models compared

| Model | Mechanism |
|---|---|
| **Random** | Samples among valid actions — absolute performance floor |
| **Reactive** | Fixed rules: shoot if line of fire, else approach or hunt |
| **Heuristic** | Multi-criteria Utility AI + hill-climbing on weights between matches |
| **Art3miz 0.1** | Proposed model — decides *whether deliberating is worth it* before deliberating |
| **MCTS** | Monte Carlo Tree Search — anchors the high-quality, high-cost end |

## Art3miz 0.1 — the proposed model

The starting formulation penalized each action by the cost of evaluating it:

```text
ActionScore = StrategicValue − λ × ComputationalCost
```

**This formulation does not work in this domain, and why is one of the findings
of this work.** Two measured reasons: the evaluation loop accounts for only 16%
of the cost (84% is pathfinding, run every turn); and since evaluating any
position costs roughly the same, the term becomes a constant added to every
candidate — formally, `argmax[Value − λk] = argmax[Value]`. λ is inert.

The reformulation applies the same trade-off one level up, to the decision about
the decision procedure itself:

```text
ValueAtStake − λ × EstimatedCost > 0   →   deliberate
```

The agent estimates what is at stake (visible enemies, proximity, own
vulnerability) and only pays for full positional evaluation when it is worth it.
With λ = 0 it always deliberates (equivalent to the heuristic); with λ high,
never (equivalent to reactive). Outside the deliberation regime it moves by
greedy stepping (~4 operations instead of ~25 search nodes), falling back to full
search only when hunting a known position.

**This is classical rational metareasoning** (Russell & Wefald, 1991) — and the
theory *predicts* the negative result above: a computation only has value
insofar as it changes the action the agent would take. See
[theoretical_foundation.md](docs/en/theoretical_foundation.md).

## Results

**Over 14,000 matches** on the official seed bank, spanning self-play, direct
confrontation, replication across three map scales, and calibration. Every
comparative claim was subjected to **significance testing**
([full analysis](docs/en/statistical_analysis.md)).

### Self-play — overall performance

| Model | Win rate | Draws | Cost | **StrategicScore** |
|---|---|---|---|---|
| Random | 0.000 | 100% | 2323 | 0.145 |
| Reactive | 0.312 | 6.5% | 437 | 0.473 |
| Heuristic | 0.295 | 11.6% | 777 | 0.438 |
| **Art3miz 0.1** | **0.314** | **5.7%** | **379** | **0.497** |

Art3miz 0.1 achieves **the highest StrategicScore in the study**, leading four of
five dimensions: it wins more, uses more cover, decides matches faster (29 turns
against 45 for the heuristic) and spends **51% less** than it. In efficiency —
wins per thousand operations — it delivers 0.829 against 0.380: more than double.

### Direct confrontation — the honest counterpoint

| Metric | Art3miz 0.1 | Heuristic | Reactive |
|---|---|---|---|
| Win rate | 0.225 | **0.339** | 0.330 |
| Cost | **510** | 719 | 484 |
| StrategicScore | 0.426 | 0.467 | **0.472** |

Against opponents paying the full price of analysis, **Art3miz 0.1 wins less**.
The savings have a price: by skipping deliberation, the agent sometimes misses
the position full evaluation would have found.

### The full spectrum — and the marginal value of computation

With MCTS anchoring the expensive end, each gain can be priced:

| | MCTS | Heuristic | Art3miz 0.1 |
|---|---|---|---|
| Win rate | **0.379** | 0.292 | 0.236 |
| Cost | 2794 | 681 | **471** |
| Efficiency (wins/1k ops) | 0.136 | 0.429 | **0.501** |

**Cost per additional win**: ≈ 3,750 operations from Art3miz to Heuristic,
≈ 24,300 from Heuristic to MCTS. **Sharply diminishing returns** — this is the
central trade-off of the work, quantified.

### Generalization — and the model's limit

Replicating across three scales, the saving over the heuristic **grows with map
size**: −16% (25×25), −29% (40×40), **−49%** (60×60). Consistent with the
mechanism: larger maps have more turns without visual contact, which is exactly
where deliberation is skipped.

**But there is an honest limit**: on 25×25 maps the Reactive AI is
*simultaneously* cheaper and more effective than the proposed model. Where every
situation is critical, there is nothing to save. The model has a
[range of applicability](docs/en/generalization.md), and it has been delimited.

**Conclusion**: the efficiency hypothesis is confirmed; the competitive
superiority hypothesis is not. The work demonstrates that the trade-off between
quality and cost is measurable, controllable via λ, and explicitable as a design
decision — a control the reference models do not offer.

Two additional findings, both statistically supported: the **Reactive AI is a
remarkably strong baseline** — the heuristic does **not** win significantly more
than it (p = 0.757) despite costing 48% more; and Art3miz's lead in the composite
score is **robust to the choice of metric weights** (leading in 100% of 10,000
random weightings — [analysis](docs/en/weight_sensitivity.md)).

## Running it

Requires [Godot 4](https://godotengine.org/).

Visual mode (watch matches in a loop):

```bash
godot --path simulator
```

Headless batch mode (data collection):

```bash
godot --headless --path simulator -- batch 1000 benchmark verde=art3miz vermelho=heuristica azul=reativa
```

Arguments: `batch <N> <bank>` where `bank` is `benchmark` (1000 seeds) or
`tuning` (200 seeds), followed by the lineup `<color>=<model>` for `verde`
(green), `vermelho` (red) and `azul` (blue). Models: `aleatoria` (random),
`reativa` (reactive), `heuristica` (heuristic), `art3miz`, `mcts`. Optional:
`turnos` (per-turn log), `mapa=<n>` (grid size), `lambda=<v>` and `budget=<n>`
(model calibration).

Each run writes a folder under `data/runs/<timestamp>_<bank>_<N>/` containing
`partidas.csv` (one row per player per match, with raw and derived metrics and
cost broken down by operation type), `resumo.csv` (aggregates),
`aprendizado.csv` (weight evolution) and `manifest.txt` (exact configuration).

**Runs are deterministic**: the same commands reproduce the same results, byte
for byte.

## Documentation

[`docs/en/`](docs/en) holds the English documentation
([index](docs/en/README.md)); [`docs/`](docs) holds the Portuguese original,
which is canonical for the thesis.

| Doc | Subject |
|---|---|
| [theoretical_foundation.md](docs/en/theoretical_foundation.md) | **Bounded rationality and metareasoning** — the theoretical basis |
| [problem.md](docs/en/problem.md) | Context, research question and hypothesis |
| [architecture.md](docs/en/architecture.md) | Separation between Core, Map, Agents, AI, Turns and Collection |
| [rules.md](docs/en/rules.md) | Rules of the simulated world |
| [map_generation.md](docs/en/map_generation.md) | Procedural generation from seeds |
| [proposed_model.md](docs/en/proposed_model.md) | Art3miz 0.1 specification |
| [metrics.md](docs/en/metrics.md) | Metrics and the normalized StrategicScore |
| [methodology.md](docs/en/methodology.md) | Experimental setup |
| [final_results.md](docs/en/final_results.md) | **Official benchmark and conclusions** |
| [statistical_analysis.md](docs/en/statistical_analysis.md) | Significance testing on raw data |
| [weight_sensitivity.md](docs/en/weight_sensitivity.md) | Robustness of the ranking to metric weights |
| [generalization.md](docs/en/generalization.md) | Replication across three map scales |

## Repository structure

```text
/
├─ simulator/               → Godot 4 project
│  ├─ core/                 → simulation, turns, batch, metrics, cost, stats
│  ├─ ai/                   → ai_base, ai_random, ai_reactive, ai_heuristic, ai_art3miz, ai_mcts
│  ├─ agents/               → agent state and attributes
│  ├─ map/                  → grid and procedural generation
│  └─ tools/                → analysis tools and document generators
├─ docs/                    → documentation (pt-BR canonical) and docs/en (English)
├─ diagrams/                → architecture, flow, decision and metrics
├─ experiments/             → seed banks (benchmark and tuning)
├─ data/runs/               → official runs (CSV + manifest)
├─ monografia/              → thesis document
└─ presentation/            → defense presentations
```

## Status

**Phases 1 through 6 complete**: environment, experimental infrastructure, the
three baseline models, the calibrated proposed model, the official benchmark and
the scientific rigor pass (theoretical grounding, significance testing, MCTS,
sensitivity analysis and generalization).

## Technologies

- **Godot 4** / GDScript — simulation, headless batch execution, statistical
  analysis and document generation
- CSV as the interchange format, open to any analysis tool
