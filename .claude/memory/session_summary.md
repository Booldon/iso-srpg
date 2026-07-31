---
name: session-summary
description: 가장 최근 세션에서 작업한 내용 요약
metadata:
  type: project
---

## 세션 요약 (2026-07-31)

### 작업 내용
- `git pull` — Fire 카드 전체(F1~F4, 34장) 반영 확인 및 브리핑
- Earth(땅) 카드 시스템 착수 — Guard 메커닉을 G1~G3 슬라이스로 구현
  - **G1** (`1a36fc4`): Guard 기반 루프 — 스택→AMR 상승 + 피격 시 innate 반격. 카드 3장(Earthen Bulwark, Earthen Smite, Thorn Armor)
  - **G2** (`d887c07`): Guard 소비 페이오프 — Crush/Cataclysm(Epic, 방어무시 버스트), Awakening of Earth(소비→영구 AMR), Fracture(영구 AMR 차감), Center of Gravity(임계 공격력+20%)
  - **G3** (`be79208`): 반응/임계 방어 + 아군 지원 — Bedrock(임계 피해감소), Unshakable Will(저HP 1회성 Guard 만충), Earthen Bond(1회성 아군 AMR), Earthen Empathy(지속 아군 AMR), Retaliatory Strike(반격 성공 후 딜증가). Provoke는 적 AI 타겟 오버라이드가 필요해 제외, 대신 Retaliatory Strike를 편입(개발자 확인)
- 디버그 "카드 직접 선택" 화면 신규 (`3cec0dc`) — `data/cards/` 전체를 체크박스로 나열, 원하는 조합으로 즉시 전투 진입. 카드 설명 호버 툴팁 추가
  - 버그 발견·수정: `GameState.debug_player_cards`로 주입하면 파티 전원에 카드가 붙어버림(원래 이 필드의 설계된 동작) — 실제 플레이와 다르게 동작해 `GameState.active_cards`(주인공 전용)로 교체
- `docs/systems/card_system_api.md` v1.4 → v1.7 계약 갱신 (G1/G2/G3 전체)
- 매 슬라이스마다 `guard_smoke_test.gd` 헤드리스 스모크 테스트 확장 (최종 37/37 통과) + grid_manager 전용 로직은 임시 통합 스크립트로 실제 배틀 씬에서 검증 후 삭제

### 결정 사항
- **Godot 바이너리를 WSL에서 직접 호출 가능함을 발견**: `/mnt/c/Users/Jung/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`. `--headless --path <wslpath -w 변환경로>`로 실행. 이제 실제 Unit/CardData 클래스로 헤드리스 검증 가능(이전엔 Python 포트로만 우회 검증했음). `.godot/` 캐시가 오래돼 있으면 `--editor --quit-after N`으로 먼저 스캔 필요
- 기존 `fire_payoff_smoke_test.gd`는 FakeUnit(덕타이핑)을 쓰는데, StatusEffects/CardEffects 함수들이 `unit: Unit` 정적 타입이라 실제 Godot에서 실행하면 컴파일 에러로 실패함(제작 당시 Python으로만 검증됐던 듯) — 아직 안 고침, 다음에 필요시 실제 Unit.new() 방식으로 교체
- Earth 필드 네이밍: attacker 자신의 스택을 건드리는 필드는 `_self` 접미사로 target 대상 필드와 구분(예: `on_attack_consume_guard_self` vs Fire의 `on_attack_consume_burn`)
- Guard 반격/소비 계열은 전부 고정값 데미지(스탯 비례 없음) 컨벤션 유지
- Fracture는 같은 공격에 소비 카드(Crush 등)가 있으면 "소비 이후" 잔여 Guard를 읽도록 처리 순서 고정
- get_incoming_multiplier()/get_outgoing_multiplier()는 순수 함수 유지 원칙 — 1회성 플래그(guard_counter_bonus_pending) 리셋은 항상 grid_manager가 담당

### 다음 작업
- **개발자 시각 검증**: 디버그 메뉴 → 카드 직접 선택에서 G1~G3 신규 카드 11장 조합 테스트 (Guard 스택 UI, AMR 변화, 반격 데미지, Earthen Bond/Empathy의 아군 AMR 표시 등)
- **G4 (다음 슬라이스 후보)**: Provoke/Impenetrable Fortress(적 AI 타겟 오버라이드 신규 필요), Growth 계열(턴종료 훅 신규 필요), Steadfast Stance(대기 추적 훅 신규 필요), Tremor/Earthquake Fury(AoE), Binding Roots, Eternal Earth(Epic)
- Earth 완료 후: Ice(얼음/Frost) 카드 시스템 착수 예정 (설계는 `docs/systems/ice_cards.md`에 Confirmed 상태로 대기 중)
- Chapter(5-스테이지 묶음) 실제 구조 구현은 여전히 미착수 (Stage만 존재)

### 주요 파일 변경
- `scripts/data/card_data.gd` — Earth G1~G3 필드 총 23개 추가
- `scripts/battle/unit.gd` — Guard/G3 런타임 필드 다수, `effective_armor()` 공식 확장
- `scripts/battle/card_effects.gd` — `apply_guard_counter()`, `get_outgoing_multiplier()` 신규, `apply_on_attack()` [4]~[6] 블록, `get_incoming_multiplier()` Bedrock 분기
- `scripts/battle/grid_manager.gd` — `_apply_earthen_bond()`, `_refresh_guard_ally_bonuses()`, `_check_low_str_triggers()` 신규 + 호출부 배선
- `data/cards/` — Earth 카드 11장 신규 (누적 45장)
- `docs/systems/card_system_api.md` — v1.7
- `scripts/battle/guard_smoke_test.gd` — G1~G3 헤드리스 테스트 37개
- `scenes/debug/card_picker.tscn`, `scripts/debug/card_picker.gd` — 카드 직접 선택 화면 신규
