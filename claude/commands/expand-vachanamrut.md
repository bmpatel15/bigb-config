---
description: Expand a principle from the open Vachanamrut note into a linked study note
argument-hint: "[focus, or mode: practical | seva | philosophical | story | knowledge-graph]"
---
Use the **expand-vachanamrut** skill on the Vachanamrut note I currently have open in Obsidian.

Focus or mode: **$ARGUMENTS** — if empty, use balanced mode and pick the strongest principle from my own reflections in the note.

All the logic lives in the skill (`~/.claude/skills/expand-vachanamrut/SKILL.md`) — follow its workflow rather than improvising: resolve the active note from the `<linked_note>` or `<editor_selection>` context Claudian provides, confirm it's a Vachanamrut note, search the vault before creating anything, write the expansion to `03 - Literature Notes/Vachanamrut/Expansions/`, add one `- Expanded in:` backlink to the source note, and run the validator. Then give me the short summary — don't paste the whole note.
