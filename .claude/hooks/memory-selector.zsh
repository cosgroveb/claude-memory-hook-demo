#!/usr/bin/env zsh
# Memory selection helper script for Claude Code
# This script is called by session-start-memory-check.zsh

# Get arguments
MEMORIES_DIR="${1:-${HOME}/.claude/memories}"
TARGET_PANE="$2"

# Check directory exists
if [[ ! -d "$MEMORIES_DIR" ]]; then
    echo "No memories directory found at $MEMORIES_DIR"
    sleep 2
    exit 0
fi

# Find markdown files
files=()
for file in "$MEMORIES_DIR"/**/*.md(N); do
    [[ -f "$file" ]] && files+=("$file")
done

# Check if any files found
if (( ${#files} == 0 )); then
    echo "No memory files found"
    sleep 2
    exit 0
fi

# Convert to relative paths for display
display_files=()
for file in "${files[@]}"; do
    # Show relative path from memories directory
    relative="${file#$MEMORIES_DIR/}"
    display_files+=("memories/$relative")
done

# Let user select files with improved styling
selected_display=$(printf '%s\n' "${display_files[@]}" | fzf --multi \
    --header="Select memories (TAB=select, ENTER=confirm)" \
    --height=100% --reverse \
    --border=rounded --border-label="╱ Claude Code Memory Selection ╱" --border-label-pos=3 \
    --info=inline-right \
    --color="fg+:15,bg+:-1,hl+:12,info:8,prompt:12,pointer:12,marker:2" \
    --padding=1,2 \
    --prompt="› " \
    --marker="✓ " \
    --pointer="▸")

# Process selections
if [[ -n "$selected_display" ]]; then
    prompt="Remember these technical knowledge areas for our session:"

    # Build content
    {
        echo "$prompt"
        echo
        while IFS= read -r display_path; do
            # Convert display path back to full path
            relative="${display_path#memories/}"
            file="$MEMORIES_DIR/$relative"

            if [[ -f "$file" ]]; then
                # Get basename without extension
                name="${file##*/}"
                name="${name%.md}"
                # Replace hyphens with spaces
                name="${name//-/ }"

                echo "## $name"
                echo
                cat "$file"
                echo
            fi
        done <<< "$selected_display"
    } | {
        # If TARGET_PANE is provided, load into tmux buffer and paste
        if [[ -n "$TARGET_PANE" ]]; then
            tmux load-buffer -
            tmux paste-buffer -t "$TARGET_PANE"
            tmux send-keys -t "$TARGET_PANE" Enter
        else
            # Otherwise just output to stdout (for testing)
            cat
        fi
    }
fi