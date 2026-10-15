#!/bin/bash
# UserPromptSubmit hook: pass dotclaude-sync notes (secret found, push failed) to Claude once.
# Prints nothing when there is no note, so it costs nothing on most messages.
cat >/dev/null
. "$(dirname "$0")/common.sh"
[ -s "$NOTICES" ] || exit 0
mv "$NOTICES" "$NOTICES.$$" 2>/dev/null || exit 0
notes=$(cut -f2- "$NOTICES.$$"); rm -f "$NOTICES.$$"
jq -n --arg c "Tell the user in one line each:
$notes" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $c}}'
