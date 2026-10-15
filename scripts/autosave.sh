#!/bin/bash
# Stop hook: commit whitelisted changes in ~/.claude and push them to the backup repo.
# Returns at once; the commit and push run in the background. Does nothing until
# /dotclaude-sync:setup has connected ~/.claude to a repo. A staged change that looks like
# a secret stops the commit and leaves a note for the next user message.
cat >/dev/null
[ "$DOTCLAUDE_SYNC_DISABLE" = 1 ] && exit 0
. "$(dirname "$0")/common.sh"
is_set_up || exit 0

(
  mkdir "$DATA/autosave.lock" 2>/dev/null || exit 0        # a run is already in progress
  trap 'rmdir "$DATA/autosave.lock" 2>/dev/null' EXIT
  cd "$DIR" || exit 0
  [ -e .git/index.lock ] && exit 0                          # another git command is running

  git add -A
  if ! git diff --cached --quiet; then
    if git diff --cached -U0 | grep '^+' | grep -q -I -E -i "$SECRET_RE"; then
      files=$(git diff --cached --name-only | tr '\n' ' ')
      git reset -q
      note "dotclaude-sync: autosave stopped. A change looks like a secret ($files). Nothing was committed or pushed. Remove the secret; the next autosave continues."
      exit 0
    fi
    files=$(git diff --cached --name-only | head -5 | tr '\n' ' ')
    git commit -q -m "Autosave: $files" >>"$LOG" 2>&1
  fi

  # Push when the branch is ahead of the remote (this also retries earlier failed pushes).
  if [ -n "$(git log --oneline '@{u}..' 2>/dev/null)" ]; then
    if git push -q >>"$LOG" 2>&1; then
      rm -f "$DATA/push-failed"
    elif [ ! -e "$DATA/push-failed" ]; then           # tell the user once per failure streak
      touch "$DATA/push-failed"
      note "dotclaude-sync: push to $(git remote get-url origin) failed. Check 'gh auth status'. Details: $LOG"
    fi
  fi
) </dev/null >/dev/null 2>&1 &
exit 0
