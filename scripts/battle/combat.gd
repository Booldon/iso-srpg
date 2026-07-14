class_name Combat


# Applies one attack in-place. Caller is responsible for checking death afterward (unit.is_alive()).
# dmg_mult: pre-computed damage multiplier from CardEffects.get_incoming_multiplier() (default 1.0).
static func resolve_attack(attacker: Unit, target: Unit, hit_armor: bool, dmg_mult: float = 1.0) -> void:
	if hit_armor:
		if not target.stats.armor_reduction_immune:
			var arm_dmg := roundi(attacker.effective_strength() * dmg_mult)
			target.stats.armor = maxi(0, target.stats.armor - arm_dmg)
	else:
		var dmg := maxi(0, attacker.effective_strength() - target.stats.armor)
		target.take_str_damage(roundi(dmg * dmg_mult))
