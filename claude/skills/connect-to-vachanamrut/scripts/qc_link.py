#!/usr/bin/env python3
"""Append a backlink to a Quick Capture entry without breaking the QC pipeline.

    python3 qc_link.py NOTE.md --link "Some note title" --match "text from the capture"
    python3 qc_link.py NOTE.md --link "Some note title" --time 17:46
    python3 qc_link.py NOTE.md --link "Some note title" --last
    ... add --dry-run to print the diff and write nothing.

WHY THIS SCRIPT EXISTS
----------------------
`qc-process` (systemd timer, 23:30) hands every *-QC.md still containing a raw
"## HH:MM" heading to Hermes, which rewrites the WHOLE FILE. Its mandated output
layout is "frontmatter, then ## <Topic> sections" — nothing else. The script
then enforces a verbatim-prose rail: every non-blank body line from the pre-run
backup must still be present afterwards, or it restores the backup and fires a
critical notification.

So appending a "## Developed Notes" section to an *unprocessed* QC note is
actively dangerous: Hermes would very likely drop the section, the rail would
fire, and the night's entire processing run would be silently reverted.

The safe insertion point is INSIDE the capture's body. Hermes carries body
lines through verbatim and moves them into the topic section along with the
rest of the entry. That works in both the processed and unprocessed states.

This script therefore:
  * takes the same flock the capture popup and qc-process share, so it can
    never write mid-capture or mid-rewrite;
  * backs the file up first (the vault has no maintained git history);
  * refuses to create or destroy any "## HH:MM" heading, since that flag is
    exactly what marks a note as needing processing;
  * leaves frontmatter byte-identical;
  * is idempotent — the same link is never added twice.

Stdlib only.
"""

from __future__ import annotations

import argparse
import fcntl
import os
import re
import shutil
import sys
import time
from pathlib import Path

RAW_HEADING_RE = re.compile(r"^## \d{2}:\d{2}$", re.M)
ENTRY_STAMP_RE = re.compile(r"^\*\*(\d{2}:\d{2})\*\* — ", re.M)
MARKER_RE = re.compile(
    r"^@[A-Za-z0-9][A-Za-z0-9_-]*(\s+@[A-Za-z0-9][A-Za-z0-9_-]*)*\s*$")
SECTION_RE = re.compile(r"^## ", re.M)

LOCK = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "obsidian-quick-capture.lock"
BACKUPS = Path(os.environ.get("XDG_STATE_HOME",
                              Path.home() / ".local/state")) / "connect-vachanamrut/backups"
LABEL = "Developed into"


def split_frontmatter(text: str) -> tuple[str, str]:
    """Return (frontmatter_including_fences, body). Frontmatter may be ''."""
    if not text.startswith("---\n"):
        return "", text
    end = text.find("\n---\n", 3)
    if end == -1:
        return "", text
    return text[:end + 5], text[end + 5:]


def is_processed(body: str) -> bool:
    """A note is unprocessed iff it still carries a raw '## HH:MM' heading.

    This is the exact test qc-process uses to select files.
    """
    return not RAW_HEADING_RE.search(body)


def find_blocks(body: str) -> list[dict]:
    """Locate capture entries in either state.

    Unprocessed: '## HH:MM' heading, then body until the next heading.
    Processed:   '**HH:MM** — ' line, then body until the next stamp or heading.
    Each block records where its body ends, which is where a link belongs.
    """
    blocks: list[dict] = []
    lines = body.splitlines(keepends=True)
    offsets, pos = [], 0
    for ln in lines:
        offsets.append(pos)
        pos += len(ln)
    offsets.append(pos)

    starts: list[tuple[int, str]] = []
    for i, ln in enumerate(lines):
        s = ln.rstrip("\n")
        if re.fullmatch(r"## \d{2}:\d{2}", s):
            starts.append((i, s[3:]))
        else:
            m = ENTRY_STAMP_RE.match(s)
            if m:
                starts.append((i, m.group(1)))

    for n, (idx, stamp) in enumerate(starts):
        # The block ends at the next entry start, or the next '## ' heading,
        # or EOF — whichever comes first.
        end = len(lines)
        if n + 1 < len(starts):
            end = starts[n + 1][0]
        for j in range(idx + 1, end):
            if lines[j].startswith("## "):
                end = j
                break
        # Trim trailing blank lines so the link lands against the prose.
        last = end
        while last > idx + 1 and not lines[last - 1].strip():
            last -= 1
        text = "".join(lines[idx:end])
        blocks.append({
            "stamp": stamp,
            "start_line": idx,
            "end_line": end,
            "insert_line": last,
            "insert_offset": offsets[last],
            "text": text,
        })
    return blocks


def choose_block(blocks: list[dict], args) -> dict | None:
    if not blocks:
        return None
    if args.time:
        hits = [b for b in blocks if b["stamp"] == args.time]
        if len(hits) > 1:
            print(f"ERROR: {len(hits)} captures at {args.time}; use --match",
                  file=sys.stderr)
            return None
        return hits[0] if hits else None
    if args.match:
        needle = args.match.strip().lower()
        hits = [b for b in blocks if needle in b["text"].lower()]
        if not hits:
            return None
        if len(hits) > 1:
            print(f"ERROR: {len(hits)} captures match {args.match!r}; "
                  "use a longer snippet or --time", file=sys.stderr)
            return None
        return hits[0]
    return blocks[-1]  # --last


def verify_rails(before: str, after: str) -> list[str]:
    """Replay qc-process's own integrity rails against our edit.

    If our write would fail these, the nightly run would restore a backup and
    alarm the user. Catching it here means we simply refuse instead.
    """
    problems = []
    fm_b, body_b = split_frontmatter(before)
    fm_a, body_a = split_frontmatter(after)

    if fm_b != fm_a:
        problems.append("frontmatter changed (must stay byte-identical)")
    if before.count("\n---\n") and after.count("---") < 2:
        problems.append("frontmatter fence lost")
    if "type: quick-capture" in before and "type: quick-capture" not in after:
        problems.append("'type: quick-capture' lost")

    before_heads = RAW_HEADING_RE.findall(body_b)
    after_heads = RAW_HEADING_RE.findall(body_a)
    if before_heads != after_heads:
        problems.append(
            f"raw '## HH:MM' headings changed ({len(before_heads)} -> "
            f"{len(after_heads)}); this flag decides whether qc-process "
            "reprocesses the note")

    # Verbatim-prose rail: every original non-blank body line must survive as a
    # substring, exactly as qc-process checks it.
    for line in body_b.splitlines():
        if not line.strip():
            continue
        if line not in after:
            problems.append(f"prose line lost: {line[:60]!r}")
            break

    # Marker-only lines must survive untouched, or qc-process's topic mapping
    # changes and the capture is filed under the wrong header.
    mb = [ln for ln in body_b.splitlines() if MARKER_RE.match(ln.strip())]
    ma = [ln for ln in body_a.splitlines() if MARKER_RE.match(ln.strip())]
    if mb != ma:
        problems.append("@context marker lines changed")
    return problems


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("note", type=Path)
    ap.add_argument("--link", required=True,
                    help="note TITLE to link to (no brackets)")
    ap.add_argument("--label", default=LABEL)
    sel = ap.add_mutually_exclusive_group(required=True)
    sel.add_argument("--match", help="unique text from the target capture")
    sel.add_argument("--time", help="capture timestamp, HH:MM")
    sel.add_argument("--last", action="store_true", help="most recent capture")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--no-lock", action="store_true",
                    help="skip the flock (tests against fixtures only)")
    args = ap.parse_args()

    if not args.note.is_file():
        print(f"ERROR: not a file: {args.note}", file=sys.stderr)
        return 1

    lock_fd = None
    if not args.no_lock:
        try:
            lock_fd = os.open(str(LOCK), os.O_CREAT | os.O_RDWR, 0o644)
            fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            print("ERROR: the Quick Capture lock is held — a capture session is "
                  "open or qc-process is running. Try again shortly.",
                  file=sys.stderr)
            return 3

    try:
        before = args.note.read_text(encoding="utf-8")
        fm, body = split_frontmatter(before)
        processed = is_processed(body)

        link_line = f"{args.label}: [[{args.link}]]"
        if link_line in before:
            print(f"OK    link already present; nothing to do ({args.note.name})")
            return 0

        blocks = find_blocks(body)
        if not blocks:
            print("ERROR: no capture entries found. This does not look like a "
                  "QC note in either the raw or processed layout.",
                  file=sys.stderr)
            return 1

        block = choose_block(blocks, args)
        if block is None:
            print("ERROR: no capture matched the selector", file=sys.stderr)
            return 1

        lines = body.splitlines(keepends=True)
        at = block["insert_line"]
        # Ensure the preceding line ends with a newline before we splice.
        if at > 0 and lines[at - 1] and not lines[at - 1].endswith("\n"):
            lines[at - 1] += "\n"
        lines.insert(at, link_line + "\n")
        after = fm + "".join(lines)

        problems = verify_rails(before, after)
        if problems:
            print("ERROR: refusing to write — the edit would break the QC "
                  "pipeline:", file=sys.stderr)
            for p in problems:
                print(f"  - {p}", file=sys.stderr)
            return 2

        state = "processed" if processed else "UNPROCESSED (qc-process will "\
                                              "still rewrite this note)"
        if args.dry_run:
            print(f"--- dry run: {args.note} [{state}] ---")
            print(f"would insert after line {at} of the body, "
                  f"in the {block['stamp']} capture:")
            print(f"  + {link_line}")
            print("rails: all passed")
            return 0

        BACKUPS.mkdir(parents=True, exist_ok=True)
        stamp = time.strftime("%Y%m%d-%H%M%S")
        backup = BACKUPS / f"{args.note.name}.{stamp}"
        shutil.copy2(args.note, backup)
        # Keep the last 20, matching qc-process's retention.
        for old in sorted(BACKUPS.glob(f"{args.note.name}.*"),
                          key=lambda p: p.stat().st_mtime, reverse=True)[20:]:
            old.unlink()

        # Write in place to preserve the inode — Obsidian and Obsidian Sync
        # both cope better with that than a replace.
        with open(args.note, "w", encoding="utf-8") as fh:
            fh.write(after)

        print(f"OK    linked {args.note.name} [{state}]")
        print(f"      capture {block['stamp']}  +  {link_line}")
        print(f"      backup: {backup}")
        return 0
    finally:
        if lock_fd is not None:
            os.close(lock_fd)


if __name__ == "__main__":
    sys.exit(main())
