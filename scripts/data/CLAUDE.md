# scripts/data/ — Resource 스크립트

## Files

| 파일 | 역할 |
|---|---|
| `unit_stats.gd` | `class_name UnitStats`. 유닛 스탯 Resource (STR/ARM/SPD/MOVE + `armor_reduction_immune`) |
| `party_roster.gd` | `class_name PartyRoster`. 파티 멤버 목록 Resource. `members: Array[Resource]`로 UnitStats .tres 참조 |

## 연결 데이터 파일 (data/)

| 파일 | 설명 |
|---|---|
| `protagonist_stats.tres` ~ `enemy_tank_stats.tres` | 각 유닛의 스탯 |
| `default_party.tres` | `PartyRoster` 인스턴스. 신규 게임 기본 파티 3명 참조 |

## 규칙
- 스탯 값은 절대 `.gd`에 하드코딩하지 않음 — `.tres` 파일 편집으로 밸런싱
- 새 캐릭터 추가 = 새 .tres 파일 + `default_party.tres` 참조 업데이트 (코드 수정 없음)
