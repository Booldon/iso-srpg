extends Control

const WORLD_MAP  := "res://scenes/world/world_map.tscn"
const BOON_DIR   := "res://data/boons/"
const PICK_COUNT := 3

@onready var _cards: HBoxContainer = $Center/Cards
@onready var _header: Label        = $Header


func _ready() -> void:
	var cd := GameState.current_chapter_data()
	_header.text = "%s 클리어!\n부운을 하나 선택하세요." % (cd.title if cd else "챕터")

	var pool := _load_boon_pool()
	pool.shuffle()
	var picks := pool.slice(0, mini(PICK_COUNT, pool.size()))
	_build_cards(picks)


func _load_boon_pool() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(BOON_DIR)
	if not dir:
		return paths
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			paths.append(BOON_DIR + fname)
		fname = dir.get_next()
	return paths


func _build_cards(picks: Array[String]) -> void:
	for path in picks:
		var boon := load(path) as BoonData
		if boon == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 160)
		btn.text = "[%s]\n\n%s" % [boon.title, boon.description]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_card_chosen.bind(path))
		_cards.add_child(btn)


func _on_card_chosen(path: String) -> void:
	GameState.advance_chapter(path)
	get_tree().change_scene_to_file(WORLD_MAP)
