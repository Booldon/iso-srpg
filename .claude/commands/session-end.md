이번 세션에서 작업한 내용을 정리해서 `.claude/memory/session_summary.md`를 업데이트해줘.

오늘 날짜를 확인하고, 아래 형식 그대로 파일을 덮어써줘 (설명 없이 바로 Write 실행):

```
---
name: session-summary
description: 가장 최근 세션에서 작업한 내용 요약
metadata:
  type: project
---

## 세션 요약 (YYYY-MM-DD)

### 작업 내용
- (이번 세션에서 완료한 것들)

### 결정 사항
- (확정된 설계·방향·선택)

### 다음 작업
- (미완료거나 다음 세션에서 이어야 할 것)

### 주요 파일 변경
- (수정·생성된 핵심 파일)
```

이전 내용은 완전히 덮어써도 됨.
작성 완료 후 `git add .claude/memory/session_summary.md && git commit -m "chore: session summary update"` 실행해줘.
