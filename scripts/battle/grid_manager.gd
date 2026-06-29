extends Node2D

const TILE_HALF_W: int = 32
const TILE_HALF_H: int = 16
const GRID_COLS: int = 8
const GRID_ROWS: int = 8

const UNIT_SCENE := preload("res://scenes/battle/unit.tscn")

@onready var _floor: Node2D = $WorldContainer/FloorLayer
@onready var _actors: Node2D = $WorldContainer/ActorsLayer

var _astar := AStar2D.new()
var _protagonist: Unit


func _ready() -> void:
	_build_grid()
	_setup_pathfinding()
	_place_protagonist()


func _input(event: InputEvent) -> void:
	if _protagonist.is_moving:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := screen_to_grid(get_global_mouse_position())
		if _is_valid_cell(cell):
			_move_protagonist_to(cell)


func grid_to_screen(col: int, row: int) -> Vector2:
	return Vector2(
		(col - row) * TILE_HALF_W,
		(col + row) * TILE_HALF_H
	)


func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var fx := screen_pos.x / TILE_HALF_W
	var fy := screen_pos.y / TILE_HALF_H
	return Vector2i(roundi((fx + fy) / 2.0), roundi((fy - fx) / 2.0))


func _cell_id(col: int, row: int) -> int:
	return row * GRID_COLS + col


func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_COLS and cell.y >= 0 and cell.y < GRID_ROWS


func _build_grid() -> void:
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			_floor.add_child(_make_tile(col, row))


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


func _setup_pathfinding() -> void:
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			_astar.add_point(_cell_id(col, row), Vector2(col, row))
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			if col + 1 < GRID_COLS:
				_astar.connect_points(_cell_id(col, row), _cell_id(col + 1, row))
			if row + 1 < GRID_ROWS:
				_astar.connect_points(_cell_id(col, row), _cell_id(col, row + 1))


func _place_protagonist() -> void:
	_protagonist = UNIT_SCENE.instantiate()
	_protagonist.grid_col = 0
	_protagonist.grid_row = 0
	_protagonist.position = grid_to_screen(0, 0)
	_actors.add_child(_protagonist)


func _move_protagonist_to(cell: Vector2i) -> void:
	var from_id := _cell_id(_protagonist.grid_col, _protagonist.grid_row)
	var to_id := _cell_id(cell.x, cell.y)
	var id_path := _astar.get_id_path(from_id, to_id)
	if id_path.size() <= 1:
		return

	var screen_path: Array[Vector2] = []
	for id in id_path.slice(1):
		var point := _astar.get_point_position(id)
		screen_path.append(grid_to_screen(int(point.x), int(point.y)))

	_protagonist.grid_col = cell.x
	_protagonist.grid_row = cell.y
	_protagonist.move_along_path(screen_path)
