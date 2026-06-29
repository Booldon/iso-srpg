extends CanvasLayer

@onready var _title: Label = $Center/VBox/Title
@onready var _restart: Button = $Center/VBox/RestartButton


func _ready() -> void:
	_restart.pressed.connect(func(): get_tree().reload_current_scene())


func show_victory() -> void:
	_title.text = "VICTORY"
	_title.modulate = Color(1.0, 0.9, 0.2)
	visible = true


func show_defeat() -> void:
	_title.text = "DEFEAT"
	_title.modulate = Color(1.0, 0.35, 0.35)
	visible = true
