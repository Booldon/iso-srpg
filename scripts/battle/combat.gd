class_name Combat


# Applies one attack in-place. Caller is responsible for checking death afterward (unit.is_alive()).
static func resolve_attack(attacker: Unit, target: Unit, hit_armor: bool) -> void:
	if hit_armor:
		if not target.stats.armor_reduction_immune:
			target.stats.armor = maxi(0, target.stats.armor - attacker.effective_strength())
	else:
		var dmg := maxi(0, attacker.effective_strength() - target.stats.armor)
		target.take_str_damage(dmg)
