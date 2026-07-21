#!/usr/bin/env python3
"""Shared helpers for the BigB-PKM Obsidian skills.

Generic vault operations only — nothing here knows about Vachanamrut,
expansions, or connections. Skill-specific rules belong in the skill's own
validator.

Consumers add this directory to sys.path, since skills are not a package:

    import sys, pathlib
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "_shared"))
    import vaultlib

Stdlib only, matching every other script in this setup.

Provenance: find_vault, split_frontmatter, parse_keys and note_titles were
extracted from expand-vachanamrut/scripts/check_expansion.py. That file was
deliberately left untouched, so the two copies can drift; if you change
behaviour here, check whether the expansion validator should follow.
"""

from __future__ import annotations

import os
import re

# --------------------------------------------------------------------------
# Vault discovery
# --------------------------------------------------------------------------

DEFAULT_VAULT = os.path.expanduser("~/Documents/BigB-PKM")


def find_vault(start: str) -> str | None:
    """Walk up from a path to the directory holding .obsidian."""
    d = os.path.abspath(start)
    while d != "/":
        if os.path.isdir(os.path.join(d, ".obsidian")):
            return d
        d = os.path.dirname(d)
    return None


def vault_root(start: str | None = None) -> str | None:
    """Best-effort vault root: walk up from `start`, else $PKM, else default.

    $PKM is exported in the user's .zshrc and is the convention the vault
    tooling (pkm-daily, sn, today-note) already relies on.
    """
    if start:
        found = find_vault(start)
        if found:
            return found
    env = os.environ.get("PKM")
    if env and os.path.isdir(os.path.join(env, ".obsidian")):
        return env
    if os.path.isdir(os.path.join(DEFAULT_VAULT, ".obsidian")):
        return DEFAULT_VAULT
    return None


# --------------------------------------------------------------------------
# Frontmatter
# --------------------------------------------------------------------------

def split_frontmatter(text: str) -> tuple[str | None, str]:
    """Return (frontmatter_without_fences, body). Frontmatter is None if absent."""
    if not text.startswith("---\n"):
        return None, text
    end = text.find("\n---\n", 3)
    if end == -1:
        return None, text
    return text[4:end + 1], text[end + 5:]


def parse_keys(fm: str) -> list[str]:
    """Ordered top-level keys of a frontmatter block."""
    return [m.group(1) for m in re.finditer(r"^([A-Za-z][\w-]*):", fm, re.M)]


def fm_value(fm: str, key: str) -> str | None:
    """Scalar value of a top-level frontmatter key, or None if absent.

    Returns '' for a present-but-empty key, which this vault uses deliberately
    (`reviewed:` and `next-review:` are left blank, never null or "").
    """
    m = re.search(rf"^{re.escape(key)}:[ \t]*(.*)$", fm, re.M)
    return m.group(1).strip() if m else None


def fm_list(fm: str, key: str) -> list[str]:
    """Values of a block-list frontmatter key, e.g. tags."""
    m = re.search(rf"^{re.escape(key)}:[ \t]*$\n((?:[ \t]+-[ \t].*\n?)*)", fm, re.M)
    if not m:
        return []
    return [re.sub(r"^[ \t]+-[ \t]*", "", ln).strip()
            for ln in m.group(1).splitlines() if ln.strip()]


# --------------------------------------------------------------------------
# Notes and links
# --------------------------------------------------------------------------

WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")


def note_titles(vault: str) -> set[str]:
    """Every note basename in the vault, for wikilink resolution."""
    titles: set[str] = set()
    for _, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        titles.update(f[:-3] for f in files if f.endswith(".md"))
    return titles


def note_paths(vault: str) -> dict[str, str]:
    """Map note basename -> full path. Later duplicates win, as Obsidian does."""
    out: dict[str, str] = {}
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for f in files:
            if f.endswith(".md"):
                out[f[:-3]] = os.path.join(root, f)
    return out


def wikilinks(body: str) -> list[str]:
    """Raw wikilink targets as written, including any |alias and #heading."""
    return WIKILINK_RE.findall(body)


def link_target(link: str) -> str:
    """Strip alias and heading/block anchor from a wikilink to its note name."""
    return link.split("|")[0].split("#")[0].split("^")[0].strip()


def broken_links(body: str, titles: set[str]) -> list[str]:
    """Wikilink targets in `body` that resolve to no note. Order-preserving."""
    seen, out = set(), []
    for link in wikilinks(body):
        target = link_target(link)
        if target and target not in titles and target not in seen:
            seen.add(target)
            out.append(target)
    return out


# --------------------------------------------------------------------------
# Filenames
# --------------------------------------------------------------------------

UNSAFE_CHARS = ':/\\|#^[]'


def sanitize_filename(title: str) -> str:
    """Strip characters Obsidian cannot use in a filename, collapse whitespace.

    The readable title stays in the note's H1; this only governs the file.
    """
    cleaned = "".join(c for c in title if c not in UNSAFE_CHARS)
    return re.sub(r"\s+", " ", cleaned).strip()


def unsafe_chars(stem: str) -> list[str]:
    return [c for c in UNSAFE_CHARS if c in stem]


# --------------------------------------------------------------------------
# Findings — the reporting shape both validators use
# --------------------------------------------------------------------------

class Findings:
    """Collect ERROR/WARN findings and render the standard report.

    Mirrors the existing validators: errors are fatal (exit 1), warnings are
    advisory (exit 0).
    """

    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def err(self, msg: str) -> None:
        self.errors.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)

    def report(self, label: str) -> int:
        for w in self.warnings:
            print(f"WARN  {w}")
        for e in self.errors:
            print(f"ERROR {e}")
        if not self.errors and not self.warnings:
            print(f"OK    {label} — all checks passed")
        elif not self.errors:
            print(f"OK    {label} — {len(self.warnings)} warning(s), no errors")
        return 1 if self.errors else 0
