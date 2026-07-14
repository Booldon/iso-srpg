class_name CardEffects


# attacker의 cards 배열을 순회하며 공격 시(on_attack) 효과를 target에 적용한다.
#
# 처리 순서 (카드별, [1] → [2]):
#
# [1] Burn 부여 (Burn 슬라이스 — 기존):
#   - on_attack_burn > 0:
#       Kindling 규칙(requires_burning == true)이고 target Burn = 0이면 스킵.
#       아니면 StatusEffects.add(target, BURN, card.on_attack_burn).
#
# [2] Detonation / burst (F1 슬라이스 — 신규):
#   a. 게이트: on_attack_min_burn > 0 이고 target Burn < on_attack_min_burn → 이 카드 스킵.
#   b. 소비: on_attack_consume_all_burn이면 전량, 아니면 on_attack_consume_burn 수만큼.
#   c. 버스트 = consumed × burst_per_stack + burst_flat.
#   d. burst > 0이면 target.take_str_damage(burst)  (방어 무시).
#
# 적 유닛은 cards == [] 이므로 자동 no-op.
# 기본값(모두 0/false)인 카드는 [1][2] 양쪽 모두 no-op.
#
# 호출 위치 (grid_manager):
#   Combat.resolve_attack(attacker, target, hit_armor)
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
			consumed = StatusEffects.consume(target, StatusEffects.Type.BURN, StatusEffects.MAX_STACK)
		elif card.on_attack_consume_burn > 0:
			consumed = StatusEffects.consume(target, StatusEffects.Type.BURN, card.on_attack_consume_burn)
		# 버스트 데미지 계산 및 방어 무시 적용
		var burst: int = consumed * card.on_attack_burst_per_stack + card.on_attack_burst_flat
		if burst > 0:
			target.take_str_damage(burst)


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
		if card.on_attack_aoe_fill_max:
			for u: Unit in splash_targets:
				var deficit: int = StatusEffects.MAX_STACK - StatusEffects.get_stacks(u, StatusEffects.Type.BURN)
				if deficit > 0:
					StatusEffects.add(u, StatusEffects.Type.BURN, deficit)
		# [C] Burn 보유 적 전체 방어 무시 버스트 (Wildfire Storm 2단계: [B] 이후 갱신된 스택 반영)
		if card.on_attack_aoe_burst_all_burning > 0:
			for u: Unit in all_enemies:
				if StatusEffects.get_stacks(u, StatusEffects.Type.BURN) > 0:
					u.take_str_damage(card.on_attack_aoe_burst_all_burning)


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
