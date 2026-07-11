# iso-srpg Role Coordination

> Design spec: `roguelike-layer-design.md`
> Agent files: `.claude/agents/*.md`
> The main session (producer/lead) references this document when routing tasks to agents.

---

## 1. Role Matrix

| Role | Agent file | Owns §(design doc) | Owns folder / files | Tools |
|---|---|---|---|---|
| **System & Combat Designer** | `systems-designer.md` | §3, §4.1–4.2, §6.5, §6.6, §7.3, **§9 all TBD** | `docs/systems/` (design docs only) | Read/Write/Edit/Grep/Glob/Bash(ro) |
| **Data & Balancer** | `data-balancer.md` | §2, §4.3, §5, §6.2, §7.2 | `data/**/*.tres` | Read/Edit/Write/Grep/Glob/Bash |
| **Combat Programmer** | `combat-programmer.md` | §3, §4, §4.3 unique mob | `scripts/battle/`, `scripts/data/unit_stats.gd` | Read/Edit/Write/Grep/Glob/Bash + Godot MCP |
| **Meta & Progression Programmer** | `meta-programmer.md` | §2, §2.2, §2.3, §6.1, §7.3 unlock | `scripts/world/`, `scripts/autoload/game_state.gd`, `scripts/data/{campaign,chapter_data,party_roster}.gd` | Read/Edit/Write/Grep/Glob/Bash + Godot MCP |
| **UI/UX Programmer** | `ui-programmer.md` | §6.5 stack counter, §6.1 card pick, §2.2 chapter-end, §7.3 perk branch | `scenes/**/*.tscn`, UI-owning scripts in `scripts/{battle,world}/` | Read/Edit/Write/Grep/Glob/Bash + Godot MCP |
| **Art Pipeline** | `art-pipeline.md` | §5 mob sprites, §4.3 unique visual | `assets/characters/`, `assets/tiles/` | Read/Write/Bash + PixelLab MCP + Godot MCP |
| **QA & Verifier** | `qa-verifier.md` | All sections (logic verification) | `tests/smoke_*.gd`, `docs/qa/*.md` | Read/Bash/Grep/Glob/Write (test & report files only) |

---

## 2. Collaboration Rules (Handoffs)

### Numbers → data → code pipeline
```
systems-designer
  → confirms numeric baselines in docs/systems/handoff_to_balancer.md
  ↓
data-balancer
  → fills data/**/*.tres instances
  ↓
combat-programmer / meta-programmer
  → implements logic that reads .tres
  ↓
qa-verifier
  → validates logic + delivers visual checklist to developer
```

### Resource schema handoff
- When a new Resource type is needed (cards, perks, etc.): **data-balancer → combat-programmer / meta-programmer**.
- Schema definition (`class_name` Resource in `.gd`): combat-programmer or meta-programmer.
- Instance population (`.tres` files): data-balancer, after schema exists.

### UI / logic split
- Card 3-pick: pool extraction and shuffle logic = meta-programmer; card rendering and selection UX = ui-programmer.
- Element stack count: calculation = meta-programmer (via `game_state.gd`); display = ui-programmer.
- Connect via **signals** or exposed `game_state.gd` properties.

### Art dependencies
- art-pipeline waits for data-balancer to confirm the mob roster (mob types per chapter) before generating sprites.
- Unique mob visual depends on systems-designer resolving the §9 TBD aura item first.

### Data / code boundary (project principle)
- **Balancing = data editing**: numeric adjustments always go through `.tres` edits, never code changes.
- data-balancer does not touch `.gd` code.
- combat-programmer and meta-programmer do not hardcode numbers in `.gd`.

### Autoload constraint
- `game_state.gd` is the only allowed autoload. Any addition requires lead (main session) approval.

### Visual verification ownership
- All agents: stop at headless / print-level checks.
- Final visual confirmation: developer runs the scene in the Godot editor. Only the developer declares a slice done.

---

## 3. Routing Workflow — Main Session

The main session acts as **producer / lead**, routing tasks to agents one vertical slice at a time.

### Slice start checklist
1. Check the relevant §N section of the design doc + current §9 TBD status.
2. If any numeric baseline is unconfirmed, send systems-designer first.
3. Forward confirmed numbers to data-balancer via handoff memo.
4. Route logic implementation to combat-programmer and meta-programmer (can be parallel).
5. Route UI work to ui-programmer after logic interfaces are confirmed.
6. On slice complete, send to qa-verifier → receive checklist → developer visual check.

### Routing example
```
# Card selection system slice
1. systems-designer → "Confirm card 3-pick pool rules + Epic unlock conditions (§6.4)"
2. data-balancer    → "Draft 15 Common card .tres files (see systems-designer handoff)"
3. meta-programmer  → "Implement card 3-pick acquisition on battle win, save to game_state"
4. ui-programmer    → "Build card selection scene, wire to meta-programmer signal"
5. qa-verifier      → "Validate card acquisition logic + visual checklist"
```

---

## 4. §9 TBD Items — Ownership Table

| # | Undecided item | Primary owner | Support |
|---|---|---|---|
| 1 | Chapter-end event content and format | **systems-designer** | meta-programmer (implementation) |
| 2 | Unique mob spawn probability | **systems-designer** | data-balancer (apply) |
| 3 | Unique mob instant reward values | **systems-designer** | data-balancer (apply) |
| 4 | Archer 2nd branch final decision (marking type candidate) | **systems-designer** | data-balancer (perk instances) |
| 5 | Bard role scope final decision (exclude terrain creation) | **systems-designer** | data-balancer (perk instances) |
| 6 | Healer perk values (temporary Strength bonus approach) | **systems-designer** | data-balancer (apply) |
| 7 | Exact ally roster headcount | **systems-designer** | data-balancer (instance count) |
| 8 | Full Rare card list (breakdown by role type across 65 cards) | **systems-designer** | data-balancer (.tres creation) |
| 9 | Base power unit for 1 Common card (perk balance reference) | **systems-designer** | data-balancer (perk tuning) |
| 10 | Per-chapter ally join timing and frequency | **systems-designer** | meta-programmer (script) + art-pipeline (sprites) |

> **Rule**: no agent begins implementation on a TBD item until systems-designer records the decision in `docs/systems/decisions_log.md`.

> **§4.3 Unique mob aura visual** (TBD): art-pipeline's domain, but only after systems-designer confirms the "immediately distinguishable" visual standard.

---

*Update this document whenever the role structure changes. Design doc revision (roguelike-layer-design.md) → sync §4 ownership table.*
