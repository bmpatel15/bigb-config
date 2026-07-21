# connect-to-vachanamrut

Take a thought — a quote, a Quick Capture, a journal line, a highlighted passage — and find
which Vachanamrut teaching it actually relates to. Explain the connection, qualify it where
the thought and the scripture diverge, and be honest about how confident the reference is.

## How this differs from `expand-vachanamrut`

They run in opposite directions and stay independently invokable.

| | `expand-vachanamrut` | `connect-to-vachanamrut` |
|---|---|---|
| Starts from | a Vachanamrut note | any thought or quote |
| Asks | what does this discourse mean for my life? | which discourse does this belong to? |
| Produces | `…/Vachanamrut/Expansions/` | `…/Vachanamrut/Connections/` |
| Title form | `Vachanamrut <Ref> — <principle>` | sentence-case claim |
| Backlink label | `- Expanded in:` | `- Connected from:` |
| Central risk | fabricating scripture | fabricating a *reference* |

Both write `type: literature`, `status: inbox`. Neither creates a permanent note — you
promote those yourself at weekly review.

They share exactly one file: `../_shared/vaultlib.py`. `expand-vachanamrut` is unmodified
and does not depend on it.

## Supported source types

Selected text · the active note · a named heading or block · the full active Quick Capture ·
a single entry inside a multi-capture `-QC.md` · a pasted quote · a personal reflection · a
book or course note · a daily-note entry · a journal passage · a capture marked with
`@context`.

**Selection wins.** Priority: `<editor_selection>` → text in the command → a named
heading/block → `<linked_note>` → newest `.claudian/sessions/*.meta.json` `currentNote` →
most recent meaningful capture → whole note. When line numbers and selected text disagree,
the text wins. The skill always states which passage it analysed.

A daily `-QC.md` usually holds several unrelated captures. The skill isolates the one you
mean rather than analysing the file, and asks when that is ambiguous.

## Verified vs suggested — the core of the skill

The vault currently holds **one** Vachanamrut note, itself flagged as an example. So
"nothing in the vault covers this" is the normal answer, and the interesting question is how
honestly the gap is reported.

| Status | Means | Shown as |
|---|---|---|
| `verified` | You read the teaching — in a vault note, or in text fetched from the source | `**[[Vachanamrut Gadhada I-15]]**` |
| `suggested` | Index or model knowledge points here; the text is unread | `**Suggested Vachanamrut — verification required: Gadhada I-15**` |
| `unresolved` | The principle is clear; no discourse can be responsibly named | a plain statement, and no reference |

`unresolved` is a **success**. The skill is built to say:

> I can identify the underlying Satsang principle, but I cannot responsibly assign a specific
> Vachanamrut reference from the currently available material.

Confidence labels — **High / Moderate / Tentative** — describe *evidence*, not enthusiasm.
In a note, an unverified guess lives in `suggested-ref:` and `ref:` stays blank; the
validator errors if that is violated.

## How search works

1. **Vault first** — `03 - Literature Notes/`, `04 - Permanent Notes/`, `00 - Home/*MOC*`,
   `02 - Fleeting Notes/`, `11 - Translations/`, `10 - Context/satsang.md`. Semantic, not
   literal: a thought about plans failing reaches sarva karta, mahima, vairagya, surrender.
2. **The index** — `references/vachanamrut-index.tsv`, all **273 discourses** (274 rows,
   including the Gadhada III *Bhugol-Khagol* appendix) with real refs and English titles,
   built from anirdesh.com and spot-checked against live pages.
3. **Verification** — `fetch_discourse.py` pulls the single leading candidate and greps it.

Ref spellings are normalised: `Gadhada I-1`, `G I 1`, `G-I-1`, `Gadhada Pratham 1`,
`Gadhada First 1`, `Vachanamrut GI-1`, `Gadhada Madhya 13`, `Vadtal-20`, `Ahmedabad 3`,
`Panchal 2` all resolve correctly.

**Titles mislead.** `Loya-14` is titled *Personal Preferences* but concerns which āchārya's
doctrine Maharaj favours — not everyday preference. A title-only matcher would mis-cite it
confidently. This is why `verified` requires reading the text.

## Write behaviour

**Default: nothing is written.** Analysis appears in chat and no file changes.

Writing happens only when you ask ("…and create a note") or pass `create-note`. Then at most
**two** files change: the new connection note, and one backlink line in the source note.

- Never overwrites an existing file — enriches, narrows, or declines.
- Never writes to `04 - Permanent Notes/` or into the `Vachanamrut/` folder root.
- Never touches a MOC.
- Never modifies scripture text or your original capture.
- A Vachanamrut backlink is added only when the connection is `verified`, the note exists,
  the link is absent, and it already has a `## Links` section.
- Reports every file changed.

The vault is on **Obsidian Sync with no maintained git history**, so writes are effectively
unrecoverable. `qc_link.py` keeps its own backups in
`~/.local/state/connect-vachanamrut/backups/` (last 20 per note).

## Quick Capture safety

This is the sharpest edge in the whole skill. `qc-process.timer` runs at **23:30** and hands
every `*-QC.md` still containing a raw `## HH:MM` heading to Hermes, which **rewrites the
whole file**, then enforces rails: if any original prose line is missing afterwards, it
**restores the backup** and fires a critical notification.

Appending a `## Developed Notes` section to an unprocessed QC note would very likely be
dropped by Hermes, trip that rail, and silently revert the night's processing.

So the backlink goes **inside the capture body**, where Hermes carries it through verbatim:

```markdown
## 12:40
@vachanamrut
Sometimes I become discouraged when seva does not go according to my plan.
Developed into: [[Discouragement in seva exposes attachment to my own plan]]
```

`scripts/qc_link.py` does only this. It takes the shared `flock`, backs the file up, and
replays every one of `qc-process`'s rails, refusing the write if any would fail. `@context`
marker lines and `## HH:MM` headings are never added, removed, or reordered. Block IDs are
off by default.

Full detail: `references/quick-capture.md`. **Read it before touching a QC note.**

## Duplicate handling

Before creating anything, the skill searches `Connections/` and `04 - Permanent Notes/` for
matching titles, aliases, and the same core claim. If something close exists it will
**enrich** it, **narrow** the new note to a differentiated angle, or **decline** — and say
which. Declining is a legitimate outcome.

Connection notes use the same title form as permanent notes on purpose: promotion is a move
plus a `type`/`status` change, no rename. That is also why the duplicate check covers `04`.

## Modes

| Mode | Returns |
|---|---|
| `quick` | Principle, strongest connection, 2–4 sentences, confidence, one link |
| `deep` *(default)* | Full analysis with supporting connections and qualification |
| `quote` | Adds compatibility verdict and attribution status |
| `reflection` | Your voice preserved, one concrete application, specific questions |
| `seva` | Weighted to dasbhav, samp, suhradbhav, recognition, correction |
| `graph` | Structure: existing notes, missing links, conservative backlinks |
| `research` | Fetches and verifies; reports exactly what was read |

Modifiers: `create-note` · `no-write` · `selected-text` · `current-capture`.
Details in `references/modes.md`.

## Invocation

```
/connect-to-vachanamrut
/connect-to-vachanamrut quick
/connect-to-vachanamrut quote no-write
/connect-to-vachanamrut reflection create-note
/connect-to-vachanamrut seva create-note
/connect-to-vachanamrut research
```

Plain language works just as well:

- *What Vachanamrut does this quote relate to?*
- *Connect this Quick Capture to the Vachanamrut.*
- *Does this thought agree with the Vachanamrut?*
- *Process the latest Quick Capture entry.*
- *Connect this to a Vachanamrut, but don't create a note.*
- *Find a Vachanamrut connection and create an evergreen note.*

## Scripts

All stdlib-only Python 3. Run with the full path — Claudian's working directory is the vault.

```bash
SK=~/.claude/skills/connect-to-vachanamrut/scripts

python3 $SK/vach_lookup.py --normalize "G-I-1"            # -> Gadhada I-1
python3 $SK/vach_lookup.py --variants  "Gadhada I-1"      # spellings to grep for
python3 $SK/vach_lookup.py --ref       "Loya-14"          # one index row
python3 $SK/vach_lookup.py --search    "<thought>"        # ranked candidates
python3 $SK/vach_lookup.py --stats

python3 $SK/fetch_discourse.py "Gadhada I-15" --grep "discouraged"
python3 $SK/qc_link.py "<note>" --link "<title>" --match "<snippet>" --dry-run
python3 $SK/check_connection.py "<note>"
python3 $SK/build_index.py --check                        # validate the index offline
```

## Configuration

`config.json` is optional — every value in it is the documented default, so deleting the file
changes nothing. It covers folders, search paths, corpus and cache paths, trusted hosts,
naming, frontmatter, default mode, default write behaviour, candidate count, the confidence
floor for naming a discourse, unresolved-link policy, backlink policy, block references, and
the QC lock. Environment variables win over the file: `$PKM`, `$XDG_CACHE_HOME`,
`$XDG_STATE_HOME`.

## Adding a trusted complete Vachanamrut text

The skill ships **titles only**, deliberately: the English Vachanamrut is a copyrighted BAPS
translation, so it is not mirrored. `fetch_discourse.py` pulls one discourse at a time on
demand and caches it in `~/.cache/vachanamrut/`, outside the vault.

If you obtain an authorised complete text, point `corpus.trusted_local_text` in
`config.json` at it and the skill will prefer it over any fetch — which also makes Research
Mode work inside Obsidian, where there is no network. Expected shape: one file per discourse
named by canonical ref (`Gadhada I-15.md`), or a single file with `# <ref>` headings.

To rebuild the index from source:

```bash
python3 ~/.claude/skills/connect-to-vachanamrut/scripts/build_index.py
```

It refuses to write unless it parses exactly 273 canonical discourses, every section
boundary lands where expected, and four refs spot-check against live pages.

## Assumptions about Claudian

Verified against `realclaudian` v2.0.38 and `.claudian/claudian-settings.json`:

- The vault is the working directory.
- Claudian sends the note's **vault-relative path, never its content** — always read the file.
- The path arrives **once per conversation**; the skill re-confirms on later turns.
- `<editor_selection path="…" lines="…">` carries a highlighted passage; text beats line
  numbers when they disagree.
- `.claudian/sessions/*.meta.json` `currentNote` is the fallback.
- Notes with a Claudian excluded tag never arrive (`excludedTags` is currently empty).
- **There is no network inside Obsidian.**

## Known limitations

- **Research Mode degrades inside Obsidian.** No network means no fetch, so results fall back
  to index-only ranking — stated explicitly rather than glossed. Run from a terminal when
  verification matters.
- **The index is titles, not text.** A title match never establishes a teaching.
- **The vault has one Vachanamrut note**, so vault-verified matches will be rare until you
  write more.
- Selection depends on you highlighting before sending.
- The title scorer is keyword-and-bridge based, not embeddings; it narrows candidates, and
  the reasoning is still the model's.
- `/note-capture` uses a per-note filename convention that conflicts with the live
  `YYYY-MM-DD-QC.md` pipeline. This skill follows the pipeline.

## Uninstall or disable

Everything lives in two places (both symlinked from `~/.claude/`):

```bash
rm -rf ~/bigb-config/claude/skills/connect-to-vachanamrut
rm     ~/bigb-config/claude/commands/connect-to-vachanamrut.md
```

To disable temporarily without deleting, rename the skill directory (a directory without a
`SKILL.md` is not loaded):

```bash
mv ~/bigb-config/claude/skills/connect-to-vachanamrut{,.disabled}
```

Optional leftovers, safe to remove any time:

```bash
rm -rf ~/.cache/vachanamrut                        # fetched discourse cache
rm -rf ~/.local/state/connect-vachanamrut          # qc_link backups
```

`_shared/vaultlib.py` is used only by this skill — remove it too if you are uninstalling.
`expand-vachanamrut` does not import it and is unaffected either way.
