class_name Combat


# Applies one attack in-place. Caller is responsible for checking death afterward.
static func resolve_attack(attacker: Unit, target: Unit, hit_armor: bool) -> void:
	if hit_armor:
		if not target.stats.armor_reduction_immune:
			target.stats.armor = maxi(0, target.stats.armor - attacker.stats.strength)
	else:
		var dmg := maxi(0, attacker.stats.strength - target.stats.armor)
		target.stats.strength = maxi(0, target.stats.strength - dmg)
