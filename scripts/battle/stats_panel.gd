extends CanvasLayer

@onready var _header: Label = $Panel/VBox/Header
@onready var _str_label: Label = $Panel/VBox/StrLabel
@onready var _arm_label: Label = $Panel/VBox/ArmLabel
@onready var _spd_label: Label = $Panel/VBox/SpdLabel


func show_unit(unit: Unit) -> void:
	_header.text = "[ PLAYER ]" if unit.is_player else "[ ENEMY ]"
	# Show effective STR; if temp > 0, append "(+temp)" so player can see the bonus
	if unit.temp_strength > 0:
		_str_label.text = "STR  %d (+%d)" % [unit.stats.strength, unit.temp_strength]
	else:
		_str_label.text = "STR  " + str(unit.stats.strength)
	_arm_label.text = "ARM  " + str(unit.stats.armor)
	_spd_label.text = "SPD  " + str(unit.stats.speed)
	var burn := StatusEffects.get_stacks(unit, StatusEffects.Type.BURN)
	if burn > 0:
		_spd_label.text += "    BURN " + str(burn)
