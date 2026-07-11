# Decisions Log

Per `docs/roles.md` §2: no agent begins implementation on a §9 TBD item — or, more broadly, on any cross-cutting mechanic — until systems-designer records the decision here. This log captures decisions made during the Fire/Ice/Earth Rare card design pass that affect systems beyond a single card (i.e. rules the combat-programmer will need before implementing the card/status-effect system).

---

## Temp STR depletion order (2026-07-11)

**Decision:** When a unit takes damage, its temporary STR buffer (granted by Solar-type heal cards, healer ally perks, etc. per §3.2) is depleted **before** permanent base STR is touched. Only once the temp buffer reaches 0 does incoming damage start reducing base STR.

**Why:** This was decided while designing Fire's heal cards (Phoenix Feather) and defense cards (Phoenix Ember) — both share a "Strength ≤30%" trigger, and this rule is what makes them meaningfully different choices: Phoenix Ember (convert enemy Burn stacks → AMR) is a *preventive* shield against future damage, while Phoenix Feather (restore temp STR) *refills the buffer that gets consumed first anyway*. Without this ordering rule, temp STR would just be indistinguishable from permanent STR during combat resolution.

**How to apply:** Combat-programmer should treat `current_STR = base_STR + temp_STR_buffer`, and route all incoming damage through the buffer first. This rule is element-agnostic — applies to any future temp-STR source (Fire heal cards, ally healer perks per §7.2), not just the two Fire cards that surfaced it.

---

## Per-element stack decay rules (2026-07-11)

**Decision:** Stack-based status effects decay differently per element, based on whether the underlying mechanic is a damage-snowball risk or not:

| Element | Status | Natural decay? | Reasoning |
|---|---|---|---|
| Fire | Burn | Yes, -1/turn | Burn is direct damage-over-time; without decay it's an unbounded death spiral |
| Ice | Frost | No | Frost only affects turn order within a speed-paired turn (§ turn system: strict 1:1 alternation, SPD only decides who acts first within a pair) — it cannot kill by itself, so unbounded accumulation isn't a runaway-damage risk |
| Earth | Guard | No | Guard stacks directly are the defensive payoff (AMR); decaying them would undercut Earth's tank identity, and like Frost it isn't a damage mechanic |

**How to apply:** When designing further stack-based effects (any future element, or Epic-tier cards), default to "no decay" unless the stack directly deals or amplifies damage over time, in which case decay is mandatory to keep the mechanic bounded.

---

## Threshold-effect stack consumption (2026-07-11)

**Decision:** Any status effect with a "reach max stack → powerful automatic effect" design (Fire: none at Rare tier, reserved for Epic; Ice: Freeze at max Frost; Earth: none, Guard's threshold effects are all card-gated at ≥4, not max) must **consume the triggering stacks** (reset to 0) at the moment the threshold effect fires, if that effect is a hard crowd-control lock (loss of an entire turn). This mirrors the decay rule's purpose: prevent a permanent, unrecoverable lock that would otherwise never end (no decay + no consumption = permanent freeze once triggered).

**How to apply:** This specifically governs Ice's Freeze (element_mechanics.md's stated primary Frost threshold effect). Soft thresholds that don't remove a full turn (e.g. Ice's Frozen Shackles move-lock, Earth's Bedrock/Center of Gravity ≥4 checks) do **not** need stack consumption — they were designed as continuously-checked conditions instead, and Frozen Shackles was explicitly scoped to a fixed 1-turn duration (re-application required each turn) rather than persisting for as long as the stack count holds, specifically to avoid a similar permanent-lock risk on non-adjacent enemies.

---

## Stack-based damage formulas use fixed values, not stat-scaling (2026-07-11)

**Decision:** Where a card's effect scales with a status stack count (Burn tick, Frostbite Retort, Earth's base counter-damage), the per-stack value is a **fixed number**, not proportional to the acting unit's own STR or AMR.

**Why:** Established by precedent (Fire's Burn tick = flat 1 STR/turn/stack, Ice's Frostbite Retort = flat 2 armor-ignoring/stack) and confirmed explicitly for Earth's counter-damage after considering (and rejecting) an AMR-proportional alternative, which would let stat-boosting Common cards compound counter-damage in a way inconsistent with the other two elements.

**How to apply:** Keep this convention for any remaining stack-based damage/effect cards in Earth's still-unfinished Utility/Heal sets and in the upcoming Epic pass, unless a specific card is deliberately designed to be the one exception (and flagged as such).

---

## Recurring "low-HP safety net" card template (2026-07-11)

**Observation (not a rule, but a pattern worth naming):** Every element so far has independently arrived at a "once per battle, when own Strength ≤30%, trigger a strong defensive/recovery effect" card in both its Defense and Heal sets (Fire: Phoenix Ember / Phoenix Feather; Ice: Cold Preservation / Hibernation; Earth: Unshakable Will in Defense — Earth's Heal set is not yet designed). This is an intentional shared design language, not accidental duplication — each element expresses the safety net through its own mechanic (AMR conversion vs. temp STR vs. AoE stack application).

**How to apply:** When designing Earth's remaining Heal (3 cards), consider whether a matching low-HP safety-net card belongs there for consistency, but it isn't mandatory — Earth's Heal role may lean more on Growth's "gradual/propagating" flavor instead per element_mechanics.md.
