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
