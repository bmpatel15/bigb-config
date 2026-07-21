---
name: expand-vachanamrut
description: Expand one principle from your own reflections in a Vachanamrut note into a linked study note in the BigB-PKM vault, with practical application, realistic examples, and candidate permanent-note claims. Use for expanding a Vachanamrut, developing a reflection into a fuller note, drawing out the practical application of a discourse, creating a study note from a highlighted passage, focusing an expansion on seva or family or work, or staging which ideas in a Vachanamrut note are worth promoting to permanent notes later. Creates a literature-stage expansion, never an evergreen or permanent note itself.
---

# Expand Vachanamrut

Take the Vachanamrut note the user has open, find the strongest principle **in their own
writing**, and expand it into a study note that makes the teaching usable in ordinary life —
ending with atomic claims staged for later promotion into permanent notes.

This automates step 4 of *Scripture Study* in the vault's `00 - Home/README.md`: *"When an
insight transcends the single passage, distill it into a permanent note and link both ways."*
The expansion is the working step between the terse literature note and that finished note.

**An expansion is not an evergreen note.** It is a literature-stage artifact: `type: literature`,
`status: inbox`, filed in `03 - Literature Notes/Vachanamrut/Expansions/`. It deepens one
discourse and stages claims. The user decides at weekly review what gets promoted — this skill
never creates a permanent note.

## Non-negotiable principles

1. **Expand the user's own thinking, not the scripture.** The principle must come from
   `## In My Own Words`, `## Reflection / Application`, a `>` blockquote, or a highlighted
   selection. Never expand the `## Key Points` summary of what the discourse says.
2. **Never invent quotations or prasangs.** No words or actions attributed to Bhagwan
   Swaminarayan, Gunatitanand Swami, Bhagatji Maharaj, Shastriji Maharaj, Yogiji Maharaj,
   Pramukh Swami Maharaj, Mahant Swami Maharaj, or any named sadhu or devotee, unless the
   account is present in the vault. Paraphrase without quotation marks when you lack exact
   wording. The vault's own rule, in `10 - Context/satsang.md`: *never fabricate quotes from
   the Vachanamrut or Swamini Vato.*
3. **Only link to notes that exist.** Verify every `[[link]]` against the filesystem before
   writing. Never create a broken link because a concept would be useful.
4. **Touch the source note once.** One edit, adding the backlink under its `## Links` — plus
   the `## Links` heading itself if the note has none. No restructuring, no rewriting, no
   reformatting, no touching scripture text or existing links.
   **At most two files change per run:** the source note, and one expansion — either a new
   one, or an existing one you are enriching under principle 6. Never a third.
5. **Keep satsang terms in their original form.** Agna, Upasana, Nischay, Divyabhav, Prapti,
   and the rest stay untranslated — see `references/satsang-terms.md`.
6. **Never overwrite an existing file.** If a close note already exists, enrich it, narrow the
   new one to a differentiated angle, or decline — and say which you did. Declining is a
   legitimate outcome.
7. **Summarise in chat; don't paste the note.** Report what was done, not the whole artifact,
   unless asked.

## Supporting files

Paths are relative to this skill directory. Consult on demand.

| File | Use it for |
|---|---|
| `references/vault-conventions.md` | Folders, frontmatter contract, link labels, naming, review triad, what breaks |
| `references/note-structure.md` | Section-by-section guidance and the six modes |
| `references/writing-style.md` | Voice, banned phrasing, the three scenario tiers |
| `references/satsang-terms.md` | Protected terminology and honorifics |
| `templates/expansion-note.md` | The skeleton to fill |
| `scripts/check_expansion.py` | Post-write validator |

## Workflow

### 1. Resolve the active note

Claudian runs with the vault as its working directory and appends the open note's
**vault-relative path** to the message. In priority order:

1. `<editor_selection path="…" lines="…">` — a highlighted passage. Use this path, and treat
   the selected text as the focus. **If the line numbers and the selected text disagree, the
   text wins** — locate it by content and ignore the line range.
2. `<linked_note>` — the note open when the conversation started.
3. The newest `.claudian/sessions/*.meta.json` and its `currentNote` field.
4. Ask.

Join the relative path with `$PKM` (default `~/Documents/BigB-PKM`).

> **Claudian sends the path only once per conversation.** If the user switched notes on a later
> turn, the model was never told. On any turn after the first, name the note you resolved and
> confirm before writing.

### 2. Confirm it is a Vachanamrut note

Accept if the path is under `03 - Literature Notes/Vachanamrut/` **or** frontmatter has
`source: Vachanamrut`. If neither holds, stop and say what the note appears to be — do not
guess or proceed on a Swamini Vato or fleeting note.

If it is already an expansion (in `Expansions/`), say so and offer to deepen it instead.

### 3. Read and segment

Read the note in full. Separate:

- **Scripture content** — `## Key Points`. Context only; never the thing being expanded.
- **The user's own voice** — `## In My Own Words`, `## Reflection / Application`, `>`
  blockquotes, questions, marginal observations. This is the raw material.

A provided selection outranks everything else in the note.

### 4. Select one principle

Pick the single strongest idea in their own writing. It should be specific enough for one note,
broader than this one Vachanamrut, useful in daily life, and connectable to other ideas.

If the note has **no personal reflection** — only `## Key Points`, or an empty template —
stop. Say so, and ask whether to expand from the scripture content instead. Do not manufacture
a reflection he did not write.

If several principles compete, choose one and say in the report which others you set aside.

### 5. Search the vault before writing anything

Search for existing related notes across `04 - Permanent Notes/`, `03 - Literature Notes/`,
`00 - Home/*MOC*`, `02 - Fleeting Notes/`, `11 - Translations/`, and `10 - Context/satsang.md`.
Search titles, headings, body text, satsang terms, and synonyms — e.g. a note on Maharaj as
doer connects to sarva karta, nischay, upasana, surrender, anxiety, ego, prapti, divine will.

**Expect few or zero hits.** The scripture side of this vault is nearly empty, so "nothing
related exists" is the normal result, not a failure. Collect only notes you have confirmed.

### 6. Duplicate check

Compare the proposed principle against existing notes in `Expansions/` and `04 - Permanent Notes/`.
If something highly similar exists, do **not** create a near-duplicate. Either:

- **enrich** the existing note with what is genuinely new, or
- **narrow** this one to the differentiated angle.

State which you chose and why. If you enrich, the same "touch it lightly" rule applies.

### 7. Compose

Fill `templates/expansion-note.md` following `references/note-structure.md` and
`references/writing-style.md`, applying the requested mode (default `balanced`).

Title: `Vachanamrut <Ref> — <principle in sentence case>`. Name the principle; never
"Thoughts on…", "Reflection", or "Expansion". Save the sentence-case *claim* form for the
`## Candidate Permanent Notes` entries — that is the permanent note's title, not this one's.

Get today's date from `date +%F`. Never guess it.

### 8. Write the file

Path: `03 - Literature Notes/Vachanamrut/Expansions/<title>.md`, creating the folder if needed.

Strip `: / \ | # ^ [ ]` from the filename; if the filename must differ from the title, keep
the readable title in the `# H1`.

If the target path already exists, do not overwrite and do not loop back. Choose once:
**enrich** that note with what is genuinely new, **rename** to a title reflecting a
differentiated angle, or **decline** and report that the principle is already covered.
Declining is a legitimate outcome — say so plainly rather than manufacturing a variant.

**If you are enriching**, that replaces writing a new file. Add only what is new, as purely
additive edits; never alter or trim existing prose, even to stay within the word budget. The
budget governs notes you author, not notes you extend — note the overage in the report.

### 9. Backlink the source note

Append one line under the source note's `## Links`:

```markdown
- Expanded in: [[Vachanamrut Gadhada I-1 — where attention rests by default]]
```

- If `## Links` is absent, append a minimal one at the end of the note.
- If this exact link is already there, change nothing.
- A note may have several expansions on different principles. The label repeats — append
  another `- Expanded in:` line and leave the existing ones alone.
- Preserve every existing line, including `Source MOC:` and `Distilled into:` entries.

**Do not touch `Vachanamrut MOC` or any other MOC.** Its empty prakaran headings are an
invitation, but the MOC indexes *source* notes and is curated by hand — the expansion is
reachable from the source note already. Mention in the report that it can be added manually
if wanted.

### 10. Validate

Claudian's working directory is the vault, not this skill, so use the full path:

```bash
python3 ~/.claude/skills/expand-vachanamrut/scripts/check_expansion.py "<path to the expansion>"
```

Run it against whichever expansion you wrote — the new one, or the one you enriched. Fix any
ERROR before reporting. Report WARNs you deliberately accepted. If you declined to write
anything, skip this step and say so.

### 11. Report

Concise summary, no full note dump:

- the principle selected (and any strong ones set aside)
- the new note's title and full path
- the source Vachanamrut note
- existing notes linked, or a plain statement that none were found
- whether the source note was updated
- any near-duplicate found and what you did about it
- the candidate permanent notes staged
- anything you could not verify

## Invocation

Runs on the open note with no arguments. Natural phrasings: *expand this Vachanamrut idea* ·
*create a permanent note from my main reflection here* · *develop the highlighted idea into a
linked note* · *create a practical application note from this Vachanamrut*.

Modes — `balanced` (default), `practical`, `seva`, `philosophical`, `story`,
`knowledge-graph`; see `references/note-structure.md`. A free-text focus ("focus on family
life", "focus on the deepest philosophical implication") is a lens over balanced mode.

## Limitations

- Only the note **path** arrives from Claudian, never its content — always read the file.
- The path is sent **once per conversation**; re-confirm on later turns.
- Notes carrying a Claudian excluded tag are suppressed and never arrive at all.
- Selection context depends on the user highlighting text before sending.
- Web research is unavailable inside Obsidian; unverifiable accounts become labelled
  illustrative scenarios, never asserted prasangs.
