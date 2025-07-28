.PHONY: install

install:
	mkdir -p ~/.claude/hooks ~/.claude/memories
	cp -f .claude/hooks/_memory-selector.zsh ~/.claude/hooks/
	cp -f .claude/hooks/session-start-memory-check.zsh ~/.claude/hooks/
	chmod +x ~/.claude/hooks/_memory-selector.zsh
	chmod +x ~/.claude/hooks/session-start-memory-check.zsh
	cp -f .claude/settings.json ~/.claude/