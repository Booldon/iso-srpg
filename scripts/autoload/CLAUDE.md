# scripts/autoload/ — GameState

## Files

| 파일 | 역할 |
|---|---|
| `game_state.gd` | 파티 생사 상태 보유·세이브/로드. 전투 씬 밖에서도 유지 |

## 왜 autoload인가

CLAUDE.md의 "No autoloads before architecture warrants it" 규칙은 크로스-씬 영속성이
필요해지는 시점까지 미루는 규칙이다. step 5(세이브+로스터)가 그 시점 — 전투 씬 리로드
후에도 파티 상태가 유지되어야 하므로, GameState autoload 1개를 공식 도입(개발자 확인됨).

## 세이브 스키마 (user://saves/save.json)

```json
{
  "version": 1,
  "party": [
    { "path": "res://data/protagonist_stats.tres", "alive": true },
    { "path": "res://data/ally1_stats.tres",        "alive": true },
    { "path": "res://data/ally2_stats.tres",         "alive": false }
  ]
}
```

- `version` 불일치 또는 파일 손상 시 `new_game()`으로 폴백.
- 승리 시에만 저장 (`apply_survivors` 호출). 패배는 저장하지 않음 → 같은 파티로 재시도.
- 생존자 스탯은 저장하지 않음. 다음 전투에서 .tres를 `.duplicate()`하므로 자동 풀피 리셋.

## 핵심 API

| 함수 | 호출자 | 동작 |
|---|---|---|
| `new_game()` | `_ready()` (세이브 없을 때) | `default_party.tres`에서 로스터 초기화 |
| `get_living_party()` | `grid_manager._place_players()` | 살아있는 멤버 레코드 배열 반환 |
| `apply_survivors(paths)` | `grid_manager._check_battle_end()` 승리 분기 | 생사 업데이트 후 세이브 기록 |
