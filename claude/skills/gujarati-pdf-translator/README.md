# gujarati-pdf-translator

A personal Claude Code skill that translates Gujarati PDFs — especially BAPS,
Swaminarayan, satsang, spiritual, historical, biographical, and scriptural
literature — into accurate, elegant, natural English while preserving proper names,
untranslated satsang terminology, devotional tone, theological precision, headings,
quotations, page order, and cultural context. It never summarizes when asked to
translate, and it never silently omits difficult or repetitive material.

## Where it is installed

Files live in the dotfiles repo and are reachable through the standard skills path:

```text
~/bigb-config/claude/skills/gujarati-pdf-translator/   # real files (version-controlled)
~/.claude/skills -> ~/bigb-config/claude/skills        # symlink created by install.sh
```

Claude Code discovers personal skills automatically: any directory
`~/.claude/skills/<name>/` containing a `SKILL.md` with `name:` and `description:`
frontmatter is loaded and offered to Claude when the description matches the task.
Mentioning Gujarati PDFs, satsang literature, or the skill by name triggers it.

```text
SKILL.md                                # workflow: inspect -> transcribe -> translate -> QC
references/glossary.md                  # protected satsang terms + prohibited renderings
references/names-and-titles.md          # canonical names, honorifics, places, scriptures
references/transliteration-guide.md     # readable romanization rules (no diacritics)
references/translation-style-guide.md   # target register, before/after examples
references/quality-assurance.md         # full audit checklist
templates/                              # output modes, audit prompt, terminology log
scripts/validate_translation.py         # structural/terminology lint (stdlib only)
```

## How to invoke it

Open Claude Code anywhere and refer to the skill or simply hand it a Gujarati PDF
task. Examples:

```text
Use the gujarati-pdf-translator skill to translate this PDF into elegant English.

Preserve all proper names and satsang terminology through transliteration.
Do not summarize.
Preserve headings and paragraph structure.
Add source-page markers.
Flag unclear text.
Use English-only output.
```

```text
Translate pages 14–25 using the gujarati-pdf-translator skill.

Do not directly translate names or terms such as agna, paksh, nishchay,
nishtha, upasana, mahima, satsang, seva, darshan, murti, or swarup.
Provide a brief explanation on first use only when needed.
```

```text
Perform a translation audit using the original Gujarati PDF.

Compare every English paragraph against the source and look for omissions,
incorrect names, translated proper nouns, damaged quotations, dropped
negations, OCR errors, pronoun ambiguity, weakened theological meaning,
and unnatural English.
```

## Output modes

Ask for one explicitly; **English-only** is the default.

| Mode | Ask for | Template |
|---|---|---|
| English-only | "English-only output" | `templates/english-only.md` |
| Bilingual | "bilingual output" | `templates/bilingual.md` |
| Parallel paragraph | "parallel paragraph output" | `templates/parallel-paragraph.md` |
| Literal + polished | "literal plus polished rendering" | (inline; used for ambiguity) |
| Annotated | "annotated translation with footnotes" | (inline) |

## Output destination

By default the finished translation is saved into the Obsidian vault:

```text
~/Documents/BigB-PKM/11 - Translations/<Document Title>.md
```

with Obsidian frontmatter (source PDF, page range, date, mode, `tags: [translation,
gujarati]`). Partial translations get the range in the filename
(`<Title> (pp 14–25).md`); long books keep their terminology log beside the
translation as `<Title> — Terminology Log.md`. Existing files are never silently
overwritten. Ask for a different path in the prompt to override.

## Adding glossary terms and names

- **Terms:** edit `references/glossary.md` — copy an existing entry, keep the same
  fields (meaning range, context-dependent uses, prohibited renderings, example,
  capitalization), insert alphabetically. Add spelling variants worth catching to
  `ALT_SPELLINGS` in `scripts/validate_translation.py`.
- **Names:** edit `references/names-and-titles.md` — the user-extensible tables at the
  bottom exist exactly for this (sadhus, devotees, villages, mandirs, publications,
  festivals, organizations). One canonical spelling per name, forever.
- During a translation, Claude also records document-specific decisions in a
  terminology log (`templates/terminology-log.md`); promote recurring entries into the
  glossary/names files so future documents inherit them.

## Second-pass translation audit

After any translation, run an independent audit pass (ideally in a fresh session so
the auditor does not trust its own earlier work):

1. Give Claude the original PDF and the finished Markdown.
2. Use the prompt in `templates/translation-audit.md` (or the third example command
   above).
3. Apply CRITICAL/MAJOR fixes; re-run the audit on changed sections.
4. Lint the result:

```bash
python3 ~/.claude/skills/gujarati-pdf-translator/scripts/validate_translation.py translation.md
python3 ... --strict   # warnings also fail the exit code
```

The linter catches structural/terminology risks (page-marker order, "idol" for murti,
lowercase Parabrahman, leftover placeholders, duplicated paragraphs). It cannot judge
translation accuracy — only the audit against the source can.

## OCR limitations

- The skill's primary method for scanned/photographed pages is rendering each page
  (`pdftoppm -png -r 150`) and reading the Gujarati directly from the image. This is
  deliberate: OCR of Gujarati devotional typography and old print is error-prone
  (broken matras, lost anusvara, split conjuncts, merged columns).
- Tesseract can assist bulk extraction **only if** the Gujarati language data is
  installed: `sudo pacman -S tesseract-data-guj tesseract-data-eng` (then verify with
  `tesseract --list-langs`). Its output is always verified visually against the page.
- Blurry, cropped, handwritten, or damaged pages are marked with explicit uncertainty
  labels rather than guessed. Expect `[Illegible Gujarati text]` and
  `[Probable reading: …]` markers in honest output.

## Recommended workflow for long books

1. **Inspect once:** page count, scanned vs. text, layout quirks (Stage 1).
2. **Translate in sections** of 5–15 pages. After each section: Stage 10 QC against
   the source, update the one shared terminology log, note page coverage
   ("translated pp. 1–40; next p. 41").
3. **Resume** later sessions by reloading the terminology log and names tables first —
   never re-decide settled terms.
4. **Whole-book pass** at the end: terminology and title consistency end-to-end,
   page-coverage check, then the final editorial pass (Stage 12).
5. **Audit** (previous section) and run the linter on the assembled book.
6. Keep the terminology log next to the translation file for the next volume.
