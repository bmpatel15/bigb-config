# Translation Audit Prompt

Use this prompt (adapted with actual file/page references) to run a second-pass audit
of a finished translation against the original Gujarati PDF.

---

Perform a translation audit of `TRANSLATION.md` against the original Gujarati source
`SOURCE.pdf`, pages N–M.

Re-establish the Gujarati source text per the gujarati-pdf-translator skill (render
pages visually where extraction is unreliable). Then compare **every English paragraph
against its Gujarati source paragraph** and report findings in these categories:

1. **Omissions** — sentences, list items, names, captions, footnotes, refrains, or
   whole paragraphs present in the Gujarati but absent from the English.
2. **Additions** — English content with no basis in the Gujarati (invented detail,
   embellished emotion, added doctrine).
3. **Mistranslations** — meaning changed, weakened, or broadened; theological
   imprecision; wrong tense/aspect/polarity.
4. **Terminology problems** — protected terms translated instead of transliterated
   (check the glossary's prohibited list: murti→idol, agna→order, seva→work …);
   inconsistent treatment of the same term.
5. **Name problems** — translated proper names, non-canonical spellings, spelling
   drift across the document, trimmed titles or honorifics.
6. **OCR issues** — English that appears to translate corrupted Gujarati; readings
   that contradict the rendered page.
7. **Pronoun ambiguity** — unclear or wrong referents; respectful plurals mishandled;
   gender assigned without evidence.
8. **Dropped negations** — check every no/not/never/only/except/unless/without/
   neither/nobody/nothing/cannot/should not/must not against the source; report any
   polarity reversal as CRITICAL.
9. **Awkward English** — calqued syntax, machine-translation artifacts, unnatural
   phrasing.

For each finding give: page number, the Gujarati text (or its location), the current
English, the problem, and a suggested correction.

Rank findings: CRITICAL (meaning reversed/lost, name or doctrine wrong) → MAJOR
(omission/addition/terminology) → MINOR (fluency).

**Do not make stylistic changes merely according to preference. Recommend changes only
when they improve fidelity, clarity, consistency, or natural English.**

End with: pages audited, counts per category, and an overall assessment of whether the
translation is publication-ready.
