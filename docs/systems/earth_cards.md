> Part of the full card pool. See card_pool_structure.md for overall breakdown and element_mechanics.md for the Earth design grammar (Guard/Growth).

# Earth Cards — Rare (20, in progress)

**Status:** IN PROGRESS — Defense (7) and Attack (6) confirmed. Utility (4) and Heal (3) not yet designed. Epic tier not yet designed (scheduled alongside Ice Epic + agnostic Epic).
**Element:** Earth — primary mechanic Guard (resistance/counter), secondary mechanic Growth (nurturing/sustain)
**Role split:** Defense 7 / Attack 6 / Utility 4 / Heal 3 (§4.2 "딜탱" identity — defense and attack both central, utility/heal lighter)

---

## Baseline Mechanics

- **Guard max stack:** 5
- **Per-stack effect:** AMR +1 (stack 5 = AMR +5) — unlike Fire/Ice, Guard stacks directly raise a real combat stat rather than being a separate counter
- **Counter-damage (innate effect of holding Guard stacks, not gated by any specific card):** on being hit while holding Guard stacks, reflect armor-ignoring damage = stacks × 2 (fixed value — matches the fixed-value convention used for Fire's tick damage and Ice's Frostbite Retort, rather than scaling off the unit's own STR/AMR)
- **No natural decay** — same reasoning as Frost: Guard is not a runaway-damage mechanic, and decaying it would undercut Earth's tank identity (stacking Guard *is* the defensive payoff)

---

## Rare — Defense (7)

| Card | Effect |
|------|--------|
| Earthen Bulwark (대지의 방패) | Battle start: Guard +2 stacks |
| Steadfast Stance (견고한 자세) | If self does not move on its turn (waits): Guard +1 additional stack |
| Thorn Armor (가시 갑옷) | Counter-damage doubled (effectively stacks × 4) |
| Earthen Bond (대지의 유대) | When an adjacent ally is hit: consume 1 Guard stack → that ally gains AMR +2 for this incoming hit only |
| Unshakable Will (부동의 의지) | Once per battle, when own Strength ≤30%: instantly fill Guard to max (5) |
| Bedrock (반석) | While own Guard ≥4: incoming damage -20% |
| Awakening of Earth (흙의 각성) | Each time Guard stacks are consumed (e.g. by an attack card): gain permanent-for-this-battle AMR +1 per stack consumed |

## Rare — Attack (6)

| Card | Effect |
|------|--------|
| Earthen Smite (대지 강타) | On attack: self Guard +1 stack |
| Crush (짓누르기) | Consume 2 Guard stacks → immediate armor-ignoring damage (3 per stack consumed) |
| Retaliatory Strike (반격의 일격) | If self successfully countered an attack this turn: next own attack (on the following turn) deals +50% damage |
| Tremor (지진) | AoE: all adjacent enemies take minor STR damage + self Guard +1 stack |
| Center of Gravity (무게중심) | While own Guard ≥4: attack damage +20% |
| Fracture (균열) | On attack: target's AMR permanently reduced by an amount equal to self's current Guard stack count (no stack consumption) |

*Draft values note: all flat numbers above (2, 4, 20%, 50%, 3-per-stack, etc.) are provisional pending overall calibration, matching the convention used in common_cards.md / fire_cards.md / ice_cards.md.*

---

## Open items

- Utility (4 cards) — not yet designed
- Heal (3 cards) — not yet designed
- Earth Epic (4 cards) — deferred to the combined Epic design pass (Ice Epic + Earth Epic + 3 agnostic Epic)
