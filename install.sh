#!/bin/bash
# install.sh — install or update Karpathy Brain (Personal)
# Usage: bash install.sh

CLAUDE_HOME="$USERPROFILE/.claude"
[ -z "$CLAUDE_HOME" ] && CLAUDE_HOME="$HOME/.claude"
WIKI_HOME="$CLAUDE_HOME/wiki"
HOOKS_DIR="$CLAUDE_HOME/hooks"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Karpathy Brain — Personal Install ==="
echo "Target: $CLAUDE_HOME"

# --- Capture git metadata from the clone (for sync log) ---
GIT_COMMIT="unknown"
GIT_COMMIT_DATE="unknown"
GIT_COMMIT_MSG="unknown"
GIT_REMOTE="unknown"
if [ -d "$SCRIPT_DIR/.git" ]; then
  GIT_COMMIT=$(git -C "$SCRIPT_DIR" rev-parse HEAD 2>/dev/null | head -c 40)
  GIT_COMMIT_DATE=$(git -C "$SCRIPT_DIR" log -1 --format=%cI 2>/dev/null)
  GIT_COMMIT_MSG=$(git -C "$SCRIPT_DIR" log -1 --format=%s 2>/dev/null)
  GIT_REMOTE=$(git -C "$SCRIPT_DIR" config --get remote.origin.url 2>/dev/null)
fi

INSTALLED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
USER_NAME="${USERNAME:-$USER}"
[ -z "$USER_NAME" ] && USER_NAME=$(whoami 2>/dev/null | tr -d '[:space:]')
MACHINE_NAME="${COMPUTERNAME:-$(hostname 2>/dev/null | tr -d '[:space:]')}"

# Create wiki structure
mkdir -p "$WIKI_HOME"/{raw/processed,wiki,_state}
mkdir -p "$HOOKS_DIR"

# Copy hooks (overwrites existing — this IS the update mechanism)
cp "$SCRIPT_DIR/hooks/"*.sh "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/"*.sh 2>/dev/null

# Seed wiki files only if they don't exist (don't overwrite user's data)
[ ! -f "$WIKI_HOME/wiki/index.md" ] && echo "# Wiki Index" > "$WIKI_HOME/wiki/index.md"
[ ! -f "$WIKI_HOME/wiki/hot.md" ] && echo "# Recent Context" > "$WIKI_HOME/wiki/hot.md"
[ ! -f "$WIKI_HOME/wiki/log.md" ] && echo "# Wiki Operations Log" > "$WIKI_HOME/wiki/log.md"
[ ! -f "$WIKI_HOME/_state/counter.txt" ] && echo "0" > "$WIKI_HOME/_state/counter.txt"
[ ! -f "$WIKI_HOME/_state/total_counter.txt" ] && echo "0" > "$WIKI_HOME/_state/total_counter.txt"

# --- Write sync log (overwrites current state) ---
SYNC_LOG="$WIKI_HOME/_state/karpathy_sync.json"
cat > "$SYNC_LOG" <<EOF
{
  "flavour": "personal",
  "installed_at": "$INSTALLED_AT",
  "installed_by": "$USER_NAME@$MACHINE_NAME",
  "git_commit": "$GIT_COMMIT",
  "git_commit_short": "${GIT_COMMIT:0:7}",
  "git_commit_date": "$GIT_COMMIT_DATE",
  "git_commit_message": "$GIT_COMMIT_MSG",
  "git_remote": "$GIT_REMOTE",
  "script_dir": "$SCRIPT_DIR"
}
EOF

# --- Append install entry to history log (newest on top not easy; append, sort by user) ---
HISTORY_LOG="$WIKI_HOME/_state/karpathy_sync_history.log"
printf '%s | commit=%s | %s | by=%s@%s\n' \
  "$INSTALLED_AT" "${GIT_COMMIT:0:7}" "$GIT_COMMIT_MSG" "$USER_NAME" "$MACHINE_NAME" >> "$HISTORY_LOG"

echo ""
echo "Hooks installed to: $HOOKS_DIR/"
ls "$HOOKS_DIR/"*.sh 2>/dev/null | while read f; do echo "  $(basename "$f")"; done
echo ""
echo "Wiki at: $WIKI_HOME/"
echo ""
echo "Sync log:"
echo "  Commit: ${GIT_COMMIT:0:7} ($GIT_COMMIT_DATE)"
echo "  Message: $GIT_COMMIT_MSG"
echo "  State:   $SYNC_LOG"
echo "  History: $HISTORY_LOG"
echo ""
echo "Next steps:"
echo "  1. Add hooks to ~/.claude/settings.json (see README.md)"
echo "  2. Paste CLAUDEMD-SNIPPET.md into your CLAUDE.md"
echo "  3. Restart Claude Code"
echo ""
echo "To check when you last updated: cat '$SYNC_LOG'"
echo "To update later:                git pull && bash install.sh"
