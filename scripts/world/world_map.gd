extends Control

const BATTLE_SCENE := "res://scenes/battle/grid.tscn"

@onready var _stage_row: HBoxContainer = $Margin/VBox/StageRow
@onready var _party_label: Label       = $Margin/VBox/PartyLabel
@onready var _enter_btn: Button        = $Margin/VBox/EnterButton


func _ready() -> void:
	_refresh_stage_nodes()
	_refresh_party_label()
	_enter_btn.disabled = GameState.is_campaign_complete()
	_enter_btn.pressed.connect(func(): get_tree().change_scene_to_file(BATTLE_SCENE))


func _refresh_stage_nodes() -> void:
	for child in _stage_row.get_children():
		child.queue_free()

	var total := GameState.get_stage_count()
	for i in range(total):
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 22)
		if i < GameState.current_stage:
			lbl.text = " [St.%d ✓] " % (i + 1)
			lbl.modulate = Color(0.4, 1.0, 0.4)
		elif i == GameState.current_stage:
			lbl.text = " [St.%d ◀] " % (i + 1)
			lbl.modulate = Color(1.0, 1.0, 0.3)
		else:
			lbl.text = " [St.%d] " % (i + 1)
			lbl.modulate = Color(0.4, 0.4, 0.4)
		_stage_row.add_child(lbl)

	# show current stage title below the chain
	var sd := GameState.current_stage_data()
	if sd:
		var title_lbl := Label.new()
		title_lbl.text = sd.title
		title_lbl.add_theme_font_size_override("font_size", 18)
		title_lbl.modulate = Color(0.85, 0.85, 0.85)
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_stage_row.get_parent().add_child(title_lbl)
		_stage_row.get_parent().move_child(title_lbl, _stage_row.get_index() + 1)


func _refresh_party_label() -> void:
	var living := GameState.get_living_party()
	var card_count := GameState.active_cards.size()
	_party_label.text = "파티 생존 %d명   ·   획득 카드 %d장" % [living.size(), card_count]
