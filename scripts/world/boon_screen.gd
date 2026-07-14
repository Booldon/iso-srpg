extends Control

const WORLD_MAP := "res://scenes/world/world_map.tscn"
const CARD_DIR  := "res://data/cards/"
const CONFIG    := preload("res://data/card_draw_config.tres")

@onready var _cards: HBoxContainer = $Center/Cards
@onready var _header: Label        = $Header

const TIER_LABEL := ["일반", "희귀", "에픽"]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()

	var sd := GameState.current_stage_data()
	_header.text = "%s 클리어!\n카드를 하나 선택하세요." % (sd.title if sd else "스테이지")

	_roll_and_build()

	if OS.is_debug_build():
		_add_debug_reload_button()


func _roll_and_build() -> void:
	for child in _cards.get_children():
		child.queue_free()
	var pool  := _load_card_pool()
	var owned := _owned_card_ids()
	var tier  := CardDraw.roll_tier(CONFIG, GameState.stages_since_rare, _rng)
	var picks := CardDraw.draw(CONFIG, pool, tier, owned, _rng)
	_build_cards(picks)


func _add_debug_reload_button() -> void:
	var btn := Button.new()
	btn.text = "[DEBUG] 다시 뽑기"
	btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.offset_left  = -200.0
	btn.offset_top   = -56.0
	btn.offset_right = -16.0
	btn.offset_bottom = -16.0
	btn.pressed.connect(_roll_and_build)
	add_child(btn)


# 전체 카드 풀 로드 (data/cards/ 디렉토리 스캔)
func _load_card_pool() -> Array[CardData]:
	var result: Array[CardData] = []
	var dir := DirAccess.open(CARD_DIR)
	if not dir:
		return result
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var card := load(CARD_DIR + fname) as CardData
			if card:
				result.append(card)
		fname = dir.get_next()
	dir.list_dir_end()
	return result


# 현재 보유 카드의 id 목록 (에픽 전제조건 판정용)
func _owned_card_ids() -> Array[String]:
	var ids: Array[String] = []
	for path in GameState.active_cards:
		var card := load(path) as CardData
		if card:
			ids.append(card.id)
	return ids


func _build_cards(picks: Array[String]) -> void:
	for path in picks:
		var card := load(path) as CardData
		if card == null:
			continue
		var tier_str: String = TIER_LABEL[card.tier] if card.tier < TIER_LABEL.size() else "?"
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 160)
		btn.text = "[%s · %s]\n\n%s" % [tier_str, card.title, card.description]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_card_chosen.bind(path))
		_cards.add_child(btn)


func _on_card_chosen(path: String) -> void:
	GameState.advance_stage(path)
	get_tree().change_scene_to_file(WORLD_MAP)
