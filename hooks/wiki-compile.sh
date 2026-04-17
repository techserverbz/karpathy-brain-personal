#!/bin/bash
# Wiki compile/lint/restructure (PERSONAL) — raw → wiki/{category}/ directly
# Usage: bash ~/.claude/hooks/wiki-compile.sh [compile|lint|restructure]

ACTION="${1:-compile}"
WIKI_HOME="$USERPROFILE/.claude/wiki"
WIKI_RAW="$WIKI_HOME/raw"
WIKI_PAGES="$WIKI_HOME/wiki"
WIKI_STATE="$WIKI_HOME/_state"

[ ! -d "$WIKI_HOME" ] && echo "Wiki not found at $WIKI_HOME" && exit 1

RAW_COUNT=$(ls "$WIKI_RAW"/*.md 2>/dev/null | wc -l | tr -d '[:space:]')
echo "[Wiki] Action: $ACTION | Raw logs: $RAW_COUNT"

if [ "$ACTION" = "compile" ] && [ "$RAW_COUNT" -eq 0 ]; then
  echo "[Wiki] Nothing to compile."
  exit 0
fi

ACTIVE_LOG=""
[ -f "$WIKI_STATE/current_rawlog.txt" ] && ACTIVE_LOG=$(cat "$WIKI_STATE/current_rawlog.txt" 2>/dev/null | tr -d '[:space:]')
ACTIVE_BASENAME=""
[ -n "$ACTIVE_LOG" ] && ACTIVE_BASENAME=$(basename "$ACTIVE_LOG")

RAW_CONTENT=""
LOGS_TO_PROCESS=""
if [ "$ACTION" = "compile" ]; then
  for f in "$WIKI_RAW"/*.md; do
    [ -f "$f" ] || continue
    [ "$(basename "$f")" = "$ACTIVE_BASENAME" ] && continue
    RAW_CONTENT+="--- FILE: $(basename "$f") ---
"
    RAW_CONTENT+="$(head -80 "$f")

"
    LOGS_TO_PROCESS+="$(basename "$f") "
  done
fi

INDEX_CONTENT=""
[ -f "$WIKI_PAGES/index.md" ] && INDEX_CONTENT=$(cat "$WIKI_PAGES/index.md")

case "$ACTION" in
  compile)
    PROMPT="You are a wiki compiler for a personal second brain at $WIKI_HOME.

RAW SESSION LOGS:
$RAW_CONTENT

CURRENT INDEX:
$INDEX_CONTENT

COMPILE IN 5 PHASES:

Phase 1 ANALYZE: Read the raw logs above. List every discrete fact, decision, person, tool, or codebase mentioned.

Phase 2 SCAN: Read existing wiki pages in $WIKI_PAGES/ (check each category folder). Note overlaps and conflicts with new facts.

Phase 3 UPDATE: Create or update wiki pages. Rules:
- Path: $WIKI_PAGES/{category}/{slug}.md
- Categories: codebases, business, people, decisions, ideas, patterns, systems, clients, finance, tools, research, meetings
- Page format:
  # Page Title
  > Category: {cat} | Last updated: $(date +%Y-%m-%d) | Confidence: high/medium/low
  - Fact [source: YYYY-MM-DD | user@machine]
  ## Related
  - [[other-page]]
- One topic per page. Bullet points. Source-attribute every fact.
- Every raw log has user: and machine: in frontmatter — extract and use in source attribution.
- If new fact conflicts with existing: add [!contradiction] marker, keep both, note which is newer.

Phase 4 QUALITY GATE: Re-read each page you wrote. Verify every fact traces back to a raw log. Remove anything you inferred but can't source.

Phase 5 REPORT:
- Rewrite $WIKI_PAGES/index.md with full catalog of ALL pages (existing + new)
- Rewrite $WIKI_PAGES/hot.md with ~500 words of the most recent important context
- Append compile report to $WIKI_PAGES/log.md
- Move ONLY these processed raw logs to $WIKI_RAW/processed/: $LOGS_TO_PROCESS
- Reset counter: echo 0 > $WIKI_STATE/counter.txt
- Update timestamp: date > $WIKI_STATE/last_compile.txt

Execute all 5 phases now."
    ;;

  lint)
    PROMPT="You are a wiki linter for a personal second brain at $WIKI_HOME.

CURRENT INDEX:
$INDEX_CONTENT

LINT THE ENTIRE WIKI:
1. Read ALL wiki pages in $WIKI_PAGES/
2. Find contradictions between pages — add [!contradiction] markers
3. Find stale pages (Last updated > 30 days)
4. Find orphan pages (exist but NOT in index.md) — add to index
5. Find missing pages (referenced via [[link]] but don't exist) — create stubs
6. Fix broken cross-references
7. Verify every page follows template format
8. Append lint report to $WIKI_PAGES/log.md
9. Update timestamp: date > $WIKI_STATE/last_lint.txt

Execute now."
    ;;

  restructure)
    PROMPT="You are a wiki restructurer for a personal second brain at $WIKI_HOME.

CURRENT INDEX:
$INDEX_CONTENT

RESTRUCTURE:
1. Read ALL wiki pages
2. Analyze: are the 12 categories still right?
3. Merge small overlapping pages
4. Split large multi-topic pages
5. Move matured pages (ideas → business if real)
6. Full index.md rebuild
7. Rewrite hot.md
8. Append restructure report to log.md

Execute now."
    ;;

  *)
    echo "Usage: wiki-compile.sh [compile|lint|restructure]"
    exit 1
    ;;
esac

echo "[Wiki] Running $ACTION via claude -p..."

PROMPT_FILE=$(mktemp)
echo "$PROMPT" > "$PROMPT_FILE"

cd "$WIKI_HOME" && claude -p "$(cat "$PROMPT_FILE")" --dangerously-skip-permissions 2>/dev/null

rm -f "$PROMPT_FILE"
echo "[Wiki] $ACTION complete."
