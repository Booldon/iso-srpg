# scripts/debug/ — Debug / Test Mode

## 목적

개발 중 특정 씬(부운 획득·전투·월드맵 등)을 title → world_map 전체 흐름 없이
직접 진입하여 반복 테스트하기 위한 시스템.

**배포 빌드(export release)에는 진입점이 전혀 노출되지 않는다.**
`OS.is_debug_build()` 가드와 title.gd 버튼 가시성으로 이중 차단.

## Files

| 파일 | 역할 |
|---|---|
| `debug_menu.gd` | 씬 루트 스크립트. `data/debug_scenarios/` 스캔 → 버튼 목록 생성 → 선택 시 GameState 주입 + 씬 전환 |

## 씬 트리 (`scenes/debug/debug_menu.tscn`)

```
DebugMenu (Control, debug_menu.gd)
├── Background (ColorRect)
├── Header (Label)
├── ScrollContainer
│   └── ScenarioList (VBoxContainer)   ← 버튼이 동적으로 추가됨
└── Footer (HBoxContainer)
    └── ExitButton                     ← 디버그 모드 해제 + title.tscn 복귀
```

## 진입점

| 방법 | 조건 | 동작 |
|---|---|---|
| 타이틀 "TEST MODE" 버튼 | `OS.is_debug_build()` 시만 visible | `GameState.enter_debug_mode()` → debug_menu.tscn |
| **F1** 단축키 | `OS.is_debug_build()` 시만 처리, `GameState._unhandled_input()` | 동일 |

## 데이터: `data/debug_scenarios/*.tres` (DebugScenario Resource)

```
label              : 메뉴 버튼 텍스트
target_scene       : 이동할 씬 res:// 경로
current_stage      : GameState.current_stage 에 주입할 값
active_boons       : 주입할 boon .tres 경로 배열
debug_player_cards : 주입할 card .tres 경로 배열 (grid_manager가 플레이어 유닛에 장착)
```

**새 테스트 추가 = `.tres` 파일 추가만, 코드 수정 없음.**
`debug_menu.gd._scan_scenarios()` 가 디렉토리를 동적 스캔 — boon_screen.gd 풀 스캔과 동일 패턴.

## 세이브 보호

디버그 모드에서는 `GameState._active_save_path()` 가 `user://saves/save_debug.json` 을 반환.
실제 `save.json` 은 건드리지 않는다. 자세한 내용은 `scripts/autoload/CLAUDE.md` 참고.

## 불변 규칙

- 이 폴더 코드는 `OS.is_debug_build()` 외부에서 절대 참조되어서는 안 된다.
- `_launch()` 는 항상 `GameState.new_game()` 을 먼저 호출해 깨끗한 파티 상태를 보장한다.
- 시나리오 필드 추가 시: `debug_scenario.gd` 에 `@export` 추가 → `.tres` 에 값 설정 →
  `debug_menu.gd._launch()` 에서 새 필드를 GameState 혹은 씬으로 전달.
