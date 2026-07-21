# Quick Capture — how it works, and what will break it

Read this before writing to any `*-QC.md`. The Quick Capture pipeline is live, automated,
and self-healing, and a careless edit can silently undo a night's processing.

## The pipeline

```
obsidian-capture  →  02 - Fleeting Notes/YYYY-MM-DD-QC.md  →  qc-process (23:30)  →  grouped note
     (append)                  one file per DAY                  (Hermes rewrite)
```

- **`obsidian-capture`** (`~/bigb-config/bin/`) appends `\n## HH:MM\n\n` plus the typed text
  to today's note, creating it with frontmatter on the first capture of the day.
- **`qc-process`** runs from `qc-process.timer` at **23:30** with `--pending`. It hands the
  file to Hermes (`claude-sonnet-5`, one-shot) to group captures under topic headers.

## The two states

A note is **unprocessed** if and only if it still contains a raw `## HH:MM` heading. That
single fact decides whether `qc-process` picks it up, which is why nothing may add or remove
one.

**Unprocessed:**

```markdown
## 12:40
@vachanamrut
Sometimes I become discouraged when seva does not go according to my plan.
```

**Processed** — the marker line is deleted, the heading becomes a topic, and the first body
line gains a bold timestamp:

```markdown
## Satsang · Vachanamrut

**12:40** — Sometimes I become discouraged when seva does not go according to my plan.
```

## `@context` markers

The first body line of a capture may be **marker-only**: one or more `@markers` separated by
spaces and nothing else. Anything with a non-marker word on the line is prose.

```
MARKER_RE='^@[A-Za-z0-9][A-Za-z0-9_-]*([[:space:]]+@[A-Za-z0-9][A-Za-z0-9_-]*)*[[:space:]]*$'
```

Matched case-insensitively; multiple markers join with ` · `. `@vachanamrut` maps to
*Satsang · Vachanamrut*; unlisted markers get Title-Cased. **Never add, remove, reorder, or
reformat a marker line** — it determines the topic header the capture lands under.

## Why a `## Developed Notes` section is dangerous

Hermes performs a **full-file replacement**, and its instructions mandate the output layout:
frontmatter, then `## <Topic>` sections whose entries begin `**HH:MM** — `. Nothing else.

`qc-process` then enforces rails *itself*, not trusting the model. The hard ones restore the
backup outright:

| Rail | Trigger |
|---|---|
| file missing | Hermes deleted it |
| frontmatter fence lost | fewer than two `---` |
| `type: quick-capture` lost | key gone |
| frontmatter changed | not byte-identical to the backup |
| **prose line lost** | any non-blank body line from the backup is no longer a substring |

So if you append a `## Developed Notes` section to an **unprocessed** note:

1. It is in the backup `qc-process` takes at 23:30.
2. Hermes, told to emit only topic sections, very likely drops it.
3. The prose-line rail fires.
4. **The backup is restored** — the whole night's grouping is reverted — and a critical
   desktop notification fires.

The user sees processing mysteriously fail. Nothing in the log points at us.

## The safe insertion point

Put the link **inside the capture's body**, as a plain prose line:

```markdown
## 12:40
@vachanamrut
Sometimes I become discouraged when seva does not go according to my plan.
Developed into: [[Discouragement in seva exposes attachment to my own plan]]
```

Hermes carries body lines through verbatim and moves them into the topic section with the
rest of the entry. This works identically in both states, and the prose rail *protects* the
line rather than tripping on it.

`scripts/qc_link.py` does this and nothing else. Use it rather than editing by hand:

```bash
python3 scripts/qc_link.py "02 - Fleeting Notes/2026-07-21-QC.md" \
  --link "Note title" --match "unique text from that capture" --dry-run
```

Select the capture with `--match` (a snippet), `--time HH:MM`, or `--last`. Ambiguous
selectors are refused rather than guessed.

Before writing it: takes the shared `flock` on
`$XDG_RUNTIME_DIR/obsidian-quick-capture.lock` (so it can never collide with an open capture
window or a running `qc-process`), backs the file up to
`~/.local/state/connect-vachanamrut/backups/`, and replays every rail above — refusing the
write if any would fail.

## Rules

- **Never** add a `## Developed Notes` (or any other) heading to a QC note.
- **Never** create or delete a `## HH:MM` heading.
- **Never** edit frontmatter — it must stay byte-identical.
- **Never** touch a capture other than the one being processed.
- **Never** rewrite, reword, reformat, or fix the spelling of the user's capture.
- **Block IDs are off by default.** Appending `^id` is rail-safe, because the rail matches
  substrings, but it clutters the note. Only on explicit request.
- The vault is on **Obsidian Sync with no maintained git history** — the local backup is the
  only undo. Keep edits small and additive.

## A note on `/note-capture`

The `/note-capture` slash command writes `YYYY-MM-DD-HHMM <slug>.md`, one file per note —
a *different* convention from the `YYYY-MM-DD-QC.md` daily file this pipeline uses, and no
files matching it exist. **Follow the pipeline convention.** If a source note turns out to
be a per-note capture, treat it as an ordinary note: a `## Links` section is safe there,
because `qc-process` never touches it.
