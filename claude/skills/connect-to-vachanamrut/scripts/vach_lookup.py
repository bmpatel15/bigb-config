#!/usr/bin/env python3
"""Normalise Vachanamrut references and search the discourse index.

    python3 vach_lookup.py --normalize "G-I-1"          -> Gadhada I-1
    python3 vach_lookup.py --ref "Loya-14"              -> the index row
    python3 vach_lookup.py --search "personal preference discouraged"
    python3 vach_lookup.py --variants "Gadhada I-1"     -> search spellings
    python3 vach_lookup.py --stats

The search is a keyword scorer over 274 discourse *titles*, not full text. It
narrows the field; it never establishes that a discourse teaches something.
Treat every hit as a candidate to verify, never as a finding.

Stdlib only.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path

INDEX = Path(__file__).resolve().parent.parent / "references" / "vachanamrut-index.tsv"

# Canonical vault spellings. The vault's one real note is
# "Vachanamrut Gadhada I-1.md" and `sn v "Gadhada I-21"` builds the same shape,
# so hyphenated Title Case is canonical.
PRAKARANS = ["Gadhada I", "Sarangpur", "Kariyani", "Loya", "Panchala",
             "Gadhada II", "Vartal", "Amdavad", "Gadhada III",
             "Ashlali", "Jetalpur"]

# Every spelling seen in the wild maps to a canonical prakaran. Keys are
# lowercased and stripped of punctuation before lookup.
ALIASES = {
    # Gadhada I
    "gadhada i": "Gadhada I", "gadhda i": "Gadhada I", "gadhadai": "Gadhada I",
    "gadhada pratham": "Gadhada I", "gadhada first": "Gadhada I",
    "gadhada 1": "Gadhada I", "pratham": "Gadhada I", "gi": "Gadhada I",
    "g i": "Gadhada I", "gad i": "Gadhada I", "gadh i": "Gadhada I",
    # Gadhada II
    "gadhada ii": "Gadhada II", "gadhda ii": "Gadhada II",
    "gadhada madhya": "Gadhada II", "gadhada second": "Gadhada II",
    "gadhada middle": "Gadhada II", "gadhada 2": "Gadhada II",
    "madhya": "Gadhada II", "gii": "Gadhada II", "g ii": "Gadhada II",
    "gad ii": "Gadhada II", "gadh ii": "Gadhada II",
    # Gadhada III
    "gadhada iii": "Gadhada III", "gadhda iii": "Gadhada III",
    "gadhada antya": "Gadhada III", "gadhada third": "Gadhada III",
    "gadhada last": "Gadhada III", "gadhada 3": "Gadhada III",
    "antya": "Gadhada III", "giii": "Gadhada III", "g iii": "Gadhada III",
    "gad iii": "Gadhada III", "gadh iii": "Gadhada III",
    # Others
    "sarangpur": "Sarangpur", "sarangpour": "Sarangpur", "s": "Sarangpur",
    "kariyani": "Kariyani", "karyani": "Kariyani", "k": "Kariyani",
    "loya": "Loya", "loyaa": "Loya", "l": "Loya",
    "panchala": "Panchala", "panchal": "Panchala", "p": "Panchala",
    "vartal": "Vartal", "vadtal": "Vartal", "v": "Vartal",
    "amdavad": "Amdavad", "ahmedabad": "Amdavad", "amdavaad": "Amdavad",
    "a": "Amdavad",
    "ashlali": "Ashlali", "jetalpur": "Jetalpur",
}

# Aggressive on purpose. A title match on "cannot" or "become" is noise, and
# noise at the top of the candidate list is precisely the weak-connection
# failure this skill exists to avoid. Better to return nothing than to rank a
# discourse highly because it shares a function word with the thought.
STOPWORDS = {
    "the", "a", "an", "of", "and", "or", "to", "in", "on", "is", "it", "that",
    "this", "for", "with", "as", "by", "at", "from", "be", "are", "was", "not",
    "one", "ones", "who", "what", "when", "which", "his", "her", "their", "its",
    "i", "my", "me", "you", "your", "we", "us", "he", "she", "they", "them",
    "but", "if", "than", "then", "so", "can", "will", "do", "does", "how",
    "cannot", "cant", "become", "becomes", "becoming", "became", "according",
    "should", "must", "have", "has", "had", "having", "about", "more", "most",
    "very", "some", "sometimes", "often", "always", "never", "did", "would",
    "could", "there", "here", "only", "just", "also", "been", "being", "am",
    "get", "gets", "got", "make", "makes", "made", "take", "takes", "come",
    "goes", "going", "went", "know", "knows", "think", "thinks", "feel",
    "feels", "seem", "seems", "own", "out", "up", "down", "over", "under",
    "into", "through", "no", "yes", "any", "all", "both", "each", "other",
    "others", "same", "such", "too", "much", "many", "way", "ways", "thing",
    "things", "person", "people", "day", "days", "time", "times", "like",
    "really", "actually", "quite", "rather", "simply", "merely", "perhaps",
    "maybe", "probably", "certainly", "definitely", "somehow", "anyway",
    "today", "tomorrow", "yesterday", "week", "weekend", "month", "year",
    "need", "needs", "want", "wants", "try", "trying", "keep", "keeps",
    "put", "let", "see", "sees", "say", "says", "said", "tell", "give",
}

# Concept bridges: everyday vocabulary -> the terms discourse titles actually
# use. Without these, "control" never reaches "sarva karta" and "burnout" never
# reaches "laziness". Deliberately conservative — a bridge that fires too often
# produces confident nonsense.
BRIDGES = {
    "control": ["karta", "doer", "god", "maya"],
    "worry": ["faith", "conviction", "hardship", "adverse"],
    "anxiety": ["faith", "conviction", "adverse", "hardship"],
    "plan": ["preference", "desires", "swabhav"],
    "preference": ["preference", "swabhav", "obstinacy"],
    "ego": ["egotism", "conceit", "humility", "swabhav"],
    "pride": ["egotism", "conceit", "humility"],
    "recognition": ["conceit", "egotism", "greatness"],
    "criticism": ["condemnation", "reverence", "flaws"],
    "correction": ["flaws", "swabhav", "obstinacy", "condemnation"],
    "discouraged": ["discouraging", "discouraged", "adverse", "meditation"],
    "consistency": ["resoluteness", "niyams", "persistence", "continuous"],
    "habit": ["swabhav", "prakruti", "vasana", "niyams"],
    "identity": ["atma", "dehbhav", "self"],
    "attachment": ["infatuation", "attachment", "worldly", "vairagya"],
    "desire": ["vasana", "desires", "vishays", "lust"],
    "detachment": ["vairagya", "uninfatuated"],
    "anger": ["anger", "swabhav"],
    "jealousy": ["jealousy", "matsar"],
    "company": ["kusangis", "company", "satsang", "association"],
    "friends": ["company", "kusangis", "satsang"],
    "service": ["seva", "service", "sevak", "servitude"],
    "seva": ["seva", "service", "sevak", "servitude", "dasbhav"],
    "humility": ["humility", "conceit", "servitude"],
    "leader": ["ruling", "eminent", "greatness"],
    "obedience": ["agna", "niyams", "loyal", "dharma"],
    "discipline": ["niyams", "dharma", "resoluteness", "austerities"],
    "effort": ["endeavor", "personal endeavor", "purusharth"],
    "grace": ["greatness", "god", "liberation"],
    "faith": ["faith", "conviction", "nischay"],
    "conviction": ["conviction", "faith", "upasana"],
    "doubt": ["doubts", "faith", "conviction"],
    "hardship": ["hardship", "adverse", "difficulties", "misery"],
    "failure": ["regress", "falling", "difficulties"],
    "peace": ["happy", "bliss", "uninfatuated"],
    "focus": ["meditation", "vrutti", "continuous", "mind"],
    "distraction": ["indriyas", "mind", "vrutti"],
    "mind": ["mind", "antahkaran", "indriyas", "chitt"],
    "death": ["matihi", "gatihi", "death"],
    "greatness": ["greatness", "mahima", "glory"],
    "surrender": ["karta", "god", "servitude"],
}


def norm_token(s: str) -> str:
    """Lowercase, strip accents and punctuation, collapse whitespace."""
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = s.lower().replace("'", "").replace("'", "")
    s = re.sub(r"[^a-z0-9]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def normalize_ref(raw: str) -> str | None:
    """Turn any reasonable spelling of a reference into the vault's form.

    Handles: 'Vachanamrut Gadhada I-1', 'Gadhada I-1', 'Gadhada Pratham 1',
    'G I 1', 'G-I-1', 'Gadhada First 1', 'Vachanamrut GI-1', 'Loya 14',
    'Ashlali', 'Jetalpur-3'. Returns None if nothing matches.
    """
    s = norm_token(raw)
    if not s:
        return None
    # Drop a leading granth word.
    s = re.sub(r"^(vachanamrut|vachanamrutam|vach|vcn)\s*", "", s).strip()

    # Trailing number is the discourse number, if present.
    m = re.match(r"^(.*?)[\s]*(\d+)$", s)
    if m:
        head, num = m.group(1).strip(), int(m.group(2))
    else:
        head, num = s, None

    # Roman numerals may be glued to the granth letter: "gi" / "giii".
    head = re.sub(r"^g\s*(i{1,3})$", r"g \1", head)
    key = re.sub(r"\s+", " ", head).strip()

    prakaran = ALIASES.get(key)
    if prakaran is None:
        # "gadhada i" written as "gadhada 1" already covered; try a looser pass
        # where the roman numeral trails the word with no space.
        m2 = re.match(r"^(gadhada|gadhda)\s*(i{1,3})$", key)
        if m2:
            prakaran = {"i": "Gadhada I", "ii": "Gadhada II",
                        "iii": "Gadhada III"}[m2.group(2)]
    if prakaran is None:
        return None

    if prakaran in ("Ashlali",) and num is None:
        return "Ashlali"
    if num is None:
        return None
    return f"{prakaran}-{num}"


def ref_variants(ref: str) -> list[str]:
    """Plausible spellings of a canonical ref, for grepping an existing vault.

    Used to find notes the user may have filed under a different convention.
    """
    m = re.match(r"^(.*?)-(\d+)$", ref)
    if not m:
        return [ref, f"Vachanamrut {ref}"]
    prak, num = m.group(1), m.group(2)
    out = {ref, f"Vachanamrut {ref}", f"{prak} {num}", f"Vachanamrut {prak} {num}"}
    extra = {
        "Gadhada I": ["Gadhada Pratham", "Gadhada First", "G I", "GI", "G-I"],
        "Gadhada II": ["Gadhada Madhya", "Gadhada Second", "G II", "GII", "G-II"],
        "Gadhada III": ["Gadhada Antya", "Gadhada Third", "G III", "GIII", "G-III"],
        "Amdavad": ["Ahmedabad"],
        "Panchala": ["Panchal"],
        "Vartal": ["Vadtal"],
    }.get(prak, [])
    for alt in extra:
        out |= {f"{alt} {num}", f"{alt}-{num}", f"Vachanamrut {alt}-{num}",
                f"Vachanamrut {alt} {num}"}
    return sorted(out)


def load_index(path: Path = INDEX) -> list[dict]:
    if not path.exists():
        print(f"ERROR: index not found at {path}\n"
              f"Build it with: python3 build_index.py", file=sys.stderr)
        sys.exit(2)
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines()[1:]:
        if not line.strip():
            continue
        parts = (line.split("\t") + [""] * 5)[:5]
        rows.append({"ref": parts[0], "vachno": int(parts[1]),
                     "title": parts[2], "url": parts[3], "note": parts[4]})
    return rows


def expand_query(query: str) -> tuple[set[str], set[str]]:
    """Return (literal terms, bridged terms) for scoring."""
    terms = {t for t in norm_token(query).split() if t and t not in STOPWORDS}
    bridged: set[str] = set()
    for t in list(terms):
        for key, vals in BRIDGES.items():
            if t == key or t.startswith(key) or key.startswith(t) and len(t) > 3:
                bridged |= {norm_token(v) for v in vals}
    return terms, bridged - terms


def search(rows: list[dict], query: str, limit: int = 8) -> list[tuple[float, dict, list[str]]]:
    terms, bridged = expand_query(query)
    if not terms and not bridged:
        return []
    scored = []
    for r in rows:
        title = norm_token(r["title"])
        words = set(title.split())
        hits = []
        score = 0.0
        for t in terms:
            if t in words:
                score += 3.0
                hits.append(t)
            elif len(t) > 4 and t in title:
                score += 2.0
                hits.append(t)
        for t in bridged:
            if t in words:
                score += 1.5
                hits.append(f"~{t}")
            elif len(t) > 4 and t in title:
                score += 1.0
                hits.append(f"~{t}")
        if score > 0:
            scored.append((score, r, hits))
    scored.sort(key=lambda x: (-x[0], x[1]["vachno"]))
    return scored[:limit]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--normalize", metavar="REF")
    g.add_argument("--variants", metavar="REF")
    g.add_argument("--ref", metavar="REF")
    g.add_argument("--search", metavar="TEXT")
    g.add_argument("--stats", action="store_true")
    ap.add_argument("--limit", type=int, default=8)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--index", type=Path, default=INDEX)
    args = ap.parse_args()

    if args.normalize:
        out = normalize_ref(args.normalize)
        if out is None:
            print(f"could not normalise {args.normalize!r}", file=sys.stderr)
            return 1
        print(json.dumps({"input": args.normalize, "ref": out}) if args.json else out)
        return 0

    if args.variants:
        ref = normalize_ref(args.variants) or args.variants
        vs = ref_variants(ref)
        print(json.dumps({"ref": ref, "variants": vs}, ensure_ascii=False)
              if args.json else "\n".join(vs))
        return 0

    rows = load_index(args.index)

    if args.stats:
        by_prak: dict[str, int] = {}
        for r in rows:
            p = re.sub(r"-\d+$", "", r["ref"])
            by_prak[p] = by_prak.get(p, 0) + 1
        total = sum(1 for r in rows if r["note"] != "appendix")
        print(f"{len(rows)} rows ({total} canonical discourses)")
        for p in PRAKARANS:
            hits = [k for k in by_prak if k == p or k.startswith(p + " ")]
            if hits:
                print(f"  {p:14} {sum(by_prak[h] for h in hits)}")
        return 0

    if args.ref:
        ref = normalize_ref(args.ref)
        if ref is None:
            print(f"could not normalise {args.ref!r}", file=sys.stderr)
            return 1
        for r in rows:
            if r["ref"] == ref:
                if args.json:
                    print(json.dumps(r, ensure_ascii=False))
                else:
                    print(f"{r['ref']}\t{r['title']}\n{r['url']}")
                return 0
        print(f"{ref} is not in the index", file=sys.stderr)
        return 1

    hits = search(rows, args.search, args.limit)
    if args.json:
        print(json.dumps([{**r, "score": s, "matched": h} for s, r, h in hits],
                         ensure_ascii=False))
        return 0
    if not hits:
        print("no title matches — the index searches titles only, so this is "
              "common. Fall back to reasoning over the concept profile.")
        return 0
    print(f"candidates for {args.search!r} (title matches only — verify before use):")
    for s, r, h in hits:
        print(f"  {s:5.1f}  {r['ref']:22} {r['title'][:58]}")
        print(f"         matched: {', '.join(h)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
