---
description: Run or inspect the argus research agent (~/Projects/argus)
argument-hint: "[scan|rank|plan|export|archive|validate|open]  (default: export)"
---
Help me run or inspect **argus**, my research agent (CLI at `~/Projects/argus`, `argus` command; maintains the Obsidian Ideas Command Center at `~/Documents/BigB-PKM/ideas.md`).

Requested action: **$ARGUMENTS** — if empty, default to a read-only `argus export` summary.

Guidance:
- `argus export` — concise summary of current ideas (read-only; the safe default).
- `argus scan` — research + update ideas.md. **This costs money** (a full scan is ~$4 via `claude -p` headless). Confirm with me before running, and offer `argus scan --dry-run` first to preview the diff without writing.
- `argus rank` / `plan` / `archive` — re-rank ideas, build/update plans, or archive weak/duplicate ideas; show what changed.
- `argus validate` — check ideas.md structure (read-only).
- `argus open` — open ideas.md in my editor.
- If I'm worried about spend, surface any cost knobs in `~/Projects/argus/.argus/config.json` (if present).

Run the requested command, then summarize the outcome (and any cost) concisely.
