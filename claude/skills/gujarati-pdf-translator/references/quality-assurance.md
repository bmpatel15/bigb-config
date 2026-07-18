# Quality Assurance — Translation Audit Checklist

Run this checklist during Stage 10 (per section) and again over the whole document
before delivery. Each item is a concrete check, not a vibe. Where a check fails, fix
the translation or add an explicit uncertainty note — never leave it silent.

## 1. Source completeness

- [ ] Every page of the requested range is accounted for; page coverage list has no
      gaps or duplicates.
- [ ] Every paragraph of the source has a corresponding English paragraph (count them
      if in doubt).
- [ ] No sentence, list item, name in a list, caption, footnote, heading, or refrain is
      missing.
- [ ] Repetitive passages are fully translated, not compressed ("…and others" is a red
      flag unless the source says it).
- [ ] Nothing was invented: every English sentence traces to Gujarati source text.
- [ ] Missing/illegible source is marked with the standard labels, not papered over.

## 2. OCR reliability

- [ ] Suspicious extraction was compared against the rendered page image.
- [ ] No corrupted OCR was translated as though valid.
- [ ] Checked: broken matras, lost anusvara/chandrabindu, split conjuncts, merged
      words, numerals-vs-letters, look-alike characters, headers merged into
      paragraphs, columns merged, repeated/missing lines at page breaks.
- [ ] Every `[OCR requires manual verification]` label is still needed (resolve or
      keep — never delete without verifying).

## 3. Names

- [ ] No proper name is translated by meaning.
- [ ] Every name uses its canonical spelling (check `names-and-titles.md` and the
      terminology log); one spelling per name across the document.
- [ ] Uncertain readings are marked `[Name uncertain: …]`, not guessed.
- [ ] -ji/-bhai/-ben suffixes preserved.

## 4. Terminology

- [ ] Protected terms (agna, paksh, nishchay, nishtha, upasana, mahima, satsang, seva,
      bhakti, darshan, murti, swarup, samagam, etc.) are transliterated per
      `glossary.md`.
- [ ] No prohibited substitution appears (murti→idol, agna→order, seva→work,
      dasbhav→slavery …) — see the glossary's quick-reference table.
- [ ] First-use glosses appear once only; later uses are bare.
- [ ] Context-dependent choices are recorded in the terminology log.
- [ ] Transliteration spellings are internally consistent (nishtha everywhere, not
      nishtha/nishthaa mixed).

## 5. Negations

- [ ] Every ન / નથી / નહીં / ના પાડી / વિના / સિવાય / -વું ન જોઈએ in the source has its
      negation in the English.
- [ ] Checked English for: no, not, never, only, except, unless, without, neither,
      nobody, nothing, cannot, should not, must not — each traced back to the source.
- [ ] No double negation was flattened into the wrong polarity.
- [ ] "Only/except/unless" restrictions preserved exactly (તો જ, સિવાય, વગર).

## 6. Quotations and speakers

- [ ] Every piece of direct speech is direct speech in English — none narrated away.
- [ ] Speaker and addressee correct at every change of turn.
- [ ] Nested quotations nest correctly.
- [ ] Scripture quotations: source identified where possible; established rendering
      used only if actually available in project references; nothing claimed as
      "official" without verification.
- [ ] Blessings, prayers, commands, rhetorical questions keep their form.

## 7. Structure

- [ ] Headings present, at the right level, in the right order.
- [ ] Paragraph boundaries match the source.
- [ ] Page order matches the source; `[Source page N]` markers sequential, at paragraph
      boundaries, never mid-sentence.
- [ ] Tables, captions, and footnotes present and attached to the right content.
- [ ] Stanzas and refrains of poetry/kirtans preserved.

## 8. Theology

- [ ] Doctrinal statements say exactly what the source says — not weakened, broadened,
      or modernized.
- [ ] Akshar/Aksharbrahman and Parabrahman/Purushottam never conflated.
- [ ] Honorifics and titles intact (no trimmed "Brahmaswarup", no dropped "Maharaj").
- [ ] No vocabulary imported from unrelated religious traditions.
- [ ] divyabhav/manushyabhav, nishchay/nishtha, upasana/bhakti distinctions preserved
      where the source distinguishes them.

## 9. Fluency

- [ ] No calqued Gujarati syntax; reads as edited English prose.
- [ ] No machine-translation artifacts (article errors, tense drift, dangling
      participles).
- [ ] No over-polish: no marketing tone, no invented emotion, no inspirational filler.
- [ ] Pronoun referents unambiguous; names repeated where clarity required.

## 10. Consistency

- [ ] One terminology log for the whole document; no term switches treatment without a
      logged reason.
- [ ] Titles rendered the same way at every occurrence.
- [ ] Capitalization consistent: Aksharbrahman, Parabrahman, Purushottam, Akshardham
      always capitalized; general terms consistently lowercase.
- [ ] Spelling of every recurring name identical throughout.

## 11. Page markers

- [ ] Format exactly `[Source page N]`, own line, paragraph boundary.
- [ ] Numbers sequential over the translated range; every translated page has one.

## 12. Uncertainty disclosures

- [ ] Every unclear reading is labeled locally with the standard labels.
- [ ] A closing uncertainty section exists if (and only if) there are significant
      issues; it lists page numbers.
- [ ] No claim of completeness or accuracy anywhere that the source's condition does
      not support.

## Final gate

- [ ] `scripts/validate_translation.py` run on the output file; errors fixed, warnings
      reviewed.
- [ ] Stage 12 editorial pass done *after* all fixes above.
