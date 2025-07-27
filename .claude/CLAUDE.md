# Claude Memory Hook Demo

This is a minimal example showing how to use hooks for selective memory loading.

## Project Context
This demo showcases a memory selection system for Claude Code that:
- Prompts you to select relevant memories at session start
- Uses file-based storage instead of external dependencies
- Maintains context without burning unnecessary tokens

## Available Memories
Technical knowledge is stored in `~/.claude/memories/`:
- `bash-best-practices.md` - Shell scripting conventions
- `debugging-process.md` - Systematic debugging methodology
- `testing-guidelines.md` - Testing best practices
- `aws-patterns.md` - AWS service patterns
- `security-checklist.md` - Security review guidelines