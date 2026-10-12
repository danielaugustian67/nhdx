"""
Build the search indexes (PRD F1.2, §9.A) — two-tier strategy:

1. B-tree exact/prefix (any query length, the only path for 1–2 char queries)
     idx_word_forms_norm      ON word_forms(norm_text)
     idx_words_romaji_search  ON words(romaji_search)
2. FTS5
     words_fts_jp     trigram, Japanese substring search for queries ≥ 3 chars
     words_fts_gloss  unicode61 + prefix index, word-based meaning search (EN/ID)

Both FTS tables are contentless (content='') and keyed by rowid = words.id.
They are not updated after build, so contentless_delete is not needed
(keeps the minimum SQLite version at 3.34 for trigram).
"""

import sqlite3
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from textnorm import normalize_latin

OUTPUT_DIR = Path(__file__).parent.parent / "output"
SQLITE_MIN_VERSION = "3.34.0"
BATCH_SIZE = 5000


def _check_trigram(conn: sqlite3.Connection) -> None:
    try:
        conn.execute("CREATE VIRTUAL TABLE temp._probe USING fts5(x, tokenize='trigram')")
        conn.execute("DROP TABLE temp._probe")
    except sqlite3.OperationalError as e:
        raise SystemExit(
            f"SQLite {sqlite3.sqlite_version} has no FTS5 trigram tokenizer "
            f"(need ≥ {SQLITE_MIN_VERSION}): {e}"
        )


def build_btree(conn: sqlite3.Connection) -> None:
    print("  B-tree indexes...")
    conn.executescript("""
        CREATE INDEX IF NOT EXISTS idx_word_forms_norm ON word_forms(norm_text);
        CREATE INDEX IF NOT EXISTS idx_words_romaji_search ON words(romaji_search);
    """)


def build_fts_jp(conn: sqlite3.Connection) -> int:
    print("  words_fts_jp (trigram)...")
    conn.executescript("""
        DROP TABLE IF EXISTS words_fts_jp;
        -- No romaji column: the app converts romaji to kana before searching,
        -- and romaji prefix is served by idx_words_romaji_search (saves ~10 MB).
        CREATE VIRTUAL TABLE words_fts_jp USING fts5(
            kanji, kana,
            content='',
            tokenize='trigram'
        );
    """)
    rows = conn.execute("""
        SELECT w.id,
               (SELECT group_concat(norm_text, ' ') FROM word_forms f
                 WHERE f.word_id = w.id AND f.kind = 'kanji'),
               (SELECT group_concat(norm_text, ' ') FROM word_forms f
                 WHERE f.word_id = w.id AND f.kind = 'kana')
          FROM words w
    """).fetchall()
    conn.executemany(
        "INSERT INTO words_fts_jp(rowid, kanji, kana) VALUES (?, ?, ?)",
        [(wid, kanji or "", kana or "") for wid, kanji, kana in rows],
    )
    return len(rows)


def build_fts_gloss(conn: sqlite3.Connection) -> int:
    print("  words_fts_gloss (unicode61, prefix)...")
    conn.executescript("""
        DROP TABLE IF EXISTS words_fts_gloss;
        CREATE VIRTUAL TABLE words_fts_gloss USING fts5(
            gloss_en, gloss_id, gloss_id_stem,
            content='',
            tokenize='unicode61 remove_diacritics 2',
            prefix='2 3'
        );
    """)
    cursor = conn.execute("""
        SELECT word_id,
               group_concat(gloss_en, '; '),
               group_concat(gloss_id, '; '),
               group_concat(gloss_id_stem, '; ')
          FROM word_senses
         GROUP BY word_id
    """)
    count = 0
    while batch := cursor.fetchmany(BATCH_SIZE):
        conn.executemany(
            "INSERT INTO words_fts_gloss(rowid, gloss_en, gloss_id, gloss_id_stem) VALUES (?, ?, ?, ?)",
            [(wid, normalize_latin(en), normalize_latin(id_), normalize_latin(stem))
             for wid, en, id_, stem in batch],
        )
        count += len(batch)
    return count


def verify(conn: sqlite3.Connection) -> bool:
    print("\nVerifying...")
    checks = [
        ("B-tree exact 'たべる'", "SELECT COUNT(*) FROM word_forms WHERE norm_text = ?", ("たべる",)),
        ("B-tree prefix 'たべ' (2 chars)",
         "SELECT COUNT(*) FROM word_forms WHERE norm_text >= ? AND norm_text < ?",
         ("たべ", "たべ\U0010ffff")),
        ("B-tree exact '木' (1 char)", "SELECT COUNT(*) FROM word_forms WHERE norm_text = ?", ("木",)),
        ("B-tree romaji 'taberu'", "SELECT COUNT(*) FROM words WHERE romaji_search = ?", ("taberu",)),
        ("Trigram substring 'たべも'", "SELECT COUNT(*) FROM words_fts_jp WHERE kana MATCH ?", ('"たべも"',)),
        ("Trigram substring '日本語'", "SELECT COUNT(*) FROM words_fts_jp WHERE kanji MATCH ?", ('"日本語"',)),
        ("Gloss 'eat'", "SELECT COUNT(*) FROM words_fts_gloss WHERE gloss_en MATCH ?", ("eat",)),
        ("Gloss prefix 'beauti*'", "SELECT COUNT(*) FROM words_fts_gloss WHERE gloss_en MATCH ?", ("beauti*",)),
    ]
    ok = True
    for label, sql, params in checks:
        n = conn.execute(sql, params).fetchone()[0]
        ok &= n > 0
        print(f"  {'✓' if n else '✗'} {label}: {n}")
    return ok


def main() -> None:
    db_path = OUTPUT_DIR / "dictionary_raw.db"
    if not db_path.exists():
        print("ERROR: dictionary_raw.db not found! Run parse_jmdict.py first.")
        sys.exit(1)

    print("=" * 50)
    print(f"Build Search Indexes (SQLite {sqlite3.sqlite_version})")
    print("=" * 50)

    conn = sqlite3.connect(str(db_path))
    _check_trigram(conn)
    start = time.time()
    build_btree(conn)
    jp = build_fts_jp(conn)
    gloss = build_fts_gloss(conn)
    conn.execute(
        "INSERT OR REPLACE INTO meta (key, value) VALUES ('sqlite_min_version', ?)",
        (SQLITE_MIN_VERSION,),
    )
    conn.commit()
    ok = verify(conn)
    conn.close()

    print(f"\n  words_fts_jp:    {jp:>8,}")
    print(f"  words_fts_gloss: {gloss:>8,}")
    print(f"  Time:            {time.time() - start:>7.1f}s")
    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
