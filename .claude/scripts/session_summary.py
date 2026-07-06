#!/usr/bin/env python3
"""
Stop-hook fallback: records recent git activity to session_summary.md
when /session-end was not run manually.

Only writes if session_summary.md is missing or older than STALE_HOURS.
Rich summaries are written by Claude via /session-end command.
"""
import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

STALE_HOURS  = 6      # overwrite only if file is this old (hours)
MIN_MESSAGES = 4      # skip very short sessions

SCRIPT_DIR   = Path(__file__).parent
MEMORY_DIR   = SCRIPT_DIR.parent / "memory"
SUMMARY_FILE = MEMORY_DIR / "session_summary.md"
COOLDOWN_FILE = SCRIPT_DIR / ".last_summary_ts"
COOLDOWN_SECONDS = 300


def cooldown_passed() -> bool:
    if not COOLDOWN_FILE.exists():
        return True
    return (time.time() - float(COOLDOWN_FILE.read_text().strip())) >= COOLDOWN_SECONDS


def summary_is_stale() -> bool:
    if not SUMMARY_FILE.exists():
        return True
    age_hours = (time.time() - SUMMARY_FILE.stat().st_mtime) / 3600
    return age_hours >= STALE_HOURS


def run(cmd: list[str]) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""


def main() -> None:
    try:
        hook_input = json.loads(sys.stdin.read())
    except Exception:
        return

    msgs = hook_input.get("message_count", 0)
    if msgs < MIN_MESSAGES:
        return

    if not cooldown_passed() or not summary_is_stale():
        return

    COOLDOWN_FILE.write_text(str(time.time()))

    now        = datetime.now().strftime("%Y-%m-%d %H:%M")
    git_log    = run(["git", "log", "--oneline", "-8"])
    git_status = run(["git", "status", "--short"])

    content = f"""---
name: session-summary
description: 가장 최근 세션에서 작업한 내용 요약 (git 기반 자동 기록 — /session-end로 덮어쓰면 더 정확해짐)
metadata:
  type: project
---

## 세션 요약 ({now}) — 자동 기록

> 더 정확한 요약을 원하면 세션 종료 전 `/session-end` 실행

### 최근 커밋 (git log)
```
{git_log or "(없음)"}
```

### 현재 변경 상태 (git status)
```
{git_status or "(클린)"}
```
"""
    SUMMARY_FILE.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    main()
