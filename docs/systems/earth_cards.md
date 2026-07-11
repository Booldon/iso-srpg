> Part of the full card pool. See card_pool_structure.md for overall breakdown and element_mechanics.md for the Earth design grammar (Guard/Growth).

# Earth Cards — Rare (20) + Epic (4)

**Status:** Confirmed
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

## Rare — Utility (4)

Allies grow via the Perk system, not Earth cards — so these support allies through generic stats (AMR, positioning), not by handing out Guard stacks directly, mirroring how Fire/Ice support allies via temp STR / SPD rather than Burn/Frost stacks.

| Card | Effect |
|------|--------|
| Earthen Empathy (대지의 유대감) | While own Guard ≥3: adjacent ally gains AMR +1 (persists as long as the condition holds) |
| Provoke (도발) | While own Guard ≥3: adjacent enemies' next attack is forced to target self |
| Binding Roots (결속의 뿌리) | Can swap positions with an adjacent ally at no move-range cost (once per own turn) |
| Earth's Blessing (대지의 축복) | Battle start: all adjacent allies gain AMR +1 (this battle only) |

*Note: Earthen Empathy / Provoke use a Guard ≥3 threshold, one tier below the ≥4 threshold used by Bedrock/Center of Gravity/Steadfast Growth — Utility is intentionally the earliest-triggering tier in Earth's numeric ladder.*

*Implementation note: Provoke requires overriding enemy AI target selection (`grid_manager.gd`'s "smart target" logic) — noted for combat-programmer, not a blocker at the design stage.*

## Rare — Heal (3)

Earth's heal role leans on Growth's gradual/propagating flavor rather than a burst recovery or a low-HP safety net (Defense's Unshakable Will already covers that trigger for this element) — deliberately differentiating Earth's sustain from Fire's/Ice's panic-button-style heal cards.

| Card | Effect |
|------|--------|
| Earthen Nourishment (대지의 자양) | Turn end: self temp STR +1 (accumulates, no cap) |
| Root Sharing (뿌리 나눔) | Each time self gains temp STR (from any source): an adjacent ally also gains half that amount, rounded **down** |
| Steadfast Growth (굳건한 성장) | While own Guard ≥4: turn end grants adjacent allies temp STR +1 |

---

## Epic (4)

Each Epic requires owning specific Rare card(s) of the same element before it appears in the pick pool (§6.4). Unlike Fire/Ice, Earth's Epic set does not include a "dual low-HP-trigger safety card" ultimate — consistent with Earth's Heal set having no low-HP trigger at all (see decisions_log.md).

| Card | Effect | Prerequisite (Rare) |
|------|--------|----------------------|
| Cataclysm (대격변) | Consume all Guard stacks → armor-ignoring damage = stacks consumed × 6 (single target) | Crush |
| Earthquake Fury (대지분노의 진) | AoE: all adjacent enemies take armor-ignoring damage = own current Guard stack × 3 (no stack consumption) | Tremor |
| Impenetrable Fortress (철옹성) | Always active, no stack condition: adjacent enemies' next attack always targets self; incoming damage -50%; counter-damage ×2 | Provoke |
| Eternal Earth (불멸의 대지) | Turn end: party-wide temp AMR += own current Guard stack count (this battle only) | Awakening of Earth **and** Steadfast Growth |
