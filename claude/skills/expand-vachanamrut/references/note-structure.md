# Expansion note structure

The skeleton is in `templates/expansion-note.md`. This file explains what each section is for
and how the modes change emphasis.

**Drop a section rather than pad it.** Every section here is optional except `## The Principle`,
`## Candidate Permanent Notes`, and `## Links`. A note with six well-earned sections beats one
with ten thin ones.

## Section by section

### `# <Title>` and the italic lead

Title is `Vachanamrut <Ref> — <principle, sentence case>`. Directly under it, one italic line
stating what the note is and where it came from:

```markdown
*Expansion of one principle from [[Vachanamrut Gadhada I-1]] — developed from my own
reflection, not a summary of the discourse.*
```

### `## The Principle`

One or two strong paragraphs. State the idea, and state what changes if it is true.

This is the hardest section to get right. It must **not** restate the Vachanamrut. The
Vachanamrut is upstream; the principle is what the user saw *in* it. Start from their sentence,
then push it further than they took it — sharpen the claim, name the mechanism, say what it
rules out.

A good test: could this paragraph appear in a note about a completely different Vachanamrut?
If yes, it is too generic. If it could only apply to this one passage, it is too narrow.

### `## Why It Matters`

Not a restatement with different words. Answer: what does someone do differently, and what
does the principle *explain* that was previously confusing? Connect it to something structural
— why a practice works, why a recurring frustration recurs.

### `## In Everyday Life`

Where the principle actually shows up. Choose only the domains that genuinely fit — three
well-chosen beats eight listed. Candidates: family · work · mandir seva · leadership ·
friendship · study · personal discipline · social media · conflict · praise and criticism ·
disappointment · decision-making · health and personal difficulty.

Name the *pattern* in each domain, not just the domain.

### `## Examples`

Three to five, each a `### Example: <short label>`. Structure each as: the situation → the
instinctive reaction → what changes when the principle is actually applied.

Keep them recognizable and small-scale. At least one should show the principle being
**hard** — applied partially, late, or with the reaction still running underneath. A set of
examples where everyone responds well is not useful to anyone.

### `## An Illustrative Scenario`

One longer account, opening with an explicit label ("Consider an illustrative situation…").

**This section is always a Tier 3 composite.** That is deliberate: the section asks for the
interior sequence — what was felt first, what was told to oneself, where the shift happened —
and you may only write an interior for a person you have constructed and labelled as such.

A **verified prasang from the vault does not go here.** Inventing an interior for a real sadhu
or devotee is exactly what `writing-style.md` forbids, and a labelled-composite heading over a
real account blurs the line the tiers exist to keep sharp. Cite verified prasangs factually in
`## Why It Matters` or `## Examples` instead — what was said or done, linked to its source note,
with no invented inner monologue. Say plainly that the account records the outward half.

Length follows the mode: 150–300 words in `balanced` and `philosophical`; ~150 in `practical`
(which compresses it); 2–3 shorter accounts in `story`; may be dropped entirely in
`knowledge-graph`. Compressing is not the same as dropping — only `knowledge-graph` drops it.

The scenario may end unresolved.

### `## Where This Gets Misunderstood`

Two or three genuine misreadings — the kind someone who accepts the teaching still falls into.
Each: name the misreading, then draw the distinction.

Familiar shapes: surrender is not passivity · humility is not avoiding responsibility ·
seeing Maharaj as the doer does not remove effort · Agna does not replace judgment ·
divyabhav does not require pretending mistakes did not happen.

Do not reuse these verbatim — derive the misreadings this specific principle invites.

### `## Living It`

Concrete behaviours, choices, and habits. Specific enough to act on tomorrow.
"Have faith" and "be positive" are not entries. "Before replying to the message, wait until
the sentence you want to send stops being about you" is.

### `## Questions to Sit With`

Four to six questions **generated for this principle** — never the same list twice across
notes. Good questions name a situation, not a virtue: not "am I humble?" but "which recent
correction am I still explaining to myself?"

### `## Candidate Permanent Notes`

**This is the payoff.** It is why the expansion exists.

Two to four atomic claims, each already written in permanent-note title form: sentence case,
a full declarative claim, standing alone without the Vachanamrut reference. These are what
the user can promote into `04 - Permanent Notes/` at weekly review.

Write them as **plain text, not wikilinks** — the notes do not exist, and unresolved links
are not used as seeds in this vault.

Annotate each with a short note on existing coverage, checked against `04 - Permanent Notes/`:

```markdown
## Candidate Permanent Notes

- **Ego turns correction into insult** — the reaction is proportional to the self-image
  being defended, not to the correction. No existing note covers this.
- **Constant remembrance surpasses other sadhana** — already exists as
  [[Constant remembrance surpasses other sadhana]]; this expansion adds the attention-under-
  pressure angle, so enrich that note rather than creating a second one.
```

Where a note already exists, link it (it is real) and say what this expansion adds.

### `## Links`

Labelled wikilinks, existing notes only:

```markdown
## Links
- Source: [[Vachanamrut Gadhada I-1]]
- Index: [[Vachanamrut MOC]]
- Related: [[Some Existing Note]]
```

`Source:` and `Index:` are always present. Add `Related:` lines only for notes verified to
exist. Zero is a normal and honest result — say so in the report rather than padding.

When several genuinely connect, cap `Related:` at **four**, ranked by how much the connection
would change a re-reading: notes the principle directly predicts or explains first, shared
terminology last. Give each a short clause naming the actual relationship — "the gap this
principle predicts will be widest with those closest" is useful; "also about seva" is not.
A note that only relates by topic is not worth a link.

Where a connection belongs to one specific claim rather than the note as a whole, link it
inline in that claim's annotation under `## Candidate Permanent Notes` instead.

**Link each note at most once per expansion.** If a note is already linked from a candidate
annotation or from the body, do not repeat it as a `Related:` line — a second edge to the same
target adds nothing to the graph and reads as padding.

## Modes

Modes shift emphasis and section weight. **They never change the skeleton**, and every mode
keeps `## The Principle`, `## Candidate Permanent Notes`, and `## Links`.

| Mode | Emphasis |
|---|---|
| `balanced` (default) | Even coverage of all sections. |
| `practical` | Expand `In Everyday Life`, `Examples`, `Living It`. Compress the scenario. Every example ends in a decidable action. |
| `seva` | Draw all domains from mandir seva: teamwork, humility, correction, recognition, reliability, mahima, leadership, karyakar dynamics. |
| `philosophical` | Expand `The Principle` and `Where This Gets Misunderstood` into doctrinal territory — Aksharbrahman/Parabrahman, Ekantik Dharma, the nature of the Satpurush — while staying anchored to what the source note actually says. Fewer examples. |
| `story` | Two or three illustrative scenarios instead of one. Each labelled per the tier rules. Compress `Living It`. |
| `knowledge-graph` | Shorten the prose sections to their essentials. Expand vault search, duplicate detection, `Candidate Permanent Notes`, and `Links`. Report the graph findings (near-duplicates, orphan opportunities, missing connective notes) in the chat summary. |

If the user gives a free-text focus instead of a mode name ("focus on family life", "focus on
the deepest philosophical implication"), honour it as a lens over balanced mode.
