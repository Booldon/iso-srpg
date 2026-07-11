---
name: session-summary
description: 가장 최근 세션에서 작업한 내용 요약
metadata:
  type: project
---

## 세션 요약 (2026-07-11)

### 작업 내용
- 로그라이크 Fire Rare 카드 20장(불카드) 설계 재개 (이전 세션 유실분 복원)
- 화상(Burn)/솔라(Solar) 베이스라인 규격 확정
- 공격 역할 7장 확정

### 결정 사항
- 화상 최대 5스택, 틱 피해 있음(스택당 1 STR/턴), 폭발은 Epic 카드 전용
- 폭발 피해: 스택당 3(방어무시) 초안 / 3스택 이상이면 폭발 가능 상태
- 역할 분배: 공격 7 / 유틸 5 / 방어 4 / 힐 4 (공격+유틸 중심)
- 산출물: 설계 문서(docs/systems/fire_cards.md)만, 스키마·.tres는 이후 단계
- 공격 7장 확정:
  1. 불씨(Ember) — 공격 시 화상 +1스택 [Epic 폭발 선행]
  2. 연쇄 발화(Kindling) — 화상 상태 적 공격 시 +2스택
  3. 화염 강타(Flame Smite) — STR 피해 + 화상 +1스택
  4. 맹화(Raging Flame) — 화상 스택 2 소모 → 즉발 STR 피해
  5. 백열(White Heat) — 이번 턴 대상 화상 틱 2배
  6. 과열(Overheat) — 화상 3스택 이상 대상에 추가 즉발 피해
  7. 겁화(Conflagration) — 인접 적 전체 화상 +1스택 (광역)
- 진행 방식: 한 번에 전체가 아닌, 역할별로 상의하며 설계

### 다음 작업
- 연쇄 발화 엣지케이스 확정 (비화상 대상 시 +1 vs 0)
- 화상 스택 자연 감소 여부 결정(A 영구 유지 / B 자연 감소) → 유틸 5장 방향 결정
- 유틸 5 → 방어 4 → 힐 4 순으로 설계 이어가기
- Epic 폭발 선행 매핑 확정 후 fire_cards.md 작성

### 주요 파일 변경
- (없음 — 설계 논의 단계, docs/systems/fire_cards.md 미작성)
- 플랜 파일: .claude/plans/system-20-parallel-storm.md
