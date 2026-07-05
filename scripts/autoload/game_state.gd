extends Node

const DEFAULT_PARTY := preload("res://data/default_party.tres")
const SAVE_DIR := "user://saves"
const SAVE_PATH := "user://saves/save.json"
const SAVE_VERSION := 1

var party: Array[Dictionary] = []


func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		load_game()
	else:
		new_game()


func new_game() -> void:
	party.clear()
	for m in DEFAULT_PARTY.members:
		var stats := m as UnitStats
		if stats:
			party.append({"path": stats.resource_path, "alive": true})


func get_living_party() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for rec in party:
		if rec["alive"]:
			result.append(rec)
	return result


func apply_survivors(surviving_paths: Array[String]) -> void:
	for rec in party:
		rec["alive"] = rec["path"] in surviving_paths
	save_game()


func save_game() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {"version": SAVE_VERSION, "party": party}
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
