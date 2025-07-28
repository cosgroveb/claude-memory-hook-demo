#!/usr/bin/env zsh
# Memory selection helper script
# This script is called by session-start-memory-check.zsh

MEMORIES_DIR="${1:-${HOME}/.claude/memories}"
TARGET_PANE="$2"

# Check directory and find files
[[ -d "$MEMORIES_DIR" ]] || { echo "No memories directory found at $MEMORIES_DIR"; sleep 2; exit 0; }
files=( "$MEMORIES_DIR"/**/*.md(N.) )
(( ${#files} )) || { echo "No memory files found"; sleep 2; exit 0; }

# Show file selector
selected_display=$(
    for file in "${files[@]}"; do
        echo "memories/${file#$MEMORIES_DIR/}"
    done | fzf --multi \
        --header="Select memories (TAB=select, ENTER=confirm)" \
        --height=100% --reverse \
        --border=rounded --border-label="╱ Claude Code Memory Selection ╱" --border-label-pos=3 \
        --info=inline-right \
        --color="fg+:15,bg+:-1,hl+:12,info:8,prompt:12,pointer:12,marker:2" \
        --padding=1,2 --prompt="› " --marker="✓ " --pointer="▸"
)

# Process selections
if [[ -n "$selected_display" ]]; then
    {
        echo "Remember these technical knowledge areas for our session:"
        while IFS= read -r display_path; do
            file="$MEMORIES_DIR/${display_path#memories/}"
            if [[ -f "$file" ]]; then
                echo "## ${${file:t:r}//-/ }"
                echo
                cat "$file"
                echo
            fi
        done <<< "$selected_display"
    } | tmux load-buffer - && \
    tmux paste-buffer -t "$TARGET_PANE" && \
    tmux send-keys -t "$TARGET_PANE" Enter
fi
