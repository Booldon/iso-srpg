# Stat Value Ratios — Common Card Baseline

**Status:** Confirmed design decision  
**Scope:** Common card tier only; Rare/Epic tiers may use different weighting

---

## Stat Value Ratio Table

| Stat  | Ratio | Notes                                      |
|-------|-------|--------------------------------------------|
| AMR   | 1.0   | Baseline reference unit                    |
| SPD   | 1.5   | Estimate — flagged for playtesting         |
| STR   | 2.0   | Mathematically derived (see rationale)     |
| Move  | 2.0   | Provisional — flagged for playtesting      |

**Target value per Common card: 6 points**

---

## Rationale

### STR ratio (2.0) — mathematically derived

The damage formula is:

```
damage = attacker_STR - defender_AMR
```

A +1 STR gain therefore yields two simultaneous benefits:
- **+1 ATK**: the attacker deals 1 more damage on offense
- **+1 effective HP**: the defender (when acting as one) survives 1 more point of incoming damage before STR reaches 0

Because a single point of STR carries both an offensive and a defensive function, it is worth exactly **2× a point of AMR**, which provides only the defensive layer (reduces incoming damage but does not affect attack power). This ratio is structural, not estimated — it follows directly from the dual-role nature of STR in the Banner Saga-derived combat system.

### SPD ratio (1.5) — estimated, needs playtesting

Going first in a turn-pair is roughly equivalent to negating one enemy action in the worst case (the enemy attacks before you and you die — going first prevents that). The exact value depends on how frequently turn order is decisive in practice. 1.5× is a reasonable starting estimate, but this should be revisited once turn dynamics are observable in actual play.

**Playtesting flag:** Reduce to 1.25 if SPD cards feel too strong; raise to 1.75 if they feel weak.

### Move ratio (2.0) — provisional

Mobility value depends heavily on map geometry: on open maps, extra move range is strong; on dense corridor maps, it is nearly worthless. 2.0 is a placeholder consistent with STR's ratio, giving Move cards the same nominal value as pure STR cards. This ratio is the hardest to quantify analytically and must be confirmed through playtesting across diverse map layouts.

**Playtesting flag:** Adjust independently per map archetype once maps exist.

---

## Acceptable Tolerance for Common Tier

Cards with a computed value of **5.5** are within acceptable tolerance for Common tier (≈8% below target). This applies to the following confirmed cards: Aggressive Stance, Road-Worn, Heavy Arms, Sprinter.

Cards with Move involvement (marked `*` in the card list) carry provisional values pending Move ratio confirmation.

---

## Dependencies

- Absolute stat numbers (base protagonist STR/AMR/SPD/Move values) are not set here. This document records only the **ratios between stats**. Once base values are confirmed by the data-balancer, card deltas can be calibrated.
- Common cards are element-agnostic (§6.5): they do not count toward element stack thresholds.
