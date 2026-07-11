> Part of the full card pool. See card_pool_structure.md for overall breakdown.

# Common Cards — Confirmed Card Pool

**Status:** Confirmed  
**Card pool size:** 15 cards (lower bound of the 15–18 range from §6.2)  
**Element:** None (all Common cards are element-agnostic)  
**Target value per card:** 6 points (see `stat_value_ratios.md` for ratio table)

`*` = involves Move stat; value is provisional pending Move ratio playtesting confirmation  
Values in parentheses use ratios: AMR×1.0, SPD×1.5, STR×2.0, Move×2.0

---

## Pure Cards (4)

Single-stat cards. Maximum focus on one dimension.

| Card         | Effect     | Value |
|--------------|------------|-------|
| Grit         | STR +3     | 6.0   |
| Steel Resolve | AMR +6    | 6.0   |
| Quick Step   | SPD +4     | 6.0   |
| Long Stride  | Move +3    | 6.0*  |

---

## Hybrid Cards (6)

Two-stat cards. Efficient spread across two dimensions.

| Card           | Effect             | Value  |
|----------------|--------------------|--------|
| Balanced Form  | STR +2, AMR +2     | 6.0    |
| Aggressive Stance | STR +2, SPD +1  | 5.5    |
| Hunter's Pace  | STR +2, Move +1    | 6.0*   |
| Guard's Poise  | AMR +3, SPD +2     | 6.0    |
| Sentinel       | AMR +2, Move +2    | 6.0*   |
| Road-Worn      | SPD +1, Move +2    | 5.5*   |

---

## Trade-off Cards (5)

High-ceiling cards with a deliberate cost. Net value calculated from gains minus losses.

| Card        | Effect              | Net Value |
|-------------|---------------------|-----------|
| Heavy Arms  | STR +5, SPD -3      | 5.5       |
| Iron Turtle | AMR +8, Move -1     | 6.0*      |
| Glass Cannon | STR +4, AMR -2     | 6.0       |
| Sprinter    | SPD +5, STR -1      | 5.5       |
| Iron Wall   | AMR +8, STR -1      | 6.0       |

---

## Design Notes

### Element neutrality
All 15 Common cards are element-agnostic. Per §6.5, they do NOT count toward same-element stack thresholds. Their purpose is to give every build a solid stat foundation regardless of which Rare/Epic element path the player pursues.

### No dominated cards
No card in this pool is strictly dominated by another — each card occupies a distinct niche:
- **Pure cards** provide the deepest investment in a single stat (highest raw stat gain per card).
- **Hybrid cards** offer two-stat efficiency; none of the two-stat combinations overlaps exactly, giving each a unique role profile.
- **Trade-off cards** allow stat floors to be broken in exchange for accepting a weakness — enabling extreme builds that Pure and Hybrid cards cannot replicate.

### Calibration note
The stat deltas recorded here are relative ratios, not final absolute values. Once the protagonist's base stat values are confirmed by the data-balancer, all card numbers must be rescaled to match the intended gameplay feel. The ratios (and the 6-point target) should remain stable; the absolute deltas will shift proportionally.

### 5.5-value cards
Cards valued at 5.5 (Aggressive Stance, Road-Worn, Heavy Arms, Sprinter) are within acceptable tolerance for Common tier. They are not underpowered — the slight value shortfall is offset by particularly synergistic stat pairings or high ceiling potential in matching builds.

### Pool size
15 cards is the confirmed lower bound of the §6.2 range (15–18). Additional Common cards may be added during playtesting if specific stat coverage gaps are identified, but the current 15 cover all single-stat and major two-stat/trade-off combinations.
