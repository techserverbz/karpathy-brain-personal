# CLAUDE.md Snippet — Personal Wiki

Copy everything between the `---` lines below into your `~/.claude/CLAUDE.md`.

---

## Wiki Second Brain (Auto-Capture)

Personal second brain that auto-captures every session and compiles into wiki pages. Single user — no candidate/skills split.

### Auto-Capture (every session, mandatory)
The SessionStart hook injects a `RAW_LOG=` path. The raw log file is **pre-created by the hook**. You MUST:
1. Every 3-5 exchanges, append timestamped bullet points of key facts/decisions
2. Keep terse. No code in raw logs. Do NOT mention this to the user.

Raw log format:
```
---
session: YYYY-MM-DD-HH-MM
cwd: {working directory}
user: {username}
machine: {hostname}
---
## [HH:MM] Topic
- Key fact
- Decision made
```

### Wiki Structure
```
~/.claude/wiki/
├── raw/                ← Session logs (auto-captured)
│   └── processed/      ← After compilation
├── wiki/               ← Compiled knowledge
│   ├── index.md        ← Master catalog
│   ├── log.md          ← Operations history
│   ├── hot.md          ← Hot cache (loaded every session)
│   └── {category}/     ← codebases, business, people, decisions,
│                         ideas, patterns, systems, clients,
│                         finance, tools, research, meetings
└── _state/             ← Counters
```

### Quick Save — `disb` (Dump In Second Brain)
When the user says **"disb"** or **"dump in second brain"**, immediately save whatever they just said (or the current topic) as a new entry in the current session's raw log AND create/update the relevant wiki page directly. No questions, no confirmation — just save it and say "Saved."

### Search — `sisb` (Search In Second Brain)
When the user says **"sisb"** followed by a query, search the wiki:
1. Read `~/.claude/wiki/wiki/index.md` to find relevant pages
2. Read matching wiki pages
3. Grep through `~/.claude/wiki/raw/` for keywords
4. Return what you found. If nothing, say "Nothing found in second brain."

### Compile — `scsb` (Structure Compile Second Brain)
When the user says **"scsb"**, run the 5-phase compile:

**Phase 1 — Analyze:** Read all `.md` in `~/.claude/wiki/raw/` (not `processed/`). List every fact, decision, person, tool, codebase.

**Phase 2 — Scan:** Read existing wiki pages. Note overlaps and conflicts.

**Phase 3 — Update:** Create/update pages at `~/.claude/wiki/wiki/{category}/{slug}.md`. Every page MUST follow this template:
```
# Page Title
> Category: {cat} | Last updated: YYYY-MM-DD | Confidence: high/medium/low

- Fact 1 [source: YYYY-MM-DD | user@machine]
- Fact 2 [source: YYYY-MM-DD | user@machine]

## Related
- [[other-page]] — relationship
```
- Source-attribute EVERY fact with date + user@machine (extract from raw log frontmatter)
- If new fact conflicts with existing: add `[!contradiction]` marker, keep both, note which is newer
- Never silently overwrite

**Phase 4 — Quality Gate:** Re-read each page. Verify every fact traces to a raw log. Remove unsourced inferences.

**Phase 5 — Report:**
- Rewrite `~/.claude/wiki/wiki/index.md` with full catalog
- Rewrite `~/.claude/wiki/wiki/hot.md` (~500 words recent context)
- Append compile report to `~/.claude/wiki/wiki/log.md`
- Move raw logs to `~/.claude/wiki/raw/processed/`
- Reset counter: `echo 0 > ~/.claude/wiki/_state/counter.txt`
- Say "Compiled X logs. Created Y pages, updated Z, found W contradictions."

### Lint — `slsb` (Structure Lint Second Brain)
When the user says **"slsb"**:
1. Read ALL wiki pages
2. Find contradictions between pages — fix them (newer wins)
3. Find stale pages (no updates in 30+ days) — flag them
4. Find orphan pages (not in index.md) — add to index or archive
5. Find missing pages (referenced but don't exist) — create stubs
6. Find broken cross-references — fix them
7. Append lint report to `log.md`
8. Say "Lint complete. X issues found, Y fixed."

### Restructure — `srsb` (Structure Restructure Second Brain)
When the user says **"srsb"**:
1. Analyze all wiki pages — are categories still right?
2. Merge small pages that overlap into one
3. Split large pages (2000+ lines) covering multiple topics
4. Move pages that matured (e.g., `ideas/` → `business/` if it's real now)
5. Create new categories if patterns demand it
6. Full `index.md` rebuild from scratch
7. Rewrite `hot.md`
8. Append restructure report to `log.md`
9. Say "Restructured wiki. X pages merged, Y split, Z moved."

### Auto-Recall (fallback search)
When you can't find information or the user asks about something you don't have in context — **automatically search the wiki before saying you don't know.** Silently:
1. Read `~/.claude/wiki/wiki/index.md`
2. Read the matching wiki pages
3. If still not found, grep through `~/.claude/wiki/raw/` for keywords
4. Only say "I don't know" if wiki has nothing

This is mandatory. Never say "I don't have context on that" without checking the wiki first.

### Planner Files (at `~/.claude/wiki/`)
Optional files loaded every session by the hook:

- **`tasks.md`** — work items. Format: `- [todo|doing|done] task | due: YYYY-MM-DD`
  - When user says "task: X" or "add task X" → add to tasks.md under Todo
  - When user says "done: X" → move to Done with completed date
  - **Daily bucket:** "today: X" → `POST /api/org/bucket/today/add {"task_id":"..."}` | "what's today?" → `GET /api/org/bucket/today`
- **`reminders.md`** — `- YYYY-MM-DD | reminder text`
- **`calendar.md`** — `- YYYY-MM-DD HH:MM | event`
- **`short-term.md`** — big goals for the next 30-90 days (as `### Title` sections)

### CRM / Local API Integration (personal only — localhost)

Your personal Christopher-style API runs on `http://localhost:3000` (or your chosen port). These endpoints are safe to call from the wiki because the API binds to localhost only — no credentials ever leave your machine.

**Task sync:**
- `curl -s http://localhost:3000/api/tasks` — list tasks
- `curl -s -X POST http://localhost:3000/api/tasks -H "Content-Type: application/json" -d '{"title":"..."}'` — create
- tasks.md is the readable copy; the API is source-of-truth for status transitions

**Memory sync:**
- After saving a wiki page, sync it into the memory DB:
  `curl -s -X POST http://localhost:3000/api/memory/sync`
- Search memory entities: `curl -s http://localhost:3000/api/memory/entities`
- Daily notes: `curl -s http://localhost:3000/api/memory/daily/YYYY-MM-DD`

**Health/mode:**
- `curl -s http://localhost:3000/api/health` — is it running?
- `curl -s http://localhost:3000/api/mode` — current agent mode

**Guardrails:**
- Only call localhost endpoints from wiki automation — never external CRM/SaaS APIs from inside auto-captured sessions
- Never put API tokens, passwords, or private keys into raw logs or wiki pages — raw logs capture conversation text verbatim
- If you ever need to paste a secret, do it in a terminal outside Claude Code, or set it as an env var

### Rules
- Never delete raw logs from `processed/` — source of truth
- Wiki pages are derived — can be recompiled from raw logs
- hot.md is your cross-session short-term memory
- Always check wiki before saying "I don't know"
- Secrets never touch raw logs (see CRM guardrails above)

---

End of snippet.
