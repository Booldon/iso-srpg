---
name: session-summary
description: 가장 최근 세션에서 작업한 내용 요약
metadata: 
  node_type: memory
  type: project
  originSessionId: c9fc6f8a-a66e-46c8-9d6c-79fd138c3099
---

## 세션 요약 (2026-07-13)

### 작업 내용
- 테스트/디버그 모드 시스템 완성 (game_state.gd 수정, debug_menu 씬+스크립트, title TEST MODE 버튼, 디버그 시나리오 .tres 3종)
- F1 단축키 → 백틱(`) 으로 변경 (Godot 에디터가 F1 가로챔 문제 해결)
- 부운(BoonData/BoonApplier) 시스템 전면 제거, 카드 선택으로 통일
  - GameState.active_boons → active_cards, advance_stage() 파라미터 정리
  - grid_manager에서 BoonApplier 제거, active_cards를 주인공(armor_reduction_immune)에만 주입
  - world_map 텍스트 "획득 부운" → "획득 카드"
- 카드 등급 추첨 시스템 구현 (Common 30 / Rare 60 / Epic 10 기본 확률)
  - CardDrawConfig Resource (가중치·천장·에픽 보정 전부 .tres 관리)
  - CardDraw static 헬퍼 (roll_tier / eligible / draw)
  - 소프트 천장(Rare 미등장마다 +15%) + 하드 천장(3스테이지째 Rare 확정)
  - 에픽 게이팅: 조건없는 에픽 상시 후보 / 조건부 에픽은 전제 카드 보유 시 후보+가중↑
  - CardData에 prerequisite_card_ids 필드 추가
  - boon_screen.gd → CardDraw 사용으로 재작성
  - 헤드리스 스모크 테스트 스크립트 작성 (card_draw_smoke_test.gd)
- GDScript 파싱 에러 수정: Array[CardData.Tier] → Array[int] (GDScript 4는 외부 enum을 배열 원소 타입으로 허용 안 함)
- 세이브 버전 v3 → v4 (active_boons→active_cards) → v5 (stages_since_rare 추가)

### 결정 사항
- 부운(BoonData) 폐기, 카드가 유일한 런 성장 시스템
- 카드는 주인공 전용 (armor_reduction_immune == true 식별)
- 기본 등급 확률 Common 30 / Rare 60 / Epic 10
- 천장: 소프트 누적(+15%/스테이지) + 하드 확정(3스테이지째 Rare 강제)
- 에픽: 조건없는 에픽 항상 후보 / 조건부 에픽은 전제 충족 시 후보 합류 + 가중 보정 (설계서 §6.4 완화)
- 후보 부족 시 "있는 만큼만 표시" (빈 화면 방지 폴백 있음)

### 다음 작업
- 에디터 시각 검증 (카드 선택 화면 등급 분리 동작, 천장 카운터, 주인공 카드 적용 확인)
- Common 카드 및 Epic 카드 .tres 데이터 추가 (현재 Rare 3장만 존재, 폴백으로만 동작 중)
- boon_screen.tscn → card_screen.tscn 개명 (파일명이 내용과 불일치, 스코프 억제 중)
- data/boons/ 폴더 정리 (코드 참조 없으나 파일 잔존)

### 주요 파일 변경
- `scripts/autoload/game_state.gd` — active_cards, stages_since_rare, save v5, 백틱 단축키
- `scripts/world/boon_screen.gd` — CardDraw 기반 재작성
- `scripts/world/title.gd` + `scenes/world/title.tscn` — TEST MODE 버튼
- `scripts/battle/grid_manager.gd` — BoonApplier 제거, active_cards 주인공 주입
- `scripts/world/world_map.gd` — 카드 수 표시
- `scripts/data/card_data.gd` — prerequisite_card_ids 추가
- `scripts/data/card_draw_config.gd` + `data/card_draw_config.tres` — 신규
- `scripts/data/card_draw.gd` — 신규 (추첨 로직)
- `scripts/data/card_draw_smoke_test.gd` — 신규 (헤드리스 테스트)
- `scripts/debug/debug_menu.gd` + `scenes/debug/debug_menu.tscn` — 신규
- `scripts/debug/CLAUDE.md` — 신규
- `data/debug_scenarios/*.tres` — 신규/갱신
