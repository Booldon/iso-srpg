extends Resource
class_name DebugScenario

## A data-driven debug scenario.  Each .tres in data/debug_scenarios/ describes
## a specific game state to jump into from the debug menu — no code changes needed
## to add new test cases, just add another .tres file.

## Label shown on the debug menu button.
@export var label: String = ""

## The scene to load after GameState is configured (res:// path).
@export var target_scene: String = ""

## ── GameState pre-configuration ──────────────────────────────────────────────

## Index into CAMPAIGN.stages to start at (0 = first battle).
@export var current_stage: int = 0

## Card .tres paths to inject into GameState.active_cards before scene load.
@export var active_cards: Array[String] = []

## Card .tres paths to inject into GameState.debug_player_cards so grid_manager
## attaches them to every player unit on placement.
@export var debug_player_cards: Array[String] = []
