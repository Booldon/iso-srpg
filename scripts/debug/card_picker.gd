extends Control

## 디버그 전용: data/cards/ 전체를 체크박스로 보여주고, 선택한 카드만 장착한 채로
## 바로 전투(grid.tscn)에 진입한다. 시나리오 .tres를 미리 만들 필요 없이 그 자리에서
## 원하는 조합을 테스트하기 위한 화면 — debug_menu.tscn에서만 진입 가능.
##
## 카드 풀 스캔은 boon_screen.gd::_load_card_pool()과 동일한 플랫 디렉터리 스캔 패턴.
## 선택 카드는 GameState.debug_player_cards로 주입 (grid_manager가 배치 시 소비하는
## 기존 경로 재사용 — 새 GameState 필드 없음).

const CARD_DIR   := "res://data/cards/"
const GRID_SCENE := "res://scenes/battle/grid.tscn"
const DEBUG_MENU := "res://scenes/debug/debug_menu.tscn"
const TIER_LABEL := ["일반", "희귀", "에픽"]

@onready var _card_list: VBoxContainer = $ScrollContainer/CardList
@onready var _start_btn: Button        = $Footer/StartButton
@onready var _back_btn: Button         = $Footer/BackButton
@onready var _count_label: Label       = $Footer/CountLabel
@onready var _detail_label: Label      = $DetailPanel/DetailMargin/DetailLabel

const DETAIL_PLACEHOLDER := "카드에 마우스를 올리면 설명이 여기 표시됩니다."

var _checkboxes: Dictionary = {}  # CheckBox -> CardData


func _ready() -> void:
	_start_btn.pressed.connect(_on_start)
	_back_btn.pressed.connect(_on_back)
	_build_card_list()
	_update_count()


func _build_card_list() -> void:
	var pool := _load_card_pool()
	pool.sort_custom(func(a: CardData, b: CardData) -> bool:
		if a.tier != b.tier:
			return a.tier < b.tier
		return a.title < b.title)
	var current_tier := -1
	for card: CardData in pool:
		if card.tier != current_tier:
			current_tier = card.tier
			var section := Label.new()
			section.text = "── %s ──" % TIER_LABEL[current_tier]
			_card_list.add_child(section)
		var cb := CheckBox.new()
		cb.text = "%s (%s)" % [card.title, card.id]
		cb.toggled.connect(_on_toggled)
		cb.mouse_entered.connect(_on_card_hover.bind(card))
		cb.mouse_exited.connect(_on_card_unhover)
		_card_list.add_child(cb)
		_checkboxes[cb] = card


func _on_toggled(_pressed: bool) -> void:
	_update_count()


# 커서를 올린 카드의 제목·등급·설명을 오른쪽 DetailPanel에 표시한다.
func _on_card_hover(card: CardData) -> void:
	_detail_label.text = "%s [%s]\n\n%s" % [card.title, TIER_LABEL[card.tier], card.description]


func _on_card_unhover() -> void:
	_detail_label.text = DETAIL_PLACEHOLDER


func _update_count() -> void:
	var n := 0
	for cb: CheckBox in _checkboxes:
		if cb.button_pressed:
			n += 1
	_count_label.text = "선택: %d장" % n


func _on_start() -> void:
	var selected: Array[String] = []
	for cb: CheckBox in _checkboxes:
		if cb.button_pressed:
			selected.append((_checkboxes[cb] as CardData).resource_path)
	GameState.enter_debug_mode()
	GameState.new_game()
	GameState.current_stage = 0
	# active_cards is gated to the protagonist only (armor_reduction_immune check in
	# grid_manager._place_players()), matching real gameplay. debug_player_cards is a
	# separate raw override that grid_manager attaches to EVERY player unit regardless of
	# armor_reduction_immune (used by data/debug_scenarios/*.tres for whole-party stress tests) —
	# must be explicitly cleared here, otherwise cards from a previously launched .tres scenario
	# leak onto every ally in this run too.
	GameState.active_cards = selected
	GameState.debug_player_cards = []
	print("[CardPicker] launching battle with %d cards (protagonist only): %s" % [selected.size(), selected])
	get_tree().change_scene_to_file(GRID_SCENE)


func _on_back() -> void:
	get_tree().change_scene_to_file(DEBUG_MENU)


# data/cards/*.tres 플랫 스캔 — boon_screen.gd::_load_card_pool()과 동일 패턴
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
