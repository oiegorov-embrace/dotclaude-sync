# Shared paths for dotclaude-sync scripts. Sourced, not run.
DIR="${DOTCLAUDE_DIR:-$HOME/.claude}"                     # the folder that is backed up
DATA="${CLAUDE_PLUGIN_DATA:-$DIR/.dotclaude-sync}"          # plugin state: notices, log
mkdir -p "$DATA"
NOTICES="$DATA/notices.pending"
LOG="$DATA/autosave.log"
SECRET_RE='(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY|(api[_-]?key|secret|password|token)["'"'"' ]*[:=]["'"'"' ]*[A-Za-z0-9/+_-]{12,})'

note() { echo "$(date '+%Y-%m-%d %H:%M')	$*" >>"$NOTICES"; }
is_set_up() { [ -d "$DIR/.git" ] && git -C "$DIR" remote get-url origin >/dev/null 2>&1; }
