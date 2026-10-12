"""
Build content.db (PRD §9.B) for v1.0:

- kana          92 basic kana + dakuten/handakuten + yōon, hiragana & katakana
- kanji         kanji course N5 to N1 (KANJIDIC2): N5 + N4 grouped by theme
                (kanji_themes.py), N3 to N1 by difficulty; easiest first
- char_strokes  KanjiVG stroke paths for every kana and course kanji (F6)
                (--with-kanji adds all KanjiVG kanji)
- courses / lessons / lesson_items
                curated curriculum from content/curriculum/*.json (if present)
- grammar       grammar points from content/grammar/n*.json (F13), validated
- id_redirects, meta

Curriculum file format (one file per course, e.g. content/curriculum/n5.json):

    {
      "course": {"id": "n5", "jlpt_level": 5, "title": "N5", "order_no": 1},
      "lessons": [
        {"id": "n5-u01-l01", "order_no": 1, "title": "Salam", "kind": "vocab",
         "items": [{"type": "word", "id": 1358280}, ...]}
      ]
    }

Word ids are validated against dictionary.db.

Grammar file format (one file per level, e.g. content/grammar/n5.json):

    {
      "level": 5,
      "points": [
        {"id": "n5-wa-desu", "pattern": "〜は〜です",
         "meaning": {"id": "…", "en": "…"}, "formation": "N₁ は N₂ です",
         "explanation": {"id": "…", "en": "…"},
         "examples": [{"ja": "わたしは学生です。", "kana": "…", "tr": {"id": "…", "en": "…"},
                       "chunks": ["わたしは", "学生", "です"]}],
         "quiz": [{"q": "これ＿＿本です。", "options": ["は", "を", "に"], "answer": 0,
                   "tr": {"id": "…", "en": "…"}}]}
      ]
    }

"chunks" (optional) are the tiles of the sentence-building exercise and must
spell the sentence without its final punctuation; each quiz question has one
＿＿ gap and the right option at "answer".
"""

import argparse
import gzip
import hashlib
import json
import re
import shutil
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from kana_to_romaji import hiragana_to_katakana, kana_to_romaji
from kanji_themes import theme_of

ROOT = Path(__file__).parent.parent
SOURCES_DIR = ROOT / "sources"
OUTPUT_DIR = ROOT / "output"
CURRICULUM_DIR = ROOT.parent / "content" / "curriculum"
GRAMMAR_DIR = ROOT.parent / "content" / "grammar"

CONTENT_VERSION = "1.4.0"

# (row_group, kana) in gojūon order
BASIC_ROWS = [
    ("a", "あいうえお"), ("ka", "かきくけこ"), ("sa", "さしすせそ"), ("ta", "たちつてと"),
    ("na", "なにぬねの"), ("ha", "はひふへほ"), ("ma", "まみむめも"), ("ya", "やゆよ"),
    ("ra", "らりるれろ"), ("wa", "わを"), ("n", "ん"),
]
DAKUTEN_ROWS = [("ga", "がぎぐげご"), ("za", "ざじずぜぞ"), ("da", "だぢづでど"), ("ba", "ばびぶべぼ")]
HANDAKUTEN_ROWS = [("pa", "ぱぴぷぺぽ")]
YOON_BASES = [("ka", "き"), ("sa", "し"), ("ta", "ち"), ("na", "に"), ("ha", "ひ"), ("ma", "み"),
              ("ra", "り"), ("ga", "ぎ"), ("za", "じ"), ("ba", "び"), ("pa", "ぴ")]
SMALL_Y = "ゃゅょ"

SCHEMA = """
CREATE TABLE courses (id TEXT PRIMARY KEY, jlpt_level INTEGER, title TEXT, order_no INTEGER);
CREATE TABLE lessons (id TEXT PRIMARY KEY, course_id TEXT REFERENCES courses(id),
                      order_no INTEGER, title TEXT, kind TEXT);
CREATE TABLE lesson_items (lesson_id TEXT, item_type TEXT, item_id TEXT, order_no INTEGER,
                           PRIMARY KEY (lesson_id, item_type, item_id));

CREATE TABLE kana (
  id INTEGER PRIMARY KEY,            -- codepoint; yōon: cp1 * 65536 + cp2
  literal TEXT NOT NULL, script TEXT NOT NULL,
  romaji TEXT NOT NULL, row_group TEXT NOT NULL,
  kind TEXT NOT NULL,                -- basic|dakuten|handakuten|yoon
  order_no INTEGER NOT NULL, example_word_id INTEGER
);

CREATE TABLE kanji (
  id INTEGER PRIMARY KEY,            -- codepoint
  literal TEXT NOT NULL,
  jlpt_level INTEGER NOT NULL,       -- 5 = N5 … 1 = N1 (from KANJIDIC2's pre-2010 levels, see kanji_course)
  grade INTEGER, stroke_count INTEGER NOT NULL, freq INTEGER,
  meanings_en TEXT NOT NULL,         -- '; '-separated, most important first
  onyomi TEXT NOT NULL,              -- katakana, '、'-separated
  kunyomi TEXT NOT NULL,             -- hiragana, okurigana after '.', '、'-separated
  theme TEXT NOT NULL,               -- kanji_themes.py key (one path unit per theme); '' for N3 to N1
  order_no INTEGER NOT NULL          -- course order, easiest first
);

CREATE TABLE char_strokes (codepoint INTEGER, stroke_no INTEGER, svg_path TEXT,
                           PRIMARY KEY (codepoint, stroke_no));

CREATE TABLE grammar (
  id TEXT PRIMARY KEY,               -- 'n5-wa-desu'
  jlpt_level INTEGER NOT NULL,
  order_no INTEGER NOT NULL,         -- within the level, as authored
  pattern TEXT NOT NULL, formation TEXT NOT NULL,
  meaning TEXT NOT NULL,             -- JSON {"id": …, "en": …}
  explanation TEXT NOT NULL,         -- JSON {"id": …, "en": …}
  examples TEXT NOT NULL,            -- JSON [{"ja", "kana", "tr": {id, en}, "chunks"?}]
  quiz TEXT NOT NULL                 -- JSON [{"q", "options", "answer", "tr": {id, en}}]
);

CREATE TABLE id_redirects (item_type TEXT NOT NULL, old_id TEXT NOT NULL, new_id TEXT,
                           PRIMARY KEY (item_type, old_id));
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
"""


def kana_rows() -> list[tuple]:
    """Return kana rows for both scripts."""
    hira: list[tuple[str, str, str]] = []  # (literal, row_group, kind)
    for kind, rows in (("basic", BASIC_ROWS), ("dakuten", DAKUTEN_ROWS),
                       ("handakuten", HANDAKUTEN_ROWS)):
        for group, chars in rows:
            hira.extend((c, group, kind) for c in chars)
    for group, base in YOON_BASES:
        hira.extend((base + y, group, "yoon") for y in SMALL_Y)

    out = []
    for script in ("hiragana", "katakana"):
        for order_no, (literal, group, kind) in enumerate(hira, 1):
            text = literal if script == "hiragana" else hiragana_to_katakana(literal)
            cps = [ord(c) for c in text]
            kid = cps[0] if len(cps) == 1 else cps[0] * 65536 + cps[1]
            out.append((kid, text, script, kana_to_romaji(text), group, kind, order_no))
    return out


def pick_example_word(dict_conn: sqlite3.Connection | None, literal: str, script: str) -> int | None:
    """Common, low-level word that starts with the kana (katakana: loanwords)."""
    if dict_conn is None:
        return None
    prefix = "primary_kana >= ?1 AND primary_kana < ?1 || char(1114111) AND length(primary_kana) > ?2"
    if script == "hiragana":
        sql = (f"SELECT id FROM words WHERE {prefix} AND (jlpt_level IS NOT NULL OR is_common = 1) "
               "ORDER BY jlpt_level IS NULL, jlpt_level DESC, is_common DESC, length(primary_kana), "
               "coalesce(freq_rank, 1000000) LIMIT 1")
    else:
        sql = (f"SELECT id FROM words WHERE {prefix} AND primary_kanji IS NULL "
               "ORDER BY is_common DESC, jlpt_level IS NULL, jlpt_level DESC, "
               "length(primary_kana), coalesce(freq_rank, 1000000) LIMIT 1")
    row = dict_conn.execute(sql, (literal, len(literal))).fetchone()
    return row[0] if row else None


# KANJIDIC2 still carries the pre-2010 four-level JLPT. Old levels 4 and 3
# match today's N5 and N4 closely enough for ordering a course, and old 1 is
# about N1. Old level 2 (739 kanji) became N3 and N2 (about 370 each, per
# Jonathan Waller's lists); it is split in half by how early the kanji shows
# up in the JLPT vocabulary (merge_jlpt.py), then by grade and frequency.
_OLD_JLPT_TO_N = {"4": 5, "3": 4, "2": 3, "1": 1}


def _split_n3_n2(rows: list[tuple], dict_conn: sqlite3.Connection) -> list[tuple]:
    """Moves the harder half of the old level 2 (marked N3 so far) to N2."""
    earliest: dict[str, int] = {}
    for kanji, level in dict_conn.execute(
            "SELECT primary_kanji, jlpt_level FROM words "
            "WHERE jlpt_level IS NOT NULL AND primary_kanji IS NOT NULL"):
        for c in kanji:
            earliest[c] = max(earliest.get(c, 0), level)
    old2 = sorted((r for r in rows if r[2] == 3),
                  key=lambda r: (-earliest.get(r[1], 0), r[3] or 99, r[5] or 9999, r[4], r[0]))
    n2 = {r[1] for r in old2[(len(old2) + 1) // 2:]}
    return [(*r[:2], 2, *r[3:]) if r[1] in n2 else r for r in rows]


def kanji_course(path: Path, dict_conn: sqlite3.Connection) -> list[tuple]:
    """
    Kanji rows in course order, N5 first. N5 and N4: theme (kanji_themes.py)
    by the average difficulty of its kanji (school grade, strokes,
    frequency), then the curated order within the theme. N3 to N1 have no
    themes yet: school grade, frequency, strokes.
    """
    import xml.etree.ElementTree as ET

    rows = []
    for _, el in ET.iterparse(path):
        if el.tag != "character":
            continue
        misc = el.find("misc")
        level = _OLD_JLPT_TO_N.get(misc.findtext("jlpt") or "")
        if level is not None:
            literal = el.findtext("literal")
            meanings = [m.text for m in el.iter("meaning")
                        if m.get("m_lang") is None and "radical" not in m.text]
            readings = lambda kind: list(dict.fromkeys(
                r.text.strip("-") for r in el.iter("reading") if r.get("r_type") == kind))
            grade = misc.findtext("grade")
            freq = misc.findtext("freq")
            rows.append((ord(literal), literal, level, int(grade) if grade else None,
                         int(misc.findtext("stroke_count")), int(freq) if freq else None,
                         "; ".join(meanings[:4]), "、".join(readings("ja_on")),
                         "、".join(readings("ja_kun"))))
        el.clear()
    rows = _split_n3_n2(rows, dict_conn)
    rows.sort(key=lambda r: (-r[2], r[3] or 99, r[4], r[5] or 9999, r[0]))
    later = [r for r in rows if r[2] <= 3]
    later.sort(key=lambda r: (-r[2], r[3] or 99, r[5] or 9999, r[4], r[0]))
    rows = [r for r in rows if r[2] >= 4]

    themes = theme_of()
    rank = {r[1]: i for i, r in enumerate(rows)}
    problems = [f"{r[1]} (N{r[2]}) has no theme" for r in rows if r[1] not in themes]
    problems += [f"{r[1]} is N{r[2]} but its theme {themes[r[1]][1]} is N{themes[r[1]][0]}"
                 for r in rows if r[1] in themes and themes[r[1]][0] != r[2]]
    problems += [f"{c} ({key}) is not a course kanji" for c, (_, key, _) in themes.items() if c not in rank]
    if problems:
        raise SystemExit("kanji_themes.py: " + "; ".join(problems))

    members: dict[str, list[int]] = {}
    for c, (_, key, _) in themes.items():
        members.setdefault(key, []).append(rank[c])
    avg = {key: sum(v) / len(v) for key, v in members.items()}
    rows.sort(key=lambda r: (-r[2], avg[themes[r[1]][1]], themes[r[1]][2]))
    themed = [(*r, themes[r[1]][1]) for r in rows] + [(*r, "") for r in later]
    return [(*r, order_no) for order_no, r in enumerate(themed, 1)]


_KANJI_BLOCK = re.compile(r'<kanji id="kvg:kanji_([0-9a-f]+)">(.*?)</kanji>', re.S)
_PATH_TAG = re.compile(r"<path\b[^>]*>")
_ATTR_ID = re.compile(r'\bid="kvg:[0-9a-f]+-s(\d+)"')
_ATTR_D = re.compile(r'\bd="([^"]+)"')


def parse_kanjivg(path: Path, wanted: set[int] | None) -> dict[int, list[tuple[int, str]]]:
    """
    Parse kanjivg.xml with regexes (the file uses kvg: attributes without a
    namespace declaration, which namespace-aware XML parsers reject).
    Variant entries (kvg:kanji_XXXXX-Kaisho etc.) are skipped by the pattern.
    """
    text = path.read_text(encoding="utf-8")
    result: dict[int, list[tuple[int, str]]] = {}
    for m in _KANJI_BLOCK.finditer(text):
        cp = int(m.group(1), 16)
        if wanted is not None and cp not in wanted:
            continue
        strokes = []
        for tag in _PATH_TAG.findall(m.group(2)):
            sid, d = _ATTR_ID.search(tag), _ATTR_D.search(tag)
            if sid and d:
                strokes.append((int(sid.group(1)), d.group(1)))
        strokes.sort()
        if strokes:
            result[cp] = strokes
    return result


def load_curriculum(conn: sqlite3.Connection, dict_conn: sqlite3.Connection | None) -> dict:
    stats = {"courses": 0, "lessons": 0, "items": 0, "missing_words": []}
    if not CURRICULUM_DIR.exists():
        return stats
    for path in sorted(CURRICULUM_DIR.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        c = data["course"]
        conn.execute("INSERT INTO courses VALUES (?, ?, ?, ?)",
                     (c["id"], c.get("jlpt_level"), c["title"], c["order_no"]))
        stats["courses"] += 1
        for lesson in data.get("lessons", []):
            conn.execute("INSERT INTO lessons VALUES (?, ?, ?, ?, ?)",
                         (lesson["id"], c["id"], lesson["order_no"], lesson["title"],
                          lesson.get("kind", "vocab")))
            stats["lessons"] += 1
            for order_no, item in enumerate(lesson.get("items", []), 1):
                conn.execute("INSERT INTO lesson_items VALUES (?, ?, ?, ?)",
                             (lesson["id"], item["type"], str(item["id"]), order_no))
                stats["items"] += 1
                if item["type"] == "word" and dict_conn is not None:
                    if not dict_conn.execute("SELECT 1 FROM words WHERE id = ?",
                                             (int(item["id"]),)).fetchone():
                        stats["missing_words"].append(f"{lesson['id']}: {item['id']}")
    return stats


GAP = "＿＿"
END_PUNCTUATION = "。！？!?"


def _check_point(p: dict, level: int) -> list[str]:
    """Problems with one grammar point, as messages."""
    errors = []
    pid = p.get("id", "?")

    def tr(v, where):
        if not (isinstance(v, dict) and all(isinstance(v.get(k), str) and v[k].strip() for k in ("id", "en"))):
            errors.append(f"{pid}: {where} needs non-empty id and en")

    if not re.fullmatch(rf"n{level}-[a-z0-9-]+", pid):
        errors.append(f"{pid}: id must look like n{level}-name")
    for key in ("pattern", "formation"):
        if not (isinstance(p.get(key), str) and p[key].strip()):
            errors.append(f"{pid}: missing {key}")
    tr(p.get("meaning"), "meaning")
    tr(p.get("explanation"), "explanation")
    examples = p.get("examples") or []
    if not examples:
        errors.append(f"{pid}: no examples")
    for i, e in enumerate(examples, 1):
        if not (e.get("ja") and e.get("kana")):
            errors.append(f"{pid}: example {i} needs ja and kana")
            continue
        tr(e.get("tr"), f"example {i} tr")
        chunks = e.get("chunks")
        if chunks is not None:
            if len(chunks) < 2 or len(set(chunks)) != len(chunks):
                errors.append(f"{pid}: example {i} needs 2+ distinct chunks")
            if "".join(chunks) != e["ja"].rstrip(END_PUNCTUATION):
                errors.append(f"{pid}: example {i} chunks {''.join(chunks)} ≠ {e['ja']}")
    if not any(e.get("chunks") for e in examples):
        errors.append(f"{pid}: no example with chunks for sentence building")
    quiz = p.get("quiz") or []
    if not quiz:
        errors.append(f"{pid}: no quiz questions")
    for i, q in enumerate(quiz, 1):
        options = q.get("options") or []
        if q.get("q", "").count(GAP) != 1:
            errors.append(f"{pid}: quiz {i} needs exactly one {GAP}")
        if not 2 <= len(options) <= 4 or len(set(options)) != len(options):
            errors.append(f"{pid}: quiz {i} needs 2 to 4 distinct options")
        if not (isinstance(q.get("answer"), int) and 0 <= q["answer"] < len(options)):
            errors.append(f"{pid}: quiz {i} answer out of range")
        tr(q.get("tr"), f"quiz {i} tr")
    return errors


def load_grammar(conn: sqlite3.Connection) -> tuple[dict[int, int], list[str]]:
    """Points per level, and problems found."""
    counts: dict[int, int] = {}
    errors: list[str] = []
    seen: set[str] = set()
    if not GRAMMAR_DIR.exists():
        return counts, errors
    for path in sorted(GRAMMAR_DIR.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        level = data["level"]
        for order_no, p in enumerate(data["points"], 1):
            problems = _check_point(p, level)
            if p.get("id") in seen:
                problems.append(f"{p.get('id')}: duplicate id")
            seen.add(p.get("id"))
            if problems:
                errors += [f"{path.name}: {m}" for m in problems]
                continue

            def dump(v):
                return json.dumps(v, ensure_ascii=False, separators=(",", ":"))

            conn.execute(
                "INSERT INTO grammar VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (p["id"], level, order_no, p["pattern"], p["formation"], dump(p["meaning"]),
                 dump(p["explanation"]), dump(p["examples"]), dump(p["quiz"])),
            )
            counts[level] = counts.get(level, 0) + 1
    return counts, errors


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--with-kanji", action="store_true",
                        help="include KanjiVG strokes for all kanji (v1.1)")
    args = parser.parse_args()

    print("=" * 50)
    print("Build content.db")
    print("=" * 50)

    kanjivg = SOURCES_DIR / "kanjivg.xml"
    if not kanjivg.exists():
        print(f"ERROR: {kanjivg} not found. Run download_sources.py first.")
        sys.exit(1)

    dict_path = OUTPUT_DIR / "dictionary.db"
    dict_conn = (sqlite3.connect(f"{dict_path.resolve().as_uri()}?mode=ro", uri=True)
                 if dict_path.exists() else None)
    if dict_conn is None:
        print("  ⚠ dictionary.db not found: example words and curriculum ids not checked")

    db_path = OUTPUT_DIR / "content.db"
    db_path.unlink(missing_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.executescript(SCHEMA)

    rows = kana_rows()
    conn.executemany(
        "INSERT INTO kana VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        [(*r, pick_example_word(dict_conn, r[1], r[2])) for r in rows],
    )
    print(f"  ✓ kana: {len(rows)} rows")

    kanjidic = SOURCES_DIR / "kanjidic2.xml"
    if not kanjidic.exists():
        print(f"ERROR: {kanjidic} not found. Run download_sources.py first.")
        sys.exit(1)
    if dict_conn is None:
        print("ERROR: dictionary.db is needed to split N3 and N2 kanji. Run the pipeline first.")
        sys.exit(1)
    course = kanji_course(kanjidic, dict_conn)
    conn.executemany("INSERT INTO kanji VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", course)
    print("  ✓ kanji: " + " + ".join(f"{sum(r[2] == n for r in course)} N{n}" for n in (5, 4, 3, 2, 1)))
    for level in (5, 4):
        order = list(dict.fromkeys(r[9] for r in course if r[2] == level))
        print(f"    N{level} themes: " + ", ".join(
            f"{t} {''.join(r[1] for r in course if r[9] == t)}" for t in order))

    kana_cps = {ord(c) for r in rows for c in r[1]}
    needed = kana_cps | {r[0] for r in course}
    strokes = parse_kanjivg(kanjivg, None if args.with_kanji else needed)
    conn.executemany(
        "INSERT INTO char_strokes VALUES (?, ?, ?)",
        [(cp, no, d) for cp, items in strokes.items() for no, d in items],
    )
    missing = sorted(chr(cp) for cp in needed - strokes.keys())
    print(f"  ✓ char_strokes: {len(strokes)} characters")
    if missing:
        print(f"  ✗ no KanjiVG data for: {' '.join(missing)}")

    cur = load_curriculum(conn, dict_conn)
    print(f"  ✓ curriculum: {cur['courses']} courses, {cur['lessons']} lessons, {cur['items']} items")
    for m in cur["missing_words"][:20]:
        print(f"  ✗ unknown word id {m}")

    grammar, grammar_errors = load_grammar(conn)
    print("  ✓ grammar: " + (" + ".join(f"{n} N{lv}" for lv, n in sorted(grammar.items(), reverse=True)) or "none"))
    for m in grammar_errors:
        print(f"  ✗ {m}")

    meta = {
        "content_version": CONTENT_VERSION,
        "build_date": datetime.now(timezone.utc).isoformat(),
        "dataset_version": (dict_conn.execute(
            "SELECT value FROM meta WHERE key = 'dataset_version'").fetchone() or [None])[0]
            if dict_conn else None,
        "attribution": "Stroke data: KanjiVG (https://kanjivg.tagaini.net), "
                       "© Ulrich Apel, CC BY-SA 3.0. Kanji data: KANJIDIC2, "
                       "© Electronic Dictionary Research and Development Group, CC BY-SA 4.0",
    }
    conn.executemany("INSERT INTO meta VALUES (?, ?)", meta.items())
    conn.commit()
    conn.execute("VACUUM")
    conn.close()
    if dict_conn:
        dict_conn.close()

    gz_path = db_path.with_name(db_path.name + ".gz")
    with open(db_path, "rb") as src, gzip.open(gz_path, "wb", compresslevel=9) as dst:
        shutil.copyfileobj(src, dst)
    digest = hashlib.sha256(gz_path.read_bytes()).hexdigest()
    gz_path.with_name("content.db.gz.sha256").write_text(f"{digest}  {gz_path.name}\n")
    print(f"\n  Output: {db_path} ({db_path.stat().st_size / 1024:.0f} KB), "
          f"{gz_path.name} ({gz_path.stat().st_size / 1024:.0f} KB)")

    if missing or cur["missing_words"] or grammar_errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
