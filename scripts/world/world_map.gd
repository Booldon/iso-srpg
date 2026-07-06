extends Control

const BATTLE_SCENE := "res://scenes/battle/grid.tscn"

@onready var _chapter_row: HBoxContainer = $Margin/VBox/ChapterRow
@onready var _party_label: Label         = $Margin/VBox/PartyLabel
@onready var _enter_btn: Button          = $Margin/VBox/EnterButton


func _ready() -> void:
	_refresh_chapter_nodes()
	_refresh_party_label()
	_enter_btn.disabled = GameState.is_campaign_complete()
	_enter_btn.pressed.connect(func(): get_tree().change_scene_to_file(BATTLE_SCENE))


func _refresh_chapter_nodes() -> void:
	for child in _chapter_row.get_children():
		child.queue_free()

	var total := GameState.get_chapter_count()
	for i in range(total):
		var lbl := Label.new()
		lbl.theme_override_font_sizes["font_size"] = 22
		if i < GameState.current_chapter:
			lbl.text = " [Ch.%d ✓] " % (i + 1)
			lbl.modulate = Color(0.4, 1.0, 0.4)
		elif i == GameState.current_chapter:
			lbl.text = " [Ch.%d ◀] " % (i + 1)
			lbl.modulate = Color(1.0, 1.0, 0.3)
		else:
			lbl.text = " [Ch.%d] " % (i + 1)
			lbl.modulate = Color(0.4, 0.4, 0.4)
		_chapter_row.add_child(lbl)

	# show current chapter title below the chain
	var cd := GameState.current_chapter_data()
	if cd:
		var title_lbl := Label.new()
		title_lbl.text = cd.title
		title_lbl.theme_override_font_sizes["font_size"] = 18
		title_lbl.modulate = Color(0.85, 0.85, 0.85)
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_chapter_row.get_parent().add_child(title_lbl)
		_chapter_row.get_parent().move_child(title_lbl, _chapter_row.get_index() + 1)


func _refresh_party_label() -> void:
	var living := GameState.get_living_party()
	var boon_count := GameState.active_boons.size()
	_party_label.text = "파티 생존 %d명   ·   획득 부운 %d개" % [living.size(), boon_count]
