#!/bin/bash
# wiki-ingest.sh (PERSONAL) — ingest a curated doc into wiki pages
# Usage: bash ~/.claude/hooks/wiki-ingest.sh {category} {source-file}
#
# Personal wiki has no skills/candidate split — ingested pages go
# directly to wiki/{category}/ and are treated as verified reference material.

CLAUDE_HOME="$USERPROFILE/.claude"
WIKI_HOME="$CLAUDE_HOME/wiki"
WIKI_PAGES="$WIKI_HOME/wiki"

CATEGORY="$1"
SOURCE_FILE="$2"

if [ -z "$CATEGORY" ] || [ -z "$SOURCE_FILE" ]; then
  echo "Usage: wiki-ingest.sh {category} {source-file}"
  echo ""
  echo "Categories: codebases, business, people, decisions, ideas, patterns,"
  echo "            systems, clients, finance, tools, research, meetings"
  echo ""
  echo "Example:"
  echo "  bash ~/.claude/hooks/wiki-ingest.sh tools ~/docs/my-workflow.md"
  exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
  echo "[ingest] Source file not found: $SOURCE_FILE"
  exit 1
fi

mkdir -p "$WIKI_PAGES/$CATEGORY" 2>/dev/null

SOURCE_BASENAME=$(basename "$SOURCE_FILE")
SOURCE_PATH=$(realpath "$SOURCE_FILE" 2>/dev/null || echo "$SOURCE_FILE")

USER_NAME="${USERNAME:-$USER}"
[ -z "$USER_NAME" ] && USER_NAME=$(whoami 2>/dev/null | tr -d '[:space:]')
MACHINE_NAME="${COMPUTERNAME:-$(hostname 2>/dev/null | tr -d '[:space:]')}"
TODAY=$(date +%Y-%m-%d)

echo "[ingest] Category: $CATEGORY"
echo "[ingest] Source: $SOURCE_BASENAME"
echo "[ingest] Target: $WIKI_PAGES/$CATEGORY/"

PROMPT_FILE=$(mktemp)
cat > "$PROMPT_FILE" <<PROMPT
You are ingesting a curated document into a personal wiki.

SOURCE FILE: $SOURCE_PATH
CATEGORY: $CATEGORY
TODAY: $TODAY
USER: $USER_NAME
MACHINE: $MACHINE_NAME
WIKI_TARGET: $WIKI_PAGES/$CATEGORY

TASK:
1. READ the source file completely
2. IDENTIFY natural sections — split into focused pages (one topic per page)
3. WRITE each page to \$WIKI_TARGET/{slug}.md

PAGE FORMAT:
---
ingested_on: $TODAY
ingested_by: $USER_NAME@$MACHINE_NAME
source_file: $SOURCE_BASENAME
source_path: $SOURCE_PATH
category: $CATEGORY
---

# Page Title
> Category: $CATEGORY | Last updated: $TODAY | Confidence: verified

Content derived from source. Preserve tables, formulas, exact numbers.

## Related
- [[other-page]]

RULES:
1. One topic per page. Keep focused.
2. Preserve tables, formulas, exact numbers — do NOT paraphrase values.
3. Cross-link via relative [[slug]] refs.
4. Append entry to $WIKI_PAGES/log.md (date, source, pages created).
5. Update $WIKI_PAGES/index.md.

Execute now.
PROMPT

cd "$WIKI_HOME" && claude -p "$(cat "$PROMPT_FILE")" --dangerously-skip-permissions

rm -f "$PROMPT_FILE"
echo "[ingest] Done. Review: ls '$WIKI_PAGES/$CATEGORY'"
