> 🇧🇷 [Português](../analise_estatistica.md) · 🇬🇧 **English**

> ⚠️ **Translated report.** The Portuguese version is **auto-generated** from raw data by `simulator/tools/analise_estatistica.gd`. This English version is a maintained translation: if the data are recollected, regenerate the Portuguese report and update this file. Figures below correspond to the final dataset.

# Statistical Significance Analysis

Reproduce the source report with:

```bash
godot --headless --path simulator --script res://tools/analise_estatistica.gd
```

## Design and choice of tests

The experiment is **paired**: every model faces exactly the same seeds and, in direct confrontation, they contest the same match. Controlling scenario variability this way permits more powerful tests than those for independent samples, and determines which tests are appropriate:

| Comparison | Test | Rationale |
|---|---|---|
| Win rates in direct confrontation | Chi-square goodness-of-fit (df = 2) | Checks whether the three counts deviate from uniform before pairwise comparisons |
| Pairwise in direct confrontation | Conditional binomial | Since only one agent wins a match, victories are mutually exclusive; the split among matches decided by the two is tested |
| Computational cost | **Paired** t-test by seed | Each pair is the same scenario played by both models — eliminating between-map variance |
| Proportions (intervals) | Wilson score interval | Maintains adequate coverage even for proportions far from 0.5 |
| StrategicScore | Percentile bootstrap (2000 resamples) | The score combines five aggregates and has no closed form for its standard error |

Significance level: **α = 0.05**. With N = 1000, the t distribution (≈999 df) is indistinguishable from the standard normal, the approximation used in p-value computations.

---

## 1. Direct confrontation — do the win rates differ?

1000 matches, one agent per model.

### 1.1 Win rates with 95% confidence intervals

| Model | Wins | Rate | 95% CI (Wilson) |
|---|---|---|---|
| art3miz_0.1 | 225/1000 | 0.225 | [0.200; 0.252] |
| heuristic | 339/1000 | 0.339 | [0.310; 0.369] |
| reactive | 330/1000 | 0.330 | [0.302; 0.360] |

### 1.2 Global test (chi-square goodness-of-fit)

Null hypothesis: the three models have the same probability of winning.

- χ² = **26.96** (df = 2), **p < 0.001**
- Expected frequency under the null: 298.0 wins per model
- Result: **HIGHLY SIGNIFICANT**

The null hypothesis is rejected: differences among the models **are not attributable to chance**. Pairwise comparisons follow.

### 1.3 Pairwise comparisons (conditional binomial test)

Among matches decided by one of the two models, is the split balanced?

| Comparison | Split | Proportion | 95% CI | p-value | Conclusion |
|---|---|---|---|---|---|
| art3miz_0.1 vs heuristic | 225–339 | 0.399 | [0.359; 0.440] | p < 0.001 | highly significant |
| art3miz_0.1 vs reactive | 225–330 | 0.405 | [0.365; 0.447] | p < 0.001 | highly significant |
| **heuristic vs reactive** | 339–330 | 0.507 | [0.469; 0.544] | **p = 0.757** | **NOT significant** |

The last row is the analysis's most consequential finding: **there is no statistical evidence that the heuristic wins more than the reactive**, despite its multi-criteria evaluation.

### 1.4 Computational cost (paired t-test by seed)

Each pair of observations is the **same scenario** faced by both models, eliminating between-map variance.

| Comparison | Mean difference | 95% CI of difference | t | p-value | Cohen's d | Effect |
|---|---|---|---|---|---|---|
| art3miz_0.1 − heuristic | −208.5 ops | [−241.5; −175.4] | −12.35 | p < 0.001 | −0.391 | small |
| art3miz_0.1 − reactive | 26.0 ops | [−3.3; 55.3] | 1.74 | p = 0.082 | 0.055 | negligible |
| heuristic − reactive | 234.5 ops | [209.6; 259.3] | 18.49 | p < 0.001 | 0.585 | medium |

---

## 2. Self-play — cost comparison among models

Each model plays against itself over the same 1000 seeds. Costs are compared **pairing by seed**: same map, same starting positions, different models.

### 2.1 Mean cost per match

| Model | Mean cost | 95% CI of the mean |
|---|---|---|
| random | 2322.7 | [2318.8; 2326.5] |
| reactive | 437.2 | [413.4; 461.0] |
| heuristic | 776.9 | [745.3; 808.5] |
| art3miz_0.1 | 378.7 | [362.7; 394.7] |

### 2.2 Pairwise comparisons (paired t-test)

| Comparison | Mean difference | 95% CI | p-value | Cohen's d | Effect |
|---|---|---|---|---|---|
| random − reactive | 1885.5 ops | [1861.2; 1909.7] | p < 0.001 | 4.816 | large |
| random − heuristic | 1545.7 ops | [1513.8; 1577.7] | p < 0.001 | 2.999 | large |
| random − art3miz_0.1 | 1944.0 ops | [1927.3; 1960.6] | p < 0.001 | 7.234 | large |
| reactive − heuristic | −339.8 ops | [−368.8; −310.7] | p < 0.001 | −0.725 | medium |
| reactive − art3miz_0.1 | 58.5 ops | [31.1; 85.9] | p < 0.001 | 0.132 | negligible |
| heuristic − art3miz_0.1 | 398.2 ops | [364.1; 432.4] | p < 0.001 | 0.724 | medium |

---

## 3. StrategicScore with confidence intervals (bootstrap)

The composite score combines five aggregates and has no closed form for its standard error. Intervals are obtained by percentile resampling with 2000 repetitions over each run's matches.

| Model | StrategicScore | 95% CI (bootstrap) |
|---|---|---|
| random | 0.1340 | [0.1138; 0.1495] |
| reactive | 0.4689 | [0.4532; 0.4843] |
| heuristic | 0.4380 | [0.4208; 0.4540] |
| art3miz_0.1 | 0.4942 | [0.4786; 0.5091] |

Intervals that **do not overlap** indicate a statistically distinguishable difference. Art3miz 0.1's interval does not overlap the heuristic's; it does overlap the reactive's slightly, so that specific comparison is not conclusive.

---

## 4. Environment neutrality (formal test)

In the Reactive AI's self-play, all three agents run the same model. Under a neutral environment, victories should distribute uniformly across the three positions — any systematic deviation would indicate terrain, colour or turn-order bias.

| Position | Wins | Rate | 95% CI |
|---|---|---|---|
| green | 306/1000 | 0.306 | [0.278; 0.335] |
| red | 328/1000 | 0.328 | [0.300; 0.358] |
| blue | 301/1000 | 0.301 | [0.273; 0.330] |

- χ² = **1.32** (df = 2), p = 0.516
- Result: **NOT SIGNIFICANT**

**The null hypothesis of uniformity is not rejected.** The absence of a statistically detectable difference among positions supports the claim that the environment introduces no systematic bias — the sector-drawing and initiative-rotation controls do their job.

> Methodological caveat: failing to reject the null does not *prove* neutrality; it demonstrates that, with power to detect differences on the order of 1.5 percentage points, none was found.

---

## Notes on approximations

- **p-values**: obtained from the standard normal. At N = 1000, the difference from the t distribution (≈999 df) is below 0.001 in the third decimal.
- **Error function**: Abramowitz & Stegun approximation (7.1.26), absolute error below 1.5 × 10⁻⁷.
- **Chi-square**: exact closed form for df = 2 (exp(−x/2)) and df = 1 (via the complementary error function).
- **Bootstrap**: resampling with a fixed seed (20260726), making the report reproducible.
- **Multiple comparisons**: pairwise tests receive no Bonferroni correction. Since the global chi-square test precedes the comparisons and the obtained p-values are orders of magnitude below α, the correction would not change any conclusion. It is flagged where a p-value approaches the threshold.
