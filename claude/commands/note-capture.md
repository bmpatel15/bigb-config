---
description: Quick-capture a timestamped note into the BigB-PKM Obsidian vault
argument-hint: "[note text]  (prefix with 'satsang:' to route to the Satsang Diksha study area)"
---
Capture a note into my Obsidian vault at `~/Documents/BigB-PKM`. Note text: **$ARGUMENTS** — if empty, ask me what to capture.

Routing:
- **Default** → a new fleeting note in `02 - Fleeting Notes/`, filename `YYYY-MM-DD-HHMM <short-slug>.md`.
- **If the text starts with `satsang:`** → route to the Satsang Diksha study area instead. Check `06 - Command Center/Satsang Study HQ.md` and `00 - Home/Satsang Exams MOC.md` for the current structure, and use `09 - Templates/Satsang Diksha Shlok Template.md` if it's a shlok. Strip the `satsang:` prefix from the body.

Note format: short YAML frontmatter (`created:`, `tags:`) then the captured text. Use the real current time via `date '+%Y-%m-%d %H:%M'`. Keep the filename filesystem-safe. After writing, tell me the exact path and offer to link it from a relevant MOC.
