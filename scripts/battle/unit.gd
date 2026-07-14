extends Node2D
class_name Unit

signal movement_finished

const TEX_N  := preload("res://assets/characters/protagonist/north.png")
const TEX_NE := preload("res://assets/characters/protagonist/north-east.png")
const TEX_E  := preload("res://assets/characters/protagonist/east.png")
const TEX_SE := preload("res://assets/characters/protagonist/south-east.png")
const TEX_S  := preload("res://assets/characters/protagonist/south.png")
const TEX_SW := preload("res://assets/characters/protagonist/south-west.png")
const TEX_W  := preload("res://assets/characters/protagonist/west.png")
const TEX_NW := preload("res://assets/characters/protagonist/north-west.png")

@onready var _sprite: Sprite2D = $Sprite2D

var is_player: bool = true
var stats: UnitStats = null
var grid_col: int = 0
var grid_row: int = 0
var is_moving: bool = false
var status: Dictionary = {}       # StatusEffects.Type(int) → stack count
var cards: Array[CardData] = []   # injected at placement; enemies always []
var roster_path: String = ""
var temp_strength: int = 0        # battle-scoped temp STR; 0 at placement, discarded on battle end


# Returns effective Strength = base stats.strength + temp_strength.
# Used for both attack power (Combat.resolve_attack) and death check (is_alive).
func effective_strength() -> int:
	return stats.strength + temp_strength


# Returns true if this unit is still alive (effective_strength > 0).
# Use this instead of checking stats.strength <= 0 directly.
func is_alive() -> bool:
	return effective_strength() > 0


# Apply STR damage, depleting temp_strength buffer first, then base stats.strength.
# Per decisions_log "Temp STR depletion order". Does NOT check death — caller must call is_alive().
func take_str_damage(amount: int) -> void:
	if amount <= 0:
		return
	var from_temp := mini(temp_strength, amount)
	temp_strength -= from_temp
	var remaining := amount - from_temp
	stats.strength = maxi(0, stats.strength - remaining)


func _ready() -> void:
	# Players face south-east (toward enemy side); enemies face north-west
	_sprite.texture = TEX_SE if is_player else TEX_NW


func face_toward_pos(target_pos: Vector2) -> void:
	var delta := target_pos - position
	var sx := 0
	var sy := 0
	if absf(delta.x) > 0.5:
		sx = 1 if delta.x > 0.0 else -1
	if absf(delta.y) > 0.5:
		sy = 1 if delta.y > 0.0 else -1
	if sx == 0 and sy == 0:
		return
	match Vector2i(sx, sy):
		Vector2i( 1, -1): _sprite.texture = TEX_NE
		Vector2i( 1,  0): _sprite.texture = TEX_E
		Vector2i( 1,  1): _sprite.texture = TEX_SE
		Vector2i( 0,  1): _sprite.texture = TEX_S
		Vector2i(-1,  1): _sprite.texture = TEX_SW
		Vector2i(-1,  0): _sprite.texture = TEX_W
		Vector2i(-1, -1): _sprite.texture = TEX_NW
		Vector2i( 0, -1): _sprite.texture = TEX_N


func move_along_path(screen_path: Array[Vector2]) -> void:
	is_moving = true
	for target_pos in screen_path:
		face_toward_pos(target_pos)
		var tween := create_tween()
		tween.tween_property(self, "position", target_pos, 0.15)
		await tween.finished
	is_moving = false
	movement_finished.emit()
