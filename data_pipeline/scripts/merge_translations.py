"""
Merge curated Indonesian meanings into word_senses.gloss_id.

JMdict has no Indonesian glosses (PRD §7), so they come from translation
files kept in the repo:

    content/translations/id/*.json

Each file is a list of objects:

    [
      {"word_id": 1358280, "sense_no": 1, "gloss_id": "makan; memakan", "machine": false},
      ...
    ]

- word_id   = JMdict ent_seq (words.id)
- sense_no  = 1-based sense number within the entry
- machine   = true for unreviewed machine translation (shown with a label in the UI)

Missing directory or files is not an error: the dictionary simply has no
Indonesian meanings yet.
"""

import json
import sqlite3
import sys
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent.parent / "output"
TRANSLATIONS_DIR = Path(__file__).parent.parent.parent / "content" / "translations" / "id"


def load_translations(directory: Path) -> list[tuple[str, int, int, int]]:
    """Return rows of (gloss_id, is_machine, word_id, sense_no)."""
    rows: list[tuple[str, int, int, int]] = []
    for path in sorted(directory.glob("*.json")):
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, list):
            raise SystemExit(f"{path.name}: expected a JSON list")
        for i, item in enumerate(data):
            try:
                gloss = str(item["gloss_id"]).strip()
                rows.append((gloss, 1 if item.get("machine") else 0,
                             int(item["word_id"]), int(item["sense_no"])))
            except (KeyError, TypeError, ValueError) as e:
                raise SystemExit(f"{path.name}[{i}]: invalid entry ({e})")
        print(f"  ✓ {path.name}: {len(data)} entries")
    return rows


def main() -> None:
    db_path = OUTPUT_DIR / "dictionary_raw.db"
    if not db_path.exists():
        print("ERROR: dictionary_raw.db not found! Run parse_jmdict.py first.")
        sys.exit(1)

    print("=" * 50)
    print("Merge Indonesian Translations")
    print("=" * 50)

    if not TRANSLATIONS_DIR.exists():
        print(f"  ⏭ No translations yet ({TRANSLATIONS_DIR})")
        return

    rows = load_translations(TRANSLATIONS_DIR)
    conn = sqlite3.connect(str(db_path))
    matched = 0
    unmatched: list[tuple[int, int]] = []
    for gloss, is_machine, word_id, sense_no in rows:
        cur = conn.execute(
            "UPDATE word_senses SET gloss_id = ?, gloss_id_is_machine = ? "
            "WHERE word_id = ? AND sense_no = ?",
            (gloss, is_machine, word_id, sense_no),
        )
        if cur.rowcount:
            matched += 1
        else:
            unmatched.append((word_id, sense_no))
    conn.commit()
    conn.close()

    print(f"\n  Applied:   {matched:,}")
    print(f"  Unmatched: {len(unmatched):,}")
    for word_id, sense_no in unmatched[:20]:
        print(f"    ⚠ word_id={word_id} sense_no={sense_no} not in JMdict")
    if unmatched:
        print("  (Entries may have been removed or renumbered in this JMdict release.)")


if __name__ == "__main__":
    main()
