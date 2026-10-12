"""
Compute derived search columns (PRD §9.A):

- word_forms.norm_text      normalize_jp(text)            → B-tree exact/prefix
- words.romaji_search       romaji without ' and -        → B-tree exact/prefix
- word_senses.gloss_id_stem Sastrawi stem of gloss_id     → FTS on base forms
"""

import sqlite3
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from textnorm import normalize_jp, romaji_search, stem_id

OUTPUT_DIR = Path(__file__).parent.parent / "output"


def compute(db_path: Path) -> dict:
    conn = sqlite3.connect(str(db_path))
    conn.create_function("normalize_jp", 1, normalize_jp, deterministic=True)
    conn.create_function("romaji_search", 1, romaji_search, deterministic=True)
    conn.create_function("stem_id", 1, stem_id, deterministic=True)

    stats = {}
    start = time.time()

    print("  word_forms.norm_text...")
    stats["forms"] = conn.execute("UPDATE word_forms SET norm_text = normalize_jp(text)").rowcount

    print("  words.romaji_search...")
    stats["words"] = conn.execute("UPDATE words SET romaji_search = romaji_search(romaji)").rowcount

    print("  word_senses.gloss_id_stem...")
    stats["stemmed"] = conn.execute(
        "UPDATE word_senses SET gloss_id_stem = stem_id(gloss_id) WHERE gloss_id IS NOT NULL"
    ).rowcount

    empty = conn.execute("SELECT COUNT(*) FROM word_forms WHERE norm_text = ''").fetchone()[0]
    conn.commit()
    conn.close()

    if empty:
        raise SystemExit(f"ERROR: {empty} word_forms have empty norm_text")

    stats["time_s"] = round(time.time() - start, 1)
    return stats


def main() -> None:
    db_path = OUTPUT_DIR / "dictionary_raw.db"
    if not db_path.exists():
        print("ERROR: dictionary_raw.db not found! Run parse_jmdict.py first.")
        sys.exit(1)

    print("=" * 50)
    print("Compute Derived Columns")
    print("=" * 50)
    stats = compute(db_path)
    print(f"\n  Forms normalized: {stats['forms']:>8,}")
    print(f"  Words (romaji):   {stats['words']:>8,}")
    print(f"  Senses stemmed:   {stats['stemmed']:>8,}")
    print(f"  Time:             {stats['time_s']:>7.1f}s")


if __name__ == "__main__":
    main()
