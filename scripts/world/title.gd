extends Control

const WORLD_MAP   := "res://scenes/world/world_map.tscn"
const DEBUG_MENU  := "res://scenes/debug/debug_menu.tscn"

@onready var _new_game_btn:  Button = $Center/VBox/NewGameButton
@onready var _continue_btn:  Button = $Center/VBox/ContinueButton
@onready var _test_mode_btn: Button = $Center/VBox/TestModeButton


func _ready() -> void:
	_continue_btn.disabled  = not GameState.has_save()
	_test_mode_btn.visible  = OS.is_debug_build()    # hidden in exported release builds
	_new_game_btn.pressed.connect(_on_new_game)
	_continue_btn.pressed.connect(_on_continue)
	_test_mode_btn.pressed.connect(_on_test_mode)


func _on_new_game() -> void:
	GameState.new_game()
	GameState.save_game()
	get_tree().change_scene_to_file(WORLD_MAP)


func _on_continue() -> void:
	get_tree().change_scene_to_file(WORLD_MAP)


func _on_test_mode() -> void:
	GameState.enter_debug_mode()
	get_tree().change_scene_to_file(DEBUG_MENU)
