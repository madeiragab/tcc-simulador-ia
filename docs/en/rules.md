> 🇧🇷 [Português](../regras.md) · 🇬🇧 **English**

# Rules of the Tactical Simulator

## 1. Environment

The environment is a two-dimensional NxN grid (40x40 by default), where each cell has a specific type.

### Cell types

- **Empty**: allows movement, no defensive bonus.
- **Wall**: blocks movement, vision and fire.
- **Light cover**: traversable cell (blocks neither movement nor line of sight); reduces incoming damage when it sits between defender and attacker (directional cover).
- **Heavy cover**: traversable under the same directional rule; reduces damage significantly.

## 2. Agents

A match is contested by 3 independent agents (free-for-all), identified by colour: green, red and blue. Each agent has:

- Position (x, y)
- Health (HP)
- Vision range (also defines attack range)
- State (alive or dead)
- Player identifier (colour)

### Tactical state

- **Cover protection**: evaluated per engagement — an agent is protected from an attacker when a cover cell is adjacent to it in that attacker's direction.
- **Cover type**: light or heavy (the stronger protection prevails).

### Perception (field of view)

Agents are **not omniscient**. An agent only knows an enemy's position when that enemy is within its field of view:

- Within vision range (Chebyshev distance)
- Unobstructed line of sight: **walls block vision; cover does not**

With no enemy in sight, the agent acts on memory and search:

- **Tactical memory**: stores the last position where it saw each enemy and hunts the nearest one; on arriving and finding nothing, it forgets.
- **Proximity sensor**: picks up a coarse cue about the nearest enemy within 15 cells — the **approximate direction** (eight octants) and the **distance band** (near ≤5, medium ≤10, far ≤15), never the exact position. Walls do not block the sensor, which represents noise rather than vision. Inspired by the motion tracker in *Alien Isolation*, it gives the agent a hunting heading without revealing the target.
- **Exploration**: beyond sensor range, the agent visits randomly drawn map destinations (RNG seeded by the match seed — behaviour remains deterministic and reproducible).

The sensor is an environment mechanic, available equally to all models, preserving comparison fairness. Every query is counted toward computational cost.

## 3. Actions

Each turn, an agent may:

1. Move up to 3 cells (path validated by breadth-first search, 4 directions, respecting walls)
2. Perform one action:
   - Attack an enemy
   - Hold position

Cover protection is directional and automatic: it applies when a cover cell is adjacent to the agent in the attacker's direction.

## 4. Turn system

- The system is based on sequential turns
- Each agent acts once per turn
- A full turn completes when every living agent has acted

### 4.1 Victory condition

- A match ends when one of two conditions occurs: only one agent remains alive, or the fixed limit of 100 turns is reached.
- The last agent standing is the winner.
- If the 100-turn limit is reached with two or more agents alive, the match ends in a draw, regardless of remaining HP.

## 5. Combat

### Line of sight

- An agent may only attack with direct line of sight
- Walls block vision completely

### Range and line of fire

- Attack range equals the agent's vision range (Chebyshev distance)
- **Fire is only permitted in a straight line**: horizontal, vertical or perfect diagonal. Without this restriction, attacks at arbitrary angles would bypass directional cover, making defences irrelevant.

### Damage (deterministic)

Damage is computed deterministically:

Damage = BaseValue − CoverReduction

The reduction only applies if a cover cell is adjacent to the target in the attacker's direction (directional cover).

Values:
- Base damage: 30
- Light cover: reduces 10
- Heavy cover: reduces 20

## 6. Metrics

The following metrics are used for evaluation (full definitions in [metrics.md](metrics.md)):

- **Win rate**: percentage of victories across multiple simulations
- **Damage ratio**: damage dealt / damage taken
- **Cover usage**: percentage of turns ending in a protected position
- **Turns to victory**: mean number of turns to win
- **Mean computational cost**: algorithmic effort in counted operations (matrix and line-of-sight operations)
