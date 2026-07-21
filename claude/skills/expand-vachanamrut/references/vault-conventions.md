# Vault conventions — BigB-PKM

Everything here was read off the live vault. If the vault and this file ever disagree,
**the vault wins** — re-check and update this file rather than forcing the old convention.

Vault root: `$PKM`, default `~/Documents/BigB-PKM`. It is a git repo.

## The pipeline

```
02 - Fleeting Notes  →  03 - Literature Notes  →  04 - Permanent Notes  →  MOCs (00 - Home)
   raw, expected          notes about a source       one atomic idea         curated indexes
   to die                 (cites source: / ref:)     in your own words
```

`type:` in frontmatter is the routing field. The `og` command files loose notes by it:
`fleeting → 02`, `literature → 03`, `permanent → 04`, `daily → 01`. Unknown types are skipped.

**Expansion notes are the literature stage.** They are *not* permanent notes. They deepen
understanding of one discourse and stage claims that may later become permanent notes.

## Where things live

| Kind | Path |
|---|---|
| Vachanamrut source notes | `03 - Literature Notes/Vachanamrut/Vachanamrut <Ref>.md` |
| **Expansion notes (this skill)** | `03 - Literature Notes/Vachanamrut/Expansions/` |
| Permanent notes | `04 - Permanent Notes/<sentence-case claim>.md` |
| MOCs | `00 - Home/<Topic> MOC.md` |
| Templates | `09 - Templates/` |
| Satsang context/persona | `10 - Context/satsang.md` |
| Gujarati translations | `11 - Translations/` |

Source notes are created by `sn v "Gadhada I-21"` and opened by `os v "Gadhada I-21"`.
Never write into the `Vachanamrut/` folder root — that folder is one-note-per-discourse and
belongs to `sn`. Expansions go in the `Expansions/` subfolder.

## Frontmatter contract

Keys in this order, matching `09 - Templates/Scripture Note Template.md`:

```yaml
---
type: literature
source: Vachanamrut
ref: <Gadhada I-1 | Sarangpur 5 | Loya 7 | …>
created: YYYY-MM-DD
status: inbox
reviewed:
review-interval: 7
next-review:
tags:
  - scripture
  - vachanamrut
  - expansion
---
```

- Dates are bare `YYYY-MM-DD`, **unquoted**. Get today from `date +%F` — never guess it.
- `tags:` is always a **block list**, never inline `[a, b]`. Values are flat kebab-case.
  There are **no nested tags** in frontmatter anywhere in this vault.
- Empty values are left blank, not `null` and not `""`.
- `status:` — `inbox` (not yet processed) · `active` (in use) · `evergreen` (finished permanent note).
  A new expansion is `inbox`; the user moves it on once they have worked it.
- `aliases:` is registered in the vault but **used in zero notes**. Do not add it.

### The review triad

`reviewed` / `review-interval` / `next-review` drive the spaced-review loop. Seed them
exactly as above (`review-interval: 7`, the other two empty). A note joins the review pool
once it is `type: literature` or `permanent` **and** no longer `status: inbox`. The `reviewed`
command then walks the ladder 3 → 7 → 14 → 30 → 90 → 180.

Leave `reviewed` and `next-review` empty. Do not compute a due date.

## Links

- **Wikilinks only.** `[[Note Name]]`. There are zero markdown-style links and zero pipe
  aliases (`[[note|alias]]`) in the entire vault — do not introduce either.
- The connections section is called **`## Links`**, never "Related Notes" or "Connections".
- Links carry a **labelled prefix** stating the relationship:

  ```markdown
  ## Links
  - Source: [[Vachanamrut Gadhada I-1]]
  - Index: [[Vachanamrut MOC]]
  - Distilled into: [[Constant remembrance surpasses other sadhana]]
  - Grew out of: [[Example Fleeting Thought]]
  - Source MOC: [[Vachanamrut MOC]]
  ```

- This skill adds one new label: **`- Expanded in: [[…]]`** on the source note.
- Every note must link to at least one other note or a MOC, or `orphans` will flag it.

## Naming

| Kind | Pattern |
|---|---|
| Source note | `Vachanamrut Gadhada I-1.md` — Title Case, spaces |
| **Expansion** | `Vachanamrut Gadhada I-1 — where attention rests by default.md` |
| Permanent note | `Constant remembrance surpasses other sadhana.md` — sentence-case claim |
| MOC | `Vachanamrut MOC.md` |

The expansion title is **source prefix + em dash + the principle in sentence case**. It names
the principle without asserting it as a finished claim — the claim title stays free for the
permanent note the expansion may later produce.

There are no Zettelkasten timestamp prefixes (`zk-prefixer` is disabled) and no dates in
content filenames. Strip `: / \ | # ^ [ ]` from filenames; keep the readable title in the `# H1`.

## Things that will quietly break

- **Body checkboxes.** The Tasks plugin has an empty global filter, so *every* `- [ ]`
  anywhere in the vault is treated as an open task and shows up in `tasks` and `rollover`.
  Use plain `-` bullets in expansion notes. Never `- [ ]`.
- **`og` and the subfolder.** `og` routes `literature` to `03 - Literature Notes/` *root*,
  not `Expansions/`. This skill writes the full path directly, so `og` never sees these notes.
- **Bases is the source of record**, Dataview is read-only analytics.
