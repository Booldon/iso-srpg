class_name CardEffects


# attacker의 cards 배열을 순회하며 공격 시(on_attack) 효과를 target에 적용한다.
#
# 현재 슬라이스에서 처리하는 필드:
#   - on_attack_burn > 0 인 카드:
#       → StatusEffects.add(target, StatusEffects.Type.BURN, card.on_attack_burn) 호출.
#
#   - Kindling 규칙 (on_attack_burn_requires_burning == true):
#       → StatusEffects.get_stacks(target, StatusEffects.Type.BURN) == 0 이면
#         해당 카드의 on_attack_burn을 적용하지 않고 넘어감 (스킵).
#       → 이미 Burn > 0 이면 정상 적용.
#
# 적 유닛(Unit.is_player == false)은 cards가 항상 빈 배열이므로 자동 no-op.
# on_attack_burn == 0 인 카드는 아무 효과 없이 패스.
#
# 호출 위치: grid_manager 내 공격 해결 직후, 사망 판정 이전.
static func apply_on_attack(attacker: Unit, target: Unit) -> void:
	for card: CardData in attacker.cards:
		if card.on_attack_burn > 0:
			if card.on_attack_burn_requires_burning and StatusEffects.get_stacks(target, StatusEffects.Type.BURN) == 0:
				continue
			StatusEffects.add(target, StatusEffects.Type.BURN, card.on_attack_burn)
