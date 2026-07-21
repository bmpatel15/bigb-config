#!/usr/bin/env python3
"""Validate a connection note written by the connect-to-vachanamrut skill.

    python3 check_connection.py "<path to the connection note>"

Enforces the vault's conventions and this skill's central safety rule: a
reference is never presented as more certain than it is. Exits non-zero on any
ERROR; WARNs are advisory.

Stdlib only. Generic vault helpers come from ../../_shared/vaultlib.py.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_shared"))
import vaultlib as V  # noqa: E402

REQUIRED_KEYS = ["type", "source", "ref", "created", "status", "reviewed",
                 "review-interval", "next-review", "tags", "connection-status"]
REQUIRED_SECTIONS = ["## The Thought", "## Core Insight", "## Links"]
VALID_STATUS = {"verified", "suggested", "unresolved"}
VALID_RELATIONSHIPS = {
    "direct-teaching", "practical-application", "modern-expression",
    "supporting-analogy", "partial-alignment", "corrective",
    "tension-requiring-qualification", "shared-struggle",
    "consequence-of-the-teaching", "failing-to-live-the-teaching",
}
FIGURES = [
    "Bhagwan Swaminarayan", "Shriji Maharaj", "Maharaj", "Gunatitanand Swami",
    "Bhagatji Maharaj", "Shastriji Maharaj", "Yogiji Maharaj",
    "Pramukh Swami Maharaj", "Mahant Swami Maharaj", "Swamishri",
]
BANNED = [
    "in today's fast-paced world", "this profound teaching reminds us",
    "it is important to note", "at its core", "this serves as a powerful reminder",
    "in conclusion", "delve into", "tapestry", "timeless wisdom",
]
HEDGES = ["verification required", "not yet verified", "unverified",
          "could not verify", "needs checking", "requires verification",
          "have not verified", "not been verified"]


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    if not os.path.isfile(path):
        print(f"ERROR: not a file: {path}")
        return 1

    text = open(path, encoding="utf-8").read()
    f = V.Findings()
    vault = V.vault_root(path)
    if not vault:
        f.warn("could not locate the vault root (.obsidian); skipped link resolution")

    fm, body = V.split_frontmatter(text)
    status = None

    # ---- frontmatter ----------------------------------------------------
    if fm is None:
        f.err("no YAML frontmatter block")
    else:
        keys = V.parse_keys(fm)
        missing = [k for k in REQUIRED_KEYS if k not in keys]
        if missing:
            f.err(f"frontmatter missing keys: {', '.join(missing)}")

        canonical = [k for k in REQUIRED_KEYS[:9] if k in keys]
        expected = [k for k in REQUIRED_KEYS[:9] if k in canonical]
        if canonical != expected:
            f.warn(f"the nine canonical keys are out of template order: {canonical}")

        if (t := V.fm_value(fm, "type")) and t != "literature":
            f.err(f"type is {t!r}, expected 'literature' — connection notes are "
                  "literature-stage, staged for promotion, not permanent notes")
        if (s := V.fm_value(fm, "source")) and s != "Vachanamrut":
            f.warn(f"source is {s!r}, expected 'Vachanamrut'")
        if (st := V.fm_value(fm, "status")) and st != "inbox":
            f.warn(f"status is {st!r}; new connection notes are normally 'inbox'")
        created = V.fm_value(fm, "created")
        if created is not None and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", created):
            f.err(f"created must be a bare unquoted YYYY-MM-DD, got {created!r}")
        if re.search(r"^tags:\s*\[", fm, re.M):
            f.err("tags must be a block list, not inline [a, b]")
        for t in ("scripture", "vachanamrut", "connection"):
            if t not in V.fm_list(fm, "tags"):
                f.warn(f"tag {t!r} not present")
        if re.search(r"^aliases:", fm, re.M):
            f.warn("aliases: is used in zero notes across this vault; drop it")
        # [ \t] not \s: \s matches newlines, so a blank `reviewed:` would
        # swallow the line break and match the next key's value.
        if re.search(r"^(reviewed|next-review):[ \t]*\S", fm, re.M):
            f.warn("reviewed/next-review should be left blank; the `reviewed` "
                   "command walks the ladder")

        # ---- the central rule: certainty must match the evidence ---------
        status = V.fm_value(fm, "connection-status")
        ref = V.fm_value(fm, "ref") or ""
        suggested = V.fm_value(fm, "suggested-ref") or ""

        if status not in VALID_STATUS:
            f.err(f"connection-status must be one of "
                  f"{sorted(VALID_STATUS)}, got {status!r}")
        elif status == "verified":
            if not ref:
                f.err("connection-status is 'verified' but ref: is empty")
            if suggested:
                f.err("connection-status is 'verified' but suggested-ref: is set; "
                      "a verified connection uses ref: alone")
        else:
            if ref:
                f.err(f"ref: is set to {ref!r} while connection-status is "
                      f"{status!r} — an unverified reference must live in "
                      "suggested-ref:, never in a field that implies certainty")
            if status == "suggested" and not suggested:
                f.err("connection-status is 'suggested' but suggested-ref: is empty")

        rel = V.fm_value(fm, "relationship")
        if rel and rel not in VALID_RELATIONSHIPS:
            f.warn(f"relationship {rel!r} is not one of the documented types")

    # ---- structure ------------------------------------------------------
    for s in REQUIRED_SECTIONS:
        if s not in body:
            f.err(f"missing required section: {s}")

    has_verified_section = "## Vachanamrut Connection" in body
    has_possible_section = "## Possible Vachanamrut Connection" in body
    if not (has_verified_section or has_possible_section):
        f.err("missing a connection section (## Vachanamrut Connection or "
              "## Possible Vachanamrut Connection)")
    if status == "verified" and has_possible_section and not has_verified_section:
        f.warn("status is 'verified' but the section is titled 'Possible'")
    if status in ("suggested", "unresolved") and has_verified_section:
        f.err(f"status is {status!r} but the section is titled "
              "'## Vachanamrut Connection', which reads as established; use "
              "'## Possible Vachanamrut Connection'")

    if status in ("suggested", "unresolved"):
        low = body.lower()
        if not any(h in low for h in HEDGES):
            f.err("an unverified connection must say so in the body; none of the "
                  "verification-required phrasings appear")
        if "## Research Needed" not in body:
            f.warn("unverified connection without a '## Research Needed' section "
                   "stating exactly what to check")

    h1 = re.search(r"^#\s+(.+)$", body, re.M)
    stem = os.path.basename(path)[:-3]
    if not h1:
        f.err("no # H1 title")
    elif h1.group(1).strip() != stem:
        f.warn(f"H1 ({h1.group(1).strip()!r}) differs from filename ({stem!r}) — "
               "intended only when the title needed sanitising")

    if bad := V.unsafe_chars(stem):
        f.err(f"filename contains unsafe characters: {' '.join(bad)}")
    if stem[:1].isupper() and stem.split() and sum(
            1 for w in stem.split()[1:] if w[:1].isupper() and w.isalpha()) >= 3:
        f.warn(f"title {stem!r} looks Title Cased; this vault uses sentence-case "
               "claims (e.g. 'Constant remembrance surpasses other sadhana')")

    if re.search(r"^\s*-\s*\[[ x]\]", body, re.M):
        f.err("body contains a '- [ ]' checkbox; the Tasks plugin has an empty "
              "global filter, so it would surface as a real open task. Use '-'.")

    # ---- links ----------------------------------------------------------
    links = V.wikilinks(body)
    if not links:
        f.err("no wikilinks at all; the note would be flagged by `orphans`")
    for link in links:
        if "|" in link:
            f.err(f"pipe alias used ('[[{link}]]'); this vault uses none")
    if vault:
        titles = V.note_titles(vault)
        for target in V.broken_links(body, titles):
            f.err(f"broken wikilink: [[{target}]] resolves to no note in the vault")

    links_block = body.split("## Links", 1)[-1] if "## Links" in body else ""
    if "Connected from:" not in links_block and "Source:" not in links_block:
        f.warn("'## Links' has no 'Connected from:' or 'Source:' line")

    # ---- fabrication guard ----------------------------------------------
    # Proximity is judged per PARAGRAPH, not by a character window. A fixed
    # window silently misses quotations that wrap across lines, which is the
    # common case and precisely the one that matters most here.
    QUOTE_RE = re.compile(r'["“”]([^"“”]{15,})["“”]',
                          re.S)
    for para in re.split(r"\n\s*\n", body):
        if not QUOTE_RE.search(para):
            continue
        for fig in FIGURES:
            if not re.search(rf"\b{re.escape(fig)}\b", para):
                continue
            if "[[" in para or "anirdesh.com" in para:
                f.warn(f"quotation near {fig!r} in a paragraph that cites a "
                       "source — confirm the wording matches it verbatim")
            else:
                f.err(f"possible fabricated quotation near {fig!r} — paraphrase "
                      "without quotation marks, or cite the source it comes from")
            break

    low = body.lower()
    for phrase in BANNED:
        if phrase in low:
            f.warn(f"banned phrase present: {phrase!r}")

    return f.report(os.path.basename(path))


if __name__ == "__main__":
    sys.exit(main())
