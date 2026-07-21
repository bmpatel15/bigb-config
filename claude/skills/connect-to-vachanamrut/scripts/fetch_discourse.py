#!/usr/bin/env python3
"""Fetch one Vachanamrut discourse for verification, and cache it.

    python3 fetch_discourse.py "Gadhada I-15"
    python3 fetch_discourse.py "Loya-14" --grep "preference"
    python3 fetch_discourse.py "Gadhada II-53" --quiet   # cache only

Fetches ONE discourse at a time, on demand. This is deliberate: the English
Vachanamrut is a copyrighted BAPS translation, so this skill does not mirror
the granth. It pulls the single discourse needed to check a specific claim,
caches it outside the vault (so it never enters the graph, Bases, or Obsidian
Sync), and leaves it at that.

Use it to answer one question: does this discourse actually teach what I am
about to say it teaches? If the fetch fails, the honest outcome is a
`suggested` reference, not a confident one.

Cache: $XDG_CACHE_HOME/vachanamrut/ (default ~/.cache/vachanamrut/)
Source: anirdesh.com, which hosts the BAPS English translation.

Stdlib only.
"""

from __future__ import annotations

import argparse
import html
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from vach_lookup import load_index, normalize_ref  # noqa: E402

CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "vachanamrut"
UA = "Mozilla/5.0 (X11; Linux x86_64) connect-to-vachanamrut/1.0"
TRUSTED_HOSTS = {"anirdesh.com", "www.anirdesh.com", "baps.org", "www.baps.org"}


def strip_html(page: str) -> str:
    page = re.sub(r"(?is)<(script|style|head|nav|footer)[^>]*>.*?</\1>", " ", page)
    page = re.sub(r"(?i)<br\s*/?>", "\n", page)
    page = re.sub(r"(?i)</(p|div|h[1-6]|li|tr)>", "\n", page)
    text = html.unescape(re.sub(r"<[^>]+>", " ", page))
    text = text.replace("’", "'").replace("‘", "'")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n\s*\n\s*\n+", "\n\n", text)
    return "\n".join(ln.strip() for ln in text.splitlines()).strip()


def extract_discourse(text: str) -> str:
    """Trim site chrome around the discourse body.

    Best-effort: the goal is a readable block to check a claim against, not a
    faithful reproduction. Anything ambiguous is left in rather than cut.
    """
    start = 0
    m = re.search(r"(?m)^\s*(On|In)\s+(Mahā|Māgshar|Kārtik|Posh|Fāgun|Chaitra|"
                  r"Vaishākh|Jyeshth|Ashādh|Shrāvan|Bhādarvā|Āso|Vaishakh|Magshar)",
                  text)
    if m:
        start = m.start()
    body = text[start:]
    for marker in ("Previous Vachanamrut", "Next Vachanamrut", "Copyright",
                   "Anirdesh", "Back to"):
        idx = body.find(marker)
        if idx > 400:
            body = body[:idx]
    return body.strip()


def fetch(ref: str, refresh: bool = False) -> tuple[str, str, dict]:
    canonical = normalize_ref(ref) or ref
    rows = {r["ref"]: r for r in load_index()}
    row = rows.get(canonical)
    if row is None:
        raise SystemExit(f"ERROR: {canonical!r} is not in the index. "
                         f"Try: python3 vach_lookup.py --normalize {ref!r}")

    host = re.sub(r"^https?://([^/]+)/.*$", r"\1", row["url"])
    if host not in TRUSTED_HOSTS:
        raise SystemExit(f"ERROR: refusing to fetch from untrusted host {host!r}")

    CACHE.mkdir(parents=True, exist_ok=True)
    cached = CACHE / f"{canonical.replace(' ', '_').replace('/', '-')}.txt"
    if cached.exists() and not refresh:
        return canonical, cached.read_text(encoding="utf-8"), row

    req = urllib.request.Request(row["url"], headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=45) as r:
            page = r.read().decode("utf-8", errors="replace")
    except (urllib.error.URLError, OSError) as exc:
        raise SystemExit(
            f"ERROR: could not fetch {canonical} ({exc}).\n"
            "No network here (Claudian runs inside Obsidian, which has none). "
            "Report the reference as 'suggested', not verified.") from exc

    body = extract_discourse(strip_html(page))
    cached.write_text(body, encoding="utf-8")
    return canonical, body, row


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ref")
    ap.add_argument("--grep", help="show only lines matching this term (case-insensitive)")
    ap.add_argument("--context", type=int, default=1, help="lines of context for --grep")
    ap.add_argument("--refresh", action="store_true")
    ap.add_argument("--quiet", action="store_true", help="cache only; print the path")
    ap.add_argument("--max-chars", type=int, default=6000)
    args = ap.parse_args()

    canonical, body, row = fetch(args.ref, refresh=args.refresh)
    cached = CACHE / f"{canonical.replace(' ', '_').replace('/', '-')}.txt"

    print(f"# {canonical} — {row['title']}")
    print(f"# source: {row['url']}")
    print(f"# cached: {cached}")
    print(f"# {len(body)} chars. This is a copyrighted BAPS translation held "
          f"locally for verification only.")
    print()

    if args.quiet:
        return 0

    if args.grep:
        lines = body.splitlines()
        pat = re.compile(re.escape(args.grep), re.I)
        hits = [i for i, ln in enumerate(lines) if pat.search(ln)]
        if not hits:
            # A failed grep is NOT proof of absence. Index titles are editorial
            # labels, not phrases lifted from the text: Gadhada I-55 is titled
            # "Resoluteness in Worship…" while the discourse itself says
            # "resolve". Rejecting a candidate on one failed word form is a
            # false negative waiting to happen.
            stem = args.grep[:5].lower()
            print(f"(no line contains {args.grep!r} verbatim.\n"
                  f" This is NOT evidence the discourse lacks the theme — the "
                  f"index titles are editorial\n labels, not quotations, so the "
                  f"text often uses a different word form.\n"
                  f" Try a shorter stem (--grep {stem!r}), a synonym, or read "
                  f"the discourse in full\n before concluding anything.)")
            return 0
        shown: set[int] = set()
        for i in hits:
            for j in range(max(0, i - args.context),
                           min(len(lines), i + args.context + 1)):
                if j not in shown:
                    shown.add(j)
                    print(f"{j + 1:5}| {lines[j]}")
            print("   ...")
        return 0

    out = body[:args.max_chars]
    print(out)
    if len(body) > args.max_chars:
        print(f"\n[truncated at {args.max_chars} chars — "
              f"use --grep to search the rest]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
