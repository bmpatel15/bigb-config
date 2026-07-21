---
name: connect-to-vachanamrut
description: Take a thought, quote, observation, Quick Capture, journal passage, course note or selected text and find which Vachanamrut teaching it actually relates to, in the BigB-PKM vault. Use for connecting a quote or captured thought to scripture, asking what Vachanamrut a reflection relates to, checking whether a quote agrees with the Vachanamrut, processing the latest Quick Capture, finding the strongest Vachanamrut connection for an idea, or turning a reflection into a linked evergreen-track note. Starts from an ordinary thought and discovers the teaching; distinguishes verified vault matches from suggested references that still need checking.
---

# Connect to Vachanamrut

Start from something the user wrote or read — a quote, a Quick Capture, a line in a
journal, a highlighted passage — and find the Vachanamrut teaching it genuinely belongs to.
Explain the connection, qualify it where the thought and the scripture do not quite agree,
and say plainly how confident the reference is.

**This is the mirror of `expand-vachanamrut`.** That skill starts at a Vachanamrut note and
develops a principle outward. This one starts at an arbitrary thought and works back to the
discourse. They stay separate and independently invokable; they share only
`../_shared/vaultlib.py`.

**The default outcome is analysis in chat, and no files change.** Writing happens only when
the user asks for it.

## The state of this vault

`03 - Literature Notes/Vachanamrut/` currently holds **one** note, `Vachanamrut Gadhada I-1`,
which is itself flagged as an example. So "no existing note covers this" is the *normal*
result, not a failure — say it plainly and move on to a suggested reference.

To compensate, this skill ships `references/vachanamrut-index.tsv`: all **273 discourses**
(274 rows, including the Gadhada III *Bhugol-Khagol* appendix) with their real refs and
English titles, built from anirdesh.com. That index lets you rank candidates against
something real instead of memory. It holds **titles only** — never treat a title match as
proof of what a discourse teaches.

## Non-negotiable principles

1. **Never present a reference as more certain than it is.** Every connection carries one of
   three states, and it must be visible in both the chat output and any note written:
   - `verified` — you read the teaching, in a vault note or in text fetched by
     `scripts/fetch_discourse.py`. Nothing else earns this word.
   - `suggested` — the index or your own knowledge points here, but you have not read it.
     Label it *Suggested Vachanamrut — verification required*.
   - `unresolved` — you can name the principle but cannot responsibly name a discourse.
   **`unresolved` is a good outcome.** Say: *"I can identify the underlying Satsang
   principle, but I cannot responsibly assign a specific Vachanamrut reference from the
   currently available material."* Never guess to seem helpful.
2. **Never invent** a discourse number, scripture wording, a prasang, or words spoken by
   Bhagwan Swaminarayan, Gunatitanand Swami, Bhagatji Maharaj, Shastriji Maharaj, Yogiji
   Maharaj, Pramukh Swami Maharaj, Mahant Swami Maharaj, or any sadhu or devotee. When you
   lack the exact wording, paraphrase **without quotation marks**. The vault's own rule, in
   `10 - Context/satsang.md`: *never fabricate quotes from the Vachanamrut or Swamini Vato.*
3. **A shared word is not a connection.** Refuse forced matches. One strong connection beats
   three weak ones, and zero beats one that is manufactured. `Loya-14` is titled *Personal
   Preferences* but concerns which āchārya's doctrine Maharaj favours — not personal
   preference in the everyday sense. Titles mislead; verify before asserting.
4. **Only link to notes that exist.** Check the filesystem before writing any `[[link]]`.
   Name a missing note in plain text instead — never as a wikilink that would leave a stub.
5. **Default to no-write.** Analysis only, unless the user asks for a note or passes
   `create-note`.
6. **At most two files change per run** — the connection note, and the source note's
   backlink. Never a third.
7. **Never touch scripture text, existing quotations, or the user's original capture.**
   Edits are additive.
8. **Keep satsang terms in their original form** — Agna, Upasana, Nischay, Divyabhav,
   Prapti, Mahima, Dasbhav and the rest stay untranslated. Shared glossary:
   `~/.claude/skills/expand-vachanamrut/references/satsang-terms.md`.

## Supporting files

Paths are relative to this skill directory. Consult on demand.

| File | Use it for |
|---|---|
| `references/connection-method.md` | Concept profile, candidate ranking, confidence, relationship types |
| `references/compatibility.md` | Judging whether a secular quote actually agrees with the Vachanamrut |
| `references/modes.md` | The seven output modes and what each returns |
| `references/quick-capture.md` | **Read before writing to any `-QC.md` note.** The Hermes safety contract |
| `references/vault-conventions.md` | Folders, frontmatter, link labels, naming, what breaks |
| `references/vachanamrut-index.tsv` | All 273 discourses: ref, vachno, title, url |
| `templates/connection-note.md` | The skeleton to fill |
| `scripts/vach_lookup.py` | Normalise refs; search the index |
| `scripts/fetch_discourse.py` | Fetch one discourse to verify a claim |
| `scripts/qc_link.py` | Safely backlink a Quick Capture entry |
| `scripts/check_connection.py` | Post-write validator |

## Workflow

### 1. Determine the source passage

Claudian runs with the vault as its working directory and appends the open note's
**vault-relative path** — never its content. In priority order:

1. `<editor_selection path="…" lines="…">` — a highlighted passage. **If the line numbers
   and the selected text disagree, the text wins**; locate it by content.
2. Text the user pasted or typed directly into the command.
3. A heading, block, or paragraph they named.
4. `<linked_note>` — the note open when the conversation started.
5. The newest `.claudian/sessions/*.meta.json` and its `currentNote` field.
6. The most recent meaningful entry in today's `-QC.md`.
7. The whole active note.

Join the relative path with `$PKM` (default `~/Documents/BigB-PKM`).

> **Claudian sends the path only once per conversation.** On any turn after the first,
> name the note you resolved and confirm before acting.

**Never analyse a whole long note when a smaller passage is available.** A daily `-QC.md`
routinely holds several unrelated captures — isolate the one meant, and if it is ambiguous,
ask rather than analysing all of them. **Always state which passage you analysed**, quoting
its first line, so a wrong guess is obvious immediately.

### 2. Understand the thought before searching

Do not start from keywords. Build an internal concept profile first — primary and secondary
principle, the human struggle described, the spiritual assumption underneath, the response
it implies, likely Vachanamrut terminology, possible misconceptions, and the synonyms the
vault might use. See `references/connection-method.md`.

Do not print the whole profile. One clean sentence of it becomes `## Core Principle`.

### 3. Search the vault first

Before any external or remembered reference, search `03 - Literature Notes/`,
`04 - Permanent Notes/`, `00 - Home/*MOC*`, `02 - Fleeting Notes/`, `11 - Translations/`,
and `10 - Context/satsang.md` — filenames, headings, body text, tags, existing wikilinks.

Ref spellings vary. Get every variant to grep for:

```bash
python3 ~/.claude/skills/connect-to-vachanamrut/scripts/vach_lookup.py --variants "Gadhada I-1"
python3 ~/.claude/skills/connect-to-vachanamrut/scripts/vach_lookup.py --normalize "G-I-1"
```

Search **semantically**, not literally: a thought about losing peace when events defy your
plan reaches notes on sarva karta, divine will, attachment to personal preference, mahima,
faith during hardship, equanimity, surrender, atma-identity, and dependence on Bhagwan.

**Expect zero hits.** Report that plainly; it is the expected state of this vault.

### 4. Rank candidates against the index

```bash
python3 ~/.claude/skills/connect-to-vachanamrut/scripts/vach_lookup.py --search "<the thought>"
```

This scores 274 discourse **titles**. It narrows the field; it never establishes a teaching.
Weigh each candidate on conceptual fit, directness, evidence actually available, whether the
match depends on interpretation, and whether it rests on a shared word. Assign High /
Moderate / Tentative. Offer at most three, and only as many as genuinely fit.

### 5. Verify, if you can

For the leading candidate, read the text:

```bash
python3 ~/.claude/skills/connect-to-vachanamrut/scripts/fetch_discourse.py "Gadhada I-15" --grep "discouraged"
```

If it confirms the teaching → `verified`, and say what you read.

**A failed `--grep` is not proof of absence.** The index titles are editorial labels, not
quotations: `Gadhada I-55` is titled *Resoluteness in Worship…* while the discourse itself
says *resolve*, so grepping "resolute" returns nothing on a discourse that is squarely about
the theme. Try a shorter stem or a synonym, or read the discourse in full, before ruling a
candidate out. Only conclude the theme is absent once you have actually read the text.

If there is no network — **Claudian runs inside Obsidian, which has none** — the result is
`suggested`, and you say the fetch was unavailable. Never imply you researched something you
did not.

### 6. Assess compatibility

Not every inspirational quote agrees with the Vachanamrut. Judge it as strongly aligned ·
aligned with qualification · partially aligned · too vague to assess · potentially
inconsistent, and add `## Important Qualification` only when it is genuinely needed. See
`references/compatibility.md`. Be respectful: name what is true in the quote before what
needs reframing.

### 7. Report

Default chat shape — concise, not an essay:

```markdown
## Core Principle
One sentence.

## Strongest Vachanamrut Connection
**[[Existing Note]]**  — or —  **Suggested Vachanamrut — verification required: Gadhada I-15**
One to three paragraphs.

## Why This Connection Fits
The shared principle, and how the contexts differ.

## Important Qualification      (only when needed)

## Related Existing Notes       (only files that exist; omit if none)

## Confidence
Level · verified from the vault, fetched, or unverified · what remains uncertain.
```

Quick Connect Mode returns far less. See `references/modes.md`.

### 8. Write only if asked

Then, and only then, follow **Note creation** below.

## Note creation

Triggered by `create-note` or a plain request ("…and create a note", "turn this into an
evergreen note"). Never by default.

1. **Duplicate check first.** Search `03 - Literature Notes/Vachanamrut/Connections/` *and*
   `04 - Permanent Notes/` for matching titles, aliases, and the same core claim. If
   something close exists, do not create a near-duplicate: **enrich** it with what is
   genuinely new, **narrow** this one to a differentiated angle, or **decline** — and say
   which you chose. Declining is legitimate.
2. **Title** — a sentence-case claim naming the insight, matching the vault's permanent-note
   form (`Constant remembrance surpasses other sadhana`). Good: *Correction hurts when ego
   feels threatened.* Bad: *Quick Capture Thought*, *Notes on ego*, *Vachanamrut idea*.
   This is deliberately the same shape as a permanent-note title, so promotion later is just
   a move plus a `type`/`status` change — which is also why the duplicate check must cover
   `04 - Permanent Notes/`.
3. **Path** — `03 - Literature Notes/Vachanamrut/Connections/<title>.md`, creating the folder
   if needed. Strip `: / \ | # ^ [ ]`; keep the readable title in the `# H1`. Never
   overwrite an existing file.
4. **Compose** from `templates/connection-note.md`. Get the date from `date +%F` — never
   guess it. `type: literature`, `status: inbox`: this is a staged note, not a finished
   permanent one. Put an unverified reference in `suggested-ref:` and leave `ref:` blank —
   never in a field that implies certainty. Title the section `## Possible Vachanamrut
   Connection` whenever the status is not `verified`.
5. **Backlink the source note** — for a `-QC.md`, use `qc_link.py` and nothing else:

   ```bash
   python3 ~/.claude/skills/connect-to-vachanamrut/scripts/qc_link.py \
     "02 - Fleeting Notes/2026-07-21-QC.md" \
     --link "<new note title>" --match "<unique text from that capture>" --dry-run
   ```

   Drop `--dry-run` to write. **Read `references/quick-capture.md` before doing this.**
   Adding a `## Developed Notes` section to an unprocessed QC note can break the nightly
   Hermes run; the script exists to prevent exactly that. For an ordinary source note,
   append one line under `## Links`.
6. **Vachanamrut backlink** — only when the connection is `verified`, the note exists, the
   link is absent, and the note already has a `## Links` section. Otherwise skip and say so.
   Never write a `suggested` connection into a Vachanamrut note. Never touch any MOC.
7. **Validate**, using the full path since the working directory is the vault:

   ```bash
   python3 ~/.claude/skills/connect-to-vachanamrut/scripts/check_connection.py "<path>"
   ```

   Fix every ERROR before reporting. Mention WARNs you deliberately accepted.
8. **Report** — the passage analysed, the connection and its status, the note's title and
   path, every file changed, any duplicate found and what you did, and anything unverified.

## Modes

`quick` · `deep` (default) · `quote` · `reflection` · `seva` · `graph` · `research`.
Modifiers: `create-note` · `no-write` · `selected-text` · `current-capture`.
Full definitions in `references/modes.md`.

Natural phrasings work as well as flags: *what Vachanamrut does this quote relate to* ·
*connect this Quick Capture to the Vachanamrut* · *does this thought agree with the
Vachanamrut* · *process the latest Quick Capture entry* · *find a Vachanamrut connection and
create an evergreen note*.

## Limitations

- Claudian sends the note **path only, never content** — always read the file. The path
  arrives **once per conversation**; re-confirm on later turns.
- Selection context depends on the user highlighting text before sending. Notes carrying a
  Claudian excluded tag never arrive at all.
- **No network inside Obsidian.** `fetch_discourse.py` will fail there, so Research Mode
  degrades to index-only ranking — say so rather than implying research happened. Run it
  from a terminal when verification matters.
- The index carries titles, not text. `verified` requires a vault note or a successful
  fetch; a title match alone is never enough.
- The vault has one Vachanamrut note, so vault-verified matches will be rare for a while.
