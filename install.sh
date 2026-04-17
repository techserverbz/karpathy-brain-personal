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

echo ""
echo "Hooks installed to: $HOOKS_DIR/"
ls "$HOOKS_DIR/"*.sh 2>/dev/null | while read f; do echo "  $(basename "$f")"; done
echo ""
echo "Wiki at: $WIKI_HOME/"
echo ""
echo "Next steps:"
echo "  1. Add hooks to ~/.claude/settings.json (see README.md)"
echo "  2. Paste CLAUDEMD-SNIPPET.md into your CLAUDE.md"
echo "  3. Restart Claude Code"
echo ""
echo "To update later: git pull && bash install.sh"
