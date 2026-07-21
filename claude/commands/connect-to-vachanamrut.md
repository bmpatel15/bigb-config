---
description: Find which Vachanamrut teaching a thought, quote or Quick Capture relates to
argument-hint: "[mode: quick | deep | quote | reflection | seva | graph | research] [create-note | no-write] [or paste the thought]"
---
Use the **connect-to-vachanamrut** skill on the passage I'm pointing at.

Arguments: **$ARGUMENTS** — if empty, use `deep` mode, no writing, and resolve the passage yourself.

Anything in the arguments that isn't a recognised mode or modifier is either the thought itself or a focus to apply.

All the logic lives in the skill (`~/.claude/skills/connect-to-vachanamrut/SKILL.md`) — follow its workflow rather than improvising: resolve the source passage (selection beats `<linked_note>`; isolate one capture from a multi-entry `-QC.md` rather than analysing the whole file, and tell me which passage you used), build the concept profile before searching, search the vault first, then rank candidates with `scripts/vach_lookup.py --search` and verify the leading one with `scripts/fetch_discourse.py` when there's a network.

Be strict about certainty: a reference is **verified** only if you actually read the teaching, otherwise label it *Suggested Vachanamrut — verification required*, and if nothing can be responsibly named, say so — that's a good answer, not a failure. Never invent a discourse number or a quotation, and only link notes that exist.

**Don't write anything unless I asked for a note** (or passed `create-note`). If I did: duplicate-check `Connections/` and `04 - Permanent Notes/` first, write to `03 - Literature Notes/Vachanamrut/Connections/` with a sentence-case claim title, backlink the source with `scripts/qc_link.py` (never by hand for a `-QC.md` — read `references/quick-capture.md` first), run `scripts/check_connection.py`, and list every file you changed.
