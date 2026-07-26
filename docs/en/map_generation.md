> 🇧🇷 [Português](../geracao_mapas.md) · 🇬🇧 **English**

# Procedural Map Generation

Specification of how each scenario is produced. Implementation: `simulator/map/map_generator.gd`.

## Principle: everything derives from one number

Each match starts from an integer — the **seed**. From it, a deterministic pseudo-random generator produces the map, obstacle positions and agent spawn points.

```text
seed → deterministic RNG → sectors → spawns → obstacles → connectivity validation
```

**The same seed always reproduces the same match.** This is what makes the experiment auditable: any result can be replayed exactly.

## Sectors and spawn points

The map is divided into **4 sectors** of equal size (each half the grid side). Three of them are drawn to host one agent each — never two in the same sector.

The drawing is done by shuffling the sector list with the seeded RNG (Fisher–Yates) and taking the first three. Within its sector, each agent's position is drawn away from the borders.

**Why this matters:** fixing spawn positions would create systematic terrain advantage — an agent always starting near cover would win more regardless of its model. Drawing sectors distributes any advantage across the 1000 simulations, and the neutrality validation ([final_results.md](final_results.md) §1) measures that it works.

## Obstacles

Three types are placed, in counts proportional to map area (calibrated for 40×40):

| Type | Quantity (40×40) | Shape |
|---|---|---|
| Wall | 10–14 segments | Straight lines of 3–7 cells, horizontal or vertical |
| Light cover | 8–12 blocks | Blocks of 1–2 cells |
| Heavy cover | 4–6 blocks | Blocks of 1–2 cells |

Scaling with area keeps terrain density constant across map sizes, which is what makes the generalization experiment ([generalization.md](generalization.md)) comparable.

### Spawn clearance

No obstacle is placed within 2 cells of any spawn point. Without this, an agent could start walled in or immediately protected, distorting the match.

## Connectivity validation

After placing obstacles, a breadth-first search runs from the first spawn point. **If it cannot reach the other two spawns, the map is discarded and regenerated** with the next draw from the same seeded RNG.

This guarantees no match is decided by an agent being unable to reach the others. Up to 25 attempts are made; a safeguard (open map) is applied if all fail.

## Reproducibility guarantees

- The RNG is seeded exclusively by the match seed — never by the clock.
- Obstacle placement order is deterministic.
- Sector shuffling uses the same seeded generator.
- Regeneration attempts consume the generator sequentially, so even the number of attempts is reproducible.
