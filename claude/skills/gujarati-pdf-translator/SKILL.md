---
name: gujarati-pdf-translator
description: Accurately translate Gujarati PDF documents into natural, elegant English while preserving proper names, untranslated satsang terminology, devotional tone, theological meaning, headings, quotations, page structure, and cultural context. Use for Gujarati PDFs, scanned Gujarati books, satsang literature, prasangs, biographies, discourses, scriptures, articles, and photographed Gujarati pages.
---

# Gujarati PDF Translator

Translate Gujarati PDF documents — especially BAPS, Swaminarayan, satsang, spiritual,
historical, biographical, and scriptural literature — into accurate, elegant, natural
English that preserves the original meaning, devotional tone, theological precision,
structure, and culturally specific terminology.

## Non-negotiable principles

1. **Translate; never summarize.** When the user asks for a translation, every sentence
   of the source must be represented in the English. Never condense repetitive passages,
   difficult passages, lists of names, quotations, captions, or footnotes.
2. **Never silently omit anything** — not a sentence, a name, a caption, a footnote, a
   refrain, or a theological idea. If something cannot be read, say so with an
   uncertainty label; do not skip it.
3. **Transliterate, don't translate, protected terminology.** Satsang terms without a
   precise English equivalent (agna, nishtha, upasana, mahima, murti, seva, darshan …)
   stay transliterated. See `references/glossary.md` before translating a single page.
4. **Never translate proper names** — people, gurus, sadhus, devotees, villages, cities,
   mandirs, organizations, festivals, scriptures, publications, titles used as names.
   See `references/names-and-titles.md`.
5. **Preserve honorifics** (Bhagwan, Maharaj, Swami, Swamishri, Guruhari, Param Pujya,
   Brahmaswarup, Sant, Bapa …). Never drop them to shorten the English. Never swap
   Swaminarayan/BAPS terminology for vocabulary of unrelated traditions.
6. **Accuracy over speed.** Be transparent about uncertainty; never present a guess as a
   reading. Never fabricate missing material from context.
7. **Guard negations.** A dropped નથી, ન, નહીં, વિના, સિવાય, or -વું ન જોઈએ reverses
   the meaning of the source. Verify every negation in the QC pass.

Supporting files (consult on demand; paths relative to this skill directory):

| File | Use it for |
|---|---|
| `references/glossary.md` | Protected satsang terms, meanings, prohibited renderings |
| `references/names-and-titles.md` | Canonical spellings of names, titles, honorifics, places, scriptures |
| `references/transliteration-guide.md` | How to romanize Gujarati readably (no academic diacritics) |
| `references/translation-style-guide.md` | Target English register, before/after examples |
| `references/quality-assurance.md` | Full audit checklist for the QC pass |
| `templates/` | Output-mode skeletons, audit prompt, terminology log |
| `scripts/validate_translation.py` | Structural/terminology lint of the finished Markdown |

## Workflow

Work through these stages in order. For long documents, Stages 2–9 repeat per section
while Stages 10–12 also run once over the whole document.

### Stage 1 — Inspect the source document

Before extracting anything, characterize the PDF:

```bash
pdfinfo file.pdf                 # page count, page size, rotation
pdffonts file.pdf                # embedded fonts => selectable text; none => scanned
pdftotext -layout -f 1 -l 3 file.pdf -   # probe extraction quality on early pages
pdfimages -list -f 1 -l 5 file.pdf       # full-page images => scanned/photographed
```

Determine and note:

- selectable text vs. scanned vs. photographed pages (may vary page-by-page);
- mixed Gujarati and English content;
- rotated pages (`pdfinfo` reports rotation; also verify visually);
- handwriting;
- tables, captions, footnotes, running headers, multi-column layouts;
- missing, duplicated, cropped, or illegible pages;
- total page count and the original reading order (which must be preserved).

**Do not rely on extracted text alone when the PDF is visually complex.** Render pages
and look at them:

```bash
pdftoppm -png -r 150 -f 12 -l 14 file.pdf <scratchpad>/page
```

Then Read the resulting PNGs. Reading the rendered page directly is the *primary* method
for scanned or complex pages — it handles devotional typography, old print, and layout
better than OCR. Use tesseract (`tesseract page-012.png out -l guj+eng`) only as a
secondary bulk-assist when the `guj` language data is installed, and always verify its
output against the rendered page. Never treat OCR output as ground truth.

### Stage 2 — Establish reliable Gujarati source text

For every page or logical section:

- extract or transcribe the Gujarati;
- preserve paragraph boundaries, headings, and quotation boundaries;
- preserve Gujarati numerals where relevant (verse numbers, dates, Samvat years);
- remove page numbers and running headers from the body text only when clearly
  identified as such;
- correct only *obvious* OCR corruption; never silently rewrite uncertain Gujarati;
- visually compare suspicious extraction/OCR output against the rendered page.

Use exactly these uncertainty labels, inline where the problem occurs:

```text
[Illegible Gujarati text]
[Probable reading: …]
[Gujarati source unclear]
[Name uncertain]
[OCR requires manual verification]
[Page appears incomplete]
```

**Never translate corrupted OCR as though it were valid Gujarati.** Guard specifically
against these failure modes:

- broken vowel marks (matras) — e.g. િ/ી, ુ/ૂ dropped or attached to the wrong consonant;
- lost anusvara (ં) or chandrabindu (ઁ) — often silently deletes an "n/m" or a nasalized
  negation;
- split conjuncts (જ્ઞ, ક્ષ, દ્ધ, ત્ર rendered as separate letters);
- merged words or words split across line breaks;
- Gujarati numerals (૦૧૨૩૪૫૬૭૮૯) mistaken for letters, and vice versa;
- visually similar characters confused (ધ/ઘ, ભ/મ, ડ/ઙ, બ/ખ, વ/ब-like shapes);
- English names corrupted inside Gujarati text;
- running headers/footers inserted into paragraphs;
- two columns merged into one interleaved stream — check reading order on every
  multi-column page against the rendered image;
- dropped negations (ન, નથી, નહીં) — re-verify visually whenever a sentence's polarity
  matters;
- repeated or missing lines at page boundaries.

### Stage 3 — Identify context

Before translating, classify the document: scripture, commentary, prasang, biography,
discourse, sermon, historical narrative, instructional material, devotional text,
letter, poem, kirtan, academic writing, or general prose.

Identify where possible: speaker, listener, narrator, audience, historical period,
source publication, level of formality, quoted scripture, and whether the text is
narrative or doctrinal. Use this to select English tone and terminology (see
`references/translation-style-guide.md`).

### Stage 4 — Translate by meaningful units

Translate complete paragraphs or coherent thought units — never word-by-word fragments.

Priorities, in order:

1. Preserve intended meaning.
2. Preserve theological precision.
3. Preserve proper names and titles.
4. Preserve culturally specific terminology.
5. Preserve speaker–listener relationships.
6. Preserve emotional and devotional tone.
7. Preserve rhetorical emphasis.
8. Produce natural English.
9. Preserve source structure.

Do not copy Gujarati syntax into English. The result should read like polished, edited
prose — but never over-polish into marketing language, casual internet tone, generic
inspirational phrasing, modernized theology, embellished prose, or invented emotional
language. Do not add concepts absent from the Gujarati.

### Stage 5 — Handle transliterated terminology

Consult `references/glossary.md`. When a Gujarati term lacks a precise English
equivalent:

- retain the transliterated term;
- lowercase for general terms unless the glossary specifies capitalization;
- give a short contextual gloss on **first use only**, and only when genuinely useful
  (e.g. *"He maintained unwavering nishtha—deep, resolute spiritual fidelity—toward his
  guru."* Later simply: *"His nishtha remained firm."*);
- use the term consistently for the rest of the document;
- do not force one English definition across every context — record context-dependent
  choices in the terminology log (`templates/terminology-log.md`);
- distinguish literal meaning, contextual meaning, theological meaning, organizational
  usage, and established BAPS usage;
- do not italicize recurring transliterated terms unless the chosen style calls for it —
  prefer clean prose.

### Stage 6 — Handle names and titles

Consult `references/names-and-titles.md` for canonical spellings, and add new names to
it as they are established. Never translate the semantic meaning of a proper name (a
person named after a Gujarati word keeps their name, not its dictionary meaning). Never
shorten a title unless the source or the user does. Never invent an English spelling for
an uncertain reading — mark it `[Name uncertain]`.

### Stage 7 — Handle pronouns carefully

Gujarati respectful pronouns (તેઓ, એમણે, પોતે, આપ) omit information English requires.

- Identify the referent from context; do not guess when ambiguous.
- Repeat the person's name or title when that improves clarity — in satsang prose,
  repeating "Swamishri" or "Maharaj" is better than an ambiguous "he".
- Preserve respectful relationships; the plural-of-respect is rendered naturally, not
  as an English plural.
- Never assign gender or identity without sufficient evidence.
- Flag unresolved ambiguity in a translator note.

### Stage 8 — Handle quotations and direct speech

Preserve: who is speaking, who is addressed, every change of speaker, rhetorical
questions, instructions, blessings, prayers, commands, emotional expressions, and
nested quotations. **Never convert direct speech into summarized narration.**

When the Gujarati quotes a known scripture (Vachanamrut, Swamini Vato, Shikshapatri …):

- identify the likely source when possible (e.g. "Vachanamrut Gadhada I-21");
- use an established English rendering only when it is available in project references;
- otherwise translate the Gujarati faithfully yourself;
- never claim wording is an official translation unless verified;
- keep quotation clearly distinguished from surrounding commentary.

### Stage 9 — Handle poetry and kirtans

For poems, verses, and kirtans: preserve meaning, devotional tone, repetition, and
stanza structure. Do not invent rhyme, force meter, rewrite the piece as a new English
poem, or omit refrains — a refrain repeats in the translation as it repeats in the
source. Unless the user requests a poetic adaptation, produce a faithful literary
translation.

### Stage 10 — Quality-control pass

After translating, compare **every** translated paragraph against the source. Use the
full checklist in `references/quality-assurance.md`. Check for: omitted sentences or
paragraphs, duplicated passages, page-order errors, dropped negations, incorrect names,
translated proper names, incorrectly translated satsang terminology, pronoun errors,
speaker confusion, damaged quotations, lost headings, missing captions or footnotes,
OCR artifacts, invented details, weakened theology, over-simplification, awkward
English, inconsistent transliteration, and inconsistent capitalization.

Pay special attention to constructions expressing: no, not, never, only, except,
unless, without, neither, nobody, nothing, cannot, should not, must not. A lost
negation can reverse the meaning of the source.

### Stage 11 — Terminology-consistency pass

For long documents, create and maintain **one** terminology log
(`templates/terminology-log.md`) covering: Gujarati term, transliteration, chosen
English treatment, first-use explanation, context, alternative meanings considered,
reason for preserving untranslated, and capitalization rule. Apply the same glossary
and log across the entire document — never restart terminology decisions on a new page
or section.

### Stage 12 — Final editorial pass

Review the English independently (without the Gujarati in front of you) for grammar,
punctuation, sentence flow, paragraph flow, readability, repetition caused by poor
translation, unnatural literal syntax, and consistency of titles and terminology. Then
spot-check against the source that no edit changed meaning. Editing improves the
English; it never alters what the source says.

## Default output

Unless the user requests otherwise, produce:

1. Document title
2. A brief translator's note — only when needed
3. English-only translation
4. Source-page markers
5. A short uncertainty section — only when necessary
6. A terminology note — only for terms that genuinely require explanation

Page markers use exactly this format, on their own line:

```text
[Source page 12]
```

Never place a page marker mid-sentence; place it at the nearest paragraph boundary.

### Output file destination

Unless the user names a different path, save the finished translation as a Markdown
file in the Obsidian vault:

```text
~/Documents/BigB-PKM/11 - Translations/<Document Title>.md
```

- **Filename:** the document's English-rendered title using canonical name spellings
  (never a translated proper name), Obsidian-safe (avoid `/ \ : # ^ [ ] |`). For a
  partial translation append the range: `<Title> (pp 14–25).md`.
- **Obsidian frontmatter** at the top of the file:

  ```yaml
  ---
  source: "<original PDF filename or path>"
  pages: "<range translated, e.g. 1–48>"
  translated: <YYYY-MM-DD>
  mode: english-only | bilingual | parallel-paragraph | annotated
  tags: [translation, gujarati]
  ---
  ```

- **Long books:** keep the terminology log beside the translation as
  `<Title> — Terminology Log.md` in the same folder, and append to the same
  translation file as sections complete.
- **Never silently overwrite** an existing file in that folder — if the target name
  exists, check whether it is an earlier section of the same job (append/resume) or an
  unrelated file (pick a new name and tell the user).

## Output modes

Templates for each mode live in `templates/`.

- **English-only** (default) — polished English without the Gujarati.
  `templates/english-only.md`
- **Bilingual** — full Gujarati source section followed by full English section.
  `templates/bilingual.md`
- **Parallel paragraph** — each Gujarati paragraph immediately followed by its English.
  `templates/parallel-paragraph.md`
- **Literal plus polished** — close rendering + polished rendering + brief note on
  important differences. Use only when explicitly requested or when ambiguity makes it
  necessary.
- **Annotated translation** — footnotes/translator notes for cultural concepts,
  theological terminology, historical references, ambiguous readings, wordplay, or
  source damage. Keep translator commentary strictly separate from the translated prose.

## Uncertainty behavior

Never claim or imply perfect accuracy when pages are blurry, text is cropped, names are
unclear, OCR is unreliable, handwriting is unreadable, or the document is incomplete.
State uncertainty plainly and *locally* — at the exact spot, using the Stage 2 labels —
plus a short uncertainty section at the end when the issues are significant. Never
fabricate missing material from context.

## Long documents and books

- Process in manageable sections (e.g. 5–15 pages), but keep **one** terminology log
  and **one** names list across all sections.
- Maintain continuity of names, titles, and terminology across chapters.
- Track page coverage explicitly (e.g. "translated: pp. 1–40; next: p. 41"); ensure no
  page is skipped and none is translated twice.
- When resuming from a later page, first reload the existing terminology log and any
  names established earlier — do not re-decide settled terms.
- After the last section, run Stages 10–12 as a whole-document pass: consistency of
  recurring terms, titles, and spellings end-to-end.
- Never translate the same recurring term differently without a reason recorded in the
  terminology log.

## Validation

After producing a Markdown translation file, optionally lint it:

```bash
python3 scripts/validate_translation.py translation.md
```

The script checks structure and terminology risks (page-marker order, unresolved
uncertainty labels, duplicated paragraphs, prohibited renderings such as "idol" for
murti, capitalization of Aksharbrahman/Parabrahman/Purushottam). It **cannot** verify
translation accuracy — the Stage 10 human/model comparison against the source remains
the real quality gate.
