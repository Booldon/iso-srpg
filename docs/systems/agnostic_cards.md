> Part of the full card pool. See card_pool_structure.md for overall breakdown.

# Agnostic Cards — Rare (10) + Epic (3)

**Status:** Confirmed
**Element:** None — these do not count toward any element stack (§6.5)

---

## Rare — Passive (5)

Multiplicative modifiers / system modifiers — the differentiator from Common cards (which are flat stat additions).

| Card | Effect |
|------|--------|
| Penetration (관통) | On attack: target's AMR is treated as halved (round down) for this attack's damage calculation |
| Heavy Blow (강타) | Outgoing damage ×1.15 |
| Swift Execution (속전속결) | If self acts first in this turn-pair (higher SPD): outgoing damage ×1.2 |
| Endurance (인내) | Incoming damage ×0.9 |
| Desperate Strike (필사의 일격) | While own Strength ≤50%: outgoing damage ×1.3 |

## Rare — Skill (5)

Strong standalone skills with no element synergy. Deliberately free of any RNG/probability effect — `Combat.resolve_attack` is fully deterministic, and introducing chance here would be a first-of-its-kind system change, not a card-level decision.

| Card | Effect |
|------|--------|
| Executioner's Blade (처형자의 검) | On attack, if target's Strength ≤20%: the attack is an unconditional execution (instant kill) |
| Perfect Guard (완벽한 방어) | On activation: all incoming damage this turn becomes 0 (3-turn cooldown) |
| Undying Will (불굴의 생명력) | Once per **chapter**: if own Strength would reach 0 (death), survive instead at Strength 1 |
| Ranged Strike (원거리 일격) | Attack range +1 tile (additive — stacks with any future ranged-unit/skill range bonus) |
| Opportunist (기회 포착) | If an adjacent enemy takes a non-attack action (e.g. moves) instead of attacking self: immediately get one reactive attack against it |

*Design note: Undying Will directly interacts with §2.3's "protagonist death = full chapter reset" rule — it was originally drafted as once-per-battle, but that was judged too strong (effectively neutering the chapter-reset stakes every fight) and was weakened to once-per-chapter.*

---

## Epic (3)

Unlike element Epics (which each require one same-element Rare card), Agnostic Epic prerequisites follow the three fixed archetypes defined in card_pool_structure.md.

| Type | Card | Effect | Prerequisite |
|------|------|--------|---------------|
| Veteran (B) | Double Strike (이중 타격) | Each turn, attack twice in place of moving (no move that turn); each hit deals only 40% damage | Total owned Rare card count ≥15 |
| Combo (A) | Vanguard Rush (필사의 돌격) | Can move and attack in the same turn (normally mutually exclusive) | Own both Penetration **and** Desperate Strike |
| Cross (C) | Quintessence of Mastery (만능의 정수) | Battle start: for every element that has reached stack tier ≥2 (§6.5), that element's effect magnitudes are amplified +10% this battle | Own Penetration **and** have reached stack tier ≥2 in any element |

*Design history: Double Strike and Vanguard Rush were originally drafted as Rare-tier skill cards (no damage penalty, no move+attack restriction lifted only partially) but were judged too strong for Rare and promoted to Epic — Double Strike gained its 40%-damage penalty in the process. Their real value at Epic tier is doubling on-attack trigger effects (e.g. Ember, Frost Strike) rather than raw damage.*
