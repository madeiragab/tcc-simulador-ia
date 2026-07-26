> 🇧🇷 [Português](../arquitetura.md) · 🇬🇧 **English**

# System Architecture

## 1. Overview

The system is composed of independent modules responsible for simulating the environment, agent decision-making and data collection for analysis.

Separation of concerns makes testing, experimentation and evolution of the system easier.

The governing principle: **the simulation core knows nothing about AI logic**. Each AI implements a single contract — receive the state, return an action — and the simulation validates and applies whatever is returned. Swapping a player's model is a single command-line argument, guaranteeing every model plays exactly the same game.

---

## 2. Main modules

### 2.1 Simulator (Core)

Responsible for managing environment state and game rules. Implementation: `core/simulation.gd`.

Functions:
- control the grid
- manage agents
- apply movement and combat rules
- run turns

### 2.2 Map

Represents the game environment. Implementation: `map/grid.gd` and `map/map_generator.gd`.

Functions:
- store cells
- check collisions
- compute line of sight
- identify cover
- generate maps procedurally from seeds

### 2.3 Agents

Represent the entities controlled by the AIs. Implementation: `agents/agent.gd`.

Functions:
- store state (position, health, orientation)
- execute actions
- interact with the environment

### 2.4 AI system

Responsible for agent decision-making. Implementation: `ai/*.gd`.

Functions:
- generate possible actions
- evaluate actions
- select the best action

Every model extends `ai/ai_base.gd`, which provides the common contract and shared perception helpers (vision cone, tactical memory, proximity sensor).

### 2.5 Turn system

Controls agent execution order. Implementation: `core/turn_system.gd`.

Functions:
- alternate among agents
- control turn start and end
- skip dead agents

### 2.6 Logger / Data collection

Responsible for recording simulation information. Implementation: `core/batch_runner.gd`, `core/cost_meter.gd`, `core/metrics.gd`.

Functions:
- save metrics
- record AI decisions
- count computational cost per agent
- export data (CSV)

### 2.7 Analysis

Statistical tooling over collected data. Implementation: `core/stats.gd`, `tools/analise_estatistica.gd`, `tools/sensibilidade_pesos.gd`.

Functions:
- significance tests (chi-square, conditional binomial, paired t-test)
- confidence intervals (Wilson, bootstrap)
- weight sensitivity analysis

---

## 3. System flow

1. Initialize map and agents from the seed
2. Start simulation
3. For each turn:
   - select the acting agent
   - attach the cost meter
   - AI decides the action
   - detach the meter
   - apply the action in the simulator
   - update state
   - record data
4. Finish when a victory condition is met or the turn limit is reached

---

## 4. Separation of concerns

- The simulator knows nothing of AI logic
- The AI does not modify state directly (it only proposes actions)
- The logger only observes and records
- The cost meter is attached exclusively during the decision phase: what is measured is the cost of *deciding*, not of executing

---

## 5. Purpose of the architecture

To guarantee:
- modularity
- ease of testing
- execution of multiple simulations
- consistent data collection
- fair comparison among models
