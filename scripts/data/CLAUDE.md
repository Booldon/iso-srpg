# scripts/data/ — Resource 스크립트

## Files

| 파일 | 역할 |
|---|---|
| `unit_stats.gd` | `class_name UnitStats`. 유닛 스탯 Resource (STR/ARM/SPD/MOVE + `armor_reduction_immune`) |
| `party_roster.gd` | `class_name PartyRoster`. 파티 멤버 목록 Resource. `members: Array[Resource]`로 UnitStats .tres 참조 |
| `boon_data.gd` | `class_name BoonData`. 부운 Resource. Target(ALLY_BUFF/ENEMY_DEBUFF)·Stat·amount 보유 |
| `stage_data.gd` | `class_name StageData`. 스테이지(전투 1회) Resource. title + `enemy_party: Array[Resource]`(UnitStats) |
| `campaign.gd` | `class_name Campaign`. 캠페인 Resource. `stages: Array[Resource]`(StageData) |

> **용어 주의**: 여기서 "스테이지" = 전투 1회 단위. `roguelike-layer-design.md`가 말하는
> "챕터"(스테이지 5개를 묶는 상위 단위 + 챕터엔드 시퀀스)는 아직 코드에 없다 —
> 로그라이크 레이어를 실제로 구현할 때 Campaign과 StageData 사이에 새로 추가해야 할 개념.

## 연결 데이터 파일 (data/)

| 파일/폴더 | 설명 |
|---|---|
| `protagonist_stats.tres` ~ `enemy_tank_stats.tres` | 각 유닛의 스탯 (스테이지1 적 포함) |
| `enemy_grunt_stage2_stats.tres` ~ `enemy_tank_stage3_stats.tres` | 스테이지 2·3 전용 적 스탯 |
| `default_party.tres` | `PartyRoster` 인스턴스. 신규 게임 기본 파티 3명 참조 |
| `boons/boon_*.tres` | BoonData 인스턴스 (6종). 부운 풀 전체. 스테이지 승리 후 3장 랜덤 추출 |
| `stages/stage_1..3.tres` | StageData 인스턴스. 각 스테이지의 적 구성 |
| `campaign.tres` | Campaign 인스턴스. 스테이지 순서 정의 |

## BoonData enum 값 (정수 직렬화)

- `Target`: ALLY_BUFF = 0, ENEMY_DEBUFF = 1
- `Stat`: STRENGTH = 0, ARMOR = 1, SPEED = 2, MOVE_RANGE = 3
- `amount`: 항상 양수; 코드(`BoonApplier`)에서 target에 따라 부호 결정

## 규칙
- 스탯 값은 절대 `.gd`에 하드코딩하지 않음 — `.tres` 파일 편집으로 밸런싱
- 새 부운 추가 = 새 `boons/*.tres` 파일만 추가; 코드 수정 불필요 (풀 자동 스캔)
- 스테이지 적 구성 변경 = `stages/*.tres`의 enemy_party 수정; 코드 수정 불필요
