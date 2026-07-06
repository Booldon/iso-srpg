class_name BoonApplier


# Applies all ALLY_BUFF boons to the given stats (mutates in place).
static func apply_ally_boons(stats: UnitStats, boon_paths: Array[String]) -> void:
	for path in boon_paths:
		var boon := load(path) as BoonData
		if boon == null or boon.target != BoonData.Target.ALLY_BUFF:
			continue
		_apply(stats, boon, 1)


# Applies all ENEMY_DEBUFF boons to the given stats (mutates in place).
static func apply_enemy_boons(stats: UnitStats, boon_paths: Array[String]) -> void:
	for path in boon_paths:
		var boon := load(path) as BoonData
		if boon == null or boon.target != BoonData.Target.ENEMY_DEBUFF:
			continue
		_apply(stats, boon, -1)


static func _apply(stats: UnitStats, boon: BoonData, sign: int) -> void:
	var delta := boon.amount * sign
	match boon.stat:
		BoonData.Stat.STRENGTH:
			stats.strength   = maxi(1, stats.strength + delta)
		BoonData.Stat.ARMOR:
			stats.armor      = maxi(0, stats.armor + delta)
		BoonData.Stat.SPEED:
			stats.speed      = maxi(1, stats.speed + delta)
		BoonData.Stat.MOVE_RANGE:
			stats.move_range = maxi(1, stats.move_range + delta)
