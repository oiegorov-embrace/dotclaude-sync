#!/bin/bash
# Show the backup state of ~/.claude: remote, last backup, unsaved and unpushed changes, notes.
. "$(dirname "$0")/common.sh"
if ! is_set_up; then echo "Not set up. Run /dotclaude-sync:setup."; exit 0; fi
cd "$DIR"
git fetch -q origin 2>/dev/null
echo "Repo:           $(git remote get-url origin)"
echo "Last commit:    $(git log -1 --format='%h %cr: %s')"
echo "Unpushed:       $(git rev-list --count '@{u}..' 2>/dev/null || echo '?') commit(s)"
echo "Uncommitted:    $(git status --porcelain | wc -l | tr -d ' ') file(s) (saved after the next Claude reply)"
echo "Tracked files:  $(git ls-files | wc -l | tr -d ' ')"
[ -s "$NOTICES" ] && { echo "Pending notes:"; cut -f2- "$NOTICES" | sed 's/^/  /'; }
[ -s "$LOG" ] && { echo "Last log lines:"; tail -3 "$LOG" | sed 's/^/  /'; }
exit 0
