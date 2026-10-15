#!/bin/bash
# SessionStart hook: if ~/.claude is not connected to a backup repo yet, ask Claude to
# mention /dotclaude-sync:setup once. Silent when everything is set up.
cat >/dev/null
. "$(dirname "$0")/common.sh"
is_set_up && exit 0
jq -n '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext:
  "dotclaude-sync is installed but ~/.claude is not backed up yet. At a natural point, tell the user once: run /dotclaude-sync:setup to connect ~/.claude to a private GitHub repo."}}'
