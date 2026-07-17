---
description: Evening ritual — rate the day, capture Win/Struggle/Lesson, plan tomorrow
argument-hint: "(optional) a one-line summary of the day"
---
Run my end-of-day ritual for the BigB-PKM vault (`~/Documents/BigB-PKM`). Keep it warm and brief — under three minutes. Do the file edits yourself; ask me the human questions (one at a time is fine, or take them all at once if I answer ahead). Work on today's daily note (`01 - Daily Notes/<today>.md`; create it with `today-note` if somehow missing). Fill the items below and preserve everything else in the note.

**Frontmatter safety (important):** edit frontmatter *surgically* — when you set a field, change only that one field's value on its own line (e.g. `log-day-rating:` → `log-day-rating: 1`). Never reorder, reformat, re-serialize, or drop any other frontmatter key. In particular, keep **every `ahnik-*` checkbox exactly as it is, including the `false` ones** — the Ahnik Dashboard's Dataview analytics count them, and dropping a `false` key corrupts the streak/percentage math — and leave all other `log-*` fields and the existing key order untouched.

1. **Day rating** — ask *"How was today, −2 to +2?"* → write the number into the `log-day-rating:` frontmatter field. If I volunteer energy, sleep, or steps, also set `log-energy-rating:`, `log-sleep-hours:`, and `log-steps:` (step count, goal 10,000); otherwise leave them blank.
2. **Summary** — my one-liner: **$ARGUMENTS** — if empty, ask *"One line — what was today about?"* → write it into the `summary:` frontmatter field.
3. **Win / Struggle / Lesson** — ask for one line each. Write them under `### Win / Struggle / Lesson` as `- **Win:** …`, `- **Struggle:** …`, `- **Lesson:** …`.
4. **Tomorrow** — ask *"What's the one thing to set up for tomorrow?"* → add it under `### Tomorrow's setup` as `- [ ] <item>`. (rollover will carry it into tomorrow automatically.)
5. **Picture** — one gentle line: if I have a photo of the day, drop it under `## Pictures`. Don't push it.

Finish with a short, genuine one-line sign-off. Do NOT open an editor. If I want to stop early, save what we have and let me go — a partial close still counts as showing up.
