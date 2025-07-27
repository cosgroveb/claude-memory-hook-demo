# Claude Memory Hook Demo

A minimal example of selective memory loading for Claude Code using hooks.

## What This Solves

Instead of loading all technical documentation into every Claude session (burning thousands of tokens), this hook lets you select only the relevant memories when you start working.

## Setup

1. Copy the `.claude` directory structure to your home directory
2. Make the hook executable: `chmod +x ~/.claude/hooks/session-start-memory-check.zsh`
3. Add your own memory files to `~/.claude/memories/`

## How It Works

When you first interact with Claude in a new session:
1. A tmux popup appears showing available memories
2. Use TAB to select relevant ones, ENTER to confirm
3. Claude receives only the selected context

## Requirements

- tmux (version 3.2+)
- fzf
- zsh

## Directory Structure

```
.claude/
├── CLAUDE.md          # Project context (loaded automatically)
├── settings.json      # Hook configuration
├── hooks/
│   └── session-start-memory-check.zsh
└── memories/         # Your technical knowledge base
    ├── bash-best-practices.md
    ├── debugging-process.md
    ├── testing-guidelines.md
    ├── aws-patterns.md
    └── security-checklist.md
```