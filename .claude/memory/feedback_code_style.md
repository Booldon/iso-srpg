---
name: feedback-code-style
description: "코드 스타일 원칙 — 하드코딩 금지, 유연한 설계, AI 확장성"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c9fc6f8a-a66e-46c8-9d6c-79fd138c3099
---

수치·공식·알고리즘을 절대 GDScript에 하드코딩하지 말 것.

**Why:** 등장인물 인원, 데미지 공식, 상태이상 수치, AI 알고리즘 모두 개발 중 변경 예정. 몹 유형별로 AI가 달라질 예정(현재는 공통 로직이지만 추후 분리됨). 한 숫자를 바꾸려면 코드 한 곳만 고쳐야 한다.

**How to apply:**
- 조정 가능한 숫자는 반드시 `const` 이름 상수로 선언 (예: `BURN_DAMAGE_PER_STACK`, `ENEMY_TURN_DELAY`)
- 밸런싱 수치(스탯, 스택 상한 등)는 `.tres` Resource 파일에만 존재, `.gd`에 절대 쓰지 않음
- 상태이상 타입은 `StatusEffects.Type` enum으로 관리 — 새 상태이상 추가 = enum 값 추가 + tick_turn_start 처리 추가
- 파티 인원수, 슬롯 배열 같은 것도 하드코딩 3 대신 데이터 길이 기반으로 결정
- 적 AI 로직은 `grid_manager.gd` 인라인에서 벗어나 몹 유형별로 분리 예정 — 새 AI 추가 시 새 클래스, 기존 코드 수정 최소화
- 코드 리뷰 시 `숫자 리터럴`이 보이면 "이게 나중에 바뀔 수 있는가?" 질문 후 상수화
