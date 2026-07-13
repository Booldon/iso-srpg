# Card / Status-Effect System — API Contract

**Version:** 1.0  
**Date:** 2026-07-13  
**Owner:** systems-designer  
**Status:** Confirmed — implementation may begin

이 문서는 combat-programmer, data-balancer, ui-programmer가 서로의 구현을 참조하지 않고
병렬로 작업할 수 있도록 작성된 **계약서**다.
각 계약에 명시된 필드명·타입·상수값·반환값은 **변경 불가**이며,
확장이 필요한 경우 반드시 이 문서를 먼저 업데이트하고 담당 에이전트에게 통보해야 한다.

---

## 계약 A — CardData Resource 스키마

**파일 위치:** `scripts/data/card_data.gd` (combat-programmer 생성)  
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

# --- 공격 시 Burn 효과 ---
# 일반 공격(resolve_attack) 직후 CardEffects.apply_on_attack()이 읽는 필드.
@export var on_attack_burn: int = 0
# true이면 대상의 Burn 스택이 0일 때 이 카드의 on_attack_burn을 적용하지 않음 (Kindling 규칙).
# false이면 대상의 Burn 스택과 무관하게 항상 적용.
@export var on_attack_burn_requires_burning: bool = false
```

### CardData 불변 규칙

- 위 필드명·타입은 **절대 변경 불가**. 미래 슬라이스에서 필드를 **추가**하는 것만 허용.
- `id`는 `.tres` 파일명 기반으로 결정. 예: `card_ember.tres` → `id = "ember"`.
- `on_attack_burn = 0`이고 향후 추가 필드도 모두 0/false인 카드는 `CardEffects.apply_on_attack()`에서 자동으로 no-op 처리됨.

---

## 계약 B — Unit 런타임 필드

**파일 위치:** `scripts/battle/unit.gd` (combat-programmer가 기존 Unit 클래스에 추가)  
**소비자:**
- combat-programmer: `StatusEffects`, `CardEffects` 호출 시 인자로 전달
- ui-programmer: `unit.status` 딕셔너리를 `StatusEffects.get_stacks()` 경유로 읽음 (직접 접근 금지)
- data-balancer: 이 필드를 직접 건드리지 않음

```gdscript
# 기존 Unit 클래스에 추가되는 두 필드:

# unit이 현재 보유한 상태이상 스택 수.
# 키: StatusEffects.Type(int), 값: 스택 수(int).
# 배틀 시작 시(grid_manager._place_players / _place_enemies) 반드시 빈 딕셔너리로 초기화.
# 직접 읽기 금지 — 반드시 StatusEffects.get_stacks()를 통해 접근.
var status: Dictionary = {}

# 배치 시 grid_manager가 주입하는 카드 목록.
# 플레이어 유닛: GameState에서 로드한 해당 유닛의 보유 카드 Array.
# 적 유닛: 항상 빈 배열 [] (적은 카드를 사용하지 않음).
# 런타임 전용 — .tres(UnitStats)에 저장하지 않음.
var cards: Array[CardData] = []
```

### Unit 필드 불변 규칙

- `status` 딕셔너리의 키 타입은 **반드시** `StatusEffects.Type`(int)이어야 한다. 문자열 키 금지.
- `cards` 배열은 배틀이 끝나면 참조가 유효하다는 보장이 없다. 배틀 외부에서 접근 금지.
- `unit.status`를 직접 수정하는 코드는 `StatusEffects.add()` 내부에만 존재해야 한다. 그 외 위치에서 `unit.status[key] = value` 형태 작성 금지.

---

## 계약 C — StatusEffects 정적 API

**파일 위치:** `scripts/battle/status_effects.gd` (combat-programmer 신규 생성)  
**소비자:**
- combat-programmer: `grid_manager.gd`의 턴 시작 훅에서 `tick_turn_start()` 호출, `CardEffects` 내부에서 `add()` / `get_stacks()` 호출
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

# Burn 스택의 상한선. add() 호출 결과가 이 값을 초과하지 않도록 클램프.
# High Density 카드(max 7)는 이번 슬라이스 제외 — Epic 슬라이스에서 이 상수 확장 예정.
const MAX_STACK: int = 5


# unit.status[type] 에 amount 스택을 추가한다.
# 결과 스택 수 = clamp(현재 스택 수 + amount, 0, MAX_STACK).
# amount가 0 이하이면 no-op.
# 호출자: CardEffects.apply_on_attack() (내부), 미래 반격 카드 로직.
static func add(unit: Unit, type: Type, amount: int) -> void


# unit.status[type] 의 현재 스택 수를 반환한다.
# unit.status에 해당 키가 없으면 0 반환 (KeyError 없음).
# 읽기 전용 — 이 함수는 unit.status를 수정하지 않음.
static func get_stacks(unit: Unit, type: Type) -> int


# 해당 unit의 턴 시작 처리를 수행하고 실제 입힌 총 데미지를 반환한다.
#
# BURN 처리 (현재 슬라이스에서 구현):
#   1. burn_stacks = get_stacks(unit, Type.BURN)
#   2. damage = burn_stacks * 1  (고정값, 스탯 비례 없음 — decisions_log.md 참조)
#   3. unit.stats.strength -= damage  (temp_str 버퍼 → base_str 순 차감은 combat.gd와 동일한 규칙)
#   4. unit.status[BURN] = max(0, burn_stacks - 1)  (감쇠 -1/턴)
#   5. return damage
#
# FROST / GUARD: 이번 슬라이스에서 아무 처리도 하지 않음 (no-op).
#
# 반환값: 실제 입힌 데미지(int). 0이면 이 턴에 Burn 효과 없음.
#
# 중요: 사망 판정(strength <= 0 체크 및 유닛 제거)은 이 함수의 책임이 아님.
#        호출자(grid_manager)가 반환값을 확인한 후 직접 사망 판정 수행.
static func tick_turn_start(unit: Unit) -> int
```

### StatusEffects 호출 순서 (grid_manager 구현 참고)

```
# 턴 시작 시 grid_manager에서 호출해야 하는 순서:
var burn_damage := StatusEffects.tick_turn_start(active_unit)
if burn_damage > 0 and active_unit.stats.strength <= 0:
    _handle_unit_death(active_unit)  # 기존 사망 처리 로직
    return  # 이미 죽었으면 이 유닛의 일반 행동 생략
```

---

## 계약 D — CardEffects 정적 API

**파일 위치:** `scripts/battle/card_effects.gd` (combat-programmer 신규 생성)  
**소비자:**
- combat-programmer: `grid_manager.gd` 내 `resolve_attack()` 직후 호출

```gdscript
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
#   Combat.resolve_attack(attacker, target, hit_armor)  ← 기존 호출
#   CardEffects.apply_on_attack(attacker, target)       ← 이 함수 (신규 추가)
#   if target.stats.strength <= 0: _handle_unit_death(target)  ← 기존 사망 판정
static func apply_on_attack(attacker: Unit, target: Unit) -> void
```

---

## 파일 소유권 매트릭스

한 파일은 정확히 한 에이전트만 소유한다.
소유자 외의 에이전트는 해당 파일을 **읽기만** 가능하며, 직접 수정하지 않는다.

| 파일 | 소유 에이전트 | 비고 |
|---|---|---|
| `scripts/data/card_data.gd` | combat-programmer | CardData 클래스 정의 |
| `data/cards/*.tres` | data-balancer | CardData 인스턴스 (값 작성) |
| `scripts/battle/status_effects.gd` | combat-programmer | StatusEffects 클래스 신규 생성 |
| `scripts/battle/card_effects.gd` | combat-programmer | CardEffects 클래스 신규 생성 |
| `scripts/battle/unit.gd` | combat-programmer | `status`, `cards` 필드 추가 |
| `scripts/battle/grid_manager.gd` | combat-programmer | tick_turn_start 훅, apply_on_attack 훅 삽입 |
| `scripts/battle/combat.gd` | combat-programmer | 현재 슬라이스에서 수정 없음 |
| `scenes/battle/*.tscn` | ui-programmer | Burn 스택 수 HUD 노드 추가 |
| `scripts/battle/stats_panel.gd` | ui-programmer | get_stacks 호출로 Burn 표시 갱신 |
| `docs/systems/card_system_api.md` | systems-designer | 이 문서 (계약 변경 시 먼저 여기 업데이트) |

---

## 불변 규칙 (decisions_log.md 요약)

이 규칙들은 이미 확정된 결정이다. 재협의 없이 임의 변경 금지.

| 규칙 | 값 | 근거 |
|---|---|---|
| Burn 틱 데미지 | `stacks × 1` STR (고정값) | 스탯 비례 없음 — decisions_log.md "Stack-based damage formulas" |
| Burn 자연 감쇠 | 턴당 -1 스택 (0 클램프) | 무한 DoT 스노볼 방지 — decisions_log.md "Per-element stack decay rules" |
| Frost / Guard 자연 감쇠 | 없음 (감쇠 없음) | Burn만 직접 데미지; 나머지 둘은 DoT 아님 |
| Kindling 규칙 | 대상 Burn = 0이면 0 적용 | 증폭 전용 카드, from-scratch 적용 불가 |
| 최대 스택 수 | 5 | High Density(max 7) 확장은 Epic 슬라이스까지 보류 |
| RNG | 없음 | 완전 결정론적 — decisions_log.md "Combat resolution stays fully deterministic" |
| temp STR 차감 순서 | temp 버퍼 먼저, 이후 base STR | decisions_log.md "Temp STR depletion order" |
| 사망 판정 책임 | grid_manager (tick_turn_start / apply_on_attack 호출 후) | StatusEffects / CardEffects는 stats만 수정 |

---

## 미래 확장 계약 (예약 공간 — 현재 슬라이스에서 구현하지 않음)

Frost / Guard 슬라이스가 시작되기 전에 이 문서를 업데이트해야 한다.
아래 항목은 예약된 확장 포인트이며, 이번 슬라이스에서는 코드를 작성하지 않는다.

### CardData에 추가될 필드 (예상)

```gdscript
# Frost 슬라이스에서 추가 예정:
@export var on_attack_frost: int = 0               # 공격 시 부여할 Frost 스택 수
@export var on_attack_frost_requires_frost: bool = false  # Kindling 패턴 동일하게 적용 가능성

# Guard 슬라이스에서 추가 예정:
@export var on_hit_guard: int = 0                  # 피격 시 자신에게 부여할 Guard 스택 수
@export var on_hit_counter_damage_multiplier: float = 1.0  # Thorn Armor "doubled" 반영 (기본 1.0 = 배율 없음)

# 미래 가능성 (Epic/agnostic 슬라이스):
@export var on_attack_burn_consume_all: bool = false   # Grand Detonation 스타일 전소 소비
@export var on_attack_burst_damage: int = 0            # 소비 후 즉발 데미지 고정값 (스탯 비례 아님)
```

### StatusEffects에 추가될 동작

- **FROST (Type = 1):**
  - `add()`: 현재 슬라이스와 동일하게 작동 (스택 클램프)
  - `tick_turn_start()` 내 FROST 처리: SPD 감소 적용 (감쇠 없음 — 명세 필요)
  - 최대 스택 도달 시 Freeze 발동: 해당 유닛의 이번 턴 행동 취소 + 스택 0 리셋 (threshold-effect stack consumption 규칙 적용)
  - Freeze 발동은 `tick_turn_start()`가 아니라 별도 `check_freeze(unit)` API가 필요할 수 있음 — Frost 슬라이스에서 결정

- **GUARD (Type = 2):**
  - `add()`: 현재 슬라이스와 동일하게 작동 (스택 클램프)
  - `tick_turn_start()` 내 GUARD 처리: no-op (감쇠 없음)
  - 피격 시 반격 (`stacks × 1` 갑옷 관통 데미지) — `on_hit_counter()` API 신규 추가 예정
  - AMR 증가는 스택 수에 비례하여 `UnitStats.armor`를 임시 증가 (배틀 종료 시 원복 필요) — 구현 방식 미확정

### MAX_STACK 확장

- High Density 카드(`on_attack_burn_max_override: int = 7` 필드 추가 예정) 구현 시
  `StatusEffects.MAX_STACK`을 전역 상수로 유지할지, 유닛별 per-unit 오버라이드로 바꿀지 결정 필요.
  현재 슬라이스에서는 전역 상수 5 고정.
