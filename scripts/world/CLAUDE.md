# scripts/world/ — 월드 씬 스크립트

## Files

| 파일 | 역할 |
|---|---|
| `title.gd` | 타이틀 스크린. 새 게임/이어하기 → world_map.tscn 전환 |
| `world_map.gd` | 월드맵. 선형 챕터 체인 표시, 파티 현황, 전투 진입 버튼 |
| `boon_screen.gd` | 부운 선택. data/boons/ 풀에서 3장 랜덤 추첨 → advance_chapter() |

## 씬 흐름

```
title.tscn ──(새 게임/이어하기)──► world_map.tscn ──(전투 시작)──► grid.tscn
    ▲                                    ▲
    │                                    │ 부운 선택 완료
    │ 패배(start_new_run 후)      boon_screen.tscn
    └────────────────────────────────────┘
```

- **타이틀 → 월드맵**: 새 게임은 `GameState.new_game()` 후 전환. 이어하기는 바로 전환.
- **전투 승리**: `grid_manager._check_battle_end()`가 `boon_screen.tscn`으로 전환.
  캠페인 완료 시에는 world_map으로 직접.
- **전투 패배**: `GameState.start_new_run()` 후 result_screen 표시. 버튼이 title.tscn으로.

## 부운 풀 스캔 (`boon_screen.gd`)

`DirAccess.open("res://data/boons/")` 로 `.tres` 파일을 동적 스캔.
새 부운 추가 = 파일만 넣으면 자동으로 풀에 포함; 코드 수정 불필요.

## 월드맵 챕터 노드 표시

`world_map.gd._refresh_chapter_nodes()` 가 `GameState.get_chapter_count()` 순회:
- `i < current_chapter` → ✓ (초록)
- `i == current_chapter` → ◀ (노랑, 현재 진입 가능)
- `i > current_chapter` → 잠김 (회색)

`_refresh_party_label()`은 생존 인원 + 획득 부운 수를 표시.
