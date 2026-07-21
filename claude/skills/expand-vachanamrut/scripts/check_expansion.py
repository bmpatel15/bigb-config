#!/usr/bin/env python3
"""Validate an expansion note written by the expand-vachanamrut skill.

    python3 check_expansion.py "<path to the new expansion note>"

Checks structure, frontmatter, and the two safety rules that matter most:
every wikilink resolves to a real note, and nothing is quoted as the words of a
spiritual figure. Exits non-zero if any ERROR is found; WARNs are advisory.

No third-party dependencies (the frontmatter subset used here is simple enough
to parse directly, so this runs anywhere python3 does).
"""

import os
import re
import sys

REQUIRED_KEYS = ["type", "source", "ref", "created", "status",
                 "reviewed", "review-interval", "next-review", "tags"]
REQUIRED_SECTIONS = ["## The Principle", "## Candidate Permanent Notes", "## Links"]
SCENARIO_LABELS = ["consider an illustrative", "a realistic example might",
                   "imagine a composite", "illustrative situation",
                   "illustrative composite"]
FIGURES = [
    "Bhagwan Swaminarayan", "Shriji Maharaj", "Gunatitanand Swami",
    "Bhagatji Maharaj", "Shastriji Maharaj", "Yogiji Maharaj",
    "Pramukh Swami Maharaj", "Mahant Swami Maharaj", "Swamishri",
]
BANNED = [
    "in today's fast-paced world", "this profound teaching reminds us",
    "it is important to note", "at its core", "this serves as a powerful reminder",
    "in conclusion", "delve into", "tapestry", "timeless wisdom",
]

errors, warnings = [], []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def find_vault(start):
    """Walk up from the note to the directory holding .obsidian."""
    d = os.path.abspath(start)
    while d != "/":
        if os.path.isdir(os.path.join(d, ".obsidian")):
            return d
        d = os.path.dirname(d)
    return None


def split_frontmatter(text):
    if not text.startswith("---\n"):
        return None, text
    end = text.find("\n---\n", 3)
    if end == -1:
        return None, text
    return text[4:end + 1], text[end + 5:]


def parse_keys(fm):
    """Ordered top-level keys of the frontmatter block."""
    return [m.group(1) for m in re.finditer(r"^([A-Za-z][\w-]*):", fm, re.M)]


def note_titles(vault):
    """Every note basename in the vault, for wikilink resolution."""
    titles = set()
    for _, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        titles.update(f[:-3] for f in files if f.endswith(".md"))
    return titles


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2

    path = sys.argv[1]
    if not os.path.isfile(path):
        print(f"ERROR: not a file: {path}")
        return 1

    text = open(path, encoding="utf-8").read()
    vault = find_vault(path)
    if not vault:
        warn("could not locate the vault root (.obsidian); skipped link resolution")

    # ---- frontmatter -------------------------------------------------
    fm, body = split_frontmatter(text)
    if fm is None:
        err("no YAML frontmatter block")
    else:
        keys = parse_keys(fm)
        missing = [k for k in REQUIRED_KEYS if k not in keys]
        if missing:
            err(f"frontmatter missing keys: {', '.join(missing)}")
        present = [k for k in keys if k in REQUIRED_KEYS]
        expected = [k for k in REQUIRED_KEYS if k in present]
        if present != expected:
            warn(f"frontmatter key order differs from the template: {present}")

        m = re.search(r"^type:\s*(\S+)", fm, re.M)
        if m and m.group(1) != "literature":
            err(f"type is '{m.group(1)}', expected 'literature' "
                "(expansions are literature-stage, not permanent)")
        m = re.search(r"^status:\s*(\S+)", fm, re.M)
        if m and m.group(1) != "inbox":
            warn(f"status is '{m.group(1)}'; new expansions are normally 'inbox'")
        m = re.search(r"^created:[ \t]*(.*)$", fm, re.M)
        if m and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", m.group(1).strip()):
            err(f"created must be a bare YYYY-MM-DD date, got '{m.group(1).strip()}'")
        if re.search(r"^tags:\s*\[", fm, re.M):
            err("tags must be a block list, not inline [a, b]")
        for t in ("scripture", "vachanamrut", "expansion"):
            if not re.search(rf"^\s+-\s+{t}\s*$", fm, re.M):
                warn(f"tag '{t}' not present")
        if re.search(r"^aliases:", fm, re.M):
            warn("aliases: is unused everywhere else in this vault")

    # ---- structure ---------------------------------------------------
    for s in REQUIRED_SECTIONS:
        if s not in body:
            err(f"missing required section: {s}")

    h1 = re.search(r"^#\s+(.+)$", body, re.M)
    if not h1:
        err("no # H1 title")
    else:
        title, stem = h1.group(1).strip(), os.path.basename(path)[:-3]
        if title != stem:
            warn(f"H1 ({title!r}) differs from filename ({stem!r}) — "
                 "intended only when the title needed sanitising")

    stem = os.path.basename(path)[:-3]
    bad = [c for c in ':/\\|#^[]' if c in stem]
    if bad:
        err(f"filename contains unsafe characters: {' '.join(bad)}")

    if re.search(r"^\s*-\s*\[[ x]\]", body, re.M):
        err("body contains a '- [ ]' checkbox; the Tasks plugin has no global "
            "filter, so it would be picked up as a real task. Use plain '-'.")

    # ---- links -------------------------------------------------------
    links = re.findall(r"\[\[([^\]]+)\]\]", body)
    if not links:
        err("no wikilinks at all; the note would be an orphan")
    if vault:
        titles = note_titles(vault)
        for link in links:
            if "|" in link:
                err(f"pipe alias used ('[[{link}]]'); this vault uses none")
            target = link.split("|")[0].split("#")[0].strip()
            if target not in titles:
                err(f"broken wikilink: [[{target}]] resolves to no note in the vault")

    links_block = body.split("## Links", 1)[-1] if "## Links" in body else ""
    for label in ("Source:", "Index:"):
        if label not in links_block:
            warn(f"'## Links' has no '{label}' line")

    # ---- safety ------------------------------------------------------
    if "## An Illustrative Scenario" in body:
        section = body.split("## An Illustrative Scenario", 1)[1].split("\n## ", 1)[0]
        if not any(lbl in section.lower() for lbl in SCENARIO_LABELS):
            err("the illustrative scenario is not labelled as illustrative/composite")

    # A quoted span near a named figure is a fabrication risk — but a verified
    # vault prasang is the *preferred* source, and citing one means writing near
    # those names. So only hard-fail when the surrounding paragraph cites nothing;
    # if it links a vault note, downgrade to a reminder to check the wording.
    paragraphs = re.split(r"\n\s*\n", body)
    for para in paragraphs:
        for fig in FIGURES:
            if fig not in para:
                continue
            for m in re.finditer(re.escape(fig), para):
                window = para[max(0, m.start() - 80):m.end() + 80]
                if not re.search(r'["“”]([^"“”]{15,})["“”]', window):
                    continue
                if "[[" in para:
                    warn(f"quotation near '{fig}' in a paragraph that cites a vault "
                         "note — confirm the wording matches that source verbatim")
                else:
                    err(f"possible fabricated quotation near '{fig}' — paraphrase "
                        "without quotation marks, or link the vault note it comes from")
                break
            else:
                continue
            break

    low = body.lower()
    for phrase in BANNED:
        if phrase in low:
            warn(f"banned phrase present: {phrase!r}")

    # Prose length, excluding the staging/link sections and headings.
    prose = re.sub(r"^#.*$", "", body.split("## Candidate Permanent Notes")[0], flags=re.M)
    words = len(prose.split())
    if words > 1800:
        warn(f"{words} words of prose — well over budget; drop a section rather than "
             "thinning the rest (see writing-style.md)")
    elif words > 1500:
        warn(f"{words} words of prose — over the 900–1500 band for most modes; fine for "
             "'story', otherwise consider dropping a section")
    elif words < 400:
        warn(f"only {words} words of prose — thin even for knowledge-graph mode")

    # ---- report ------------------------------------------------------
    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    if not errors and not warnings:
        print(f"OK    {os.path.basename(path)} — all checks passed")
    elif not errors:
        print(f"OK    {os.path.basename(path)} — {len(warnings)} warning(s), no errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
