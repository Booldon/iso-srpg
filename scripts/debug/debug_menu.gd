extends Control

## Debug scenario launcher.  Scans data/debug_scenarios/ for DebugScenario .tres
## files and builds a button per scenario.  Selecting one pre-configures GameState
## and jumps directly to the target scene — no need to play through from title.
##
## Only reachable from: title "TEST MODE" button (debug builds) or F1 hotkey.
## Adding a new test case = drop a new .tres in data/debug_scenarios/; no code edit needed.

const SCENARIO_DIR := "res://data/debug_scenarios/"
const TITLE_SCENE  := "res://scenes/world/title.tscn"

@onready var _scenario_list: VBoxContainer = $ScrollContainer/ScenarioList
@onready var _exit_btn: Button              = $Footer/ExitButton


func _ready() -> void:
	_exit_btn.pressed.connect(_on_exit)
	_build_scenario_list()


func _build_scenario_list() -> void:
	var scenarios := _scan_scenarios()
	if scenarios.is_empty():
		var lbl := Label.new()
		lbl.text = "data/debug_scenarios/ 에 .tres 파일이 없습니다."
		_scenario_list.add_child(lbl)
		return

	for scenario: DebugScenario in scenarios:
		var btn := Button.new()
		btn.text = scenario.label if scenario.label != "" else scenario.target_scene
		btn.custom_minimum_size = Vector2(0, 48)
		btn.pressed.connect(_launch.bind(scenario))
		_scenario_list.add_child(btn)


func _scan_scenarios() -> Array[DebugScenario]:
	var result: Array[DebugScenario] = []
	var dir := DirAccess.open(SCENARIO_DIR)
	if not dir:
		return result
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res := load(SCENARIO_DIR + fname)
			if res is DebugScenario:
				result.append(res)
		fname = dir.get_next()
	dir.list_dir_end()
	# Sort alphabetically by file name for consistent order.
	result.sort_custom(func(a: DebugScenario, b: DebugScenario) -> bool:
		return a.label < b.label)
	return result


func _launch(scenario: DebugScenario) -> void:
	GameState.enter_debug_mode()
	GameState.new_game()                                              # clean base: all party alive
	GameState.current_stage        = scenario.current_stage
	GameState.active_cards         = scenario.active_cards.duplicate()
	GameState.debug_player_cards   = scenario.debug_player_cards.duplicate()
	GameState.stages_since_rare    = scenario.stages_since_rare
	print("[DebugMenu] launching '%s' → %s  (stage=%d  cards=%d  debug_cards=%d  pity=%d)" % [
		scenario.label,
		scenario.target_scene,
		GameState.current_stage,
		GameState.active_cards.size(),
		GameState.debug_player_cards.size(),
		GameState.stages_since_rare,
	])
	get_tree().change_scene_to_file(scenario.target_scene)


func _on_exit() -> void:
	GameState.exit_debug_mode()
	get_tree().change_scene_to_file(TITLE_SCENE)
