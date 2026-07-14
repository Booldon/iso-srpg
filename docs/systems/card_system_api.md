# Card / Status-Effect System — API Contract

**Version:** 1.4 (F4 — Burn tick modifiers: White Heat, Smolder, High Density, Brittle Coat)
**Date:** 2026-07-15  
**Owner:** systems-designer  
**Status:** Confirmed — implementation may begin

이 문서는 combat-programmer, data-balancer, ui-programmer가 서로의 구현을 참조하지 않고
병렬로 작업할 수 있도록 작성된 **계약서**다.
각 계약에 명시된 필드명·타입·상수값·반환값은 **변경 불가**이며,
확장이 필요한 경우 반드시 이 문서를 먼저 업데이트하고 담당 에이전트에게 통보해야 한다.

---

## 계약 A — CardData Resource 스키마

**파일 위치:** `scripts/data/card_data.gd` (combat-programmer 소유)  
**소비자:**
- data-balancer: 이 스키마를 기반으로 `data/cards/*.tres` 파일 작성
- combat-programmer: `CardEffects` 구현 시 필드 읽기
- ui-programmer: **이 Resource를 직접 읽지 않음** — 카드 표시 데이터는 별도 UI 레이어에서 처리

```gdscript
extends Resource
class_name CardData

# Element: 카드가 속한 원소. NONE은 무속성(agnostic) 카드에 사용.
enum Element { NONE, FIRE, ICE, EARTH }

# Tier: 카드 등급. COMMON/RARE/EPIC 순서로 int 값 0/1/2 고정 (직렬화 키로 사용됨).
enum Tier { COMMON, RARE, EPIC }

@export var id: String = ""               # 고유 식별자. snake_case. 예: "ember", "kindling"
@export var title: String = ""            # 표시 이름 (한국어 가능). 예: "불씨"
@export var description: String = ""      # 카드 효과 설명 (UI 표시용 자연어)
@export var element: Element = Element.FIRE
@export var tier: Tier = Tier.RARE

# --- 에픽 전제조건 ---
# 비어있으면 조건없는 에픽(Epic 롤 시 항상 후보).
# 채워져 있으면 이 id들의 카드를 모두 보유해야 카드 풀에 등장. (tier가 EPIC일 때만 체크됨)
@export var prerequisite_card_ids: Array[String] = []

# --- 공격 시 Burn 부여 (Burn 슬라이스 — 구현됨) ---
# 일반 공격(resolve_attack) 직후 CardEffects.apply_on_attack()이 읽는 필드.
@export var on_attack_burn: int = 0
# true이면 대상의 Burn 스택이 0일 때 이 카드의 on_attack_burn을 적용하지 않음 (Kindling 규칙).
# false이면 대상의 Burn 스택과 무관하게 항상 적용.
@export var on_attack_burn_requires_burning: bool = false

# --- Detonation / burst 효과 (F1 슬라이스 — 구현됨) ---
# 게이트: 대상 Burn 스택이 on_attack_min_burn 이상일 때만 아래 detonation 필드가 발동.
# 0이면 게이트 없음 (항상 적용).
@export var on_attack_min_burn: int = 0

# 대상 Burn 스택 소비 수. 0이면 소비 없음.
# on_attack_consume_all_burn이 true면 이 값은 무시됨.
@export var on_attack_consume_burn: int = 0

# true이면 대상 Burn 스택을 전량 소비 (Grand Detonation 스타일).
# false이면 on_attack_consume_burn 수만큼 소비.
@export var on_attack_consume_all_burn: bool = false

# 소비한 스택 1개당 방어 무시 STR 데미지.
# 소비가 없는 경우(consume = 0, consume_all = false)에는 0 사용.
@export var on_attack_burst_per_stack: int = 0

# 스택 소비 없이 고정으로 방어 무시 보너스 데미지 (Overheat형).
# on_attack_min_burn 게이트를 통과했을 때만 발동.
# 소비 효과(consume)와 동시에 가질 수 있음.
@export var on_attack_burst_flat: int = 0

# --- Solar / temp STR 효과 (F1 슬라이스 — 구현됨) ---
# 전투 시작 시(배치 직후) 이 카드를 보유한 유닛 자신에게 부여하는 임시 Strength.
# temp_strength 버퍼에 쌓임 — 피해 시 base STR보다 먼저 깎임 (take_str_damage 규칙).
# 0이면 효과 없음.
@export var battle_start_temp_str_self: int = 0

# --- 전투 시작 스탯 보너스 (Common 슬라이스 — 구현됨) ---
# 배치 직후 unit.stats에 직접 더해지는 값. 음수면 패널티 (Trade-off 카드용).
# base stats 수정이므로 temp_strength와 달리 피해 시 일반 STR 차감 규칙을 따름.
# 모든 값의 기본은 0 (no-op).
#
# 적용 순서 (grid_manager._place_players):
#   unit.stats.strength  = max(1, unit.stats.strength  + sum(card.battle_start_str_bonus))
#   unit.stats.armor     = max(0, unit.stats.armor     + sum(card.battle_start_armor_bonus))
#   unit.stats.speed     = max(1, unit.stats.speed     + sum(card.battle_start_spd_bonus))
#   unit.stats.move_range= max(1, unit.stats.move_range+ sum(card.battle_start_move_bonus))
# Solar(temp) 합산과 동일한 루프에서 처리. 적 유닛은 cards==[] 이므로 자동 no-op.
@export var battle_start_str_bonus:   int = 0
@export var battle_start_armor_bonus: int = 0
@export var battle_start_spd_bonus:   int = 0
@export var battle_start_move_bonus:  int = 0

# --- 피격 반응 효과 (F2 슬라이스 — 구현됨) ---
# 아래 필드는 target(피격자)의 카드에서 읽힌다.
# 공격 직후 CardEffects.apply_on_hit(attacker, target) / get_incoming_multiplier(attacker, target) 에서 처리.

# 피격 시 공격자(attacker)에게 Burn을 부여한다 (Flame Retort 스타일).
# 0이면 no-op. 적 유닛은 cards == [] 이므로 자동 no-op.
@export var on_hit_burn_attacker: int = 0

# 피격 시 공격자(attacker)가 Burn 상태이면 받는 피해를 감소시킨다 (Ember Barrier 스타일).
# 값은 감소 비율 (0.0 ~ 1.0). 0.3 = 30% 감소 (dmg × 0.7). 곱셈적 합산.
# get_incoming_multiplier()가 반환하는 float 값이 Combat.resolve_attack(dmg_mult)에 전달됨.
# 0.0이면 no-op.
@export var on_hit_dmg_reduction_burning: float = 0.0

# 이 유닛의 인접 아군(player unit)이 피격될 때 그 공격자(attacker)에게 Burn을 부여한다 (Ashen Ward 스타일).
# 0이면 no-op. 처리 책임: grid_manager._apply_ashen_ward().
# "인접" 정의: 맨해튼 거리 = 1 (상하좌우 4방향).
@export var on_adjacent_ally_hit_burn_attacker: int = 0

# --- AoE + on-death 전이 (F3 슬라이스 — 구현됨) ---
# 이 카드를 보유한 유닛이 공격할 때 "splash 대상"(target + target에 인접한 살아있는 적)에 Burn을 부여 (Conflagration 스타일).
# splash 대상 계산 책임: grid_manager._splash_targets(target).
# 0이면 no-op.
@export var on_attack_aoe_burn: int = 0

# true이면 공격 시 splash 대상 각각의 Burn을 MAX_STACK까지 충전 (Wildfire Storm 1단계).
# on_attack_aoe_burn과 독립적으로 작동 (둘 다 갖는 카드는 없지만 문법상 허용).
# false이면 no-op.
@export var on_attack_aoe_fill_max: bool = false

# > 0이면 공격 시, fill_max/aoe_burn 처리 직후, Burn 스택이 남아있는 살아있는 적 **전체**에
# 이 값만큼 방어 무시 STR 데미지 (Wildfire Storm 2단계).
# "전체" 기준: grid_manager가 _living_enemies()로 전달하는 목록.
# 0이면 no-op.
@export var on_attack_aoe_burst_all_burning: int = 0

# true이면 이 카드를 보유한 유닛이 있을 때, Burn 스택을 가진 적이 죽으면
# 남은 스택의 절반(올림, ceili(stacks / 2.0))을 인접한 살아있는 적 하나에 전이한다 (Ember Trace 스타일).
# 발동 조건: 사망 유닛의 Burn > 0 AND 인접 살아있는 적 존재 AND 보유자 존재.
# 처리 책임: grid_manager._sweep_deaths() → CardEffects.transfer_burn_on_death().
# false이면 no-op.
@export var on_burn_kill_transfer_stacks: bool = false

# --- F4 틱 수정자 (구현됨) ---
# 아래 필드들은 attacker(공격자)의 카드에서 읽힌다 (on_attack_burn_max_override 제외).

# White Heat: 공격 시 대상의 다음 Burn 틱 데미지에 곱할 배수. 틱 적용 후 즉시 1.0으로 리셋.
# 1.0이면 no-op. 처리: apply_on_attack() [3] 블록 → target.burn_tick_mult_next = 이 값.
@export var on_attack_burn_tick_multiplier: float = 1.0

# Smolder: 공격 시 대상의 자연 Burn 감쇠를 2턴에 1회로 늦춤.
# false이면 no-op. 처리: apply_on_attack() [3] 블록 → target.burn_decay_slowed = true.
@export var on_attack_burn_decay_slow: bool = false

# High Density: 보유 시 전투 시작 시 모든 유닛의 Burn 상한을 이 값으로 올림 (예: 7).
# 0이면 no-op (기본 MAX_STACK=5 유지). on_attack이 아니라 전투 시작 시 grid_manager._setup_burn_caps()가 처리.
# 여러 카드가 있으면 최댓값 적용.
@export var on_attack_burn_max_override: int = 0

# Brittle Coat: Burn 스택이 임계 이상인 적의 유효 AMR을 지속 차감하는 양 (예: 2).
# 0이면 no-op. 처리 책임: grid_manager._refresh_burn_armor_debuffs() → enemy.burn_armor_debuff 갱신.
# 스택 소비 없음. Combat.resolve_attack()의 strength-hit 경로가 target.effective_armor()를 사용해 반영.
@export var on_burn_threshold_armor_debuff: int = 0

# Brittle Coat 발동 최소 Burn 스택. get_stacks(enemy, BURN) >= 이 값이면 디버프 활성.
# on_burn_threshold_armor_debuff == 0이면 이 값은 무시됨.
@export var on_burn_threshold_armor_min: int = 3
```

### CardData 불변 규칙

- 위 필드명·타입은 **절대 변경 불가**. 미래 슬라이스에서 필드를 **추가**하는 것만 허용.
- `id`는 `.tres` 파일명 기반으로 결정. 예: `card_ember.tres` → `id = "ember"`.
- 모든 int 필드의 기본값은 0, bool은 false, float은 1.0 (no-op). 기본값만 갖는 카드는 자동 no-op 처리됨.

---

## 계약 B — Unit 런타임 필드 및 메서드

**파일 위치:** `scripts/battle/unit.gd` (combat-programmer 소유)  
**소비자:**
- combat-programmer: `StatusEffects`, `CardEffects`, `Combat` 호출 시 인자·메서드로 사용
- ui-programmer: `unit.status` 딕셔너리를 `StatusEffects.get_stacks()` 경유로 읽음 (직접 접근 금지).
  `unit.effective_strength()`으로 현재 유효 STR 조회 가능 (UI 표시용).
- data-balancer: 이 필드/메서드를 직접 건드리지 않음

```gdscript
# ── 런타임 필드 (기존 — Burn 슬라이스에서 추가됨) ──────────────────────────
# unit이 현재 보유한 상태이상 스택 수.
# 키: StatusEffects.Type(int), 값: 스택 수(int).
# 배치 시 빈 딕셔너리로 초기화. 직접 읽기 금지 — StatusEffects.get_stacks() 경유 필수.
var status: Dictionary = {}

# 배치 시 grid_manager가 주입하는 카드 목록.
# 플레이어 유닛: GameState.active_cards 기반. 적 유닛: 항상 [].
# 런타임 전용 — UnitStats(.tres)에 저장하지 않음.
var cards: Array[CardData] = []

# ── 런타임 필드 (신규 — F1 슬라이스) ────────────────────────────────────────
# 이번 전투에만 유효한 임시 Strength (Solar/힐 카드가 부여).
# 배치 시 0으로 초기화. 전투 종료 후 폐기 (영구 저장하지 않음).
# 피해 시 base stats.strength보다 먼저 차감됨 (decisions_log "Temp STR depletion order").
var temp_strength: int = 0

# ── 런타임 필드 (신규 — F4 슬라이스) ────────────────────────────────────────
# High Density: 이 유닛의 Burn 스택 상한. 기본값 = StatusEffects.MAX_STACK(5).
# grid_manager._setup_burn_caps()이 전투 시작 시 보유 카드에 따라 상향 (예: 7). .tres 저장 안 함.
var burn_max: int = 5

# White Heat: 다음 tick_turn_start()에서 Burn 데미지에 곱할 배수. 틱 후 즉시 1.0으로 리셋.
# grid_manager._resolve_full_attack() → apply_on_attack() [3]이 설정. .tres 저장 안 함.
var burn_tick_mult_next: float = 1.0

# Smolder: 참이면 자연 Burn 감쇠가 2턴에 1회. apply_on_attack() [3]이 true로 설정.
# 한 번 설정되면 전투 내내 유지(리셋 없음). .tres 저장 안 함.
var burn_decay_slowed: bool = false

# Smolder 내부 토글: 이번 턴 감쇠를 건너뜀 여부. tick_turn_start()가 관리.
var _burn_decay_skip: bool = false

# Brittle Coat: grid_manager._refresh_burn_armor_debuffs()가 갱신하는 현재 AMR 차감량.
# Burn 임계 미달 시 0으로 복귀. 외부에서 직접 세팅 금지 — grid_manager만 갱신.
var burn_armor_debuff: int = 0


# ── 메서드 (신규 — F1 슬라이스) ─────────────────────────────────────────────
# 현재 유효 Strength = stats.strength + temp_strength.
# 공격력 계산(Combat.resolve_attack)과 사망 판정(grid_manager) 양쪽에서 이 값을 사용.
# 읽기 전용 계산 — unit의 상태를 수정하지 않음.
func effective_strength() -> int

# 이 유닛이 생존 중인지 반환. effective_strength() > 0 이면 생존.
# grid_manager의 사망 판정을 unit.stats.strength <= 0 대신 이 함수로 교체.
func is_alive() -> bool

# Strength 피해를 temp 버퍼 우선으로 차감한다.
#   1. from_temp = min(temp_strength, amount)
#   2. temp_strength -= from_temp
#   3. stats.strength = max(0, stats.strength - (amount - from_temp))
# 반환값: 없음(void). 사망 판정은 호출자(grid_manager / StatusEffects)의 책임.
# 적용 대상: STR hit 공격, Burn 틱 데미지, detonation burst — 모두 이 함수 경유.
func take_str_damage(amount: int) -> void

# ── 메서드 (신규 — F4 슬라이스) ─────────────────────────────────────────────
# 현재 유효 Armor = max(0, stats.armor - burn_armor_debuff).
# Combat.resolve_attack()의 strength-hit 경로가 stats.armor 대신 이 값을 사용.
# armor-hit(방어 차감 공격)는 base stats.armor를 직접 차감 (이 함수와 무관).
# 읽기 전용 계산 — unit의 상태를 수정하지 않음.
func effective_armor() -> int
```

### Unit 불변 규칙

- `status` 딕셔너리의 키 타입은 **반드시** `StatusEffects.Type`(int). 문자열 키 금지.
- `unit.status`를 직접 수정하는 코드는 `StatusEffects.add()` / `StatusEffects.consume()` 내부에만 존재. 그 외 위치에서 `unit.status[key] = value` 작성 금지.
- `cards` 배열은 배틀 외부에서 접근 금지.
- `take_str_damage()`를 우회하여 `stats.strength`나 `temp_strength`를 외부에서 직접 감산 금지.
- F4 신규 필드(`burn_max`, `burn_tick_mult_next`, `burn_decay_slowed`, `_burn_decay_skip`, `burn_armor_debuff`)는 배치 시 초기화, .tres 저장 안 함. `burn_armor_debuff`는 grid_manager만 갱신.

---

## 계약 C — StatusEffects 정적 API

**파일 위치:** `scripts/battle/status_effects.gd` (combat-programmer 소유)  
**소비자:**
- combat-programmer: `grid_manager.gd`의 턴 시작 훅에서 `tick_turn_start()` 호출,
  `CardEffects` 내부에서 `add()` / `get_stacks()` / `consume()` 호출
- ui-programmer: `get_stacks(unit, Type.BURN)`으로 화염 스택 수 조회 (UI 표시)
- qa-verifier: 단위 테스트 작성 시 이 API만 사용

```gdscript
class_name StatusEffects

# Type: 상태이상 종류. int 값 0/1/2 고정 — unit.status 딕셔너리 키로 사용.
# 절대 변경 금지. 미래 슬라이스에서 값 추가만 허용.
enum Type {
	BURN  = 0,   # 턴 시작 시 STR 데미지 + 자연 감쇠
	FROST = 1,   # SPD 감소 (미구현, 예약됨)
	GUARD = 2    # AMR 증가 + 반격 (미구현, 예약됨)
}

# Burn 스택의 기본 상한선. 비-BURN 타입(FROST, GUARD 등)의 클램프 기준.
# BURN의 실제 상한은 unit.burn_max (기본값 = MAX_STACK; High Density 보유 시 7로 상향).
const MAX_STACK: int = 5


# unit.status[type] 에 amount 스택을 추가한다.
# BURN 타입: 결과 스택 수 = clamp(현재 + amount, 0, unit.burn_max).
# 비-BURN 타입: 결과 스택 수 = clamp(현재 + amount, 0, MAX_STACK).
# amount가 0 이하이면 no-op.
# 호출자: CardEffects.apply_on_attack() 내부.
static func add(unit: Unit, type: Type, amount: int) -> void


# unit.status[type] 의 현재 스택 수를 반환한다.
# unit.status에 해당 키가 없으면 0 반환 (KeyError 없음).
# 읽기 전용 — unit.status를 수정하지 않음.
static func get_stacks(unit: Unit, type: Type) -> int


# unit.status[type] 에서 최대 amount 스택을 제거하고 실제 제거된 수를 반환한다. (F1 신규)
#
# 동작:
#   1. current = get_stacks(unit, type)
#   2. removed = min(current, amount)   (음수 방지: amount <= 0 이면 no-op, return 0)
#   3. unit.status[type] = current - removed
#   4. return removed
#
# 반환값: 실제 제거된 스택 수(int). 0이면 스택이 없었거나 amount <= 0.
# 호출자: CardEffects.apply_on_attack() 내부 (detonation 소비 처리).
static func consume(unit: Unit, type: Type, amount: int) -> int


# 해당 unit의 턴 시작 처리를 수행하고 실제 입힌 총 데미지를 반환한다.
#
# BURN 처리 (F4 갱신):
#   1. burn_stacks = get_stacks(unit, Type.BURN)
#   2. damage = roundi(burn_stacks × BURN_DAMAGE_PER_STACK × unit.burn_tick_mult_next)
#      (White Heat: burn_tick_mult_next = 2.0이면 틱 데미지 2배)
#   3. unit.burn_tick_mult_next = 1.0  ← 틱 후 즉시 리셋
#   4. unit.take_str_damage(damage)  ← temp 버퍼 우선 차감 (F1)
#   5. 자연 감쇠 (F4 갱신):
#      - unit.burn_decay_slowed == false: unit.status[BURN] = max(0, burn_stacks - BURN_DECAY_PER_TURN)  (매턴 -1)
#      - unit.burn_decay_slowed == true (Smolder):
#          if unit._burn_decay_skip:  감쇠 없이 skip = false로 전환
#          else: unit.status[BURN] = max(0, burn_stacks - BURN_DECAY_PER_TURN); skip = true
#          (→ 짝수 턴만 감쇠: 실질 감쇠 속도 절반)
#   6. return damage
#
# FROST / GUARD: 아무 처리도 하지 않음 (no-op).
#
# 반환값: 실제 입힌 데미지(int). 0이면 이 턴에 Burn 효과 없음.
# 중요: 사망 판정은 이 함수의 책임이 아님 — 호출자(grid_manager)가 수행.
static func tick_turn_start(unit: Unit) -> int
```

### StatusEffects 호출 순서 (grid_manager 구현 참고)

```gdscript
# 턴 시작 시 grid_manager에서 호출해야 하는 순서 (F1 갱신):
var burn_damage := StatusEffects.tick_turn_start(active_unit)
if burn_damage > 0 and not active_unit.is_alive():
	_kill_unit(active_unit)  # 기존 사망 처리 로직
	_check_battle_end()
	# ... 이후 처리
	return
```

---

## 계약 D — CardEffects 정적 API

**파일 위치:** `scripts/battle/card_effects.gd` (combat-programmer 소유)  
**소비자:**
- combat-programmer: `grid_manager.gd` 내 `resolve_attack()` 직후 호출

```gdscript
class_name CardEffects


# attacker의 cards 배열을 순회하며 공격 시(on_attack) 효과를 target에 적용한다.
#
# 처리 순서 (카드별로 순서대로):
#
# [1] Burn 부여 (Burn 슬라이스 — 기존):
#   - on_attack_burn > 0 인 카드:
#       → Kindling 규칙(on_attack_burn_requires_burning == true)이고 target Burn = 0이면 스킵.
#       → 아니면 StatusEffects.add(target, BURN, card.on_attack_burn) 호출.
#
# [2] Detonation / burst (F1 슬라이스 — 신규):
#   a. 게이트 체크:
#       - on_attack_min_burn > 0 이고 get_stacks(target, BURN) < on_attack_min_burn → 이 카드 스킵.
#   b. 스택 소비:
#       - on_attack_consume_all_burn == true → consumed = consume(target, BURN, get_stacks(target, BURN))
#           ★ 버그 수정(F4): MAX_STACK(5) 대신 실제 현재 스택 수를 전달해야 High Density(7스택) 시 전량 소비됨.
#       - 아니면 consumed = consume(target, BURN, card.on_attack_consume_burn)
#   c. 버스트 데미지 계산:
#       burst = consumed × card.on_attack_burst_per_stack + card.on_attack_burst_flat
#   d. 방어 무시 데미지 적용:
#       if burst > 0: target.take_str_damage(burst)
#       (armor를 무시 — Combat.resolve_attack()의 strength hit 경로와 달리 armor 차감 없음)
#
# [3] F4 틱 수정자 (신규 — Burn 부여 [1] 이후, detonation [2] 이후에 처리):
#   attacker.cards 순회:
#   - on_attack_burn_tick_multiplier > 1.0: target.burn_tick_mult_next = card.on_attack_burn_tick_multiplier
#     (같은 공격에 여러 White Heat류가 있으면 마지막 카드 값 적용 — 중복 불가 카드 설계 기준)
#   - on_attack_burn_decay_slow == true: target.burn_decay_slowed = true
#     (한 번 설정되면 전투 내내 유지 — 리셋 조건 없음)
#
# 순서 불변 규칙: [1] Burn 부여 → [2] Detonation → [3] 틱 수정자. 순서 역전 금지.
#
# 호출 위치 (grid_manager._resolve_full_attack → _sweep_deaths):
#   var dmg_mult := CardEffects.get_incoming_multiplier(attacker, target)
#   Combat.resolve_attack(attacker, target, hit_armor, dmg_mult)
#   CardEffects.apply_on_attack(attacker, target)
#   CardEffects.apply_on_hit(attacker, target)
#   grid_manager._apply_ashen_ward(attacker, target)
#   CardEffects.apply_on_attack_aoe(attacker, _splash_targets(target), _living_enemies())
#   grid_manager._refresh_burn_armor_debuffs()  ← F4 신규
#   grid_manager._sweep_deaths()
static func apply_on_attack(attacker: Unit, target: Unit) -> void


# target의 cards에서 on_hit_dmg_reduction_burning > 0.0인 것을 집계해
# Combat.resolve_attack()에 전달할 피해 배율을 반환한다 (F2 신규).
#
# 계산:
#   mult = 1.0
#   target.cards 순회: on_hit_dmg_reduction_burning > 0.0인 카드마다,
#     if StatusEffects.get_stacks(attacker, BURN) > 0: mult *= (1.0 - card.on_hit_dmg_reduction_burning)
#   return mult
#
# 반환값: float (1.0 = 감소 없음, 0.7 = 30% 감소).
# 여러 Ember Barrier 중첩 시 곱셈 합산 (1.0 × 0.7 × 0.7 = 0.49).
# 적 유닛 카드 없음(cards==[]) → 항상 1.0 반환.
# 호출 위치: grid_manager._resolve_full_attack() 내부, Combat.resolve_attack() 직전.
static func get_incoming_multiplier(attacker: Unit, target: Unit) -> float


# target의 cards에서 on_hit_burn_attacker > 0인 것을 집계해 attacker에게 Burn을 부여한다 (F2 신규).
#
# 처리:
#   target.cards 순회: on_hit_burn_attacker > 0인 카드마다
#     StatusEffects.add(attacker, Type.BURN, card.on_hit_burn_attacker)
#
# 적 유닛 cards == [] → 자동 no-op (player가 enemy를 칠 때 빈 루프).
# 호출 위치: grid_manager._resolve_full_attack() 내부, apply_on_attack() 직후.
static func apply_on_hit(attacker: Unit, target: Unit) -> void


# 공격 시 AoE 효과를 적용한다 (F3 신규).
#
# splash_targets: target + target에 인접한 살아있는 적 전체.
#   grid_manager._splash_targets(target)이 계산해서 전달.
# all_enemies: 살아있는 적 전체 목록 (grid_manager._living_enemies()).
#   burst_all_burning 계산에 사용 (fill_max 이후 갱신 필요 없음 — 같은 배열 참조).
#
# 처리 순서 (카드별, [A] → [B] → [C]):
#   [A] on_attack_aoe_burn > 0: splash_targets 각각에 StatusEffects.add(BURN, card.on_attack_aoe_burn).
#   [B] on_attack_aoe_fill_max: splash_targets 각각의 Burn을 unit.burn_max까지 충전.
#       deficit = u.burn_max - get_stacks(u, BURN); if deficit > 0: add(u, BURN, deficit).
#       ★ F4 갱신: MAX_STACK → u.burn_max (High Density 보유 시 7까지 충전).
#   [C] on_attack_aoe_burst_all_burning > 0: [A][B] 처리 후 all_enemies 순회 →
#       Burn 보유 유닛(get_stacks > 0)에 take_str_damage(card.on_attack_aoe_burst_all_burning) (방어 무시).
#
# 적 유닛은 cards == [] 이므로 자동 no-op (attacker가 적일 때).
# 호출 위치: grid_manager._resolve_full_attack() 내부, apply_on_hit() 직후.
static func apply_on_attack_aoe(attacker: Unit, splash_targets: Array[Unit], all_enemies: Array[Unit]) -> void


# Ember Trace: 불붙은 상태로 사망한 유닛의 Burn 스택 일부를 인접 살아있는 적에게 전이한다 (F3 신규).
#
# 인수:
#   dead_unit: 방금 사망 처리된 적 유닛 (_kill_unit 호출 전에 계산).
#   adjacent_enemies: dead_unit에 인접한 살아있는 적 목록 (grid_manager._adjacent_enemies_of(dead_unit)).
#   players: 살아있는 플레이어 유닛 목록 (grid_manager._living_players()).
#
# 발동 조건 (모두 충족 시에만):
#   1. get_stacks(dead_unit, BURN) > 0
#   2. adjacent_enemies가 비어 있지 않음
#   3. players 중 하나라도 on_burn_kill_transfer_stacks == true 카드 보유
#
# 전이량: ceili(stacks / 2.0). 결정론적: adjacent_enemies[0] (방향 순서상 첫 번째).
# 반환값: 없음 (void). 사망 판정/kill 처리는 호출자(grid_manager._sweep_deaths)의 책임.
# 호출 위치: grid_manager._sweep_deaths() 내부, _kill_unit(dead_unit) 직전.
static func transfer_burn_on_death(dead_unit: Unit, adjacent_enemies: Array[Unit], players: Array[Unit]) -> void
```

---

## 계약 E — Combat 데미지 계산 (F4 갱신)

**파일 위치:** `scripts/battle/combat.gd` (combat-programmer 소유)

```gdscript
# resolve_attack의 strength-hit 경로가 F4부터 target.effective_armor()를 사용한다.
#
# Strength hit (hit_armor == false):
#   var dmg := maxi(0, attacker.effective_strength() - target.effective_armor())  ← F4: stats.armor → effective_armor()
#   target.take_str_damage(roundi(dmg * dmg_mult))
#
# Armor hit (hit_armor == true):
#   if not target.stats.armor_reduction_immune:
#       target.stats.armor = maxi(0, target.stats.armor - roundi(attacker.effective_strength() * dmg_mult))
#   (armor-hit는 base stats.armor를 직접 차감 — effective_armor()와 무관)
```

---

## grid_manager F4 신규 함수 (combat-programmer 소유)

```gdscript
# 전투 시작 시 1회 호출 (배치 완료 직후).
# 플레이어 카드 중 on_attack_burn_max_override > 0인 최댓값을 구해,
# get_all_units() 전체 유닛의 burn_max를 그 값으로 세팅.
# 보유자 없으면 no-op (burn_max 기본값 5 유지).
func _setup_burn_caps() -> void

# Burn 스택 변동 후(공격 완료, 틱 처리 후) 호출해 Brittle Coat 디버프를 갱신한다.
# 플레이어 카드의 on_burn_threshold_armor_debuff 합산 → 각 적에 대해:
#   if get_stacks(enemy, BURN) >= card.on_burn_threshold_armor_min:
#       enemy.burn_armor_debuff += card.on_burn_threshold_armor_debuff
#   else: enemy.burn_armor_debuff = 0
# 호출 위치: _resolve_full_attack() 끝, _on_turn_started() 틱 처리 후.
func _refresh_burn_armor_debuffs() -> void
```

---

## 파일 소유권 매트릭스

한 파일은 정확히 한 에이전트만 소유한다.
소유자 외의 에이전트는 해당 파일을 **읽기만** 가능하며, 직접 수정하지 않는다.

| 파일 | 소유 에이전트 | 상태 |
|---|---|---|
| `scripts/data/card_data.gd` | combat-programmer | F4: `on_attack_burn_tick_multiplier`, `on_attack_burn_decay_slow`, `on_attack_burn_max_override`, `on_burn_threshold_armor_debuff`, `on_burn_threshold_armor_min` 추가 |
| `data/cards/*.tres` | data-balancer | F4: `card_white_heat`, `card_smolder`, `card_high_density`, `card_brittle_coat` 추가 |
| `scripts/battle/status_effects.gd` | combat-programmer | F4: `add()` BURN 상한 `unit.burn_max` 사용, `tick_turn_start()` 배수·감쇠 지연 갱신 |
| `scripts/battle/card_effects.gd` | combat-programmer | F4: `apply_on_attack()` [3] 틱 수정자 블록 추가, detonation consume-all 버그 수정, aoe fill_max `unit.burn_max` 기준 갱신 |
| `scripts/battle/unit.gd` | combat-programmer | F4: `burn_max`, `burn_tick_mult_next`, `burn_decay_slowed`, `_burn_decay_skip`, `burn_armor_debuff` 필드, `effective_armor()` 추가 |
| `scripts/battle/combat.gd` | combat-programmer | F4: strength-hit 경로가 `target.effective_armor()` 사용으로 갱신 |
| `scripts/battle/grid_manager.gd` | combat-programmer | F4: `_setup_burn_caps()`, `_refresh_burn_armor_debuffs()` 추가; `_resolve_full_attack()` 끝·턴 시작 후 디버프 갱신 호출 추가 |
| `scenes/battle/*.tscn` | ui-programmer | 변경 없음 |
| `scripts/battle/stats_panel.gd` | ui-programmer | F4: AMR 표시에 `burn_armor_debuff` 병기 (예: `ARM  3 (-2)`) |
| `docs/systems/card_system_api.md` | systems-designer | 이 문서 (계약 변경 시 먼저 여기 업데이트) |

---

## 불변 규칙 (decisions_log.md 요약)

이 규칙들은 이미 확정된 결정이다. 재협의 없이 임의 변경 금지.

| 규칙 | 값 | 근거 |
|---|---|---|
| Burn 틱 데미지 | `stacks × 1` STR (고정값) | 스탯 비례 없음 — decisions_log.md "Stack-based damage formulas" |
| Burn 자연 감쇠 | 턴당 -1 스택 (0 클램프) | 무한 DoT 스노볼 방지 — decisions_log.md "Per-element stack decay rules" |
| Frost / Guard 자연 감쇠 | 없음 (감쇠 없음) | Burn만 직접 데미지; 나머지 둘은 DoT 아님 |
| Kindling 규칙 | 대상 Burn = 0이면 on_attack_burn 미적용 | 증폭 전용 카드, from-scratch 적용 불가 |
| 기본 최대 스택 수 | 5 (MAX_STACK 상수) | High Density 보유 시 unit.burn_max = 7로 상향 (F4 구현됨) |
| Burn 틱 데미지 | `roundi(stacks × 1 × burn_tick_mult_next)` STR (고정값) | White Heat 배수 포함; 스탯 비례 없음 |
| RNG | 없음 | 완전 결정론적 — decisions_log.md "Combat resolution stays fully deterministic" |
| temp STR 성격 | 공격력·HP 양쪽 적용 (effective_strength()) | 단일 스탯 원칙 유지, Fire=버스트 정체성 강화 |
| temp STR 차감 순서 | temp 버퍼 먼저, 이후 base STR | decisions_log.md "Temp STR depletion order" |
| detonation 데미지 | 방어 무시 (armor 차감 없음) | 폭발 = 관통 페이오프 |
| strength-hit 유효 방어 | `target.effective_armor()` = `max(0, armor - burn_armor_debuff)` | Brittle Coat 지속 디버프 반영 (F4) |
| 사망 판정 책임 | grid_manager (`tick_turn_start` / `apply_on_attack` 호출 후 `is_alive()` 체크) | StatusEffects / CardEffects는 stats만 수정 |

---

## 미래 확장 계약 (예약 공간 — 현재 슬라이스에서 구현하지 않음)

구현 완료 슬라이스: F1(detonation+temp STR+Solar), F2(반응형 방어), F3(AoE+on-death 전이), F4(틱 수정자).
→ 해당 필드는 모두 계약 A CardData 스키마 참고.

### CardData에 추가될 필드 (예상 — Guard 슬라이스)

```gdscript
# Guard 슬라이스에서 추가 예정:
@export var on_hit_guard: int = 0
@export var on_hit_counter_damage_multiplier: float = 1.0
```

### StatusEffects에 추가될 동작

- **FROST (Type = 1):** SPD 감소 + 임계 시 Freeze (행동 취소) — Frost 슬라이스에서 명세
- **GUARD (Type = 2):** 피격 시 반격 + AMR 임시 증가 — Guard 슬라이스에서 명세
