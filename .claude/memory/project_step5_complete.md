---
name: project-step5-complete
description: Step 5 월드맵+챕터+로그라이크 부운 시스템 완료 상태 및 다음 방향
metadata: 
  node_type: memory
  type: project
  originSessionId: d196e30f-acbc-4ade-993a-dcce80bed2fe
---

Step 5 (story/dialogue/maps)의 핵심 슬라이스 완료 (2026-07-06).

**Why:** 게임 루프가 닫히지 않았었음 (배틀만 반복). 선형 챕터 체인 + 로그라이크 부운 시스템으로 완전한 런 구조 구현.

**완료된 커밋:**
- `a1ebabb` feat(step:5/data) — BoonData/ChapterData/Campaign Resource + 3챕터 데이터 + 6종 부운 풀
- `d91dbd1` feat(step:5/run) — GameState 런 상태 (current_chapter, active_boons, 세이브 v2)
- `2848e73` feat(step:5/flow) — title.tscn / world_map.tscn / boon_screen.tscn + 씬 전환
- `8afb0c7` feat(step:5/combat) — BoonApplier, _place_enemies() ChapterData 소싱, 패배→런 리셋
- `bc7653f` fix(step:5/flow) — add_theme_font_size_override() 수정

**현재 게임 루프:**
타이틀 → 월드맵 → 전투 → 부운 선택(3택) → 월드맵 → ... → 캠페인 클리어(3챕터)
패배 → start_new_run() → 타이틀(챕터0, 부운 초기화)

**아직 없는 것 (Step 5 잔여):**
- Dialogue Manager 스텁 (CLAUDE.md 명시 요구사항)
- 캠페인 클리어 후 엔딩 화면
- 파티 멤버 이름 (UnitStats에 unit_name 필드 없음)
- 부운 풀 확장 (현재 6종)

**How to apply:** 다음 슬라이스 제안 시 위 잔여 항목 중 하나를 고르도록 안내.
