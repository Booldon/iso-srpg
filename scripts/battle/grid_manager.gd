extends Node2D

const TILE_HALF_W: int = 32
const TILE_HALF_H: int = 16
const GRID_COLS: int = 8
const GRID_ROWS: int = 8

const UNIT_SCENE := preload("res://scenes/battle/unit.tscn")

@onready var _floor: Node2D = $WorldContainer/FloorLayer
@onready var _actors: Node2D = $WorldContainer/ActorsLayer
@onready var _turn_manager: TurnManager = $TurnManager
@onready var _attack_menu: CanvasLayer = $AttackMenu
@onready var _stats_panel: CanvasLayer = $StatsPanel
@onready var _result_screen: CanvasLayer = $ResultScreen

var _astar := AStar2D.new()
var _players: Array[Unit] = []
var _enemies: Array[Unit] = []
var _unit_at: Dictionary = {}   # Vector2i -> Unit
var _hover_tile: Polygon2D
var _active_tile: Polygon2D
var _active_tween: Tween
var _player_can_act: bool = false
var _pending_target: Unit = null
var _battle_over: bool = false


func _ready() -> void:
	_build_grid()
	_setup_hover_tile()
	_setup_active_tile()
	_setup_pathfinding()
	_place_players()
	_place_enemies()
	_turn_manager.turn_started.connect(_on_turn_started)
	_attack_menu.armor_chosen.connect(_on_attack_armor)
	_attack_menu.strength_chosen.connect(_on_attack_strength)
	_attack_menu.cancelled.connect(_on_attack_cancel)
	var all_units: Array[Unit] = []
	all_units.append_array(_players)
	all_units.append_array(_enemies)
	_turn_manager.start_battle(all_units)


func _process(_delta: float) -> void:
	var cell := screen_to_grid(get_global_mouse_position())
	if _is_valid_cell(cell):
		_hover_tile.visible = true
		_hover_tile.position = grid_to_screen(cell.x, cell.y)
	else:
		_hover_tile.visible = false

	if not _battle_over and not _turn_manager.get_all_units().is_empty():
		_active_tile.visible = true
		_active_tile.position = _turn_manager.current_unit().position
		var hovered := _unit_at.get(cell) as Unit
		_stats_panel.show_unit(hovered if hovered else _turn_manager.current_unit())
	else:
		_active_tile.visible = false


func _input(event: InputEvent) -> void:
	if _battle_over or not _player_can_act:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var active := _turn_manager.current_unit()
		var cell := screen_to_grid(get_global_mouse_position())
		if _unit_at.has(cell) and not _unit_at[cell].is_player:
			var target: Unit = _unit_at[cell]
			if _is_adjacent(active, target):
				_pending_target = target
				_player_can_act = false
				_attack_menu.show_menu()
		elif _is_valid_cell(cell) and not _unit_at.has(cell):
			_do_player_move(active, cell)


func _on_turn_started(unit: Unit) -> void:
	if unit.is_player:
		_player_can_act = true
	else:
		_run_enemy_turn(unit)


func _on_attack_armor() -> void:
	_execute_player_attack(true)


func _on_attack_strength() -> void:
	_execute_player_attack(false)


func _on_attack_cancel() -> void:
	_player_can_act = true


func _execute_player_attack(hit_armor: bool) -> void:
	var attacker := _turn_manager.current_unit()
	Combat.resolve_attack(attacker, _pending_target, hit_armor)
	if _pending_target.stats.strength <= 0:
		_kill_unit(_pending_target)
		_check_battle_end()
		if _battle_over:
			return
	_pending_target = null
	_turn_manager.end_turn()


func _do_player_move(unit: Unit, cell: Vector2i) -> void:
	_player_can_act = false
	var path := _build_screen_path(unit, cell)
	if path.is_empty():
		_player_can_act = true
		return
	_move_unit(unit, cell)
	await unit.move_along_path(path)
	_turn_manager.end_turn()


func _run_enemy_turn(unit: Unit) -> void:
	await get_tree().create_timer(0.5).timeout
	var target := _find_adjacent_player(unit)
	if target:
		var hit_armor := randi() % 2 == 0
		Combat.resolve_attack(unit, target, hit_armor)
		if target.stats.strength <= 0:
			_kill_unit(target)
			_check_battle_end()
			if _battle_over:
				return
	else:
		var cell := _pick_adjacent_cell(unit)
		if cell != Vector2i(unit.grid_col, unit.grid_row):
			var path := _build_screen_path(unit, cell)
			_move_unit(unit, cell)
			await unit.move_along_path(path)
	_turn_manager.end_turn()


func _move_unit(unit: Unit, cell: Vector2i) -> void:
	_unit_at.erase(Vector2i(unit.grid_col, unit.grid_row))
	unit.grid_col = cell.x
	unit.grid_row = cell.y
	_unit_at[cell] = unit


func _kill_unit(unit: Unit) -> void:
	_unit_at.erase(Vector2i(unit.grid_col, unit.grid_row))
	_turn_manager.remove_unit(unit)
	unit.queue_free()


func _check_battle_end() -> void:
	var has_player := false
	var has_enemy := false
	for u in _turn_manager.get_all_units():
		if u.is_player:
			has_player = true
		else:
			has_enemy = true
	if not has_enemy:
		_battle_over = true
		_result_screen.show_victory()
	elif not has_player:
		_battle_over = true
		_result_screen.show_defeat()


func _is_adjacent(a: Unit, b: Unit) -> bool:
	return abs(a.grid_col - b.grid_col) + abs(a.grid_row - b.grid_row) == 1


func _find_adjacent_player(unit: Unit) -> Unit:
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var cell := Vector2i(unit.grid_col + dir.x, unit.grid_row + dir.y)
		if _unit_at.has(cell) and _unit_at[cell].is_player:
			return _unit_at[cell]
	return null


func _pick_adjacent_cell(unit: Unit) -> Vector2i:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	dirs.shuffle()
	for dir in dirs:
		var candidate := Vector2i(unit.grid_col + dir.x, unit.grid_row + dir.y)
		if _is_valid_cell(candidate) and not _unit_at.has(candidate):
			return candidate
	return Vector2i(unit.grid_col, unit.grid_row)


func _build_screen_path(unit: Unit, cell: Vector2i) -> Array[Vector2]:
	var from_id := _cell_id(unit.grid_col, unit.grid_row)
	var to_id := _cell_id(cell.x, cell.y)
	var id_path := _astar.get_id_path(from_id, to_id)
	if id_path.size() <= 1:
		return []
	var screen_path: Array[Vector2] = []
	for id in id_path.slice(1):
		var point := _astar.get_point_position(id)
		screen_path.append(grid_to_screen(int(point.x), int(point.y)))
	return screen_path


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


func _setup_active_tile() -> void:
	_active_tile = Polygon2D.new()
	_active_tile.polygon = PackedVector2Array([
		Vector2(0, -TILE_HALF_H),
		Vector2(TILE_HALF_W, 0),
		Vector2(0, TILE_HALF_H),
		Vector2(-TILE_HALF_W, 0),
	])
	_active_tile.color = Color(1.0, 0.85, 0.0, 0.5)
	_active_tile.visible = false
	_floor.add_child(_active_tile)
	_active_tween = create_tween().set_loops()
	_active_tween.tween_property(_active_tile, "color:a", 0.2, 0.5)
	_active_tween.tween_property(_active_tile, "color:a", 0.5, 0.5)


func _setup_hover_tile() -> void:
	_hover_tile = Polygon2D.new()
	_hover_tile.polygon = PackedVector2Array([
		Vector2(0, -TILE_HALF_H),
		Vector2(TILE_HALF_W, 0),
		Vector2(0, TILE_HALF_H),
		Vector2(-TILE_HALF_W, 0),
	])
	_hover_tile.color = Color(1.0, 1.0, 0.5, 0.3)
	_hover_tile.visible = false
	_floor.add_child(_hover_tile)


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


func _place_players() -> void:
	var placements: Array = [
		[Vector2i(0, 0), "protagonist_stats.tres", Color.WHITE],
		[Vector2i(0, 2), "ally1_stats.tres",       Color(0.7, 0.9, 1.0)],
		[Vector2i(0, 4), "ally2_stats.tres",       Color(0.9, 0.7, 1.0)],
	]
	for p in placements:
		var unit := UNIT_SCENE.instantiate()
		unit.is_player = true
		unit.stats = load("res://data/" + p[1]).duplicate()
		unit.grid_col = p[0].x
		unit.grid_row = p[0].y
		unit.position = grid_to_screen(p[0].x, p[0].y)
		unit.modulate = p[2]
		_actors.add_child(unit)
		_unit_at[p[0]] = unit
		_players.append(unit)


func _place_enemies() -> void:
	var placements: Array = [
		[Vector2i(7, 7), "enemy_grunt_stats.tres"],
		[Vector2i(7, 5), "enemy_fast_stats.tres"],
		[Vector2i(7, 3), "enemy_tank_stats.tres"],
	]
	for p in placements:
		var unit := UNIT_SCENE.instantiate()
		unit.is_player = false
		unit.stats = load("res://data/" + p[1]).duplicate()
		unit.grid_col = p[0].x
		unit.grid_row = p[0].y
		unit.position = grid_to_screen(p[0].x, p[0].y)
		unit.modulate = Color(1.0, 0.3, 0.3)
		_actors.add_child(unit)
		_unit_at[p[0]] = unit
		_enemies.append(unit)
