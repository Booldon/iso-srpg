extends Node

const DEFAULT_PARTY  := preload("res://data/default_party.tres")
const CAMPAIGN       := preload("res://data/campaign.tres")
const SAVE_DIR       := "user://saves"
const SAVE_PATH      := "user://saves/save.json"
const SAVE_PATH_DEBUG := "user://saves/save_debug.json"
const SAVE_VERSION   := 5
const DEBUG_MENU     := "res://scenes/debug/debug_menu.tscn"

var party: Array[Dictionary] = []
var current_stage: int = 0            # index into CAMPAIGN.stages
var active_cards: Array[String] = []  # card .tres paths acquired this run (protagonist)
var stages_since_rare: int = 0        # pity counter: consecutive stages without Rare/Epic

# ── Debug (transient, never written to save JSON) ──
var debug_mode: bool = false
var debug_player_cards: Array[String] = []  # injected by grid_manager at placement


func _ready() -> void:
	if FileAccess.file_exists(_active_save_path()):
		load_game()
	else:
		new_game()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	# F1 is intercepted by the Godot editor (Search Help); use backtick instead.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_QUOTELEFT:
		enter_debug_mode()
		get_tree().change_scene_to_file(DEBUG_MENU)


# ── Query ──────────────────────────────────────────────────────────────────

func has_save() -> bool:
	return FileAccess.file_exists(_active_save_path())


func get_living_party() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for rec in party:
		if rec["alive"]:
			result.append(rec)
	return result


func current_stage_data() -> StageData:
	if current_stage < CAMPAIGN.stages.size():
		return CAMPAIGN.stages[current_stage] as StageData
	return null


func is_campaign_complete() -> bool:
	return current_stage >= CAMPAIGN.stages.size()


func get_stage_count() -> int:
	return CAMPAIGN.stages.size()


# ── Mutations ──────────────────────────────────────────────────────────────

func new_game() -> void:
	party.clear()
	for m in DEFAULT_PARTY.members:
		var stats := m as UnitStats
		if stats:
			party.append({"path": stats.resource_path, "alive": true})
	current_stage = 0
	active_cards.clear()
	stages_since_rare = 0


# Called on defeat: wipe run state and persist so next session starts fresh.
func start_new_run() -> void:
	new_game()
	save_game()


func apply_survivors(surviving_paths: Array[String]) -> void:
	for rec in party:
		rec["alive"] = rec["path"] in surviving_paths
	save_game()


# Called after card selection: append card, update pity counter, advance stage, save.
func advance_stage(card_path: String) -> void:
	active_cards.append(card_path)
	# Update pity counter based on the chosen card's tier.
	var card := load(card_path) as CardData
	if card != null and card.tier >= CardData.Tier.RARE:
		stages_since_rare = 0
	else:
		stages_since_rare += 1
	current_stage += 1
	save_game()


# ── Debug ─────────────────────────────────────────────────────────────────

func enter_debug_mode() -> void:
	debug_mode = true


func exit_debug_mode() -> void:
	debug_mode = false


func _active_save_path() -> String:
	return SAVE_PATH_DEBUG if debug_mode else SAVE_PATH


# ── Persistence ───────────────────────────────────────────────────────────

func save_game() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {
		"version": SAVE_VERSION,
		"party": party,
		"current_stage": current_stage,
		"active_cards": active_cards,
		"stages_since_rare": stages_since_rare,
	}
	var file := FileAccess.open(_active_save_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	var file := FileAccess.open(_active_save_path(), FileAccess.READ)
	if not file:
		new_game()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or parsed.get("version") != SAVE_VERSION:
		new_game()
		return
	party.clear()
	for rec in parsed["party"]:
		party.append({"path": rec["path"], "alive": rec["alive"]})
	current_stage = int(parsed.get("current_stage", 0))
	active_cards.clear()
	for c in parsed.get("active_cards", []):
		active_cards.append(str(c))
	stages_since_rare = int(parsed.get("stages_since_rare", 0))
