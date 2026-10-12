"""
Merge JLPT level labels into the dictionary database.

JLPT levels are not part of JMdict — they come from Jonathan Waller's
community lists (tanos.co.uk, CC BY), with JMdict ent_seq per word added by
stephenmk/yomitan-jlpt-vocab:

    sources/jlpt/n5.csv … n1.csv
    columns: jmdict_seq,kana,kanji,waller_definition

Matching is by ent_seq (= words.id). Rows without a usable ent_seq fall back
to matching kanji+kana, then kana alone among kana-only entries.

A word listed on several levels gets the easiest one (highest N number),
since that is where a learner first meets it.
"""

import csv
import sqlite3
import sys
from pathlib import Path

SOURCES_DIR = Path(__file__).parent.parent / "sources"
OUTPUT_DIR = Path(__file__).parent.parent / "output"


def load_jlpt_lists(jlpt_dir: Path) -> list[tuple[int, int | None, str, str]]:
    """Return rows of (level, ent_seq or None, kanji, kana)."""
    rows = []
    for level in range(5, 0, -1):
        path = jlpt_dir / f"n{level}.csv"
        if not path.exists():
            raise SystemExit(f"ERROR: {path} not found. Run download_sources.py first.")
        with open(path, encoding="utf-8", newline="") as f:
            count = 0
            for r in csv.DictReader(f):
                seq = r.get("jmdict_seq", "").strip()
                rows.append((level, int(seq) if seq.isdigit() else None,
                             r.get("kanji", "").strip(), r.get("kana", "").strip()))
                count += 1
        print(f"  ✓ N{level}: {count} words")
    return rows


def merge_jlpt_levels(db_path: Path, rows: list[tuple[int, int | None, str, str]]) -> dict:
    conn = sqlite3.connect(str(db_path))
    conn.execute("UPDATE words SET jlpt_level = NULL")

    stats = {"by_id": 0, "by_text": 0, "unmatched": []}
    for level, seq, kanji, kana in rows:
        params: tuple
        if seq is not None and conn.execute("SELECT 1 FROM words WHERE id = ?", (seq,)).fetchone():
            sql, params, key = "id = ?", (seq,), "by_id"
        elif kanji:
            sql, params, key = ("id IN (SELECT a.word_id FROM word_forms a JOIN word_forms b "
                                "ON a.word_id = b.word_id WHERE a.text = ? AND b.text = ?)",
                                (kanji, kana), "by_text")
        else:
            sql, params, key = "primary_kanji IS NULL AND primary_kana = ?", (kana,), "by_text"

        cur = conn.execute(
            f"UPDATE words SET jlpt_level = max(coalesce(jlpt_level, 0), ?) WHERE {sql}",
            (level, *params),
        )
        if cur.rowcount:
            stats[key] += 1
        else:
            stats["unmatched"].append(f"N{level} {seq} {kanji or ''}{'/' if kanji else ''}{kana}")
    conn.commit()

    stats["per_level"] = {
        f"N{lv}": conn.execute("SELECT COUNT(*) FROM words WHERE jlpt_level = ?", (lv,)).fetchone()[0]
        for lv in range(5, 0, -1)
    }
    conn.close()
    return stats


def main() -> None:
    db_path = OUTPUT_DIR / "dictionary_raw.db"
    if not db_path.exists():
        print("ERROR: dictionary_raw.db not found! Run parse_jmdict.py first.")
        sys.exit(1)

    print("=" * 50)
    print("Merge JLPT Levels")
    print("=" * 50)

    print("\n[1/2] Loading JLPT word lists...")
    rows = load_jlpt_lists(SOURCES_DIR / "jlpt")

    print(f"\n[2/2] Merging into database ({len(rows)} rows)...")
    stats = merge_jlpt_levels(db_path, rows)

    print(f"\n  Matched by ent_seq: {stats['by_id']:>6,}")
    print(f"  Matched by text:    {stats['by_text']:>6,}")
    print(f"  Unmatched:          {len(stats['unmatched']):>6,}")
    for u in stats["unmatched"][:20]:
        print(f"    ⚠ {u}")
    for level, count in stats["per_level"].items():
        print(f"    {level}: {count:>5,} words")


if __name__ == "__main__":
    main()
