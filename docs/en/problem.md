> 🇧🇷 [Português](../problema.md) · 🇬🇧 **English**

# Research Problem

## Context

Simulated tactical environments are widely used to evaluate the performance of Artificial Intelligence agents, enabling controlled and repeatable testing.

However, evaluating those agents frequently relies on final outcomes alone — win or loss — without considering the quality of the decisions taken throughout the simulation.

## Problem

This approach limits the analysis of strategic behaviour, since it captures neither positioning, use of cover, nor the efficiency of actions. Crucially, it also ignores the **computational cost of producing those decisions**: an agent may win at a processing cost that would render it impractical in production.

## Research question

How can the strategic quality of AI agents be effectively evaluated in controlled tactical environments, considering simultaneously the value of decisions and the cost of producing them?

## Hypothesis

The use of composite metrics, combined with a decision model that considers strategic value and computational cost simultaneously, enables more precise evaluation and more efficient decisions.

## Theoretical framing

The problem of deciding how much computation to invest in a decision is the object of the **metareasoning** literature (RUSSELL; WEFALD, 1991) and of **bounded rationality** (SIMON, 1955). The theoretical grounding of this work, and the way it explains the results obtained, is developed in [theoretical_foundation.md](theoretical_foundation.md).
