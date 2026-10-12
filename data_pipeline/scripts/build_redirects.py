"""
Build id_redirects by diffing against the previously shipped dictionary.db
(PRD §7, "Stabilitas ID antar-versi dataset").

JMdict ent_seq values are mostly stable, but entries can be removed or merged
between releases. For each word id present in the previous release and missing
in this one:

  1. same (primary_kanji, primary_kana) under a new id → redirect to it
  2. otherwise a unique entry with the same primary_kanji (or kana-only
     primary_kana) → redirect to it
  3. otherwise new_id = NULL (entry removed; the app shows it as unavailable)

Redirects shipped in the previous release are carried forward and re-resolved
so that chains (A → B, then B removed) still point at a live entry.

Usage:
    python build_redirects.py                       # uses output/previous/dictionary.db
    python build_redirects.py --previous PATH       # explicit previous release
No previous release (first build) → table stays empty.
"""

import argparse
import sqlite3
import sys
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent.parent / "output"
DEFAULT_PREVIOUS = OUTPUT_DIR / "previous" / "dictionary.db"


def _load_words(conn: sqlite3.Connection) -> dict[int, tuple[str | None, str]]:
    return {
        wid: (kanji, kana)
        for wid, kanji, kana in conn.execute("SELECT id, primary_kanji, primary_kana FROM words")
    }


def build(raw_db: Path, previous_db: Path) -> dict:
    new = sqlite3.connect(str(raw_db))
    old = sqlite3.connect(f"{previous_db.resolve().as_uri()}?mode=ro", uri=True)

    new_words = _load_words(new)
    old_words = _load_words(old)

    by_pair: dict[tuple[str | None, str], list[int]] = {}
    by_kanji: dict[str, list[int]] = {}
    by_kana: dict[str, list[int]] = {}
    for wid, (kanji, kana) in new_words.items():
        by_pair.setdefault((kanji, kana), []).append(wid)
        if kanji:
            by_kanji.setdefault(kanji, []).append(wid)
        else:
            by_kana.setdefault(kana, []).append(wid)

    def resolve(old_id: int) -> int | None:
        if old_id in new_words:
            return old_id
        if old_id not in old_words:
            return None
        kanji, kana = old_words[old_id]
        for candidates in (
            by_pair.get((kanji, kana), []),
            by_kanji.get(kanji, []) if kanji else by_kana.get(kana, []),
        ):
            if len(candidates) == 1:
                return candidates[0]
        return None

    redirects: dict[str, str | None] = {}
    stats = {"removed": 0, "remapped": 0, "dropped": 0, "carried": 0}

    for old_id in old_words.keys() - new_words.keys():
        target = resolve(old_id)
        redirects[str(old_id)] = None if target is None else str(target)
        stats["removed"] += 1
        stats["remapped" if target is not None else "dropped"] += 1

    # Carry forward previous redirects, re-resolving their targets.
    has_table = old.execute(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'id_redirects'"
    ).fetchone()
    if has_table:
        for old_id, prev_target in old.execute(
            "SELECT old_id, new_id FROM id_redirects WHERE item_type = 'word'"
        ):
            if old_id in redirects:
                continue
            target = resolve(int(prev_target)) if prev_target is not None else None
            redirects[old_id] = None if target is None else str(target)
            stats["carried"] += 1

    new.execute("DELETE FROM id_redirects WHERE item_type = 'word'")
    new.executemany(
        "INSERT INTO id_redirects (item_type, old_id, new_id) VALUES ('word', ?, ?)",
        redirects.items(),
    )
    new.commit()
    new.close()
    old.close()
    return stats


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--previous", type=Path, default=DEFAULT_PREVIOUS)
    args = parser.parse_args()

    raw_db = OUTPUT_DIR / "dictionary_raw.db"
    if not raw_db.exists():
        print("ERROR: dictionary_raw.db not found! Run parse_jmdict.py first.")
        sys.exit(1)

    print("=" * 50)
    print("Build ID Redirects")
    print("=" * 50)

    if not args.previous.exists():
        print(f"  ⏭ No previous release at {args.previous} (first build): no redirects")
        return

    stats = build(raw_db, args.previous)
    print(f"  Removed since previous: {stats['removed']:>6,}")
    print(f"    remapped:             {stats['remapped']:>6,}")
    print(f"    no replacement:       {stats['dropped']:>6,}")
    print(f"  Carried forward:        {stats['carried']:>6,}")


if __name__ == "__main__":
    main()
