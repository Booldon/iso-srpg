# scripts/battle/ — Battle System

## Files

| 파일 | 역할 |
|---|---|
| `grid_manager.gd` | 씬 루트 스크립트. 그리드 생성·경로탐색·입력 처리·유닛 배치·승패 판정 총괄. `_place_players()`는 `GameState.get_living_party()` + `BoonApplier`로 소싱. `_place_enemies()`는 `GameState.current_chapter_data().enemy_party` 소싱 |
| `turn_manager.gd` | 턴 순서 관리. 팀별 speed 정렬 후 페어 인터리빙, `turn_started` 시그널 발행 |
| `unit.gd` | 유닛 컴포넌트. 런타임 상태(`is_player`, `stats`, `grid_col/row`, `is_moving`) 보유. `move_along_path()` 로 셀 단위 트윈 이동. `face_toward_pos(target_pos)` 로 이동·공격 시 8방향 스프라이트 전환 |
| `combat.gd` | 순수 데미지 계산. `Combat.resolve_attack(attacker, target, hit_armor)` 로 stats 직접 수정 |
| `attack_menu.gd` | CanvasLayer UI. `armor_chosen` / `strength_chosen` / `cancelled` 시그널 발행 |
| `stats_panel.gd` | CanvasLayer UI. `show_unit(unit)` 로 STR/ARM/SPD 표시. 마우스 오버 유닛 우선 |
| `boon_applier.gd` | `class_name BoonApplier`. 순수 함수. `apply_ally_boons(stats, paths)` / `apply_enemy_boons(stats, paths)` |
| `result_screen.gd` | CanvasLayer UI. **패배 전용** 오버레이. 버튼 → title.tscn. 승리 씬 전환은 grid_manager가 담당 |

## 씬 트리 (scenes/battle/grid.tscn)

```
GridRoot (Node2D, grid_manager.gd)
├── Camera2D
├── WorldContainer (Node2D)
│   ├── FloorLayer          ← 타일, 이동범위, 활성타일, 호버타일 (이 순서로 렌더)
│   └── ActorsLayer         ← 모든 Unit 노드 (y_sort_enabled = true)
├── TurnManager (Node)
├── AttackMenu (CanvasLayer)
├── StatsPanel (CanvasLayer)
└── ResultScreen (CanvasLayer)
```

## 턴 흐름

1. `TurnManager.start_battle(units)` — 팀별 speed 정렬 → 페어 구성 → `turn_started` 발행
2. **플레이어 턴**: 소프트락 가드(이동·공격 모두 불가면 자동 `end_turn`), 통과 시 `_player_can_act = true` + 이동 범위 표시
   - 범위 내 빈 칸 클릭 → 이동 → `end_turn()`
   - 인접 적 클릭 → 공격 메뉴 → 데미지 → 사망 체크 → `end_turn()`
3. **적 턴**: 0.5초 대기 → 인접 시 스마트 타겟 공격(실데미지 우선, 면역 armor 회피), 아니면 최근접 플레이어 방향으로 접근 이동 → `end_turn()`
4. **전투 종료**: 승리 → `apply_survivors()` → `boon_screen.tscn`(캠페인 미완) / `world_map.tscn`(완료). 패배 → `start_new_run()` → `result_screen.show_defeat()`

## 핵심 불변 조건

- `_unit_at: Dictionary` (Vector2i → Unit) — 점유 맵의 유일한 진실. 이동 전후 반드시 갱신
- 유닛 생성 시 `.tres`를 `.duplicate()` — 각 유닛이 독립적인 Resource 사본 보유
- `_player_can_act` — 적 턴·이동 중 입력 차단의 유일한 게이트
- FloorLayer 렌더 순서: `grid tiles < range tiles < active tile < hover tile` — 범위 갱신 후 `move_child`로 강제 유지
- A* disabled 플래그는 `_build_screen_path()` 호출 시마다 `_sync_astar_occupancy(mover)`로 `_unit_at`과 동기화됨 — 다른 유닛을 우회
- 이동범위 표시·판정의 단일 진실은 `_compute_reachable(unit)` BFS 결과(`_reachable` 캐시). 맨해튼 거리로 직접 계산하지 않음

## 데이터 파일 (data/)

| 파일 | STR | ARM | SPD | MOVE |
|---|---|---|---|---|
| `protagonist_stats.tres` | 10 | 3 | 12 | 4 |
| `ally1_stats.tres` | 9 | 2 | 10 | 3 |
| `ally2_stats.tres` | 7 | 4 | 8 | 3 |
| `enemy_grunt_stats.tres` | 8 | 2 | 8 | 3 |
| `enemy_fast_stats.tres` | 6 | 1 | 11 | 5 |
| `enemy_tank_stats.tres` | 10 | 4 | 5 | 2 |

주인공만 `armor_reduction_immune = true`.
