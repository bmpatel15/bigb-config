# Vault conventions — BigB-PKM (connection notes)

Everything here was read off the live vault. If the vault and this file disagree, **the vault
wins** — re-check and update this file rather than forcing the old convention.

Vault root: `$PKM`, default `~/Documents/BigB-PKM`.

**Sync and safety.** The vault syncs via **Obsidian Sync**. A `.git` directory exists with a
GitHub remote, but it is stale — the last commit is from 2026-07-17 with dozens of files
dirty — so **git is not a usable undo net**. Treat every write as unrecoverable: default to
no-write, edit additively, never overwrite an existing file, and rely on
`scripts/qc_link.py`'s own backups when touching a capture.

## The pipeline

```
02 - Fleeting Notes  →  03 - Literature Notes  →  04 - Permanent Notes  →  MOCs (00 - Home)
   raw, expected          notes about a source       one atomic idea         curated indexes
   to die                 (cites source: / ref:)     in your own words
```

`type:` is the routing field the `og` command files by: `fleeting → 02`, `literature → 03`,
`permanent → 04`, `daily → 01`.

**A connection note is a literature-stage artifact.** `type: literature`, `status: inbox`,
filed in `03 - Literature Notes/Vachanamrut/Connections/`. It is staged for the user to
promote at weekly review — this skill never writes a permanent note, exactly as
`expand-vachanamrut` never does.

## Where things live

| Kind | Path |
|---|---|
| Vachanamrut source notes | `03 - Literature Notes/Vachanamrut/Vachanamrut <Ref>.md` |
| Expansion notes (`expand-vachanamrut`) | `03 - Literature Notes/Vachanamrut/Expansions/` |
| **Connection notes (this skill)** | `03 - Literature Notes/Vachanamrut/Connections/` |
| Permanent notes | `04 - Permanent Notes/<sentence-case claim>.md` |
| Quick Capture | `02 - Fleeting Notes/YYYY-MM-DD-QC.md` |
| Daily notes | `01 - Daily Notes/YYYY-MM-DD.md` |
| MOCs | `00 - Home/<Topic> MOC.md` |
| Templates | `09 - Templates/` |
| Satsang context | `10 - Context/satsang.md` |

Never write into the `Vachanamrut/` folder root — one note per discourse, owned by
`sn v "<ref>"`. Never write into `04 - Permanent Notes/`; the user promotes notes there.

## Frontmatter contract

The nine canonical keys in template order, then this skill's three:

```yaml
---
type: literature
source: Vachanamrut
ref:                      # ONLY when connection-status is verified; blank otherwise
created: YYYY-MM-DD
status: inbox
reviewed:
review-interval: 7
next-review:
tags:
  - scripture
  - vachanamrut
  - connection
connection-status: verified | suggested | unresolved
suggested-ref:            # the unverified guess lives here, never in ref:
relationship: practical-application
---
```

- Dates are bare `YYYY-MM-DD`, **unquoted**. Get today from `date +%F` — never guess.
- `tags:` is always a **block list**, never inline `[a, b]`. Flat kebab-case, no nesting.
- Empty values are left blank — not `null`, not `""`.
- Leave `reviewed` and `next-review` empty; the `reviewed` command walks the ladder
  3 → 7 → 14 → 30 → 90 → 180.
- **Do not add `aliases:`** — registered in the vault, used in zero notes.
- New keys are kebab-case, matching `review-interval`, `next-review`, `ahnik-*`.

`ref:` and `connection-status` are the pair that matters. A populated `ref:` asserts the
reference is established; anything less certain belongs in `suggested-ref:`.
`check_connection.py` treats a mismatch as an ERROR.

## Links

- **Wikilinks only.** Zero markdown links and zero pipe aliases (`[[note|alias]]`) exist in
  this vault — do not introduce either.
- The section is **`## Links`**, never "Related Notes" or "Connections".
- Links carry a labelled prefix:

  ```markdown
  ## Links
  - Connected from: [[2026-07-21-QC]]
  - Source: [[Vachanamrut Gadhada I-15]]
  - Index: [[Vachanamrut MOC]]
  - Distilled into: [[Constant remembrance surpasses other sadhana]]
  ```

- This skill adds one label: **`- Connected from:`**, pointing at the capture or note the
  thought came from. `expand-vachanamrut` owns `- Expanded in:`.
- Every note must link to something, or `orphans` flags it.

## Naming

| Kind | Pattern |
|---|---|
| Source note | `Vachanamrut Gadhada I-1.md` — Title Case, spaces |
| Expansion | `Vachanamrut Gadhada I-1 — where attention rests by default.md` |
| **Connection** | `Correction hurts when ego feels threatened.md` — sentence-case claim |
| Permanent note | `Constant remembrance surpasses other sadhana.md` — sentence-case claim |

A connection note deliberately uses the **same title form as a permanent note**, because it
is a permanent note in waiting: promotion is a move into `04 - Permanent Notes/` plus a
`type`/`status` change, with no rename. That is also why duplicate-checking must cover
`04 - Permanent Notes/` — a collision there is a real risk.

The title names the **insight**, not the capture. Good: *Recognition weakens seva when it
becomes the reward.* Bad: *Quick Capture thought*, *Quote reflection*, *Notes on ego*.

No Zettelkasten timestamp prefixes, no dates in content filenames. Strip `: / \ | # ^ [ ]`;
keep the readable title in the `# H1`.

### Canonical reference form

Hyphenated: `Gadhada I-15`, `Sarangpur-9`, `Loya-14`, `Panchala-2`, `Gadhada II-53`,
`Vartal-20`, `Amdavad-3`, `Gadhada III-39`, plus `Ashlali` and `Jetalpur-1..5`. Use
`vach_lookup.py --normalize` on anything the user typed, and `--variants` to generate the
spellings worth grepping the vault for.

## Things that will quietly break

- **Body checkboxes.** The Tasks plugin has an empty global filter, so *every* `- [ ]`
  anywhere in the vault becomes a live open task in `tasks` and `rollover`. Use plain `-`.
- **Quick Capture edits.** See `quick-capture.md` — the 23:30 Hermes run will revert a
  night's processing if a QC note is edited carelessly.
- **`og` and the subfolder.** `og` routes `literature` to the `03 - Literature Notes/` root,
  not `Connections/`. Write the full path directly.
- **Bases is the source of record**; Dataview is read-only analytics.
