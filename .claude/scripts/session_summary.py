#!/usr/bin/env python3
"""
Stop-hook script: reads the current session transcript, calls Claude API (Haiku)
to produce a Korean session summary, and overwrites .claude/memory/session_summary.md.

Cooldown: skips if run within COOLDOWN_SECONDS to avoid firing after every response.
"""
import json
import os
import sys
import time
import urllib.request
from datetime import datetime
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────
COOLDOWN_SECONDS = 120        # skip if last summary was < 2 min ago
MIN_MESSAGES     = 4          # don't summarize tiny sessions
MAX_MESSAGES     = 80         # cap to keep prompt short
MAX_MSG_CHARS    = 600        # truncate individual messages

SCRIPT_DIR   = Path(__file__).parent
PROJECT_DIR  = SCRIPT_DIR.parent.parent          # .claude/scripts/ -> project root
MEMORY_DIR   = SCRIPT_DIR.parent / "memory"
SUMMARY_FILE = MEMORY_DIR / "session_summary.md"
COOLDOWN_FILE = SCRIPT_DIR / ".last_summary_ts"


# ── Helpers ───────────────────────────────────────────────────────────────

def encoded_project_path(project_dir: Path) -> str:
    return str(project_dir).replace("/", "-")


def find_transcript(session_id: str | None, project_dir: Path) -> Path | None:
    encoded = encoded_project_path(project_dir)
    projects_dir = Path.home() / ".claude" / "projects" / encoded

    if session_id:
        candidate = projects_dir / f"{session_id}.jsonl"
        if candidate.exists():
            return candidate

    # Fallback: most recently modified .jsonl
    jsonl_files = sorted(
        projects_dir.glob("*.jsonl"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    return jsonl_files[0] if jsonl_files else None


def parse_transcript(path: Path) -> list[dict]:
    msgs = []
    try:
        with path.open(encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                    if obj.get("type") in ("user", "assistant"):
                        msgs.append(obj)
                except json.JSONDecodeError:
                    pass
    except Exception:
        pass
    return msgs


def extract_text(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(
            item.get("text", "")
            for item in content
            if isinstance(item, dict) and item.get("type") == "text"
        )
    return ""


def build_excerpt(msgs: list[dict]) -> str:
    lines = []
    for msg in msgs[-MAX_MESSAGES:]:
        role = msg.get("type", "").upper()
        raw  = msg.get("message", {}).get("content", "")
        text = extract_text(raw).strip()[:MAX_MSG_CHARS]
        if text:
            lines.append(f"{role}: {text}")
    return "\n\n".join(lines)


def call_haiku(prompt: str, api_key: str) -> str:
    payload = json.dumps({
        "model": "claude-haiku-4-5-20251001",
        "max_tokens": 1024,
        "messages": [{"role": "user", "content": prompt}],
    }).encode()

    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=payload,
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        result = json.loads(resp.read())
        return result["content"][0]["text"]


def cooldown_passed() -> bool:
    if not COOLDOWN_FILE.exists():
        return True
    last = float(COOLDOWN_FILE.read_text().strip())
    return (time.time() - last) >= COOLDOWN_SECONDS


def update_cooldown() -> None:
    COOLDOWN_FILE.write_text(str(time.time()))


# ── Main ──────────────────────────────────────────────────────────────────

def main() -> None:
    # Read hook input
    try:
        hook_input = json.loads(sys.stdin.read())
    except Exception:
        return

    if not cooldown_passed():
        return

    session_id = hook_input.get("session_id")
    transcript_path_raw = hook_input.get("transcript_path", "")

    # Resolve transcript
    if transcript_path_raw and Path(transcript_path_raw).exists():
        transcript = Path(transcript_path_raw)
    else:
        transcript = find_transcript(session_id, PROJECT_DIR)

    if transcript is None:
        return

    msgs = parse_transcript(transcript)
    if len(msgs) < MIN_MESSAGES:
        return

    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        return

    excerpt = build_excerpt(msgs)
    now     = datetime.now().strftime("%Y-%m-%d %H:%M")

    prompt = f"""다음은 Claude Code 세션의 대화 발췌입니다.
다음 세션에서 Claude가 바로 이어서 작업할 수 있도록, 핵심만 한국어로 정리해주세요.

출력 형식 (이 형식 그대로 출력, 설명 없이):

## 세션 요약 ({now})

### 작업 내용
- (완료된 주요 작업들, 불릿 형식)

### 결정 사항
- (이번 세션에서 확정된 설계·방향)

### 다음 작업
- (미완료거나 이어서 해야 할 것)

### 주요 파일 변경
- (수정·생성된 핵심 파일명)

---
대화 발췌:
{excerpt}"""

    try:
        body = call_haiku(prompt, api_key)
    except Exception:
        return

    update_cooldown()

    content = f"""---
name: session-summary
description: 가장 최근 세션에서 작업한 내용 요약 (Stop 훅 자동 생성)
metadata:
  type: project
---

{body}
"""
    SUMMARY_FILE.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    main()
