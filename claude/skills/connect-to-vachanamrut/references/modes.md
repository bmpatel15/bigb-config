# Output modes

Default is `deep` with no writing. Modes are lenses over the same method, not different
methods — the rails in `SKILL.md` apply to all of them.

Set with a flag (`/connect-to-vachanamrut quick`) or in plain words ("use Quick Connect
Mode", "just give me the short version").

## `quick` — Quick Connect

For use mid-capture, when the user does not want to be pulled out of what they were doing.
**Return only:**

- the underlying principle (one line)
- the strongest connection
- two to four sentences of explanation
- confidence level
- the existing wikilink, if one exists
- at most one related-note link

No qualification section, no application section, no reflection questions. If the honest
answer is `unresolved`, say that in one sentence — do not expand to compensate.

```markdown
**Principle:** Discouragement in seva tracks attachment to your own plan, not to the seva.

**Suggested Vachanamrut — verification required: Gadhada I-15** *(Not Becoming Discouraged
in Meditation).* Maharaj's concern there is continuing when the effort feels unsuccessful;
applied here, the discouragement is a signal about authorship rather than about the work.
Context differs — that discourse concerns meditation, not organised seva.

**Confidence:** Moderate · title match only, text unread. No vault note exists.
```

## `deep` — Deep Analysis (default)

The full shape from `SKILL.md` §7: core principle, strongest connection, supporting
connections, why it fits, qualification where needed, practical implications, related
existing notes, confidence and source status. Still prose, not an essay — if it runs past
roughly 600 words without the user asking for more, it is too long.

## `quote` — Quote Mode

For a captured quotation. Include the quote verbatim, its core principle, the compatibility
verdict (see `compatibility.md`), the strongest connection, a concise explanation,
**attribution status**, source status, and related links.

Never assume the attribution is right. Never dress a paraphrase as a quotation.

## `reflection` — Personal Reflection Mode

For the user's own observation. Connect it to the human struggle, the teaching, and **one**
concrete application, then offer reflection questions specific to this thought.

**Preserve their voice.** A personal observation has a texture — hesitancy, self-criticism,
a particular example — that generic motivational prose destroys. Quote their phrasing back
where it is sharper than yours. Do not resolve an observation they left open.

## `seva` — Seva Mode

Same as `deep`, weighted toward the seva context: dasbhav, humility, correction, teamwork,
reliability, recognition, samp, suhradbhav, leadership, obedience, mahima, attachment to
roles, personal preference, service without ego.

Useful because seva thoughts often look like management problems and are usually about ego,
authorship, or preference. Say which.

## `graph` — Knowledge Graph Mode

Prioritise structure over exposition:

- search existing notes exhaustively
- locate every relevant Vachanamrut link
- find related evergreen notes and duplicate concepts
- suggest missing connections
- propose conservative backlinks
- build a structured connection note if asked

Report what exists and what is missing. Given the current vault, "missing" will dominate —
that is useful information, not a failure.

## `research` — Research Mode

Use trusted sources to pin the reference down.

```bash
python3 scripts/vach_lookup.py --search "<thought>"          # narrow
python3 scripts/fetch_discourse.py "Gadhada I-15" --grep "discouraged"   # verify
```

Report: sources searched · the discourse identified · the relevant section · whether the
relationship is direct or interpretive · confidence · remaining ambiguity.

**Source hierarchy** — never skip a tier silently:

1. Existing Vachanamrut notes in the vault
2. A trusted local Vachanamrut text, if one is configured
3. `fetch_discourse.py` against anirdesh.com (BAPS English translation)
4. Other approved external sources, when tools and permission exist
5. Model knowledge — **always** labelled unverified

**Claudian has no network.** Inside Obsidian the fetch fails, and Research Mode degrades to
index-only ranking. Say that explicitly; never describe research you did not perform. When
verification matters, tell the user to run it from a terminal.

Do not use blogs, quote sites, forum posts, or unsourced summaries to establish a reference.

## Modifiers

| Modifier | Effect |
|---|---|
| `create-note` | Run the note-creation workflow after the analysis. |
| `no-write` | Explicit analysis-only. Already the default; use it to be sure. |
| `selected-text` | Force the highlighted passage as the source, ignoring the rest of the note. |
| `current-capture` | Force the most recent meaningful entry in today's `-QC.md`. |

Modes combine with modifiers: `/connect-to-vachanamrut seva create-note`,
`/connect-to-vachanamrut quote no-write`.
