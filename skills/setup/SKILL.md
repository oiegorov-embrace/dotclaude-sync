---
name: setup
description: Connect ~/.claude to a private GitHub repo so dotclaude-sync backs it up after each Claude reply. Use when the user runs /dotclaude-sync:setup or asks to "back up my .claude", "set up dotclaude sync", or "connect my Claude config to GitHub".
argument-hint: "[owner/name]"
---

Set up the dotclaude-sync backup of `~/.claude`.

1. Run the setup script. Pass the repo the user gave (`$ARGUMENTS`), if any; otherwise the plugin option `repo`, else `<gh login>/claude-config`, is used:

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh" $ARGUMENTS
   ```

2. Report the result to the user in a few lines:
   - On success: the repo URL, that it is private, and the list of tracked files. Say that changes are now committed and pushed automatically after each Claude reply, and that transcripts, prompt history, caches and logs are never tracked.
   - On `SETUP FAILED`: quote the reason and the fix the script gives. Do not work around it (do not change gh login, repo visibility, or delete content in a repo).
3. If the script kept an existing `~/.claude/.gitignore`, say so and offer to compare it with the plugin whitelist at `${CLAUDE_PLUGIN_ROOT}/templates/gitignore`. Do not change it unless the user agrees.
