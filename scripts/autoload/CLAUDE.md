# scripts/autoload/ — GameState

## Files

| 파일 | 역할 |
|---|---|
| `game_state.gd` | 파티·런 상태 보유·세이브/로드. 전투·월드맵·부운 씬 밖에서도 유지 |

## 왜 autoload인가

CLAUDE.md의 "No autoloads before architecture warrants it" 규칙은 크로스-씬 영속성이
필요해지는 시점까지 미루는 규칙이다. step 5(세이브+로스터)가 그 시점 — 전투 씬 리로드
후에도 파티 상태가 유지되어야 하므로, GameState autoload 1개를 공식 도입(개발자 확인됨).

## 세이브 스키마 v2 (user://saves/save.json)

```json
{
  "version": 2,
  "party": [
    { "path": "res://data/protagonist_stats.tres", "alive": true },
    { "path": "res://data/ally1_stats.tres",        "alive": true },
    { "path": "res://data/ally2_stats.tres",         "alive": false }
  ],
  "current_chapter": 1,
  "active_boons": ["res://data/boons/boon_str_up.tres"]
}
```

- `version` 불일치 또는 파일 손상 시 `new_game()`으로 폴백 (런 리셋).
- **패배**: `start_new_run()` → `new_game()` + 저장 → 챕터0·부운 초기화. 다음 세션은 처음부터.
- **승리**: `apply_survivors()` 후 `boon_screen`에서 부운 선택 → `advance_chapter(path)` 저장.
- 생존자 스탯은 저장하지 않음. 다음 전투에서 `.tres.duplicate()`하므로 자동 풀피 리셋.
- 부운은 .tres 경로 문자열로 저장 (Resource 객체 아님).

## 핵심 API

| 함수 | 호출자 | 동작 |
|---|---|---|
| `has_save()` | `title.gd` | 세이브 파일 존재 여부 (이어하기 활성화) |
| `new_game()` | `_ready()` / `start_new_run()` | 파티+챕터+부운 초기화 |
| `start_new_run()` | `grid_manager._check_battle_end()` 패배 분기 | 런 리셋 후 저장 |
| `get_living_party()` | `grid_manager._place_players()`, `world_map.gd` | 살아있는 멤버 레코드 반환 |
| `apply_survivors(paths)` | `grid_manager._check_battle_end()` 승리 분기 | 생사 업데이트 후 저장 |
| `advance_chapter(path)` | `boon_screen._on_card_chosen()` | 부운 누적 + 챕터++ + 저장 |
| `current_chapter_data()` | `grid_manager._place_enemies()`, `world_map.gd` | 현재 ChapterData 반환 |
| `is_campaign_complete()` | `grid_manager._check_battle_end()`, `world_map.gd` | 챕터 소진 여부 |
| `get_chapter_count()` | `world_map.gd` | 전체 챕터 수 반환 |
