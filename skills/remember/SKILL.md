# /remember

Capture something to short-term memory.

## Instructions

1. Determine the current project context:
   - If inside a git repo, use the repo name as project tag
   - Otherwise use "global"

2. Append to `~/.claude-memory/shortterm-{project}.md`:

```
## [CURRENT_TIMESTAMP_UTC]
**Type:** feedback
**Context:** [CURRENT_WORKING_DIRECTORY]
**Entry:** $ARGUMENTS
```

3. Stage and commit the change:
```bash
cd ~/.claude-memory && git add -A && git commit -m "yamc: remember shortterm-{project}" --quiet
```

4. Confirm with a brief one-liner. Do not interpret, classify, or editorialize.
