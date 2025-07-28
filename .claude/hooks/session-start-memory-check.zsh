#!/usr/bin/env zsh
# Session start hook for Claude Code memory selection

# Basic configuration
MEMORIES_DIR="${HOME}/.claude/memories"
HOOKS_DIR="${HOME}/.claude/hooks"

# Skip if not in tmux
[[ -z "$TMUX" ]] && exit 0

# Check requirements
command -v tmux >/dev/null 2>&1 || exit 0
command -v fzf >/dev/null 2>&1 || exit 0

# Find Claude PID
PID=$$
while [[ $(ps -p "$PID" -o ppid= 2>/dev/null) -gt 1 ]]; do
    PID=$(ps -p "$PID" -o ppid= | tr -d ' ')
    [[ $(ps -p "$PID" -o comm=) == "claude" ]] && break
done

# Use TMPDIR if available (macOS), otherwise /tmp (Linux)
MARKER_DIR="${TMPDIR:-/tmp}"
SESSION_MARKER="${MARKER_DIR}/claude-memory-selected-${PID}"

# Skip if already run for this tmux session/window
[[ -f "$SESSION_MARKER" ]] && exit 0

# Check if helper script exists
MEMORY_SELECTOR="$HOOKS_DIR/_memory-selector.zsh"
if [[ ! -x "$MEMORY_SELECTOR" ]]; then
    echo "Memory selector script not found or not executable: $MEMORY_SELECTOR" >&2
    exit 1
fi

# Mark session
touch "$SESSION_MARKER"

# Get target pane
TARGET_PANE="$(tmux display-message -p '#S:#I.#P')"

# Run memory selector in tmux popup
tmux display-popup -E -w 80% -h 60% -t "$TARGET_PANE" -- \
    "$MEMORY_SELECTOR" "$MEMORIES_DIR" "$TARGET_PANE"