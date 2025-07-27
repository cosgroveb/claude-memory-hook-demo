#!/usr/bin/env zsh
# ~/.claude/hooks/session-start-memory-check.zsh
# Zsh-optimized version with 5 key improvements

# Improvement #1: Zsh's setopt for better safety and features
setopt ERR_EXIT          # Exit on error (like set -e)
setopt PIPE_FAIL         # Fail on pipe errors (like set -o pipefail)
setopt NO_UNSET          # Error on unset variables (like set -u)
setopt EXTENDED_GLOB     # Enable advanced glob patterns
setopt NULL_GLOB        # Empty array if no matches (prevents errors)

# Configuration
typeset -r MEMORIES_DIR="${HOME}/.claude/memories"
typeset -r SESSION_MARKER="/tmp/claude-session-$$"

# Check prerequisites using zsh's cleaner conditionals
[[ -f $SESSION_MARKER ]] && exit 0
[[ -z $TMUX ]] && exit 0
(( $+commands[tmux] )) || exit 0
(( $+commands[fzf] )) || exit 0

# Mark session as initialized
touch $SESSION_MARKER

# Get current tmux pane
TARGET_PANE="$(tmux display-message -p '#S:#I.#P')"

# Show memory selection popup with embedded zsh
tmux display-popup -E -w 80% -h 80% -t "$TARGET_PANE" zsh -c '
    setopt ERR_EXIT PIPE_FAIL NO_UNSET EXTENDED_GLOB NULL_GLOB
    
    # Improvement #2: Zsh arrays handle spaces/special chars properly
    typeset -r MEMORIES_DIR="'"$MEMORIES_DIR"'"
    typeset -r TARGET_PANE="'"$TARGET_PANE"'"
    
    # Check directory existence
    if [[ ! -d $MEMORIES_DIR ]]; then
        print "No memories directory found at $MEMORIES_DIR"
        print "Press any key to continue..."
        read -k 1
        exit 0
    fi
    
    # Improvement #3: Zsh glob patterns with qualifiers
    # (.N) = NULL_GLOB, (.) = regular files only, (om) = sort by modification time
    typeset -a memory_files
    memory_files=( $MEMORIES_DIR/**/*.md(.Nom) )
    
    if (( ${#memory_files} == 0 )); then
        print "No memory files found"
        print "Press any key to continue..."
        read -k 1
        exit 0
    fi
    
    # Improvement #4: Zsh parameter expansion for transformations
    # Create user-friendly names using zsh modifiers
    typeset -a memory_names
    for file in $memory_files; do
        # :t = basename, :r = remove extension
        # ${(C)var} = capitalize words, ${var:gs/-/ /} = global substitution
        local name=${${file:t:r}:gs/-/ /}
        memory_names+=( ${(C)name} )
    done
    
    # Create associative array for name->file mapping
    typeset -A name_to_file
    for i in {1..$#memory_files}; do
        name_to_file[$memory_names[$i]]=$memory_files[$i]
    done
    
    # Create a preview script that can access our associative array
    # This is cleaner than trying to pass complex data through environment
    local preview_cmd='
        name=$1
        shift
        # Recreate the file mapping
        typeset -A name_to_file
        while [[ $# -gt 0 ]]; do
            name_to_file[$1]=$2
            shift 2
        done
        
        # Show the preview with nice formatting
        print "\\033[1;36m━━━ $name ━━━\\033[0m"
        print
        if [[ -f ${name_to_file[$name]} ]]; then
            # Show file size and preview
            local size=$(wc -c < "${name_to_file[$name]}" | tr -d " ")
            local lines=$(wc -l < "${name_to_file[$name]}" | tr -d " ")
            print "\\033[90m📄 $lines lines, $size bytes\\033[0m"
            print
            cat "${name_to_file[$name]}" | head -40
        else
            print "\\033[31mFile not found\\033[0m"
        fi
    '
    
    # Build arguments for preview command
    local -a preview_args
    for name filepath in ${(kv)name_to_file}; do
        preview_args+=( "$name" "$filepath" )
    done
    
    # Let user select memories with fzf
    # Enhanced with preview showing file content
    local selected_names
    selected_names=$(print -l $memory_names | fzf --multi \
        --header="Select Technical Knowledge (TAB=select, ENTER=confirm)" \
        --height=80% --reverse --border --info=inline \
        --preview="zsh -c '$preview_cmd' -- {} $preview_args" \
        --preview-window=right:60%:wrap) || exit 0
    
    if [[ -n $selected_names ]]; then
        # Build the prompt content
        local prompt="Remember these technical knowledge areas for our session:"
        
        # Improvement #5: Zsh string accumulation with proper quoting
        local content=""
        for name in ${(f)selected_names}; do
            local filepath=$name_to_file[$name]
            
            if [[ -f $filepath ]]; then
                content+=$'"'"'

## '"'"'$name$'"'"'
'"'"'$(<$filepath)
            fi
        done
        
        # Use zsh here-string for cleaner syntax
        print -r -- "$prompt$content" | tmux load-buffer -
        
        tmux paste-buffer -t "$TARGET_PANE"
        tmux send-keys -t "$TARGET_PANE" Enter
    fi
'