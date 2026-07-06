extends Control

const WORLD_MAP := "res://scenes/world/world_map.tscn"

@onready var _new_game_btn: Button  = $Center/VBox/NewGameButton
@onready var _continue_btn: Button  = $Center/VBox/ContinueButton


func _ready() -> void:
	_continue_btn.disabled = not GameState.has_save()
	_new_game_btn.pressed.connect(_on_new_game)
	_continue_btn.pressed.connect(_on_continue)


func _on_new_game() -> void:
	GameState.new_game()
	GameState.save_game()
	get_tree().change_scene_to_file(WORLD_MAP)


func _on_continue() -> void:
	get_tree().change_scene_to_file(WORLD_MAP)
