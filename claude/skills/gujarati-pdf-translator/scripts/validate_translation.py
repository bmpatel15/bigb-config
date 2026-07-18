#!/usr/bin/env python3
"""Structural and terminology lint for Gujarati-to-English translation Markdown.

WHAT THIS SCRIPT CAN AND CANNOT DO
----------------------------------
This validator detects *structural and terminology risks* in a finished translation
file: page-marker problems, unresolved uncertainty labels, duplicated paragraphs,
leftover placeholders, suspicious English substitutions for protected satsang terms,
and inconsistent spelling/capitalization of key terms.

It CANNOT establish translation accuracy. It does not read Gujarati, does not compare
against the source PDF, and cannot detect omissions, mistranslations, or dropped
negations. The real quality gate is the Stage 10 paragraph-by-paragraph comparison
against the source (see references/quality-assurance.md and
templates/translation-audit.md).

USAGE
-----
    python3 validate_translation.py TRANSLATION.md
    python3 validate_translation.py --strict TRANSLATION.md   # warnings also fail

EXIT CODES
----------
    0  clean (or warnings only, without --strict)
    1  errors found (or warnings found with --strict)
    2  usage error / unreadable file

EXTENDING
---------
Add a function that accepts (text, lines) and returns a list of Finding objects,
then append it to the CHECKS registry at the bottom of this file. Term lists are
plain module-level constants — extend them freely.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

ERROR = "ERROR"
WARNING = "WARNING"

# ---------------------------------------------------------------------------
# Terminology configuration — extend these freely.
# ---------------------------------------------------------------------------

# Protected transliterated terms expected to appear untranslated in satsang texts.
PROTECTED_TERMS = {
    "agna",
    "paksh",
    "nishchay",
    "nishtha",
    "upasana",
    "mahima",
    "satsang",
    "seva",
    "bhakti",
    "darshan",
    "murti",
    "swarup",
    "samagam",
    "suhradbhav",
    "atmabuddhi",
    "divyabhav",
    "manushyabhav",
    "gunatit",
    "pragat",
    "prapti",
    "khap",
    "ruchi",
    "vrutti",
    "chintavan",
    "manan",
    "nididhyas",
    "priti",
    "dasbhav",
    "pativratapanu",
}

# English words that often signal a protected term was translated away.
# Maps the suspicious English word/phrase -> the protected term it may have replaced.
# These are flagged FOR REVIEW (warning) only when the protected term also appears in
# the document (mixed treatment) — a normal English use of "work" or "side" in a
# document that never deals with seva/paksh is not flagged.
SUSPICIOUS_SUBSTITUTIONS = {
    "order": "agna",
    "orders": "agna",
    "side": "paksh",
    "certainty": "nishchay",
    "loyalty": "nishtha",
    "worship": "upasana",
    "greatness": "mahima",
    "good company": "satsang",
    "seeing": "darshan",
    "work": "seva",
    "form": "swarup",
    "slavery": "dasbhav",
    "statue": "murti",
    "statues": "murti",
}

# Renderings that are essentially always wrong in satsang translation output.
# Reported even if the protected term is absent; escalated to ERROR when the
# protected term is present (clear mixed treatment).
ALWAYS_SUSPICIOUS = {
    "idol": "murti",
    "idols": "murti",
}

# Terms that must always be capitalized (checked as standalone words).
CAPITALIZED_TERMS = {"Akshar", "Aksharbrahman", "Parabrahman", "Purushottam", "Akshardham"}

# Non-canonical spelling variants of protected terms (all lowercase).
ALT_SPELLINGS = {
    "agna": {"aagna", "agya", "ajna", "aajna"},
    "nishtha": {"nishthaa", "nishta", "nistha"},
    "nishchay": {"nischay", "nishchaya"},
    "upasana": {"upasna", "upaasana"},
    "murti": {"moorti", "murthi", "moorthi"},
    "swarup": {"swaroop", "svarup", "swarupa"},
    "seva": {"sewa"},
    "darshan": {"darshana", "darshun"},
    "satsang": {"satsanga", "sathsang"},
    "gnan": {"jnana", "gyan", "gnana"},
}

# Uncertainty labels from the skill's Stage 2 — legitimate, but each one left in the
# final file means a human still needs to resolve or accept it.
UNCERTAINTY_LABELS = [
    "[Illegible Gujarati text]",
    "[Probable reading:",
    "[Gujarati source unclear]",
    "[Name uncertain",
    "[OCR requires manual verification]",
    "[Page appears incomplete]",
]

# Leftover work markers that must never ship in a finished translation.
PLACEHOLDER_PATTERNS = [
    r"\bTODO\b",
    r"\bFIXME\b",
    r"\bXXX\b",
    r"\[translation pending\]",
    r"\[TRANSLATE\]",
    r"lorem ipsum",
]

PAGE_MARKER_RE = re.compile(r"\[Source page (\d+)\]")


@dataclass
class Finding:
    severity: str  # ERROR or WARNING
    line: int      # 1-based; 0 for document-level findings
    code: str
    message: str


def _word_re(word: str) -> re.Pattern:
    """Case-insensitive whole-word (or whole-phrase) pattern."""
    return re.compile(r"\b" + re.escape(word) + r"\b", re.IGNORECASE)


# ---------------------------------------------------------------------------
# Checks. Each takes (text, lines) and returns a list of Findings.
# ---------------------------------------------------------------------------

def check_page_markers(text: str, lines: list[str]) -> list[Finding]:
    """Page markers: present, unique, in order, on their own line."""
    findings: list[Finding] = []
    seen: dict[int, int] = {}  # page number -> first line
    prev_page = None

    markers = [
        (i, int(m.group(1)), line)
        for i, line in enumerate(lines, start=1)
        for m in PAGE_MARKER_RE.finditer(line)
    ]

    if not markers:
        findings.append(Finding(
            WARNING, 0, "PAGE-NONE",
            "no [Source page N] markers found — expected unless the user asked for "
            "output without page markers"))
        return findings

    for lineno, page, line in markers:
        if line.strip() != f"[Source page {page}]":
            findings.append(Finding(
                WARNING, lineno, "PAGE-INLINE",
                f"[Source page {page}] is not on its own line — markers belong at a "
                "paragraph boundary, never mid-sentence"))
        if page in seen:
            findings.append(Finding(
                ERROR, lineno, "PAGE-DUP",
                f"duplicate marker [Source page {page}] (first at line {seen[page]}) "
                "— possible duplicated passage or copy/paste error"))
        else:
            seen[page] = lineno
        if prev_page is not None and page < prev_page:
            findings.append(Finding(
                ERROR, lineno, "PAGE-ORDER",
                f"[Source page {page}] appears after [Source page {prev_page}] — "
                "page-order error"))
        elif prev_page is not None and page > prev_page + 1:
            findings.append(Finding(
                WARNING, lineno, "PAGE-GAP",
                f"gap in page markers: {prev_page} -> {page} — verify pages "
                f"{prev_page + 1}–{page - 1} were not skipped"))
        prev_page = page
    return findings


def check_uncertainty_labels(text: str, lines: list[str]) -> list[Finding]:
    """Unresolved uncertainty labels — legitimate, but flagged for human review."""
    findings = []
    for i, line in enumerate(lines, start=1):
        for label in UNCERTAINTY_LABELS:
            if label in line:
                findings.append(Finding(
                    WARNING, i, "UNCERTAIN",
                    f"unresolved uncertainty label {label!r} — resolve against the "
                    "source or confirm it should remain"))
    return findings


def check_empty_sections(text: str, lines: list[str]) -> list[Finding]:
    """A heading followed by nothing (next heading or EOF) is an empty section."""
    findings = []
    heading_re = re.compile(r"^#{1,6}\s")
    heading_lines = [i for i, line in enumerate(lines, start=1)
                     if heading_re.match(line)]
    for idx, hline in enumerate(heading_lines):
        end = heading_lines[idx + 1] - 1 if idx + 1 < len(heading_lines) else len(lines)
        body = [l for l in lines[hline:end] if l.strip()]
        if not body:
            findings.append(Finding(
                WARNING, hline, "SECTION-EMPTY",
                f"section {lines[hline - 1].strip()!r} has no content — accidental "
                "empty section?"))
    return findings


def _paragraphs(lines: list[str]):
    """Yield (start_line, paragraph_text) for blank-line-separated paragraphs."""
    start = 0
    buf: list[str] = []
    for i, line in enumerate(lines, start=1):
        if line.strip():
            if not buf:
                start = i
            buf.append(line.strip())
        elif buf:
            yield start, " ".join(buf)
            buf = []
    if buf:
        yield start, " ".join(buf)


def check_repeated_paragraphs(text: str, lines: list[str]) -> list[Finding]:
    """Identical substantial paragraphs — suspicious unless a refrain (kirtan)."""
    findings = []
    seen: dict[str, int] = {}
    for start, para in _paragraphs(lines):
        norm = re.sub(r"[^\w\s]", "", para.lower())
        norm = re.sub(r"\s+", " ", norm).strip()
        if len(norm.split()) < 12:  # short lines/refrain fragments are too noisy
            continue
        if norm in seen:
            findings.append(Finding(
                WARNING, start, "PARA-DUP",
                f"paragraph repeats line {seen[norm]} verbatim — duplicated passage, "
                "or a legitimate refrain (verify against the source)"))
        else:
            seen[norm] = start
    return findings


def check_placeholders(text: str, lines: list[str]) -> list[Finding]:
    """Untranslated placeholders and leftover work markers."""
    findings = []
    patterns = [re.compile(p, re.IGNORECASE) for p in PLACEHOLDER_PATTERNS]
    for i, line in enumerate(lines, start=1):
        for pat in patterns:
            if pat.search(line):
                findings.append(Finding(
                    ERROR, i, "PLACEHOLDER",
                    f"leftover placeholder matches {pat.pattern!r} — unfinished "
                    "translation must not ship"))
        if line.strip() in {"...", "…"}:
            findings.append(Finding(
                ERROR, i, "PLACEHOLDER",
                "paragraph consists only of an ellipsis — untranslated content?"))
    return findings


def check_suspicious_substitutions(text: str, lines: list[str]) -> list[Finding]:
    """English glosses that may have replaced a protected term.

    Not every appearance of these English words is wrong. A word is flagged for
    review only when the corresponding protected term also appears in the document
    (mixed treatment suggests inconsistency), except for ALWAYS_SUSPICIOUS renderings
    ("idol"), which are flagged regardless.
    """
    findings = []
    lower_text = text.lower()
    present = {t for t in PROTECTED_TERMS if _word_re(t).search(lower_text)}

    def scan(word: str, term: str, always: bool):
        pat = _word_re(word)
        for i, line in enumerate(lines, start=1):
            for m in pat.finditer(line):
                # Common idiom that has nothing to do with agna.
                if word.startswith("order"):
                    ctx = line[max(0, m.start() - 3):m.end() + 3].lower()
                    if "in order to" in ctx:
                        continue
                if always:
                    sev = ERROR if term in present else WARNING
                    findings.append(Finding(
                        sev, i, "TERM-PROHIBITED",
                        f"{m.group(0)!r} — prohibited rendering of protected term "
                        f"'{term}' (see references/glossary.md)"))
                elif term in present:
                    findings.append(Finding(
                        WARNING, i, "TERM-SUBST",
                        f"{m.group(0)!r} may be a translation of protected term "
                        f"'{term}', which also appears in this document — review "
                        "for consistent treatment"))

    for word, term in ALWAYS_SUSPICIOUS.items():
        scan(word, term, always=True)
    for word, term in SUSPICIOUS_SUBSTITUTIONS.items():
        scan(word, term, always=False)
    return findings


def check_capitalization(text: str, lines: list[str]) -> list[Finding]:
    """Aksharbrahman, Parabrahman, Purushottam (etc.) must always be capitalized."""
    findings = []
    for term in CAPITALIZED_TERMS:
        pat = _word_re(term)
        for i, line in enumerate(lines, start=1):
            for m in pat.finditer(line):
                if m.group(0) != term:
                    findings.append(Finding(
                        WARNING, i, "TERM-CAPS",
                        f"{m.group(0)!r} should be written {term!r} — divine names "
                        "and metaphysical entities are always capitalized"))
    return findings


def check_spelling_variants(text: str, lines: list[str]) -> list[Finding]:
    """Non-canonical spellings of protected terms (nishthaa, moorti, swaroop …)."""
    findings = []
    for canonical, variants in ALT_SPELLINGS.items():
        for variant in variants:
            pat = _word_re(variant)
            for i, line in enumerate(lines, start=1):
                if pat.search(line):
                    findings.append(Finding(
                        WARNING, i, "TERM-SPELLING",
                        f"non-canonical spelling {variant!r} — use {canonical!r} "
                        "(see references/transliteration-guide.md)"))
    return findings


# Registry: add new checks here.
CHECKS = [
    check_page_markers,
    check_uncertainty_labels,
    check_empty_sections,
    check_repeated_paragraphs,
    check_placeholders,
    check_suspicious_substitutions,
    check_capitalization,
    check_spelling_variants,
]


def validate(path: Path) -> list[Finding]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    findings: list[Finding] = []
    for check in CHECKS:
        findings.extend(check(text, lines))
    findings.sort(key=lambda f: (f.line, f.severity != ERROR, f.code))
    return findings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=("Lint a Gujarati->English translation Markdown file for "
                     "structural and terminology risks. This does NOT verify "
                     "translation accuracy — only a paragraph-by-paragraph "
                     "comparison against the Gujarati source can do that."))
    parser.add_argument("file", type=Path, help="Markdown translation file to check")
    parser.add_argument("--strict", action="store_true",
                        help="treat warnings as failures (exit 1)")
    args = parser.parse_args(argv)

    if not args.file.is_file():
        print(f"error: cannot read file: {args.file}", file=sys.stderr)
        return 2

    findings = validate(args.file)
    counts = defaultdict(int)
    for f in findings:
        counts[f.severity] += 1
        loc = f"{args.file}:{f.line}" if f.line else f"{args.file}:-"
        print(f"{loc}: {f.severity} [{f.code}] {f.message}")

    errors, warnings = counts[ERROR], counts[WARNING]
    print(f"\n{errors} error(s), {warnings} warning(s) in {args.file}")
    print("note: this lint detects structural/terminology risks only; it cannot "
          "establish translation accuracy.")

    if errors or (args.strict and warnings):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
