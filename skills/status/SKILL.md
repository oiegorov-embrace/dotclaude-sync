---
name: status
description: Show the dotclaude-sync backup state of ~/.claude (repo, last backup, unpushed or uncommitted changes, notes). Use when the user runs /dotclaude-sync:status or asks "is my .claude backed up", "did my config sync", or "what is in my Claude backup".
---

1. Run:

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/status.sh"
   ```

2. Summarize it in a few lines. If there are unpushed commits or a note about a failed push, suggest `gh auth status` to check the login. To list exactly which files are backed up, run `git -C ~/.claude ls-files`.
