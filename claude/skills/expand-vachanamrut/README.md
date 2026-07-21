# expand-vachanamrut

Turns a Vachanamrut literature note into an **expansion note**: one principle from your own
reflections, developed into something practical and linked, ending with atomic claims staged
for later promotion into permanent notes.

This is step 4 of *Scripture Study* in `00 - Home/README.md`, automated up to the point where
judgment is needed — and stopping there.

## What it is not

An expansion is **not an evergreen note**. It is a literature-stage working artifact:

| | Expansion | Permanent note |
|---|---|---|
| `type:` | `literature` | `permanent` |
| `status:` | `inbox` | `evergreen` |
| Folder | `03 - Literature Notes/Vachanamrut/Expansions/` | `04 - Permanent Notes/` |
| Title | `Vachanamrut Gadhada I-1 — where attention rests by default` | `Constant remembrance surpasses other sadhana` |
| Scope | one discourse, explored | one claim, atomic |

The skill **never creates permanent notes.** It proposes candidates in a
`## Candidate Permanent Notes` section; promotion stays a weekly-review decision.

## Using it

From the open note in Obsidian (Claudian), or from the terminal in the vault:

```
/expand-vachanamrut
/expand-vachanamrut practical
/expand-vachanamrut focus on seva
```

Or just ask: *"expand this Vachanamrut idea into a note"*, *"develop the highlighted idea"*,
*"create a practical application note from this Vachanamrut"*.

Highlight a passage before sending to focus the expansion on it.

### Modes

| Mode | Emphasis |
|---|---|
| `balanced` | Default. Even coverage. |
| `practical` | Daily behaviours, decisions, habits. |
| `seva` | Mandir seva: teamwork, correction, recognition, reliability, mahima. |
| `philosophical` | Doctrinal implications, anchored to the source note. |
| `story` | Several illustrative scenarios instead of one. |
| `knowledge-graph` | Link discovery, duplicate detection, missing-note suggestions. |

A free-text focus ("focus on family life") works as a lens over balanced mode.

## What it writes

**One new file** in `03 - Literature Notes/Vachanamrut/Expansions/`, and **one line** appended
to the source note's `## Links`:

```markdown
- Expanded in: [[Vachanamrut Gadhada I-1 — where attention rests by default]]
```

Nothing else in the source note is touched — no restructuring, no reformatting, no changes to
scripture text or existing links. The link is not duplicated if it is already there.

## Safety rules

- **No invented quotations or prasangs.** Nothing is attributed to Bhagwan Swaminarayan,
  Gunatitanand Swami, or any Guru unless the account is in the vault. Missing wording is
  paraphrased without quote marks.
- **Three tiers of example**: verified (from a vault note, linked) · ordinary real-world
  (unlabelled, nothing claimed) · illustrative composite (**always labelled**, e.g. "Consider
  an illustrative situation…").
- **No broken links.** Every `[[link]]` is checked against the filesystem first. Concepts
  worth a note but not yet written are listed as plain text, not as unresolved links.
- **Satsang terms stay untranslated** — Agna, Upasana, Nischay, Divyabhav, Prapti, and the rest.

`scripts/check_expansion.py` enforces the mechanical half of this after every write:

```bash
python3 scripts/check_expansion.py "path/to/note.md"
```

It checks frontmatter keys and order, `type: literature`, bare-date format, block-list tags,
required sections, filename safety, H1/filename agreement, stray `- [ ]` checkboxes, wikilink
resolution, pipe aliases, scenario labelling, quotation marks near a named figure, and banned
phrasing. Non-zero exit on any error.

## Duplicate handling

Before writing, the skill searches `04 - Permanent Notes/`, `03 - Literature Notes/`,
`00 - Home/*MOC*`, `02 - Fleeting Notes/`, `11 - Translations/`, and `10 - Context/satsang.md`
by title, heading, body text, satsang terminology, and synonyms.

If a close match exists it will **not** create a near-duplicate — it either enriches the
existing note or narrows the new one to a differentiated angle, and tells you which.

Candidate permanent notes are cross-checked against `04 - Permanent Notes/` too, so a claim
that already has a note is flagged as "enrich this" rather than proposed as new.

## Limitations

- Claudian sends the note **path only, never content** — the skill reads the file itself.
- The path is sent **once per conversation**. If you switch notes mid-conversation the model
  isn't told, so on later turns it names the note it resolved and confirms before writing.
- Notes carrying a Claudian excluded tag never reach the skill.
- Selection context requires highlighting text before sending.
- No web access inside Obsidian; unverifiable accounts become labelled illustrative scenarios.
- `og` routes `literature` to `03 - Literature Notes/` *root*, not `Expansions/`. The skill
  writes the full path directly so this never bites — but a stray expansion left in the vault
  root would be mis-filed by `og`.

## Files

```
SKILL.md                          workflow and principles (what Claude reads)
README.md                         this file
references/vault-conventions.md   folders, frontmatter, link labels, naming, review triad
references/note-structure.md      section-by-section guidance, the six modes
references/writing-style.md       voice, banned phrasing, scenario tiers
references/satsang-terms.md       protected terminology, honorifics
templates/expansion-note.md       the skeleton
scripts/check_expansion.py        validator
```

Plus the thin entry point at `bigb-config/claude/commands/expand-vachanamrut.md`.

## Uninstalling

```sh
rm -rf ~/bigb-config/claude/skills/expand-vachanamrut
rm ~/bigb-config/claude/commands/expand-vachanamrut.md
```

Both are reached through the `~/.claude/skills` and `~/.claude/commands` symlinks, so nothing
else needs cleaning up. Notes already written stay where they are; remove the
`03 - Literature Notes/Vachanamrut/Expansions/` folder if you want them gone too.
