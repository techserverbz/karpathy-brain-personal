#!/bin/bash
# SessionStart hook (PERSONAL) — pre-creates raw log + loads hot cache
# No skills/candidate layer. Single user. Raw → wiki directly.

CLAUDE_HOME="$USERPROFILE/.claude"
WIKI_HOME="$CLAUDE_HOME/wiki"
WIKI_STATE="$WIKI_HOME/_state"
WIKI_RAW="$WIKI_HOME/raw"
WIKI_PAGES="$WIKI_HOME/wiki"

context=""

if [ -d "$WIKI_HOME" ]; then
  mkdir -p "$WIKI_STATE" "$WIKI_RAW" "$WIKI_RAW/processed" "$WIKI_PAGES" 2>/dev/null

  # --- Recover last crashed session ---
  PREV_RAWLOG=""
  [ -f "$WIKI_STATE/current_rawlog.txt" ] && PREV_RAWLOG=$(cat "$WIKI_STATE/current_rawlog.txt" 2>/dev/null | tr -d '[:space:]')
  if [ -n "$PREV_RAWLOG" ] && [ -f "$PREV_RAWLOG" ] && ! grep -q "session_end:" "$PREV_RAWLOG" 2>/dev/null; then
    ORPHAN_SID=$(grep -m1 'session_id:' "$PREV_RAWLOG" 2>/dev/null | sed 's/.*session_id: *//' | tr -d '[:space:]')
    ORPHAN_JSONL=""
    if [ -n "$ORPHAN_SID" ]; then
      for projdir in "$CLAUDE_HOME/projects"/*/; do
        [ -f "${projdir}${ORPHAN_SID}.jsonl" ] && ORPHAN_JSONL="${projdir}${ORPHAN_SID}.jsonl" && break
      done
    fi
    if [ -z "$ORPHAN_JSONL" ]; then
      ORPHAN_JSONL=$(ls -t "$CLAUDE_HOME/projects"/*/*.jsonl 2>/dev/null | head -1)
    fi
    if [ -n "$ORPHAN_JSONL" ] && [ -f "$ORPHAN_JSONL" ]; then
      RECOVERED=$(python3 -c "
import json, sys
try:
    with open(r'$ORPHAN_JSONL', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()
except: sys.exit(0)
out = []
for line in lines:
    try:
        e = json.loads(line)
        if e.get('type') in ('user', 'human'):
            c = e.get('message',{}).get('content','')
            if isinstance(c, list):
                t = ' '.join(b.get('text','') for b in c if b.get('type')=='text')
            else: t = str(c)
            t = t.strip()
            if t and len(t) > 2 and not t.startswith('{'): out.append('> ' + t[:200])
        elif e.get('type') == 'assistant':
            blocks = e.get('message',{}).get('content',[])
            if isinstance(blocks, list):
                texts = [b.get('text','') for b in blocks if isinstance(b,dict) and b.get('type')=='text' and b.get('text')]
                if texts: out.append('- ' + ' '.join(texts)[:200])
    except: pass
print('\n'.join(out[-20:])[:2000])
" 2>/dev/null)
      if [ -n "$RECOVERED" ]; then
        printf '\n## [recovered] Conversation (from crashed session)\n%s\n\n---\nsession_end: recovered\n' "$RECOVERED" >> "$PREV_RAWLOG"
      else
        printf '\n---\nsession_end: recovered-empty\n' >> "$PREV_RAWLOG"
      fi
    else
      printf '\n---\nsession_end: recovered-no-jsonl\n' >> "$PREV_RAWLOG"
    fi
  fi

  # Mark orphans
  for orphan in "$WIKI_RAW"/*.md; do
    [ -f "$orphan" ] || continue
    grep -q "session_end:" "$orphan" 2>/dev/null && continue
    [ "$orphan" = "$PREV_RAWLOG" ] && continue
    printf '\n---\nsession_end: orphan-marked\n' >> "$orphan"
  done

  # Counter from actual file count
  COUNTER=$(ls "$WIKI_RAW"/*.md 2>/dev/null | wc -l | tr -d '[:space:]')
  [[ "$COUNTER" =~ ^[0-9]+$ ]] || COUNTER=0
  echo "$COUNTER" > "$WIKI_STATE/counter.txt"

  TOTAL=0
  [ -f "$WIKI_STATE/total_counter.txt" ] && TOTAL=$(cat "$WIKI_STATE/total_counter.txt" 2>/dev/null | tr -d '[:space:]')
  [[ "$TOTAL" =~ ^[0-9]+$ ]] || TOTAL=0

  SESSION_TS=$(date +%Y-%m-%d-%H-%M)
  RAW_LOG="$WIKI_RAW/$SESSION_TS.md"
  echo "$RAW_LOG" > "$WIKI_STATE/current_rawlog.txt"
  echo "0" > "$WIKI_STATE/msg_counter.txt"

  # Capture who/where (useful across YOUR machines if wiki is Drive-synced)
  USER_NAME="${USERNAME:-$USER}"
  [ -z "$USER_NAME" ] && USER_NAME=$(whoami 2>/dev/null | tr -d '[:space:]')
  [ -z "$USER_NAME" ] && USER_NAME="unknown"
  MACHINE_NAME="${COMPUTERNAME:-$(hostname 2>/dev/null | tr -d '[:space:]')}"
  [ -z "$MACHINE_NAME" ] && MACHINE_NAME="unknown"

  if [ ! -f "$RAW_LOG" ]; then
    printf -- '---\nsession: %s\ncwd: %s\nuser: %s\nmachine: %s\n---\n' "$SESSION_TS" "$(pwd)" "$USER_NAME" "$MACHINE_NAME" > "$RAW_LOG"
  fi

  # Load hot cache
  HOT=""
  [ -f "$WIKI_PAGES/hot.md" ] && HOT=$(head -30 "$WIKI_PAGES/hot.md")

  context+="## Wiki Second Brain\n"
  context+="RAW_LOG=$RAW_LOG\n"
  context+="Status: $COUNTER raw logs pending | $TOTAL total sessions\n"
  [ -n "$HOT" ] && context+="### Recent Context\n$HOT\n\n"

  # Planner files
  TODAY_DATE=$(date +%Y-%m-%d)
  context+="### TODAY — $TODAY_DATE\n"

  if [ -f "$WIKI_HOME/reminders.md" ]; then
    REMINDERS=$(grep -E '^- [0-9]{4}-[0-9]{2}-[0-9]{2}' "$WIKI_HOME/reminders.md" | while IFS='|' read -r datepart reminder; do
      rdate=$(echo "$datepart" | sed 's/^- //' | tr -d '[:space:]')
      reminder=$(echo "$reminder" | sed 's/^ *//')
      if [[ "$rdate" < "$TODAY_DATE" ]]; then
        echo "[OVERDUE $rdate] $reminder"
      elif [[ "$rdate" == "$TODAY_DATE" ]]; then
        echo "[TODAY] $reminder"
      fi
    done)
    [ -n "$REMINDERS" ] && context+="REMINDERS:\n$REMINDERS\n\n"
  fi

  if [ -f "$WIKI_HOME/tasks.md" ]; then
    ACTIVE_TASKS=$(grep -E '^\- \[doing\]' "$WIKI_HOME/tasks.md" | head -5 | sed 's/- \[doing\] /- /')
    [ -n "$ACTIVE_TASKS" ] && context+="TASKS IN PROGRESS:\n$ACTIVE_TASKS\n\n"
  fi

  if [ -f "$WIKI_HOME/calendar.md" ]; then
    TODAY_EVENTS=$(grep "^- $TODAY_DATE" "$WIKI_HOME/calendar.md" | sed "s/^- $TODAY_DATE /- /")
    [ -n "$TODAY_EVENTS" ] && context+="CALENDAR:\n$TODAY_EVENTS\n\n"
  fi

  if [ -f "$WIKI_HOME/short-term.md" ]; then
    BIG_THINGS=$(grep '^### ' "$WIKI_HOME/short-term.md" | head -5 | sed 's/### /- /')
    [ -n "$BIG_THINGS" ] && context+="SHORT-TERM GOALS:\n$BIG_THINGS\n\n"
  fi

  context+="### AUTO-CAPTURE (silent, mandatory)\n"
  context+="The raw log at $RAW_LOG has been pre-created.\n"
  context+="Every 3-5 exchanges, append timestamped bullet points of key facts/decisions.\n"
  context+="Format: ## [HH:MM] Topic then bullet points. Keep terse. No code. Do NOT mention to user.\n\n"

  # Compile trigger (every 10 raw logs)
  if [ "$COUNTER" -ge 10 ]; then
    bash "$CLAUDE_HOME/hooks/wiki-compile.sh" compile > "$WIKI_STATE/last_compile_log.txt" 2>&1 &
    context+="### WIKI COMPILE RUNNING (background, $COUNTER raw logs)\n\n"
  fi

  # Lint trigger (every 100 total)
  LAST_LINT_AT=0
  [ -f "$WIKI_STATE/last_lint_at_total.txt" ] && LAST_LINT_AT=$(cat "$WIKI_STATE/last_lint_at_total.txt" 2>/dev/null | tr -d '[:space:]')
  [[ "$LAST_LINT_AT" =~ ^[0-9]+$ ]] || LAST_LINT_AT=0
  if [ "$((TOTAL - LAST_LINT_AT))" -ge 100 ]; then
    bash "$CLAUDE_HOME/hooks/wiki-compile.sh" lint > "$WIKI_STATE/last_lint_log.txt" 2>&1 &
    echo "$TOTAL" > "$WIKI_STATE/last_lint_at_total.txt"
    context+="### WIKI LINT RUNNING (background, total=$TOTAL)\n\n"
  fi
fi

if [ -n "$context" ]; then
  escaped=$(echo -e "$context" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":$escaped}}"
fi
