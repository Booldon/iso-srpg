extends CanvasLayer

const TITLE_SCENE := "res://scenes/world/title.tscn"

@onready var _title: Label   = $Center/VBox/Title
@onready var _restart: Button = $Center/VBox/RestartButton


func _ready() -> void:
	# Defeat: run was already reset by grid_manager; go back to title.
	_restart.pressed.connect(
		func(): get_tree().change_scene_to_file(TITLE_SCENE)
	)


# Victory no longer shows this screen — grid_manager transitions directly
# to boon_screen (or world_map on campaign complete). Kept for safety.
func show_victory() -> void:
	_title.text = "VICTORY"
	_title.modulate = Color(1.0, 0.9, 0.2)
	visible = true


func show_defeat() -> void:
	_title.text = "전멸"
	_title.modulate = Color(1.0, 0.35, 0.35)
	_restart.text = "타이틀로"
	visible = true
