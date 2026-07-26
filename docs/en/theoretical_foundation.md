> 🇧🇷 [Português](../fundamentacao_teorica.md) · 🇬🇧 **English**

# Theoretical Foundation — Bounded Rationality and Metareasoning

This document situates the proposed model within the literature that precedes it. The formulation developed in this work — deciding whether deliberating is worthwhile before deliberating — corresponds to the classical problem of **rational metareasoning**, formalized by Russell and Wefald (1991). Recognizing this lineage matters in two ways: it grounds the model theoretically and, as shown below, **it explains the negative result obtained with the initial formulation**.

## 1. Bounded rationality

The starting point is Simon's (1955, 1957) critique of perfect rationality. Real agents decide under constraints of time, information and processing capacity; the optimal choice is often inaccessible, and the rational agent is the one that decides well *given what it can compute*. Simon proposes *satisficing* — seeking a good-enough solution rather than the optimal one — as the response to those constraints.

Russell (1997) formalizes the idea as **bounded optimality**: the optimal agent is not the one that picks the best action, but the one whose *program* produces the best possible behaviour within the available computational resources. Quality becomes a property of the decision architecture, not merely of the isolated decision.

This is precisely the premise of the present work: an agent that spends excessive processing to decide may be impractical, however good its individual decisions may be.

## 2. Metareasoning and the value of computation

Russell and Wefald (1991) formalize the problem of **deciding whether to deliberate**. They treat computations as actions — with their own costs and benefits — and define the **value of computation** (VOC): the expected utility gain a computation produces, minus the cost of running it (time, energy, opportunity).

The central point of the formulation, and the most relevant one here, is where the benefit comes from:

> A computation has value only insofar as it **changes the external action** the agent would take.

A deliberation that produces plenty of information but ends up recommending the same action that would have been chosen without it has **zero** value, however costly it was. The stopping rule follows: deliberate while the expected value of the next computation exceeds its cost; when it no longer does, act.

Zilberstein (1996) extends the treatment to **anytime algorithms**, which produce solutions of increasing quality over time and can be interrupted at any moment, allowing deliberation to be traded for quality explicitly and controllably. Horvitz (1988) addresses reasoning under varying and uncertain resource constraints, and Gershman, Horvitz and Tenenbaum (2015) consolidate the agenda under the banner of **computational rationality**, connecting the formulation across cognitive science and artificial intelligence.

## 3. Where the proposed model fits

Art3miz 0.1 implements a myopic approximation of the metareasoning stopping rule. Before running full positional evaluation, the agent estimates the value at stake in the situation and compares it to the predicted cost of the analysis:

**ValueAtStake − λ × EstimatedCost > 0 → deliberate**

The correspondence with the classical formulation is direct:

| Metareasoning (Russell & Wefald, 1991) | Art3miz 0.1 |
|---|---|
| Value of computation | ValueAtStake — proxy for how much the analysis may change the chosen action |
| Cost of computation | EstimatedCost, in counted operations |
| Stopping rule (VOC ≤ 0 → act) | Economic regime when the inequality fails |
| Myopic approximation (single-step) | Per-situation estimate, without multi-turn projection |

The λ parameter plays the role of the **conversion rate between domain utility and computational cost** — the quantity that, in the original formulation, makes the benefit of deliberation and the price of obtaining it comparable.

Two simplifications relative to the original framework should be made explicit: (i) ValueAtStake is a situational heuristic, not an expectation computed over the distribution of possible outcomes; and (ii) the decision is binary (deliberate or not), whereas the general formulation also allows choosing *which* computation to run among several. Both are approximations the literature recognizes as necessary for real-time application.

## 4. The theory explains the negative result

The most relevant finding of this work — that the initial formulation, applied to the choice among actions, is inert — **is not an anomaly: it is a prediction of the theory**.

The initial formulation subtracted, from each candidate action, the cost of evaluating it:

Score(A) = Value(A) − λ × Cost(A)

It was measured that, in this domain, evaluating any position costs approximately the same. With Cost(A) ≈ k for every candidate action, the subtracted term is constant and does not change which candidate has the highest score:

argmax[ Value(A) − λk ] = argmax[ Value(A) ]

The result is exactly what Russell and Wefald's principle anticipates: **a computation whose outcome does not change the chosen action has zero value**. Subtracting a uniform cost from all alternatives does not change the selected action and therefore cannot produce any effect — neither on decision quality, nor on the processing consumed, since the cost was already paid before the subtraction.

Empirical confirmation is unambiguous: runs with λ = 0 and λ = 0.005 produced identical results, and the full λ sweep did not change measured cost (see [hybrid_results.md](hybrid_results.md) §1).

The reformulation corrects precisely the level of application: the trade-off stops operating *among actions*, where costs are uniform and the term is inert, and starts operating *among decision procedures*, where costs differ by orders of magnitude — deliberating costs about twenty-five times more than the economic step.

## 5. Contribution relative to the literature

Metareasoning is an established framework, and this work does not propose a theoretical extension to it. The contribution is of a different kind:

1. **Application and empirical evaluation** of the principle in a turn-based tactical domain with limited perception, under a controlled protocol and over 14,000 matches.
2. **Empirical demonstration of an inapplicability condition** for the per-action formulation: when alternatives have uniform evaluation cost, the penalty term is inert. This is a corollary of the classical principle, here measured and quantified.
3. **A reproducible measurement instrument** that quantifies cost by operation counting, independent of hardware, with statistically verified neutrality — reusable by other investigations.

## References

GERSHMAN, S. J.; HORVITZ, E. J.; TENENBAUM, J. B. **Computational rationality: A converging paradigm for intelligence in brains, minds, and machines**. Science, v. 349, n. 6245, p. 273-278, 2015.

HORVITZ, E. J. **Reasoning under varying and uncertain resource constraints**. In: NATIONAL CONFERENCE ON ARTIFICIAL INTELLIGENCE (AAAI), 7., 1988. Proceedings. Saint Paul: AAAI Press, 1988. p. 111-116.

RUSSELL, S. **Rationality and intelligence**. Artificial Intelligence, v. 94, n. 1-2, p. 57-77, 1997.

RUSSELL, S.; WEFALD, E. **Principles of metareasoning**. Artificial Intelligence, v. 49, n. 1-3, p. 361-395, 1991.

SIMON, H. A. **A behavioral model of rational choice**. The Quarterly Journal of Economics, v. 69, n. 1, p. 99-118, 1955.

SIMON, H. A. **Models of man: social and rational**. New York: John Wiley and Sons, 1957.

ZILBERSTEIN, S. **Using anytime algorithms in intelligent systems**. AI Magazine, v. 17, n. 3, p. 73-83, 1996.
