> 🇧🇷 [Português](../README.md) · 🇬🇧 **English**

# Documentation

English documentation for the project. The [Portuguese version](../README.md) is canonical for the thesis; this translation covers the technical documentation.

## 0. Foundation

- **[theoretical_foundation.md](theoretical_foundation.md)**: Bounded rationality (Simon), metareasoning and the value of computation (Russell & Wefald), anytime algorithms (Zilberstein) and computational rationality. Situates the proposed model in the literature and shows that the negative result obtained is a corollary of the classical principle.

## 1. System and architecture

- **[architecture.md](architecture.md)**: Logical separation of responsibilities among the Core, Map, Agents, AI, Turns and Collection modules.
- **[rules.md](rules.md)**: Rules of the simulated world — cells, agents, perception, actions, combat and victory conditions.
- **[map_generation.md](map_generation.md)**: Procedural generation from seeds — sectors, spawn drawing, obstacles and connectivity validation.

## 2. Methodology

- **[problem.md](problem.md)**: Context, research question and hypothesis.
- **[methodology.md](methodology.md)**: Experimental setup, bias controls and execution protocol.
- **[metrics.md](metrics.md)**: Metric definitions and the normalized StrategicScore, with the rationale for normalization.

## 3. Decision models

- **[ai.md](ai.md)**: The Utility AI paradigm, action generation/filtering/evaluation, and between-match learning.
- **[baselines.md](baselines.md)**: Reference models — Random and Reactive (floor and functional agent), Heuristic (Utility AI) and MCTS (high-cost anchor).
- **[proposed_model.md](proposed_model.md)**: **Art3miz 0.1** — why the direct formulation is inert and how the reformulation applies the trade-off to the decision of whether to deliberate.

## 4. Results

- **[hybrid_results.md](hybrid_results.md)**: Calibration of the proposed model — the negative result of the direct formulation and the λ sweep.
- **[final_results.md](final_results.md)**: **Official benchmark** — the reference document for the work's results, with significance testing.
- **[statistical_analysis.md](statistical_analysis.md)**: Significance report — chi-square, conditional binomial tests, paired t-tests, Wilson intervals and bootstrap.
- **[weight_sensitivity.md](weight_sensitivity.md)**: Robustness of the ranking to the choice of metric weights.
- **[generalization.md](generalization.md)**: Replication across three map scales, and the model's range of applicability.

## Documents not translated

The following exist only in Portuguese, as they concern the Brazilian academic process:

- `roadmap_implementacao.md` — implementation phases and status
- `coleta_dados.md` — collected data schema
- `contribuicao.md` — contribution statement (superseded by `proposed_model.md`)
- `resultados_validacao.md`, `resultados_campanha.md` — historical records of the research path
- `agentes.md`, `movimento.md`, `turnos.md`, `experiments.md` — specification fragments consolidated into `rules.md` and `methodology.md`
- `presentation/banca_*.md` — speaking notes for the thesis defence
