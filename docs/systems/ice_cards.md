> Part of the full card pool. See card_pool_structure.md for overall breakdown and element_mechanics.md for the Ice design grammar (Frost/Preserve).

# Ice Cards — Rare (20) + Epic (4)

**Status:** Confirmed
**Element:** Ice — primary mechanic Frost (control), secondary mechanic Preserve (protection)
**Role split rationale:** Ice's primary synergy role is tanker/control (§4.2), the inverse of Fire's attack-heavy split — so Utility and Defense lead here instead of Attack.

---

## Baseline Mechanics

- **Frost max stack:** 5 (no extension card in this set — a "raise the cap" utility card was considered and cut in favor of a move-lock card instead)
- **Per-stack effect:** SPD -1 (stack 5 = SPD -5)
- **No natural decay.** Unlike Burn, Frost is a non-lethal control effect (it only affects turn order within a speed-paired turn, not survival) — so unbounded accumulation is not a runaway-damage risk the way Burn is.
- **Freeze (reaching max stack):** target loses its next action. On trigger, **all Frost stacks are consumed (reset to 0)** — this prevents a permanent, un-decaying CC lock (the control-effect equivalent of Burn's damage-snowball problem).
- **Control ladder:** Slow (1+ stack) → Move-lock (2+ stack, via Frozen Shackles) → Freeze (5 stack, or forced early via Flash Freeze at 3+)

---

## Rare — Attack (4)

| Card | Effect |
|------|--------|
| Frost Strike (서리 일격) | STR damage + Frost +1 stack |
| Chain of Frost (얼어붙는 사슬) | Attacking a Frosted target: +2 stacks. Non-frosted target: +0 |
| Absolute Zero (절대영도) | Target with Frost ≥4: bonus immediate armor-ignoring damage |
| Shatter Strike (파쇄의 일격) | Attacking a Frozen (action-lost) target: damage ×2 |

## Rare — Utility (7)

| Card | Effect |
|------|--------|
| Frost Breath (서리 뿜기) | AoE: all adjacent enemies gain Frost +1 stack |
| Frost Transfer (냉기 전이) | Move a target's entire Frost stack to an adjacent enemy (source reset to 0) |
| Rime (서릿발) | Target with Frost ≥3: takes +20% incoming damage |
| Binding Chill (예속의 한기) | Frost application always grants at least 2 stacks (upgrades 1-stack applications to 2) |
| Frozen Shackles (결빙 족쇄) | Attacking a target with Frost ≥2: target cannot move **this turn only** (must be re-applied each turn; independent of whether stacks persist) |
| Flash Freeze (급속 냉각) | Attacking a target with Frost ≥3: force-trigger Freeze immediately, without consuming stacks as a cost (the Freeze trigger's own stack-reset still applies) |
| Winter's Touch (겨울의 손길) | Each time an ally attacks a Frosted enemy: allies gain SPD +1 (this battle only) |

## Rare — Defense (6)

| Card | Effect |
|------|--------|
| Crystal Ward (결정 보호막) | Battle start: self AMR +2 (persistent) |
| Frost Plating (서리 갑주) | On being hit: attacker gains Frost +1 stack |
| Frostbite Retort (얼어붙는 반격) | On being hit: consume all of the attacker's Frost stacks → reflect armor-ignoring damage = stacks × 2 |
| Cold Preservation (냉기 보존) | Once per battle, when own Strength ≤30%: AMR +4 (works regardless of any Frost stacks) |
| Ice Shield (얼음 방패) | When an adjacent ally is hit: self absorbs 15% of that damage |
| Frost Blessing (서리의 축복) | Each time self applies a Frost effect: AMR +1 this turn (accumulates across the battle, no cap) |

## Rare — Heal (3)

Ice's heal role is expressed as **damage prevention** (freezing enemies before they act), not direct temp-STR restoration like Fire — per element_mechanics.md's role coverage table.

| Card | Effect |
|------|--------|
| Preventive Frost (예방의 서리) | Incoming damage reduced by 10% per Frost stack the attacker holds. Practical cap is 4 stacks (-40%) — 5 stacks means the attacker is Frozen and cannot attack at all, so that tier is never actually observed in play |
| Frozen Moment (정지된 순간) | Party-wide temp STR += (number of currently Frozen enemies) |
| Hibernation (겨울잠) | Once per battle, when own Strength ≤30%: instantly fill one adjacent enemy's Frost to max stack |

*Draft values note: the -10%/stack, and all flat numbers above, are provisional pending overall calibration.*

---

## Epic (4)

Each Epic requires owning specific Rare card(s) of the same element before it appears in the pick pool (§6.4).

| Card | Effect | Prerequisite (Rare) |
|------|--------|----------------------|
| Absolute Zero Strike (절대영도의 일격) | Instantly Freeze the target regardless of its current Frost stack, plus a fixed armor-ignoring damage of 25 | Absolute Zero |
| Permafrost (영구 동토) | AoE: instantly Freeze all adjacent enemies regardless of their current Frost stack | Frost Breath |
| Frozen Judgment (얼어붙은 심판) | On being hit: reflect formula upgraded from stacks × 2 to **stacks × 6**, and the reflected target is force-Frozen regardless of stack | Frostbite Retort |
| General Winter's Grace (동장군의 은총) | No HP-threshold gate. Once per battle: gain AMR +4 **and** instantly Freeze one adjacent enemy, simultaneously | Cold Preservation **and** Hibernation |
