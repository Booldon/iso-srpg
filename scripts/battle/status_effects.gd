class_name StatusEffects

# Type: 상태이상 종류. int 값 0/1/2 고정 — unit.status 딕셔너리 키로 사용.
# 절대 변경 금지. 미래 슬라이스에서 값 추가만 허용.
enum Type {
	BURN  = 0,   # 턴 시작 시 STR 데미지 + 자연 감쇠
	FROST = 1,   # SPD 감소 (미구현, 예약됨)
	GUARD = 2    # AMR 증가 + 반격 (미구현, 예약됨)
}

# Burn 스택의 상한선. add() 호출 결과가 이 값을 초과하지 않도록 클램프.
# High Density 카드(max 7)는 이번 슬라이스 제외 — Epic 슬라이스에서 이 상수 확장 예정.
const MAX_STACK: int = 5
const BURN_DAMAGE_PER_STACK: int = 1
const BURN_DECAY_PER_TURN: int = 1


# unit.status[type] 에 amount 스택을 추가한다.
# 결과 스택 수 = clamp(현재 스택 수 + amount, 0, MAX_STACK).
# amount가 0 이하이면 no-op.
static func add(unit: Unit, type: Type, amount: int) -> void:
	if amount <= 0:
		return
	var current: int = unit.status.get(type, 0)
	unit.status[type] = clampi(current + amount, 0, MAX_STACK)


# unit.status[type] 의 현재 스택 수를 반환한다.
# unit.status에 해당 키가 없으면 0 반환 (KeyError 없음).
# 읽기 전용 — 이 함수는 unit.status를 수정하지 않음.
static func get_stacks(unit: Unit, type: Type) -> int:
	return unit.status.get(type, 0)


# unit.status[type] 에서 최대 amount 스택을 제거하고 실제 제거된 수를 반환한다.
# amount <= 0 이면 no-op, 0 반환.
# 호출자: CardEffects.apply_on_attack() 내 detonation 소비 처리.
static func consume(unit: Unit, type: Type, amount: int) -> int:
	if amount <= 0:
		return 0
	var current: int = unit.status.get(type, 0)
	var removed: int = mini(current, amount)
	unit.status[type] = current - removed
	return removed


# 해당 unit의 턴 시작 처리를 수행하고 실제 입힌 총 데미지를 반환한다.
#
# BURN 처리:
#   1. burn_stacks = get_stacks(unit, Type.BURN)
#   2. damage = burn_stacks × BURN_DAMAGE_PER_STACK  (고정값, 스탯 비례 없음)
#   3. unit.take_str_damage(damage)  (temp 버퍼 우선 차감 — F1 갱신)
#   4. unit.status[BURN] = max(0, burn_stacks - BURN_DECAY_PER_TURN)  (감쇠 -1/턴)
#   5. return damage
#
# FROST / GUARD: 아무 처리도 하지 않음 (no-op).
#
# 중요: 사망 판정은 이 함수의 책임이 아님 — 호출자(grid_manager)가 unit.is_alive() 체크 후 수행.
static func tick_turn_start(unit: Unit) -> int:
	var burn: int = get_stacks(unit, Type.BURN)
	if burn == 0:
		return 0
	var damage: int = burn * BURN_DAMAGE_PER_STACK
	unit.take_str_damage(damage)
	unit.status[Type.BURN] = maxi(0, burn - BURN_DECAY_PER_TURN)
	return damage
