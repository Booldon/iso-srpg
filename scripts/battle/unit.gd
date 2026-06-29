extends Node2D
class_name Unit

signal movement_finished

var is_player: bool = true
var stats: UnitStats = null
var grid_col: int = 0
var grid_row: int = 0
var is_moving: bool = false


func move_along_path(screen_path: Array[Vector2]) -> void:
	is_moving = true
	for target_pos in screen_path:
		var tween := create_tween()
		tween.tween_property(self, "position", target_pos, 0.15)
		await tween.finished
	is_moving = false
	movement_finished.emit()
