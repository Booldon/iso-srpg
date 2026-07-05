# iso-srpg — Claude Code Project Guide

## What this project is
2D isometric tactical RPG (SRPG). Story-driven, single-player, offline.
Engine: **Godot 4.7 stable, GDScript only** (no C#, no GDNative).
Developer directs; Claude generates and debugs all code.

## Communication
- Always communicate with the developer in Korean (한국어). Code, identifiers, commit
  messages, and code comments stay in English.

## Build order (DO NOT skip ahead)
1. Grid rendering + single unit placement with isometric depth sorting (Y-sort)
2. Unit movement on grid (click-to-move, pathfinding)
3. Turn manager (alternating: player unit → enemy unit → repeat)
4. One complete 3v3 battle with win/lose conditions
5. Story, dialogue, maps — later

**Never scaffold the whole game. One vertical slice at a time.**

## Combat rules
- Max 3 party members; permadeath (dead = gone, tracked in save)
- **Strength = HP = attack power** (single stat, not two)
- **Armor** = damage reduction layer
- On attack, attacker chooses: hit **Armor** (reduce defense) or hit **Strength** (deal lethal damage)
- Turns alternate strictly 1:1 (player unit → enemy unit → repeat); within each pair, the unit with higher **Speed** acts first
- **NOT in v1:** Willpower resource, class systems, terrain height bonuses

## Protagonist special trait
Right arm is indestructible: `armor_reduction_immune = true` on their Resource.
This is a unique trait, not a general system — do not generalize it prematurely.

## Data architecture (hard rules)
- **NEVER hardcode stats** (characters, enemies, skills, items) — all go in Godot Custom Resources (`.tres`)
- Balancing = editing `.tres` files, never touching code
- Saves: JSON (`user://saves/`) — chapter, party state, alive/dead flags, story flags
- Dialogue: Dialogue Manager addon (not built yet; stub the interface now, wire later)

## Art pipeline
- Pixel art, isometric 2:1 angle
- Source sprites: PixelLab MCP → `assets/characters/`, `assets/tiles/`
- Manual cleanup in Aseprite (~20%); do not regenerate sprites that have been hand-edited
- Protagonist palette: muted cold grey-blue everywhere; **right arm only** gets cyan accent

## Naming conventions
- Files & folders: `snake_case` (`turn_manager.gd`, `grid_cell.tscn`)
- Classes / `class_name`: `PascalCase` (`class_name TurnManager`)
- Nodes in the scene tree: `PascalCase` (`GridContainer`, `UnitSprite`)
- Functions & variables: `snake_case`; private members prefixed `_` (`_compute_path`)
- Constants & enums: `ALL_CAPS` (`const MAX_PARTY = 3`)
- Signals: `snake_case`, past-tense verb (`unit_moved`, `turn_ended`)
- Resource files: `<thing>_<id>.tres` (`enemy_grunt.tres`)
- Use `class_name` for Resources and reusable types; skip it for one-off scene scripts

## Forbidden patterns
- No C# scripts — GDScript only
- No hardcoded stat numbers in `.gd` files
- No singletons/autoloads for game state before the architecture warrants it
- No placeholder "TODO: add real logic" stubs committed to main
- No full-game scaffolding in one pass

## Verification
- Primary: run the slice in the Godot editor and confirm the behavior visually before committing
- A slice is "done" only when it works end-to-end on screen, not when the code compiles
- Pure-logic units (pathfinding, damage calc) may add headless `.gd` smoke tests later;
  do NOT pull in a test framework (GUT) until the logic is non-trivial (~step 4 combat)
- Never commit a slice you have not actually run

## Git discipline
- Commit on logical boundaries (feature works end-to-end, tree is clean)
- A clean working tree = a safe checkpoint; do not leave half-broken state

### Commit message format
Subject: `type(step:N[/tag]): brief description`
Types: `feat` `fix` `data` `art` `docs`

Body (required for feat/fix, optional for data/art/docs):
```
was:  what the game could NOT do before this commit
now:  what the game CAN do after this commit

ref:  file.gd — key_function(), another_function()   ← only when multiple functions changed
```

**Rules:**
- `was/now` captures the capability delta between steps — an AI reading git log can reconstruct game state from these lines alone
- `ref:` is optional; add it when the commit touches several non-obvious entry points
- Step number matches the build order (1–5); use a `/tag` suffix for sub-steps (`step:4/ux`, `step:4/fix`)
- Body lines stay in English; keep `was`/`now` to one line each

**Examples:**
```
feat(step:2): click-to-move with A* pathfinding

was:  unit placed on grid, no interaction
now:  click any cell → unit moves via shortest path; occupied cells blocked
```
```
fix(step:4): occupancy-aware path, BFS range, engaging enemy AI

was:  enemies wander; units clip through each other; range ignores obstacles
now:  enemies advance toward party; paths route around units; range is BFS-accurate

ref:  grid_manager.gd — _compute_reachable(), _sync_astar_occupancy(), _run_enemy_turn()
```

## Project structure
- `scenes/` — `.tscn` files (e.g. `scenes/battle/grid.tscn`)
- `scripts/` — `.gd` files, mirror the scenes/ tree where it makes sense
- `data/` — `.tres` Resource files (stats, skills, items)
- `assets/` — sprites, audio (PixelLab output, hand-edited art)
- `saves/` — runtime JSON (gitignored)
- Each scene gets its own folder once it grows past one file (scene + script + sub-resources together)
- Scene root node name = PascalCase feature name; attach one script per scene root
- **Each `scripts/` subfolder contains a `CLAUDE.md` with module-specific documentation — read it before editing that module**

## Key file locations
- `assets/characters/protagonist/` — 8-dir sprites (92×92px, character_id: `1598650f-b3ed-46a8-b44f-1ec7f750b1dd`)
- `assets/tiles/` — isometric tile sprites
