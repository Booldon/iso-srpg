# Card Pool Structure — Confirmed Total Pool

**Status:** Confirmed  
**Total pool size:** 100 cards

| Tier   | Type                    | Count                  | Notes                                                          |
|--------|-------------------------|------------------------|----------------------------------------------------------------|
| Common | Element-agnostic        | 15                     | Pure stat. Confirmed — see common_cards.md                     |
| Rare   | Fire / Earth / Ice      | 20 per element = 60    | Element-specific skill cards                                   |
| Rare   | Element-agnostic        | 10                     | Passive type (5) + Skill type (5)                              |
| Epic   | Fire / Earth / Ice      | 4 per element = 12     | Finisher cards, require Rare prerequisites                     |
| Epic   | Element-agnostic        | 3                      | Combo-type (A) / Veteran-type (B) / Cross-type (C) — 1 each   |
| **Total** |                      | **100**                |                                                                |

---

## Rare Tier Breakdown (80 cards total)

### Element Rare (60 cards): 20 per element × 3 elements
- Within each element: Attack / Defense / Heal / Utility types mixed (no role lock)
- Each element has dual-nature mechanics (see element_mechanics.md)

### Agnostic Rare (10 cards)
- **Passive type (5):** multiplicative modifiers — AMR penetration, damage amplification, etc.
  - Differentiator from Common: Common = flat stat addition; Passive Rare = multiplier / system modifier
- **Skill type (5):** strong standalone skills with no element synergy, straightforward and powerful

---

## Epic Tier Breakdown (15 cards total)

### Element Epic (12 cards): 4 per element
- Prerequisite: must own specific Rare card(s) of the same element
- These are the primary Epic path — element cards are the main picks

### Agnostic Epic (3 cards): one of each unlock type
- **Combo-type (A):** requires specific agnostic Rare card combination
- **Veteran-type (B):** requires total Rare card count ≥ N (TBD threshold)
- **Cross-type (C):** requires agnostic Rare + element stack tier ≥ 2 in any element
- Note: agnostic Epic intentionally limited to 3 — element cards are the dominant pick

---

## Element Stack Counting (§6.5)

| Card Category       | Counts toward element stack? |
|---------------------|------------------------------|
| Element Rare        | Yes — same element           |
| Element Epic        | Yes — same element           |
| Common              | No                           |
| Agnostic Rare       | No                           |
| Agnostic Epic       | No                           |
