#!/bin/bash
# Connect ~/.claude to a private GitHub backup repo and make the first push.
# Usage: setup.sh [owner/name]   (default: plugin option "repo", else <gh login>/claude-config)
# Needs a working `gh` login. Safe to run again: it reports and stops if already set up.
# It does NOT restore from a repo that already has content.
set -u
. "$(dirname "$0")/common.sh"
TEMPLATE="$(dirname "$0")/../templates/gitignore"
fail() { echo "SETUP FAILED: $*"; exit 1; }

if is_set_up; then
  echo "Already set up: $DIR -> $(git -C "$DIR" remote get-url origin)"
  exit 0
fi

if [ -z "${DOTCLAUDE_REMOTE_URL:-}" ]; then
  gh auth status >/dev/null 2>&1 || fail "gh is not logged in. Run 'gh auth login' in a terminal, then run setup again."
  login=$(gh api user --jq .login) || fail "cannot read the gh user"
fi
repo="${1:-${CLAUDE_PLUGIN_OPTION_REPO:-}}"
[ -n "$repo" ] || repo="${login:-local}/claude-config"
case "$repo" in */*) ;; *) fail "repo must be owner/name, got '$repo'" ;; esac

# 1. Check the remote repo before touching anything: it must be private and empty, or absent.
if [ -z "${DOTCLAUDE_REMOTE_URL:-}" ]; then
  if info=$(gh repo view "$repo" --json visibility,isEmpty 2>/dev/null); then
    [ "$(jq -r .visibility <<<"$info")" = PRIVATE ] || fail "$repo exists and is not private. Use a private repo."
    [ "$(jq -r .isEmpty <<<"$info")" = true ] || fail "$repo already has content. Restore is not supported yet; use another repo name."
    create=no
  else
    create=yes
  fi
  url="https://github.com/$repo.git"
else
  create=no; url="$DOTCLAUDE_REMOTE_URL"   # tests: a local bare repo
fi

# 2. Local repo with the whitelist.
cd "$DIR" || fail "$DIR does not exist"
[ -d .git ] || git init -q -b main || fail "git init failed"
if [ -f .gitignore ]; then
  echo "Kept the existing $DIR/.gitignore (not replaced by the plugin whitelist)."
else
  cp "$TEMPLATE" .gitignore
fi
if [ -z "$(git config user.email)" ] && [ -n "${login:-}" ]; then
  id=$(gh api user --jq .id)
  git config user.name "$login"
  git config user.email "$id+$login@users.noreply.github.com"
fi

# 3. First commit, with a secret check.
git add -A
if git diff --cached -U0 | grep '^+' | grep -q -I -E -i "$SECRET_RE"; then
  echo "Files with possible secrets:"
  git diff --cached --name-only | while read -r f; do
    git diff --cached -U0 -- "$f" | grep '^+' | grep -q -I -E -i "$SECRET_RE" && echo "  $f"
  done
  git reset -q
  fail "nothing was committed. Remove the secrets (or exclude those files in .gitignore), then run setup again."
fi
git diff --cached --quiet || git commit -q -m "dotclaude-sync: first backup of ~/.claude" || fail "commit failed"

# 4. Remote and first push.
if [ "$create" = yes ]; then
  gh repo create "$repo" --private --description "Backup of my ~/.claude (dotclaude-sync)" >/dev/null || fail "gh repo create $repo failed"
fi
git remote add origin "$url" 2>/dev/null || git remote set-url origin "$url"
git push -q -u origin HEAD 2>&1 || fail "push to $url failed"

echo "Set up: $DIR -> $url ($( [ $create = yes ] && echo 'new private repo' || echo 'existing empty repo'))"
echo "Tracked files ($(git ls-files | wc -l | tr -d ' ')):"
git ls-files | sed 's/^/  /'
