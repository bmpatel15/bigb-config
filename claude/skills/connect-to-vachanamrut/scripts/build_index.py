#!/usr/bin/env python3
"""Build the Vachanamrut discourse index from anirdesh.com.

One-shot corpus builder. The artifact it produces —
`references/vachanamrut-index.tsv` — is committed, so you only re-run this to
refresh it. Bibliographic metadata only (ref, title, URL): this deliberately
does NOT mirror the discourse text, which is a copyrighted BAPS translation.
Full text is fetched one discourse at a time, on demand, by fetch_discourse.py.

    python3 build_index.py [--out PATH] [--check]

--check re-runs the structural assertions against an existing index without
touching the network.

Stdlib only.
"""

from __future__ import annotations

import argparse
import html
import re
import sys
import urllib.request
from pathlib import Path

TOC_URL = "https://anirdesh.com/vachanamrut/index.php?format=en"
DISCOURSE_URL = "https://anirdesh.com/vachanamrut/index.php?format=en&vachno={n}"
UA = "Mozilla/5.0 (X11; Linux x86_64) connect-to-vachanamrut/1.0"

# Section sizes, read off the live table of contents headings ("Gadhada I (78)").
# Order matters: it is the document order the anchors appear in.
SECTIONS = [
    ("Gadhada I", 78),
    ("Sarangpur", 18),
    ("Kariyani", 12),
    ("Loya", 18),
    ("Panchala", 7),
    ("Gadhada II", 67),
    ("Vartal", 20),
    ("Amdavad", 3),
    ("Gadhada III", 39),
    ("Additional", 11),
]

# The canonical 273 excludes Bhugol-Khagol, an unnumbered Gadhada III appendix
# that nonetheless has its own vachno. We keep it, flagged, because a thought
# about cosmology should still be able to reach it.
CANONICAL_TOTAL = 273

ANCHOR_RE = re.compile(
    r'<a\s[^>]*vachno=(\d+)[^>]*>(.*?)</a>', re.S | re.I)
HEADING_RE = re.compile(
    r'(Gadhada I{1,3}|Sarangpur|Kariyani|Loya|Panchala|Vartal|Amdavad|Additional)'
    r'\s*\((\d+)\)')
# "12. Some Title"  ->  ("12", "Some Title")
NUMBERED_RE = re.compile(r'^(\d+)\.\s*(.+)$', re.S)
# "3. Jetalpur-1: Means to ..."  ->  ("Jetalpur-1", "Means to ...")
SELFREF_RE = re.compile(r'^(?:\d+\.\s*)?([A-Za-zĀ-ſ]+(?:-\d+)?)\s*:\s*(.+)$', re.S)


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=45) as r:
        return r.read().decode("utf-8", errors="replace")


def clean(fragment: str) -> str:
    """Strip tags/entities and normalise whitespace and quote characters."""
    text = html.unescape(re.sub(r"<[^>]+>", " ", fragment))
    text = text.replace("’", "'").replace("‘", "'")
    text = text.replace("“", '"').replace("”", '"')
    return re.sub(r"\s+", " ", text).strip()


def parse_toc(page: str) -> list[dict]:
    """Walk headings and anchors in document order, assigning refs."""
    tokens = []
    for m in HEADING_RE.finditer(page):
        tokens.append(("heading", m.start(), m.group(1), int(m.group(2))))
    for m in ANCHOR_RE.finditer(page):
        tokens.append(("anchor", m.start(), int(m.group(1)), clean(m.group(2))))
    tokens.sort(key=lambda t: t[1])

    rows: list[dict] = []
    section = None
    seen_vachno: set[int] = set()

    for kind, _pos, a, b in tokens:
        if kind == "heading":
            section = a
            continue
        if section is None:
            continue
        vachno, label = a, b

        # Trailing cross-reference links ("Vachanāmrut Loyā-7.2") repeat a
        # vachno already claimed. They are footnotes, not discourses.
        if vachno in seen_vachno:
            continue

        if section == "Additional":
            # These carry their own real refs: "Amdavad-4:", "Ashlali:",
            # "Jetalpur-1:". Sequential numbering would be wrong.
            m = SELFREF_RE.match(label)
            if not m:
                print(f"warn: unparsed Additional entry v={vachno}: {label!r}",
                      file=sys.stderr)
                continue
            ref, title = m.group(1), m.group(2)
            ref = ref.replace("Amdavad", "Amdavad")  # already vault spelling
            note = "additional"
        else:
            m = NUMBERED_RE.match(label)
            if m:
                ref = f"{section}-{m.group(1)}"
                title = m.group(2)
                note = ""
            else:
                # Unnumbered appendix, e.g. Gadhada III "Bhugol-Khagol".
                ref = f"{section} {label}"
                title = label
                note = "appendix"

        seen_vachno.add(vachno)
        rows.append({
            "ref": ref.strip(),
            "vachno": vachno,
            "title": title.strip(),
            "url": DISCOURSE_URL.format(n=vachno),
            "note": note,
        })
    return rows


def validate(rows: list[dict]) -> list[str]:
    """Structural assertions. Returns a list of failures (empty == good)."""
    errs = []
    counted = [r for r in rows if r["note"] != "appendix"]
    if len(counted) != CANONICAL_TOTAL:
        errs.append(f"expected {CANONICAL_TOTAL} canonical discourses, "
                    f"got {len(counted)}")

    refs = [r["ref"] for r in rows]
    dupes = {r for r in refs if refs.count(r) > 1}
    if dupes:
        errs.append(f"duplicate refs: {sorted(dupes)}")

    by_ref = {r["ref"]: r for r in rows}
    # Section boundaries: first and last of each numbered prakaran.
    expected_bounds = {
        "Gadhada I-1": 1, "Gadhada I-78": 78,
        "Sarangpur-1": 79, "Sarangpur-18": 96,
        "Kariyani-1": 97, "Kariyani-12": 108,
        "Loya-1": 109, "Loya-18": 126,
        "Panchala-1": 127, "Panchala-7": 133,
        "Gadhada II-1": 134, "Gadhada II-67": 200,
        "Vartal-1": 201, "Vartal-20": 220,
        "Amdavad-1": 221, "Amdavad-3": 223,
        "Gadhada III-1": 224, "Gadhada III-39": 262,
    }
    for ref, vachno in expected_bounds.items():
        row = by_ref.get(ref)
        if row is None:
            errs.append(f"missing expected ref {ref!r}")
        elif row["vachno"] != vachno:
            errs.append(f"{ref} has vachno {row['vachno']}, expected {vachno}")

    for r in rows:
        if not r["title"]:
            errs.append(f"{r['ref']} has an empty title")
        if "\t" in r["ref"] or "\t" in r["title"]:
            errs.append(f"{r['ref']} contains a tab")
    return errs


def spot_check(rows: list[dict], refs: list[str]) -> list[str]:
    """Fetch individual discourse pages and confirm the ref->vachno mapping.

    The live page footer renders 'Vachanamrut || <n> || <vachno> ||'; we settle
    for confirming the title we indexed actually appears on the page we mapped.
    """
    problems = []
    by_ref = {r["ref"]: r for r in rows}
    for ref in refs:
        row = by_ref.get(ref)
        if row is None:
            problems.append(f"{ref}: not in index")
            continue
        try:
            page = clean(fetch(row["url"]))
        except Exception as exc:  # noqa: BLE001 - report, don't crash the build
            problems.append(f"{ref}: fetch failed ({exc})")
            continue
        needle = row["title"].split(";")[0].strip()
        if needle.lower() not in page.lower():
            problems.append(
                f"{ref} (v={row['vachno']}): title {needle!r} not found on page")
        else:
            print(f"  ok  {ref:16} v={row['vachno']:<4} {row['title'][:52]}")
    return problems


def write_tsv(rows: list[dict], out: Path) -> None:
    lines = ["ref\tvachno\ttitle\turl\tnote"]
    lines += [f"{r['ref']}\t{r['vachno']}\t{r['title']}\t{r['url']}\t{r['note']}"
              for r in rows]
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def read_tsv(path: Path) -> list[dict]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines()[1:]:
        if not line.strip():
            continue
        parts = line.split("\t")
        parts += [""] * (5 - len(parts))
        ref, vachno, title, url, note = parts[:5]
        rows.append({"ref": ref, "vachno": int(vachno), "title": title,
                     "url": url, "note": note})
    return rows


def main() -> int:
    default_out = Path(__file__).resolve().parent.parent / "references" / "vachanamrut-index.tsv"
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, default=default_out)
    ap.add_argument("--check", action="store_true",
                    help="validate an existing index; no network")
    ap.add_argument("--no-spot-check", action="store_true")
    args = ap.parse_args()

    if args.check:
        if not args.out.exists():
            print(f"ERROR: {args.out} does not exist", file=sys.stderr)
            return 1
        rows = read_tsv(args.out)
        errs = validate(rows)
        print(f"{len(rows)} rows in {args.out}")
        for e in errs:
            print(f"ERROR: {e}", file=sys.stderr)
        print("index OK" if not errs else f"{len(errs)} problem(s)")
        return 1 if errs else 0

    print(f"fetching {TOC_URL}")
    rows = parse_toc(fetch(TOC_URL))
    print(f"parsed {len(rows)} entries")

    errs = validate(rows)
    if errs:
        for e in errs:
            print(f"ERROR: {e}", file=sys.stderr)
        print("refusing to write a malformed index", file=sys.stderr)
        return 1

    if not args.no_spot_check:
        print("spot-checking ref->vachno mapping against live pages:")
        problems = spot_check(rows, ["Gadhada I-78", "Gadhada II-1",
                                     "Vartal-20", "Jetalpur-1"])
        if problems:
            for p in problems:
                print(f"ERROR: {p}", file=sys.stderr)
            return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    write_tsv(rows, args.out)
    counted = sum(1 for r in rows if r["note"] != "appendix")
    print(f"wrote {args.out} — {len(rows)} rows ({counted} canonical)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
