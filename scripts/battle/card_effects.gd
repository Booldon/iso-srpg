class_name CardEffects

# Guard 반격의 스택당 고정 데미지 (decisions_log 규약: 스택 기반 데미지는 고정값, 스탯 비례 아님).
const GUARD_COUNTER_PER_STACK: int = 1


# attacker의 cards 배열을 순회하며 공격 시(on_attack) 효과를 target/attacker에 적용한다.
#
# 처리 순서 (카드별, [1] → [6], 순서 역전 금지):
#
# [1] Burn 부여 (target의 Burn 스택 증가)
# [2] Detonation / burst (target의 Burn 소비 → 방어 무시 데미지, F1)
# [3] F4 틱 수정자 (target.burn_tick_mult_next / burn_decay_slowed 설정)
# [4] Guard 자가 부여 (attacker 자신의 Guard 스택 증가, G1: Earthen Smite)
# [5] Guard 소비 버스트 (attacker 자신의 Guard 소비 → target 방어 무시 데미지 + Awakening 트리거, G2)
# [6] Fracture (attacker의 [5] 소비 이후 잔여 Guard만큼 target AMR 영구 차감, G2)
#
# 적 유닛은 cards == [] 이므로 자동 no-op. 기본값(모두 0/false)인 카드는 전 단계 no-op.
#
# 호출 위치 (grid_manager):
#   Combat.resolve_attack(attacker, target, hit_armor, dmg_mult)
#   CardEffects.apply_on_attack(attacker, target)
#   if not target.is_alive(): _kill_unit(target)
static func apply_on_attack(attacker: Unit, target: Unit) -> void:
	for card: CardData in attacker.cards:
		# [1] Burn 부여
		if card.on_attack_burn > 0:
			if card.on_attack_burn_requires_burning and StatusEffects.get_stacks(target, StatusEffects.Type.BURN) == 0:
				pass  # Kindling 규칙: 대상 Burn 없으면 스킵
			else:
				StatusEffects.add(target, StatusEffects.Type.BURN, card.on_attack_burn)

		# [2] Detonation / burst
		var has_detonation := (
			card.on_attack_consume_burn > 0
			or card.on_attack_consume_all_burn
			or card.on_attack_burst_flat > 0
		)
		if not has_detonation:
			continue
		# 게이트: 최소 Burn 스택 요건
		if card.on_attack_min_burn > 0 and StatusEffects.get_stacks(target, StatusEffects.Type.BURN) < card.on_attack_min_burn:
			continue
		# 소비량 결정
		var consumed: int = 0
		if card.on_attack_consume_all_burn:
			# F4 bug fix: pass actual current stacks, not MAX_STACK, so High Density (7 stacks) is fully consumed
			consumed = StatusEffects.consume(target, StatusEffects.Type.BURN, StatusEffects.get_stacks(target, StatusEffects.Type.BURN))
		elif card.on_attack_consume_burn > 0:
			consumed = StatusEffects.consume(target, StatusEffects.Type.BURN, card.on_attack_consume_burn)
		# 버스트 데미지 계산 및 방어 무시 적용
		var burst: int = consumed * card.on_attack_burst_per_stack + card.on_attack_burst_flat
		if burst > 0:
			target.take_str_damage(burst)

	# [3] F4 tick modifiers (White Heat, Smolder) — processed after [1] Burn grant and [2] detonation
	for card: CardData in attacker.cards:
		if card.on_attack_burn_tick_multiplier > 1.0:
			target.burn_tick_mult_next = card.on_attack_burn_tick_multiplier
		if card.on_attack_burn_decay_slow:
			target.burn_decay_slowed = true

	# [4] Guard 자가 부여 (G1: Earthen Smite) — attacker 자신에게 (target 아님)
	for card: CardData in attacker.cards:
		if card.on_attack_guard_self > 0:
			StatusEffects.add(attacker, StatusEffects.Type.GUARD, card.on_attack_guard_self)

	# [5] Guard 소비 버스트 (G2: Crush/Cataclysm) — attacker 자신의 Guard 소비, target에 방어 무시 데미지
	for card: CardData in attacker.cards:
		var has_guard_consume := card.on_attack_consume_guard_self > 0 or card.on_attack_consume_all_guard_self
		if not has_guard_consume:
			continue
		var consumed: int = 0
		if card.on_attack_consume_all_guard_self:
			consumed = StatusEffects.consume(attacker, StatusEffects.Type.GUARD, StatusEffects.get_stacks(attacker, StatusEffects.Type.GUARD))
		else:
			consumed = StatusEffects.consume(attacker, StatusEffects.Type.GUARD, card.on_attack_consume_guard_self)
		if consumed <= 0:
			continue
		var burst: int = consumed * card.on_attack_guard_burst_per_stack
		if burst > 0:
			target.take_str_damage(burst)
		# Awakening of Earth: 이 소비에 반응해 attacker 자신 영구 AMR 획득
		for c2: CardData in attacker.cards:
			if c2.on_guard_consumed_gain_armor > 0:
				attacker.stats.armor += consumed * c2.on_guard_consumed_gain_armor

	# [6] Fracture (G2) — [5] 소비 이후 attacker의 잔여 Guard만큼 target AMR 영구 차감 (소비 없음)
	for card: CardData in attacker.cards:
		if card.on_attack_armor_shred_by_guard:
			var g: int = StatusEffects.get_stacks(attacker, StatusEffects.Type.GUARD)
			if g > 0:
				target.stats.armor = maxi(0, target.stats.armor - g)


# attacker의 cards에서 on_guard_threshold_dmg_bonus 를 집계해 공격 배율을 반환한다 (G2, Center of
# Gravity). get_incoming_multiplier()(F2, target측 피해 감소)와 반대 방향 — 이건 attacker측
# 피해 증폭. 반환값: float (1.0 = 보너스 없음). Combat.resolve_attack(dmg_mult)에 전달.
static func get_outgoing_multiplier(attacker: Unit) -> float:
	var mult := 1.0
	for card: CardData in attacker.cards:
		if card.on_guard_threshold_dmg_bonus > 0.0:
			if StatusEffects.get_stacks(attacker, StatusEffects.Type.GUARD) >= card.on_guard_threshold_dmg_bonus_min:
				mult *= (1.0 + card.on_guard_threshold_dmg_bonus)
	return mult


# target의 cards에서 on_hit_dmg_reduction_burning 을 집계해 피해 배율을 반환한다 (F2).
# 반환값: float (1.0 = 감소 없음). Combat.resolve_attack(dmg_mult) 에 전달.
static func get_incoming_multiplier(attacker: Unit, target: Unit) -> float:
	var mult := 1.0
	for card: CardData in target.cards:
		if card.on_hit_dmg_reduction_burning > 0.0:
			if StatusEffects.get_stacks(attacker, StatusEffects.Type.BURN) > 0:
				mult *= (1.0 - card.on_hit_dmg_reduction_burning)
	return mult


# target의 cards에서 on_hit_burn_attacker 를 집계해 attacker에 Burn을 부여한다 (F2).
# 적 유닛은 cards == [] 이므로 자동 no-op.
static func apply_on_hit(attacker: Unit, target: Unit) -> void:
	for card: CardData in target.cards:
		if card.on_hit_burn_attacker > 0:
			StatusEffects.add(attacker, StatusEffects.Type.BURN, card.on_hit_burn_attacker)


# 공격 AoE 효과를 적용한다 (F3 신규).
# splash_targets: target + target에 인접한 살아있는 적 (grid_manager._splash_targets()가 전달).
# all_enemies: 살아있는 적 전체 (grid_manager._living_enemies()가 전달).
# 처리 순서: [A] aoe_burn → [B] fill_max → [C] burst_all_burning.
# 적 유닛(attacker)은 cards == [] 이므로 자동 no-op.
static func apply_on_attack_aoe(
		attacker: Unit,
		splash_targets: Array[Unit],
		all_enemies: Array[Unit]) -> void:
	for card: CardData in attacker.cards:
		# [A] AoE Burn 확산 (Conflagration)
		if card.on_attack_aoe_burn > 0:
			for u: Unit in splash_targets:
				StatusEffects.add(u, StatusEffects.Type.BURN, card.on_attack_aoe_burn)
		# [B] Burn MAX 충전 (Wildfire Storm 1단계)
		# F4: MAX_STACK → u.burn_max so High Density (burn_max=7) is respected
		if card.on_attack_aoe_fill_max:
			for u: Unit in splash_targets:
				var deficit: int = u.burn_max - StatusEffects.get_stacks(u, StatusEffects.Type.BURN)
				if deficit > 0:
					StatusEffects.add(u, StatusEffects.Type.BURN, deficit)
		# [C] Burn 보유 적 전체 방어 무시 버스트 (Wildfire Storm 2단계: [B] 이후 갱신된 스택 반영)
		if card.on_attack_aoe_burst_all_burning > 0:
			for u: Unit in all_enemies:
				if StatusEffects.get_stacks(u, StatusEffects.Type.BURN) > 0:
					u.take_str_damage(card.on_attack_aoe_burst_all_burning)


# Guard 반격 (G1 신규): target(피격자)이 Guard 스택 보유 시 attacker에 방어무시 반격 데미지.
# innate 효과 — 카드로 게이팅되지 않음(Guard 스택만 있으면 항상 발동). 스택 소비 없음.
# 반격 = stacks × GUARD_COUNTER_PER_STACK × counter_mult.
# counter_mult: target.cards의 counter_damage_multiplier 곱셈 합산 (Thorn Armor). 없으면 1.0.
# 적 유닛은 cards == [] 이므로 counter_mult는 항상 1.0 (하지만 적도 Guard 스택은 가질 수 있음).
# 사망 판정은 호출자(grid_manager._sweep_deaths)의 책임.
static func apply_guard_counter(attacker: Unit, target: Unit) -> void:
	var stacks: int = StatusEffects.get_stacks(target, StatusEffects.Type.GUARD)
	if stacks <= 0:
		return
	var mult := 1.0
	for card: CardData in target.cards:
		if card.counter_damage_multiplier > 1.0:
			mult *= card.counter_damage_multiplier
	var counter: int = roundi(stacks * GUARD_COUNTER_PER_STACK * mult)
	if counter > 0:
		attacker.take_str_damage(counter)


# Ember Trace: 불붙은 상태로 사망한 적의 Burn 스택 절반(올림)을 인접 적에 전이한다 (F3 신규).
# dead_unit: 사망 처리 직전의 적 유닛 (_kill_unit 호출 전에 call).
# adjacent_enemies: dead_unit에 인접한 살아있는 적 (grid_manager._adjacent_enemies_of(dead_unit)).
# players: 살아있는 플레이어 유닛 (grid_manager._living_players()).
# 발동 조건: dead_unit.Burn > 0 AND adjacent_enemies 비어있지 않음 AND players 중 보유자 존재.
static func transfer_burn_on_death(
		dead_unit: Unit,
		adjacent_enemies: Array[Unit],
		players: Array[Unit]) -> void:
	var stacks: int = StatusEffects.get_stacks(dead_unit, StatusEffects.Type.BURN)
	if stacks <= 0 or adjacent_enemies.is_empty():
		return
	# 보유자 확인: players 중 하나라도 on_burn_kill_transfer_stacks == true 카드 보유 시 발동
	var owns: bool = false
	for p: Unit in players:
		for card: CardData in p.cards:
			if card.on_burn_kill_transfer_stacks:
				owns = true
				break
		if owns:
			break
	if not owns:
		return
	# 결정론적: adjacent_enemies[0] (4방향 순서상 첫 번째 인접 적)
	var transfer: int = ceili(stacks / 2.0)
	StatusEffects.add(adjacent_enemies[0], StatusEffects.Type.BURN, transfer)
