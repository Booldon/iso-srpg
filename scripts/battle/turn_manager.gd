extends Node
class_name TurnManager

signal turn_started(unit: Unit)

var _units: Array[Unit] = []
var _index: int = 0


func start_battle(units: Array[Unit]) -> void:
	var players: Array[Unit] = []
	var enemies: Array[Unit] = []
	for u in units:
		if u.is_player:
			players.append(u)
		else:
			enemies.append(u)

	# Sort each team by speed descending
	players.sort_custom(func(a, b): return a.stats.speed > b.stats.speed)
	enemies.sort_custom(func(a, b): return a.stats.speed > b.stats.speed)

	# Pair up by rank; the faster unit in each pair acts first (1:1 alternation preserved)
	_units.clear()
	var pair_count := mini(players.size(), enemies.size())
	for i in range(pair_count):
		if players[i].stats.speed >= enemies[i].stats.speed:
			_units.append(players[i])
			_units.append(enemies[i])
		else:
			_units.append(enemies[i])
			_units.append(players[i])

	# Leftover units when team sizes differ
	for i in range(pair_count, players.size()):
		_units.append(players[i])
	for i in range(pair_count, enemies.size()):
		_units.append(enemies[i])

	_index = 0
	turn_started.emit(_units[0])


func end_turn() -> void:
	_index = (_index + 1) % _units.size()
	turn_started.emit(_units[_index])


func current_unit() -> Unit:
	return _units[_index]
