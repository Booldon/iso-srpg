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
var _range_tiles: Array[Polygon2D] = []
var _reachable: Dictionary = {}  # Vector2i -> step count; cached by _show_move_range


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
		elif _is_valid_cell(cell) and not _unit_at.has(cell) and _is_in_move_range(active, cell):
			_do_player_move(active, cell)


func _on_turn_started(unit: Unit) -> void:
	if unit.is_player:
		# Soft-lock guard: if the unit can neither move nor attack, skip its turn automatically
		var reachable := _compute_reachable(unit)
		if reachable.is_empty() and _find_adjacent_enemy(unit) == null:
			_turn_manager.end_turn()
			return
		_player_can_act = true
		_show_move_range(unit)
	else:
		_clear_move_range()
		_run_enemy_turn(unit)


func _on_attack_armor() -> void:
	_execute_player_attack(true)


func _on_attack_strength() -> void:
	_execute_player_attack(false)


func _on_attack_cancel() -> void:
	_player_can_act = true
	_show_move_range(_turn_manager.current_unit())


func _execute_player_attack(hit_armor: bool) -> void:
	_clear_move_range()
	var attacker := _turn_manager.current_unit()
	attacker.face_toward_pos(_pending_target.position)
	Combat.resolve_attack(attacker, _pending_target, hit_armor)
	if _pending_target.stats.strength <= 0:
		_kill_unit(_pending_target)
		_check_battle_end()
		if _battle_over:
			return
	_pending_target = null
	_turn_manager.end_turn()


func _do_player_move(unit: Unit, cell: Vector2i) -> void:
	_clear_move_range()
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
		# Smart attack: prefer real damage; avoid wasting attack on immune armor
		var dmg := maxi(0, unit.stats.strength - target.stats.armor)
		var hit_armor: bool
		if dmg > 0:
			hit_armor = false  # can deal real damage — hit Strength
		else:
			hit_armor = not target.stats.armor_reduction_immune  # hit Armor only if target is not immune
		unit.face_toward_pos(target.position)
		Combat.resolve_attack(unit, target, hit_armor)
		if target.stats.strength <= 0:
			_kill_unit(target)
			_check_battle_end()
			if _battle_over:
				return
	else:
		# Approach the nearest living player unit
		var nearest := _find_nearest_player(unit)
		if nearest:
			var reachable := _compute_reachable(unit)
			var best_cell := Vector2i(unit.grid_col, unit.grid_row)
			var best_dist := absi(nearest.grid_col - unit.grid_col) + absi(nearest.grid_row - unit.grid_row)
			for cell: Vector2i in reachable.keys():
				var d := absi(nearest.grid_col - cell.x) + absi(nearest.grid_row - cell.y)
				if d < best_dist:
					best_dist = d
					best_cell = cell
			if best_cell != Vector2i(unit.grid_col, unit.grid_row):
				var path := _build_screen_path(unit, best_cell)
				_move_unit(unit, best_cell)
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
		var survivors: Array[String] = []
		for u in _turn_manager.get_all_units():
			if u.is_player:
				survivors.append(u.roster_path)
		GameState.apply_survivors(survivors)
		if GameState.is_campaign_complete():
			get_tree().change_scene_to_file("res://scenes/world/world_map.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/world/boon_screen.tscn")
	elif not has_player:
		_battle_over = true
		GameState.start_new_run()
		_result_screen.show_defeat()


# BFS: returns {Vector2i: steps} for all cells reachable within move_range,
# routing around occupied cells. The unit's own start cell is excluded from the result.
func _compute_reachable(unit: Unit) -> Dictionary:
	var result: Dictionary = {}
	var queue: Array = [{"cell": Vector2i(unit.grid_col, unit.grid_row), "steps": 0}]
	var visited: Dictionary = {Vector2i(unit.grid_col, unit.grid_row): true}
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not queue.is_empty():
		var entry = queue.pop_front()
		var cell: Vector2i = entry["cell"]
		var steps: int = entry["steps"]
		if steps > 0:
			result[cell] = steps
		if steps >= unit.stats.move_range:
			continue
		for dir in dirs:
			var nxt := cell + dir
			if not _is_valid_cell(nxt):
				continue
			if visited.has(nxt):
				continue
			if _unit_at.has(nxt) and _unit_at[nxt] != unit:
				continue  # blocked by another unit
			visited[nxt] = true
			queue.append({"cell": nxt, "steps": steps + 1})
	return result


# Sync A* disabled flags so paths route around all units except the mover itself.
func _sync_astar_occupancy(mover: Unit) -> void:
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var cell := Vector2i(col, row)
			var id := _cell_id(col, row)
			_astar.set_point_disabled(id, _unit_at.has(cell) and _unit_at[cell] != mover)


func _is_in_move_range(_unit: Unit, cell: Vector2i) -> bool:
	return _reachable.has(cell)


func _is_adjacent(a: Unit, b: Unit) -> bool:
	return abs(a.grid_col - b.grid_col) + abs(a.grid_row - b.grid_row) == 1


func _find_adjacent_player(unit: Unit) -> Unit:
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var cell := Vector2i(unit.grid_col + dir.x, unit.grid_row + dir.y)
		if _unit_at.has(cell) and _unit_at[cell].is_player:
			return _unit_at[cell]
	return null


func _find_adjacent_enemy(unit: Unit) -> Unit:
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var cell := Vector2i(unit.grid_col + dir.x, unit.grid_row + dir.y)
		if _unit_at.has(cell) and not _unit_at[cell].is_player:
			return _unit_at[cell]
	return null


func _find_nearest_player(unit: Unit) -> Unit:
	var nearest: Unit = null
	var best_dist := GRID_COLS * GRID_ROWS + 1  # greater than any possible Manhattan distance on this grid
	for u in _turn_manager.get_all_units():
		if not u.is_player:
			continue
		var d := absi(u.grid_col - unit.grid_col) + absi(u.grid_row - unit.grid_row)
		if d < best_dist:
			best_dist = d
			nearest = u
	return nearest


func _build_screen_path(unit: Unit, cell: Vector2i) -> Array[Vector2]:
	_sync_astar_occupancy(unit)
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


func _show_move_range(unit: Unit) -> void:
	_clear_move_range()
	_reachable = _compute_reachable(unit)
	for cell: Vector2i in _reachable.keys():
		var tile := Polygon2D.new()
		tile.polygon = PackedVector2Array([
			Vector2(0, -TILE_HALF_H),
			Vector2(TILE_HALF_W, 0),
			Vector2(0, TILE_HALF_H),
			Vector2(-TILE_HALF_W, 0),
		])
		tile.color = Color(0.2, 0.6, 1.0, 0.3)
		tile.position = grid_to_screen(cell.x, cell.y)
		_floor.add_child(tile)
		_range_tiles.append(tile)
	# Keep active and hover tiles rendered above range tiles
	_floor.move_child(_active_tile, -1)
	_floor.move_child(_hover_tile, -1)


func _clear_move_range() -> void:
	for tile in _range_tiles:
		tile.queue_free()
	_range_tiles.clear()
	_reachable.clear()


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
	var slots: Array = [
		[Vector2i(0, 0), Color.WHITE],
		[Vector2i(0, 2), Color(0.7, 0.9, 1.0)],
		[Vector2i(0, 4), Color(0.9, 0.7, 1.0)],
	]
	var living := GameState.get_living_party()
	for i in range(living.size()):
		var rec: Dictionary = living[i]
		var cell: Vector2i = slots[i][0]
		var unit := UNIT_SCENE.instantiate()
		unit.is_player = true
		unit.stats = load(rec["path"]).duplicate()
		BoonApplier.apply_ally_boons(unit.stats, GameState.active_boons)
		unit.roster_path = rec["path"]
		unit.grid_col = cell.x
		unit.grid_row = cell.y
		unit.position = grid_to_screen(cell.x, cell.y)
		unit.modulate = slots[i][1]
		_actors.add_child(unit)
		_unit_at[cell] = unit
		_players.append(unit)


func _place_enemies() -> void:
	var slots: Array[Vector2i] = [
		Vector2i(7, 7),
		Vector2i(7, 5),
		Vector2i(7, 3),
	]
	var stage := GameState.current_stage_data()
	if stage == null:
		push_error("GridManager: no stage data for index %d" % GameState.current_stage)
		return
	for i in range(stage.enemy_party.size()):
		if i >= slots.size():
			break
		var stats_res := stage.enemy_party[i] as UnitStats
		if stats_res == null:
			continue
		var cell := slots[i]
		var unit := UNIT_SCENE.instantiate()
		unit.is_player = false
		unit.stats = stats_res.duplicate()
		BoonApplier.apply_enemy_boons(unit.stats, GameState.active_boons)
		unit.grid_col = cell.x
		unit.grid_row = cell.y
		unit.position = grid_to_screen(cell.x, cell.y)
		unit.modulate = Color(1.0, 0.3, 0.3)
		_actors.add_child(unit)
		_unit_at[cell] = unit
		_enemies.append(unit)
