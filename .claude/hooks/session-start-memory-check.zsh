#!/usr/bin/env zsh
# Simplified memory selection hook for Claude Code

# Basic configuration
MEMORIES_DIR="${HOME}/.claude/memories"

# Skip if not in tmux
[[ -z "$TMUX" ]] && exit 0

# Use tmux session and window as stable identifier
TMUX_SESSION="$(tmux display-message -p '#S:#I')"
SESSION_MARKER="/tmp/claude-memory-selected-${TMUX_SESSION//[^a-zA-Z0-9]/-}"

# Skip if already run for this tmux session/window
[[ -f "$SESSION_MARKER" ]] && exit 0

# Mark session
touch "$SESSION_MARKER"

# Check requirements
command -v tmux >/dev/null 2>&1 || exit 0
command -v fzf >/dev/null 2>&1 || exit 0

# Get target pane
TARGET_PANE="$(tmux display-message -p '#S:#I.#P')"

# Create temporary script for the popup
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << 'EOF'
#!/usr/bin/env zsh

MEMORIES_DIR="$1"
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
    --border=rounded --border-label="╱ Memory Selection ╱" --border-label-pos=3 \
    --info=inline-right \
    --color="fg+:15,bg+:-1,hl+:12,info:8,prompt:12,pointer:12" \
    --padding=1,2 \
    --prompt="› ")

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
    } | tmux load-buffer -
    
    tmux paste-buffer -t "$TARGET_PANE"
    tmux send-keys -t "$TARGET_PANE" Enter
fi
EOF

chmod +x "$TEMP_SCRIPT"

# Run in tmux popup
tmux display-popup -E -w 80% -h 60% -t "$TARGET_PANE" -- "$TEMP_SCRIPT" "$MEMORIES_DIR" "$TARGET_PANE"

# Cleanup
rm -f "$TEMP_SCRIPT"