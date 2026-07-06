---
name: feedback_verification
description: Godot 시각적 검증은 개발자가 직접 에디터에서 확인한다 — Claude가 스크린샷 설정을 시도하지 말 것
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b426d327-4eb9-457c-9ba3-350858fe2a53
---

Godot 프로젝트의 시각적 동작 검증은 개발자가 직접 Windows Godot 에디터에서 실행해서 확인한다.

**Why:** Claude가 WSL2 환경에서 스크린샷 도구 설치·xvfb 설정 등을 시도하면 시간 낭비. 개발자가 "내가 확인할게"라고 명확히 선호를 밝힘.

**How to apply:** /verify 스킬이나 시각적 검증 요청이 들어오면, print() 로그나 headless 구문검사까지만 하고 "Godot 에디터에서 직접 확인해주세요 + 확인 포인트 목록" 형식으로 마무리한다. 스크린샷 도구 설치나 xvfb 세팅을 시도하지 않는다.
