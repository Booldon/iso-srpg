#!/usr/bin/env bash
# Links this project's .claude/memory into ~/.claude so Claude Code finds it.
# Run once after cloning on a new machine: bash setup_claude_memory.sh

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENCODED="$(echo "$PROJECT_DIR" | tr '/' '-')"
CLAUDE_PROJECT_DIR="$HOME/.claude/projects/${ENCODED}"
MEMORY_LINK="$CLAUDE_PROJECT_DIR/memory"

mkdir -p "$CLAUDE_PROJECT_DIR"

if [ -L "$MEMORY_LINK" ]; then
    echo "Already linked: $MEMORY_LINK"
elif [ -d "$MEMORY_LINK" ]; then
    echo "ERROR: $MEMORY_LINK is a real directory (not a symlink)."
    echo "Merge its contents into .claude/memory/ manually, then remove it and re-run."
    exit 1
else
    ln -s "$PROJECT_DIR/.claude/memory" "$MEMORY_LINK"
    echo "Done: $MEMORY_LINK -> $PROJECT_DIR/.claude/memory"
fi
