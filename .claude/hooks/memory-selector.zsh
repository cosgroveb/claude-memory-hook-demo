#!/usr/bin/env zsh
# Memory selection helper script for Claude Code
# This script is called by session-start-memory-check.zsh

# Get arguments
MEMORIES_DIR="${1:-${HOME}/.claude/memories}"
TARGET_PANE="$2"

# Find all memory files
files=( "$MEMORIES_DIR"/**/*.md(N.) )
[[ ${#files} == 0 ]] && { echo "No memories found"; sleep 2; exit 0; }

# Show file selector and process selections
printf 'memories/%s\n' "${files[@]#$MEMORIES_DIR/}" | \
fzf --multi \
    --header="Select memories (TAB=select, ENTER=confirm)" \
    --height=100% --reverse \
    --border=rounded --border-label="╱ Claude Code Memory Selection ╱" --border-label-pos=3 \
    --info=inline-right \
    --color="fg+:15,bg+:-1,hl+:12,info:8,prompt:12,pointer:12,marker:2" \
    --padding=1,2 \
    --prompt="› " \
    --marker="✓ " \
    --pointer="▸" | \
{
    # Process selected files
    selections=$(cat)
    [[ -z "$selections" ]] && exit 0
    
    echo "Remember these technical knowledge areas for our session:"
    echo
    
    while IFS= read -r path; do
        file="$MEMORIES_DIR/${path#memories/}"
        [[ -f "$file" ]] && {
            echo "## ${${file:t:r}//-/ }"
            echo
            cat "$file"
            echo
        }
    done <<< "$selections"
} | tmux load-buffer - && \
tmux paste-buffer -t "$TARGET_PANE" && \
tmux send-keys -t "$TARGET_PANE" Enter