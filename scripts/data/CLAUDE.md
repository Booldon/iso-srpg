# scripts/data/ — Resource 스크립트

## Files

| 파일 | 역할 |
|---|---|
| `unit_stats.gd` | `class_name UnitStats`. 유닛 스탯 Resource (STR/ARM/SPD/MOVE + `armor_reduction_immune`) |
| `party_roster.gd` | `class_name PartyRoster`. 파티 멤버 목록 Resource. `members: Array[Resource]`로 UnitStats .tres 참조 |
| `stage_data.gd` | `class_name StageData`. 스테이지(전투 1회) Resource. title + `enemy_party: Array[Resource]`(UnitStats) |
| `campaign.gd` | `class_name Campaign`. 캠페인 Resource. `stages: Array[Resource]`(StageData) |
| `card_data.gd` | `class_name CardData`. 카드 Resource. Element·Tier·효과 필드 + `prerequisite_card_ids` (에픽 전제 조건) |
| `card_draw_config.gd` | `class_name CardDrawConfig`. 카드 추첨 확률·천장 수치 Resource. 코드 수정 없이 밸런싱. |
| `card_draw.gd` | `class_name CardDraw`. 순수 static. 등급 롤·후보 필터·가중 추출 담당 |
| `debug_scenario.gd` | `class_name DebugScenario`. 디버그 메뉴 시나리오 Resource |

> **용어 주의**: 여기서 "스테이지" = 전투 1회 단위. `roguelike-layer-design.md`가 말하는
> "챕터"(스테이지 5개를 묶는 상위 단위 + 챕터엔드 시퀀스)는 아직 코드에 없다 —
> 로그라이크 레이어를 실제로 구현할 때 Campaign과 StageData 사이에 새로 추가해야 할 개념.

## 연결 데이터 파일 (data/)

| 파일/폴더 | 설명 |
|---|---|
| `protagonist_stats.tres` ~ `enemy_tank_stats.tres` | 각 유닛의 스탯 (스테이지1 적 포함) |
| `enemy_grunt_stage2_stats.tres` ~ `enemy_tank_stage3_stats.tres` | 스테이지 2·3 전용 적 스탯 |
| `default_party.tres` | `PartyRoster` 인스턴스. 신규 게임 기본 파티 3명 참조 |
| `cards/card_*.tres` | CardData 인스턴스. 전투 승리 후 카드 선택 화면 풀. 추가 = 파일만 넣으면 자동 스캔. |
| `card_draw_config.tres` | CardDrawConfig 인스턴스 1개. 추첨 가중치·천장·에픽 보정 수치 |
| `stages/stage_1..3.tres` | StageData 인스턴스. 각 스테이지의 적 구성 |
| `campaign.tres` | Campaign 인스턴스. 스테이지 순서 정의 |

## 카드 추첨 시스템 (CardDraw)

### 등급 결정 흐름
1. `CardDraw.roll_tier(cfg, stages_since_rare, rng)` → 등급 1개 결정
   - `stages_since_rare >= rare_pity_hard_cap` → Rare 확정 (하드 천장)
   - 아니면 `{common, rare + stages*bonus, epic}` 가중치로 룰렛
2. `CardDraw.draw(cfg, pool, tier, owned_ids, rng)` → 경로 배열 반환
   - 후보 0장이면 Rare → Common → Epic 순 폴백
   - Epic 등급: 조건부-충족 카드 `epic_conditioned_weight_mult` 배 가중 비복원 추출

### 에픽 카드 조건 (`CardData.prerequisite_card_ids`)
- 비어있으면 **조건없는 에픽** → Epic 롤 시 항상 후보
- 채워져 있으면 **조건부 에픽** → 해당 id들을 모두 보유해야 후보 합류 + 가중치 보정 ↑
- 기존 Rare 카드(ember·kindling·flame_smite)는 prerequisite_card_ids 불필요 (tier=RARE)

### 천장(피티) 상태
- `GameState.stages_since_rare`: Rare/Epic 미등장 연속 스테이지 수
- 카드 선택 시 `advance_stage()` 내부에서 자동 갱신 (선택 카드 tier >= RARE → 0 리셋)

## 규칙
- 스탯·확률 수치는 절대 `.gd`에 하드코딩하지 않음 — `.tres` 파일 편집으로 밸런싱
- 새 카드 추가 = 새 `cards/*.tres` 파일만; 코드 수정 불필요 (풀 자동 스캔)
- 스테이지 적 구성 변경 = `stages/*.tres`의 enemy_party 수정; 코드 수정 불필요
