# Karpathy Brain — Personal

A self-building wiki that auto-captures every Claude Code session. For single-user personal use (solo developer, one person's notes).

**No skills/candidate split.** All compiled pages go straight into `wiki/{category}/`. You're the only writer — no promotion workflow needed.

**Includes CRM / local API sync.** Because this wiki is personal and local (or synced only to your own Drive), it's safe to wire in a localhost API server (e.g. Christopher at `http://localhost:3000`) for task sync, memory sync, daily notes, and mode switching. Details in `CLAUDEMD-SNIPPET.md`.

---

## 🚀 Just Paste This URL to Claude

**Install or update:**
> Install this: https://github.com/techserverbz/karpathy-brain-personal

Claude will clone into `~/.claude/wiki/karpathy-brain/`, run `install.sh`, and verify.

**Check if outdated:**
> Is my karpathy-brain-personal up to date? https://github.com/techserverbz/karpathy-brain-personal

Claude reads your sync log (`~/.claude/wiki/_state/karpathy_sync.json`), compares with the latest commit on GitHub, reports the diff, and offers to update if behind.

---

---

## Where the Clone Lives

The clone sits **inside `~/.claude/wiki/`** so everything Claude-related lives in one place. The clone is the **source**; `install.sh` copies hooks to `~/.claude/hooks/` and creates wiki data folders in `~/.claude/wiki/`.

### Final layout

```
~/.claude/
├── hooks/                        ← hooks copied here by install.sh
├── wiki/
│   ├── karpathy-brain/           ← git clone (source — run git pull here)
│   │   ├── hooks/
│   │   ├── install.sh
│   │   └── .git/
│   ├── raw/                      ← session logs (auto)
│   │   └── processed/
│   ├── wiki/                     ← compiled pages
│   ├── _state/
│   │   ├── karpathy_sync.json    ← sync log (last commit, date, who)
│   │   └── karpathy_sync_history.log
│   ├── tasks.md                  ← planner files
│   ├── reminders.md
│   └── calendar.md
└── CLAUDE.md
```

### Manual setup (if you're not using Claude)

```bash
cd ~/.claude/wiki
git clone https://github.com/techserverbz/karpathy-brain-personal.git karpathy-brain
cd karpathy-brain
bash install.sh
```

**Windows (Git Bash):**
```bash
cd /c/Users/$USERNAME/.claude/wiki
git clone https://github.com/techserverbz/karpathy-brain-personal.git karpathy-brain
cd karpathy-brain
bash install.sh
```

### Update later

Tell Claude: *"update karpathy brain"* — or manually:
```bash
cd ~/.claude/wiki/karpathy-brain
git pull
bash install.sh
```

The sync log at `~/.claude/wiki/_state/karpathy_sync.json` updates automatically every run.

---

## What's in this folder

```
Karpathy Brain - Personal/
├── README.md                 ← this file
├── CLAUDEMD-SNIPPET.md       ← copy-paste into your CLAUDE.md
└── hooks/
    ├── session-start.sh      ← pre-creates raw log + loads hot cache
    ├── session-stop.sh       ← extracts conversation + finalizes log
    ├── wiki-compile.sh       ← compiles raw → wiki pages (auto every 10 sessions)
    └── wiki-ingest.sh        ← manually ingest curated docs
```

---

## Setup (5 minutes)

### 1. Create the wiki folder structure

```bash
mkdir -p ~/.claude/wiki/{raw,raw/processed,wiki,_state}
mkdir -p ~/.claude/hooks
```

### 2. Copy the hooks

Copy all 4 files from `hooks/` into `~/.claude/hooks/`.

**On Windows (Git Bash):**
```bash
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

**On Mac/Linux:**
```bash
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

### 3. Create initial wiki files

```bash
echo "# Wiki Index" > ~/.claude/wiki/wiki/index.md
echo "# Recent Context" > ~/.claude/wiki/wiki/hot.md
echo "# Wiki Operations Log" > ~/.claude/wiki/wiki/log.md
echo "0" > ~/.claude/wiki/_state/counter.txt
echo "0" > ~/.claude/wiki/_state/total_counter.txt
```

### 4. Register hooks in `~/.claude/settings.json`

Add (or merge with existing):

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/session-start.sh" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/session-stop.sh" }] }
    ]
  }
}
```

### 5. Add the Wiki section to your CLAUDE.md

Copy the **entire contents** of `CLAUDEMD-SNIPPET.md` into `~/.claude/CLAUDE.md` (or your project's CLAUDE.md).

### 6. Restart Claude Code

Start a new session. You should see `RAW_LOG=...` in the session context and a file appear at `~/.claude/wiki/raw/{timestamp}.md`.

---

## How it works

### Auto-capture (every session)
- Session starts → hook pre-creates raw log with user/machine attribution
- Every 3-5 exchanges → Claude appends timestamped bullets to raw log (silent)
- Session ends → hook extracts conversation from JSONL, marks session_end

### Auto-compile (every 10 sessions)
- Counter hits 10 → `wiki-compile.sh` runs in background
- Raw logs analyzed → facts extracted → wiki pages created/updated in `wiki/{category}/`
- Processed logs moved to `raw/processed/`
- `hot.md` rewritten with recent context → loaded at next session start

### Categories
```
wiki/
├── codebases/   ← repos, architecture, key files
├── business/    ← revenue, clients, strategy
├── people/      ← contacts, relationships
├── decisions/   ← why we chose X over Y
├── ideas/       ← things to build
├── patterns/    ← recurring solutions
├── systems/     ← how things are set up
├── clients/     ← client contacts, projects
├── finance/     ← money stuff
├── tools/       ← CLIs, APIs, scripts
├── research/    ← experiments, learnings
└── meetings/    ← notes, decisions
```

---

## Commands (after setup)

Once CLAUDEMD-SNIPPET is in place, Claude responds to:

| Command | Action |
|---------|--------|
| **disb** | Dump In Second Brain — save current topic immediately |
| **sisb {query}** | Search In Second Brain — wiki + raw logs |
| **scsb** | Structure Compile — compile raw logs into wiki |
| **slsb** | Structure Lint — find contradictions, orphans |
| **srsb** | Structure Restructure — reorganize wiki |

---

## Manual ingest

For curated reference material (existing docs you want in the wiki):

```bash
bash ~/.claude/hooks/wiki-ingest.sh tools ~/docs/my-workflow.md
```

Splits the doc into focused pages under `wiki/tools/`.

---

## Google Drive sync (optional, for multi-machine use)

Move `~/.claude/wiki/` to Google Drive and symlink back:

**Windows:**
```bash
# Close Claude Code first
mv ~/.claude/wiki "G:/My Drive/karpathy-brain"
cmd //c mklink /D "%USERPROFILE%\.claude\wiki" "G:\My Drive\karpathy-brain"
```

**Mac:**
```bash
mv ~/.claude/wiki "~/Google Drive/karpathy-brain"
ln -s "~/Google Drive/karpathy-brain" ~/.claude/wiki
```

Your raw logs, wiki pages, and hot cache now sync across your machines. User/machine frontmatter lets you see which laptop wrote what.

---

## Troubleshooting

**Raw logs not created:** Check `~/.claude/settings.json` has hooks registered. Run `bash ~/.claude/hooks/session-start.sh` directly to see errors.

**Compile never runs:** Check counter: `cat ~/.claude/wiki/_state/counter.txt`. Should increment each session. Auto-triggers at 10.

**Hot cache empty:** Empty until first compile runs. Say `scsb` in a session to force a compile.

**Claude not capturing:** The CLAUDEMD-SNIPPET must be in your CLAUDE.md. Without it, Claude doesn't know about the raw log.

---

## Sync Log — Check When You Last Updated

Every time you run `bash install.sh`, it writes two files:

- `~/.claude/wiki/_state/karpathy_sync.json` — current state (commit, date, who, from where)
- `~/.claude/wiki/_state/karpathy_sync_history.log` — append-only history of all installs

**Check current sync state:**
```bash
cat ~/.claude/wiki/_state/karpathy_sync.json
```

Example output:
```json
{
  "flavour": "personal",
  "installed_at": "2026-04-19T21:55:00Z",
  "installed_by": "Shubham(Code)@DESKTOP",
  "git_commit": "7da1c84a...",
  "git_commit_short": "7da1c84",
  "git_commit_date": "2026-04-17T14:10:01Z",
  "git_commit_message": "Karpathy Brain — Personal: ...",
  "git_remote": "https://github.com/techserverbz/karpathy-brain-personal.git"
}
```

**See full history:**
```bash
cat ~/.claude/wiki/_state/karpathy_sync_history.log
```

**Update:** `cd` into your clone, then `git pull && bash install.sh`. The sync log updates automatically.
