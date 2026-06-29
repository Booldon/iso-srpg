extends Node2D

const TILE_HALF_W: int = 32
const TILE_HALF_H: int = 16
const GRID_COLS: int = 8
const GRID_ROWS: int = 8
const SPRITE_HEIGHT: int = 92

@onready var _world: Node2D = $WorldContainer


func _ready() -> void:
	_build_grid()
	_place_protagonist()


func grid_to_screen(col: int, row: int) -> Vector2:
	return Vector2(
		(col - row) * TILE_HALF_W,
		(col + row) * TILE_HALF_H
	)


func _build_grid() -> void:
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			_world.add_child(_make_tile(col, row))


func _make_tile(col: int, row: int) -> Polygon2D:
	var tile := Polygon2D.new()
	tile.polygon = PackedVector2Array([
		Vector2(0, -TILE_HALF_H),
		Vector2(TILE_HALF_W, 0),
		Vector2(0, TILE_HALF_H),
		Vector2(-TILE_HALF_W, 0),
	])
	tile.color = Color(0.35, 0.55, 0.35) if (col + row) % 2 == 0 else Color(0.28, 0.45, 0.28)
	tile.position = grid_to_screen(col, row)
	return tile


func _place_protagonist() -> void:
	var unit := Node2D.new()
	unit.name = "ProtagonistUnit"
	unit.position = grid_to_screen(0, 0)

	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/characters/protagonist/south.png")
	# Align sprite bottom to the tile's bottom vertex for correct isometric footing
	sprite.position = Vector2(0, TILE_HALF_H - SPRITE_HEIGHT / 2)
	unit.add_child(sprite)

	_world.add_child(unit)
