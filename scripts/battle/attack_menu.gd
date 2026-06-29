extends CanvasLayer

signal armor_chosen
signal strength_chosen
signal cancelled

@onready var _hit_armor: Button = $Panel/VBoxContainer/HitArmor
@onready var _hit_strength: Button = $Panel/VBoxContainer/HitStrength
@onready var _cancel: Button = $Panel/VBoxContainer/Cancel


func _ready() -> void:
	_hit_armor.pressed.connect(func(): _choose(armor_chosen))
	_hit_strength.pressed.connect(func(): _choose(strength_chosen))
	_cancel.pressed.connect(func(): _choose(cancelled))


func show_menu() -> void:
	visible = true


func _choose(sig: Signal) -> void:
	visible = false
	sig.emit()
