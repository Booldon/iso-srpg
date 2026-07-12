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

**Observation:** Fire and Ice both arrived at a "once per battle, when own Strength ≤30%, trigger a strong defensive/recovery effect" card in **both** their Defense and Heal sets (Fire: Phoenix Ember / Phoenix Feather; Ice: Cold Preservation / Hibernation). Earth deliberately breaks this pattern: Unshakable Will (Defense) has the trigger, but Earth's Heal set (Earthen Nourishment / Root Sharing / Steadfast Growth) has no low-HP trigger at all — it leans entirely on Growth's gradual/propagating flavor instead, giving Earth a passive-sustain identity distinct from Fire's/Ice's panic-button heals.

**How to apply:** Don't assume every element needs a low-HP safety net in every role — the shared template is a convenience, not a hard rule. Keep this asymmetry in mind when balancing: Earth's Strength never gets a heal-side "instant save" the way Fire/Ice do, so its survivability comes from steady AMR/temp-STR accumulation instead of a clutch trigger.

---

## No active-skill slot limit (2026-07-11)

**Decision:** There is no pre-battle "equip N active skills from your pool" loadout system. Every unlocked card that has a genuine active/alternative-action component (as opposed to passive always-on triggers) is available whenever its trigger condition is met, with no artificial cap on how many can be available in a single battle.

**Why:** Auditing the ~74 element + agnostic cards designed so far, the large majority are passive (auto-trigger on a normal attack/hit, e.g. Ember, Frost Plating, Brittle Coat) and need no UI slot at all. Only a small minority spend a resource as an alternative to a normal attack (Raging Flame, Crush, all Epic finishers, Double Strike, Vanguard Rush). For those, the existing stack-threshold conditions already bound how many are simultaneously offerable on a given attack — a hard slot limit would add pre-battle UI complexity (contrary to the project's "one vertical slice at a time" principle) to solve a problem that may not materialize. If playtesting later shows decision-paralysis in the attack menu, add a slot system then.

**How to apply:** ui-programmer should extend `attack_menu.gd` to show extra options (beyond the existing Armor/Strength choice) only for active-cost cards whose condition currently holds on the selected target — not a fixed list of equipped skills.

---

## Combat resolution stays fully deterministic — no RNG-based card effects (2026-07-11)

**Decision:** No card in any tier introduces a probability/chance element (e.g. "25% chance to..."). All effects are deterministic given the current game state.

**Why:** `Combat.resolve_attack` computes `damage = attacker.strength - target.armor` with no randomness anywhere in the combat resolution. Introducing RNG at the card level would be a first-of-its-kind system change with much broader implications (save/replay determinism, difficulty tuning, player trust in visible numbers) than any single card is worth. This surfaced while designing the Agnostic Rare skill set, where a "critical hit chance" card was considered and rejected for this reason.

**How to apply:** If a future card idea's only interesting form involves a percentage chance, redesign it as a deterministic threshold/condition instead (the project's cards consistently do this already — e.g. stack-count thresholds rather than "chance to apply").

---

## Undying Will vs. the chapter-reset rule (2026-07-11)

**Decision:** The agnostic Rare skill card Undying Will ("survive at Strength 1 instead of dying") is capped at **once per chapter**, not once per battle.

**Why:** §2.3 makes protagonist death carry real weight (full chapter reset). A once-per-battle version of this card would neutralize that stakes in every single fight, which is too strong for a Rare-tier card and undermines the roguelike tension the chapter-reset rule is there to create. Once-per-chapter preserves the safety-net value while still leaving death a real possibility across a chapter's 5 stages.

**How to apply:** meta-programmer implementing the chapter-reset/death-check logic (`GameState`, `_place_players()`, etc.) needs to track this card's usage at chapter scope (reset the "used" flag on chapter start/reset), not at battle scope like other cards' "once per battle" triggers.

---

## Card application timing: immediate per-stage, not batched at chapter end (2026-07-12)

**Decision:** A card won from a stage-clear activates **immediately**, contributing to the same chapter's remaining stages and boss fight — not held pending until the chapter ends. §6.1's "챕터 클리어 시 그 챕터에서 획득한 카드 전부 활성화" wording is superseded by this decision (see corresponding edit to `roguelike-layer-design.md` §6.1).

**Why:** Two problems surfaced from a manual 3v3 balance simulation (protagonist + 2 allies vs stage-3 grunt/fast/tank, using the actual `turn_manager.gd` speed-pairing and a highest-STR-target enemy AI):
1. **Pacing** — with batched application, the character stays flat for 4 stages and jumps by 5 cards all at once at the chapter boundary. This reads as dead time mid-chapter.
2. **Structural mismatch with §4.3** — chapter difficulty escalates *within* the chapter (late stages get 강화판 monsters), but batching meant the player fights that escalation using only the *previous* chapter's cards, never benefiting from the current chapter's own picks until after the hardest fights (including the boss) are already over. Player power was flat while enemy power ramped — backwards from the intended risk/reward curve.

Note: batching was never required by §2.3's reset rule. "직전 챕터까지 확정된 카드만 유지" already means a chapter reset discards everything earned in the current attempt, whether or not it had been "activated" — so immediate application doesn't weaken the reset stakes at all.

**How to apply:** meta-programmer's card-acquisition flow should call the activation path right after each stage-clear card pick, not defer it to chapter-end. Chapter-reset logic still wipes all of the current chapter's picks (active or not) and keeps only prior-chapter's confirmed cards, exactly as before. §7.3's per-chapter power table (5/10/15/20/25 cards) still holds as the *end-of-chapter* checkpoint, but the state mid-chapter is now a smooth ramp between those checkpoints rather than a flat line followed by a jump.

---

## Earth counter-damage coefficient reduced: stacks × 2 → stacks × 1 (2026-07-12)

**Decision:** Earth's innate counter-damage (on being hit while holding Guard stacks, reflect armor-ignoring damage) is reduced from `stacks × 2` to `stacks × 1`. Thorn Armor (previously "doubled, effectively stacks × 4") now reads "doubled, effectively stacks × 2". Retaliatory Strike, Bedrock, Impenetrable Fortress, and all other cards that reference counter-damage relatively (not as a fixed number) are unaffected by this change.

**Why:** The same 3v3 balance simulation that led to the card-application-timing decision above (see that entry) flagged Earth as overperforming Fire/Ice. Root cause identified: Earth's counter-damage is innate (any card that grants Guard stacks — e.g. a single Earthen Bulwark pick — activates it for the rest of the battle, no further setup) and self-referential (reflects the *defender's own* stack count). Ice's comparable payoff, Frostbite Retort, requires a dedicated card slot **and** requires the *attacker* to already be carrying Frost stacks (i.e. the player must have applied Frost to that specific enemy first via a separate attack card). Earth was getting two-for-one value (AMR boost + unconditional reflect) from a single Defense card where Ice needed two cards plus setup for a comparable reflect. Considered but rejected: fully gating counter-damage behind a dedicated card (would orphan Retaliatory Strike's trigger condition and require rewriting Thorn Armor/Impenetrable Fortress's "doubled" framing, since there'd be no baseline to double) and adding a Guard-stack threshold gate (adds a second variable to retest alongside the coefficient change — deferred in favor of the simpler single-variable fix first).

**How to apply:** data-balancer should use `stacks × 1` as the baseline reflect value when Guard mechanics are implemented in `.tres`/code. This value is still provisional pending the overall stat/damage calibration pass noted throughout `fire_cards.md` / `ice_cards.md` / `earth_cards.md` — re-run the 3v3 sim (highest-STR-target AI, burn-tick-at-turn-start, per this session's findings) once calibration lands to confirm the coefficient change actually closes the gap with Fire/Ice rather than just narrowing it.
