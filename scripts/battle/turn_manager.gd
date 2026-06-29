extends Node
class_name TurnManager

signal turn_started(unit: Unit)

var _units: Array[Unit] = []
var _index: int = 0


func start_battle(units: Array[Unit]) -> void:
	_units = units
	_index = 0
	turn_started.emit(_units[0])


func end_turn() -> void:
	_index = (_index + 1) % _units.size()
	turn_started.emit(_units[_index])


func current_unit() -> Unit:
	return _units[_index]
