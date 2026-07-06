extends Node

const DEFAULT_PARTY := preload("res://data/default_party.tres")
const CAMPAIGN      := preload("res://data/campaign.tres")
const SAVE_DIR      := "user://saves"
const SAVE_PATH     := "user://saves/save.json"
const SAVE_VERSION  := 2

var party: Array[Dictionary] = []
var current_chapter: int = 0           # index into CAMPAIGN.chapters
var active_boons: Array[String] = []   # .tres paths accumulated this run


func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		load_game()
	else:
		new_game()


# ── Query ──────────────────────────────────────────────────────────────────

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func get_living_party() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for rec in party:
		if rec["alive"]:
			result.append(rec)
	return result


func current_chapter_data() -> ChapterData:
	if current_chapter < CAMPAIGN.chapters.size():
		return CAMPAIGN.chapters[current_chapter] as ChapterData
	return null


func is_campaign_complete() -> bool:
	return current_chapter >= CAMPAIGN.chapters.size()


func get_chapter_count() -> int:
	return CAMPAIGN.chapters.size()


# ── Mutations ──────────────────────────────────────────────────────────────

func new_game() -> void:
	party.clear()
	for m in DEFAULT_PARTY.members:
		var stats := m as UnitStats
		if stats:
			party.append({"path": stats.resource_path, "alive": true})
	current_chapter = 0
	active_boons.clear()


# Called on defeat: wipe run state and persist so next session starts fresh.
func start_new_run() -> void:
	new_game()
	save_game()


func apply_survivors(surviving_paths: Array[String]) -> void:
	for rec in party:
		rec["alive"] = rec["path"] in surviving_paths
	save_game()


# Called after boon selection: append boon, advance chapter, save.
func advance_chapter(boon_path: String) -> void:
	active_boons.append(boon_path)
	current_chapter += 1
	save_game()


# ── Persistence ───────────────────────────────────────────────────────────

func save_game() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {
		"version": SAVE_VERSION,
		"party": party,
		"current_chapter": current_chapter,
		"active_boons": active_boons,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
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
	current_chapter = int(parsed.get("current_chapter", 0))
	active_boons.clear()
	for b in parsed.get("active_boons", []):
		active_boons.append(str(b))
