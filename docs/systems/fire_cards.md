> Part of the full card pool. See card_pool_structure.md for overall breakdown and element_mechanics.md for the Fire design grammar (Burn/Solar).

# Fire Cards — Rare (20) + Epic (4)

**Status:** Confirmed
**Element:** Fire — primary mechanic Burn (destruction), secondary mechanic Solar (renewal)

---

## Baseline Mechanics

- **Burn max stack:** 5 (extendable to 7 via High Density)
- **Tick damage:** 1 STR per stack, per turn (innate effect of holding Burn stacks — not gated by any specific card)
- **Natural decay:** -1 stack per turn (prevents unbounded DoT snowball)
- **Detonation (consume-all-stacks-for-burst):** reserved for Epic tier only; Rare tier can only trigger partial-stack effects (see Raging Flame, Overheat)
- **Kindling-type cards** (bonus stacks on an already-burning target) apply **0 stacks** if the target has no existing Burn — they only amplify, never apply from scratch

---

## Rare — Attack (7)

| Card | Effect |
|------|--------|
| Ember (불씨) | On attack: Burn +1 stack. *[Epic detonation prerequisite]* |
| Kindling (연쇄 발화) | Attacking a Burning target: Burn +2 stacks. Non-burning target: +0 |
| Flame Smite (화염 강타) | STR damage + Burn +1 stack |
| Raging Flame (맹화) | Consume 2 Burn stacks → immediate burst STR damage |
| White Heat (백열) | Target's Burn tick damage doubled this turn |
| Overheat (과열) | Target with Burn ≥3: bonus immediate damage |
| Conflagration (겁화) | AoE: all adjacent enemies gain Burn +1 stack |

## Rare — Utility (5)

| Card | Effect |
|------|--------|
| Smolder (은근한 불씨) | Target's natural Burn decay only applies once every 2 turns (slows decay, does not stop it) |
| Ember Trace (잔불) | On death of a Burning enemy: half (round up) of its remaining stacks transfer to an adjacent enemy |
| Preheat (예열) | Non-attack actions (e.g. wait) can still apply Burn +1 to a chosen target on turn end (2-turn cooldown) |
| Brittle Coat (물러진 갑옷) | Enemies with Burn ≥3: AMR -2 (persistent status, no stack consumption) |
| High Density (고온 응축) | Burn max stack 5 → 7 |

## Rare — Defense (4)

| Card | Effect |
|------|--------|
| Flame Retort (반격의 불꽃) | On being hit: attacker gains Burn +2 stacks |
| Ember Barrier (화염 방벽) | Self only. On being hit, if attacker is Burning: incoming damage -30% |
| Ashen Ward (잿빛 수호) | When an adjacent ally is hit: attacker instead gains Burn +2 stacks |
| Phoenix Ember (불사조의 재) | Once per battle, when own Strength ≤30%: consume all Burn stacks on the enemy that last attacked self → gain temp AMR +2 per stack consumed |

## Rare — Heal (4)

All Fire heal effects grant **temporary STR** (per §3.2 — no permanent max-HP restoration), scoped to the current battle only.

| Card | Effect |
|------|--------|
| Solar Blessing (태양의 축복) | Battle start: self temp STR +3 |
| Shared Warmth (온기 나눔) | Battle start: one adjacent ally also gains temp STR +2 |
| Ember Regrowth (잔불의 재생) | Each kill via Burn: self temp STR +2 (accumulates per battle) |
| Phoenix Feather (불사조의 깃털) | Once per battle, when own Strength ≤30%: immediately restore temp STR equal to 25% of max |

*Draft values note (matches common_cards.md convention): the +3 / +2 / -30% / 25% numbers above are provisional pending overall stat/damage calibration.*

---

## Epic (4)

Each Epic requires owning specific Rare card(s) of the same element before it appears in the pick pool (§6.4).

| Card | Effect | Prerequisite (Rare) |
|------|--------|----------------------|
| Grand Detonation (대폭발) | Target Burn ≥3: consume all stacks → armor-ignoring damage = stacks × 5 | Ember |
| Wildfire Storm (겁화의 폭풍) | All adjacent enemies: Burn instantly filled to max, then all Burning enemies take AoE burst damage | Conflagration |
| Phoenix Descent (불사조의 강림) | No HP-threshold gate. Once per battle: consume all Burn stacks on the current target → simultaneous temp AMR conversion + temp STR restoration | Phoenix Ember **and** Phoenix Feather |
| Avatar of Blaze (작열의 화신) | Non-boss enemy reaching max Burn stack: instant execution + party-wide temp STR. **Boss enemies:** instead take armor-ignoring damage = max stack × 4 (party-wide temp STR still applies) | High Density |

*Implementation note: Avatar of Blaze requires a "boss" flag on the enemy unit, which does not yet exist in `UnitStats` — flagged for combat-programmer when this is implemented.*
