"""
Test and benchmark the dictionary database.

Validates:
1. Row counts (expected minimums)
2. Search acceptance criteria (PRD §12 v1.0 #2) using search_reference.search
3. Search latency through the full two-tier search (p95 ≤ 100 ms target)
4. Data integrity (orphans, derived columns, redirects)
"""

import sqlite3
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from search_reference import search

OUTPUT_DIR = Path(__file__).parent.parent / "output"


class TestResult:
    def __init__(self, name: str, passed: bool | None, detail: str = ""):
        self.name = name
        self.passed = passed  # None = skipped
        self.detail = detail

    def __str__(self):
        status = {True: "✓ PASS", False: "✗ FAIL", None: "⏭ SKIP"}[self.passed]
        return f"  {status}: {self.name}" + (f" — {self.detail}" if self.detail else "")


def _word_id(conn: sqlite3.Connection, kanji: str | None, kana: str) -> int | None:
    row = conn.execute(
        "SELECT id FROM words WHERE primary_kanji IS ? AND primary_kana = ? "
        "ORDER BY is_common DESC LIMIT 1",
        (kanji, kana),
    ).fetchone()
    return row[0] if row else None


def _headword(conn: sqlite3.Connection, wid: int) -> str:
    return conn.execute(
        "SELECT coalesce(primary_kanji, primary_kana) FROM words WHERE id = ?", (wid,)
    ).fetchone()[0]


def test_row_counts(conn: sqlite3.Connection) -> list[TestResult]:
    results = []
    checks = {
        "words": ("SELECT COUNT(*) FROM words", 100000),
        "word_forms": ("SELECT COUNT(*) FROM word_forms", 150000),
        "word_senses": ("SELECT COUNT(*) FROM word_senses", 150000),
        "common_words": ("SELECT COUNT(*) FROM words WHERE is_common = 1", 10000),
        "words_fts_jp": ("SELECT COUNT(*) FROM words_fts_jp", 100000),
        "words_fts_gloss": ("SELECT COUNT(*) FROM words_fts_gloss", 100000),
        "N5 words": ("SELECT COUNT(*) FROM words WHERE jlpt_level = 5", 100),
    }
    for name, (query, min_expected) in checks.items():
        count = conn.execute(query).fetchone()[0]
        results.append(TestResult(f"Row count: {name}", count >= min_expected,
                                  f"{count:,} (min: {min_expected:,})"))
    return results


def test_search(conn: sqlite3.Connection) -> list[TestResult]:
    results = []

    def expect_top(query: str, target: int | None, top_n: int, label: str) -> None:
        if target is None:
            results.append(TestResult(label, False, "target word not in DB"))
            return
        ranked = search(conn, query, limit=top_n)
        pos = ranked.index(target) + 1 if target in ranked else None
        shown = ", ".join(_headword(conn, w) for w in ranked[:top_n])
        results.append(TestResult(label, pos is not None,
                                  f"rank {pos}" if pos else f"top {top_n}: {shown}"))

    taberu = _word_id(conn, "食べる", "たべる")
    for q in ("taberu", "たべる", "食べる", "eat", "タベル", "ﾀﾍﾞﾙ"):
        expect_top(q, taberu, 3, f"'{q}' → 食べる in top 3")

    has_id = conn.execute("SELECT 1 FROM word_senses WHERE gloss_id IS NOT NULL LIMIT 1").fetchone()
    for q in ("makan", "memakan", "dimakan"):
        if has_id:
            expect_top(q, taberu, 3, f"'{q}' → 食べる in top 3")
        else:
            results.append(TestResult(f"'{q}' → 食べる in top 3", None, "no Indonesian glosses yet"))

    # Short queries (1–2 chars) must work through the B-tree path
    for q, kanji, kana in (("木", "木", "き"), ("目", "目", "め")):
        expect_top(q, _word_id(conn, kanji, kana), 3, f"1-char '{q}' → {kanji} in top 3")
    hits = search(conn, "食べ", limit=20)
    results.append(TestResult("2-char prefix '食べ' returns 食べる/食べ物", taberu in hits,
                              f"{len(hits)} results"))

    # Substring (trigram) for ≥ 3 chars inside a longer word
    tabemono = _word_id(conn, "食べ物", "たべもの")
    expect_top("べもの", tabemono, 20, "substring 'べもの' → 食べ物 in top 20")

    # ぢ/づ folding: a romaji query cannot tell づ from ず
    tsuzuku = _word_id(conn, "続く", "つづく")
    expect_top("つずく", tsuzuku, 3, "'つずく' → 続く (づ/ず folding)")
    expect_top("tsuzuku", tsuzuku, 3, "'tsuzuku' → 続く in top 3")

    expect_top("cat", _word_id(conn, "猫", "ねこ"), 5, "'cat' → 猫 in top 5")
    expect_top("neko", _word_id(conn, "猫", "ねこ"), 3, "'neko' → 猫 in top 3")
    expect_top("gakkou", _word_id(conn, "学校", "がっこう"), 3, "'gakkou' → 学校 in top 3")
    return results


def test_search_latency(conn: sqlite3.Connection) -> list[TestResult]:
    queries = [
        "taberu", "neko", "sakura", "eat", "cat", "beautiful", "run", "water",
        "たべる", "ねこ", "食べる", "日本語", "学校", "先生", "ありがとう",
        "木", "目", "食べ", "た", "a", "go", "to be", "べもの", "コーヒー",
    ]
    for q in queries[:5]:
        search(conn, q)  # warm up

    latencies: list[float] = []
    for q in queries:
        for _ in range(10):
            start = time.perf_counter()
            search(conn, q)
            latencies.append((time.perf_counter() - start) * 1000)

    latencies.sort()
    pct = lambda p: latencies[min(len(latencies) - 1, int(len(latencies) * p))]
    worst = max(queries, key=lambda q: _time_once(conn, q))
    return [
        TestResult("Search latency p50", pct(0.50) <= 50, f"{pct(0.50):.1f}ms"),
        TestResult("Search latency p95", pct(0.95) <= 100, f"{pct(0.95):.1f}ms (target: ≤100ms)"),
        TestResult("Search latency max", latencies[-1] <= 300,
                   f"{latencies[-1]:.1f}ms (slowest query: '{worst}')"),
    ]


def _time_once(conn: sqlite3.Connection, q: str) -> float:
    start = time.perf_counter()
    search(conn, q)
    return time.perf_counter() - start


def test_data_integrity(conn: sqlite3.Connection) -> list[TestResult]:
    checks = [
        ("No orphan word_forms",
         "SELECT COUNT(*) FROM word_forms WHERE word_id NOT IN (SELECT id FROM words)"),
        ("No orphan word_senses",
         "SELECT COUNT(*) FROM word_senses WHERE word_id NOT IN (SELECT id FROM words)"),
        ("All words have senses",
         "SELECT COUNT(*) FROM words WHERE id NOT IN (SELECT DISTINCT word_id FROM word_senses)"),
        ("All words have romaji", "SELECT COUNT(*) FROM words WHERE romaji IS NULL OR romaji = ''"),
        ("All words have romaji_search", "SELECT COUNT(*) FROM words WHERE romaji_search = ''"),
        ("All forms have norm_text", "SELECT COUNT(*) FROM word_forms WHERE norm_text = ''"),
        ("Stems present for Indonesian glosses",
         "SELECT COUNT(*) FROM word_senses WHERE gloss_id IS NOT NULL AND gloss_id_stem IS NULL"),
        ("POS codes resolve in pos_tags",
         "WITH RECURSIVE split(code, rest) AS ("
         "  SELECT NULL, pos || ';' FROM word_senses WHERE pos IS NOT NULL"
         "  UNION ALL SELECT substr(rest, 1, instr(rest, ';') - 1), substr(rest, instr(rest, ';') + 1)"
         "  FROM split WHERE rest <> '') "
         "SELECT COUNT(DISTINCT code) FROM split WHERE code IS NOT NULL "
         "AND code NOT IN (SELECT code FROM pos_tags)"),
        ("食べる is an ichidan verb",
         "SELECT COUNT(*) = 0 FROM words WHERE primary_kanji = '食べる' AND verb_group = 'ichidan'"),
        ("JLPT levels valid",
         "SELECT COUNT(*) FROM words WHERE jlpt_level IS NOT NULL AND jlpt_level NOT IN (1,2,3,4,5)"),
        ("Redirect targets exist",
         "SELECT COUNT(*) FROM id_redirects WHERE item_type = 'word' AND new_id IS NOT NULL "
         "AND CAST(new_id AS INTEGER) NOT IN (SELECT id FROM words)"),
        ("Redirect sources are gone",
         "SELECT COUNT(*) FROM id_redirects WHERE item_type = 'word' "
         "AND CAST(old_id AS INTEGER) IN (SELECT id FROM words)"),
    ]
    results = []
    for name, sql in checks:
        bad = conn.execute(sql).fetchone()[0]
        results.append(TestResult(name, bad == 0, f"{bad} bad rows" if bad else "clean"))

    meta = dict(conn.execute("SELECT key, value FROM meta"))
    for key in ("dataset_version", "sqlite_min_version", "attribution"):
        results.append(TestResult(f"meta.{key} present", key in meta, meta.get(key, "missing")[:40]))

    journal = conn.execute("PRAGMA journal_mode").fetchone()[0]
    results.append(TestResult("Journal mode is not WAL (read-only asset)", journal != "wal", journal))

    integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
    results.append(TestResult("SQLite integrity", integrity == "ok", integrity))
    return results


def main() -> None:
    db_path = OUTPUT_DIR / "dictionary.db"
    if not db_path.exists():
        print("ERROR: dictionary.db not found! Run the pipeline first (python build_all.py).")
        sys.exit(1)

    print("=" * 60)
    print(f"Dictionary Database Tests — {db_path.name}")
    print(f"Size: {db_path.stat().st_size / (1024*1024):.1f} MB, SQLite {sqlite3.sqlite_version}")
    print("=" * 60)

    conn = sqlite3.connect(f"{db_path.resolve().as_uri()}?mode=ro", uri=True)

    all_results: list[TestResult] = []
    sections = [
        ("Row Counts", test_row_counts),
        ("Search Acceptance", test_search),
        ("Search Latency Benchmark", test_search_latency),
        ("Data Integrity", test_data_integrity),
    ]
    for i, (title, fn) in enumerate(sections, 1):
        print(f"\n[{i}/{len(sections)}] {title}")
        for r in fn(conn):
            all_results.append(r)
            print(r)
    conn.close()

    failed = [r for r in all_results if r.passed is False]
    skipped = sum(1 for r in all_results if r.passed is None)
    passed = sum(1 for r in all_results if r.passed)

    print("\n" + "=" * 60)
    print(f"Results: {passed} passed, {len(failed)} failed, {skipped} skipped")
    print("=" * 60)
    if failed:
        print("\nFailed tests:")
        for r in failed:
            print(f"  ✗ {r.name}: {r.detail}")
        sys.exit(1)


if __name__ == "__main__":
    main()
