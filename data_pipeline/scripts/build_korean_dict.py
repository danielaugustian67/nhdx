"""
Build korean.db, the Korean dictionary of the Kamus tab when Korean is being
learned.

Sources:
- Korean entries of English Wiktionary, as extracted by wiktextract
  (sources/korean/kaikki-korean.jsonl from kaikki.org; CC BY-SA 4.0 / GFDL):
  Hangul headwords with romanization, hanja and English senses.
- The Korean course words (content/korean/words.json): Indonesian and English
  meanings written for learners, and their topic.
- English entries of English Wiktionary (sources/english/kaikki-english.jsonl.gz,
  optional): a translation table row of an English word lists Korean and
  Indonesian words for the same sense. A Korean word outside the course gets
  those Indonesian words as gloss_id when the English word is also one of the
  Korean word's own meanings (both directions agree). Cached in
  sources/english/ko-id-pairs.json.

One row per Hangul headword: Wiktionary entries of the same word (homonyms,
parts of speech) are merged into numbered sense groups. A course word keeps
its course id (90000000 + crc32 % 10000000, as in content.db) so bookmarks and
review cards of the course and the dictionary are the same item; any other
word gets 100000000 + crc32(hangul) % 2000000000, below 2^31 like every word
id synced to Supabase.

Tables:
    words      id, hangul, romaja, romaja_search, romaja_alt, hanja, pos,
               gloss, gloss_id, senses (JSON), topic, rank
    glosses    word_id, sense_no, text  -- normalized meanings, exact search
    words_fts  FTS5 over every meaning, rowid = words.id
    meta       dataset_version, source, license, entries

Usage:
    python build_korean_dict.py
"""

import gzip
import hashlib
import json
import re
import shutil
import sqlite3
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from build_content_db import ko_word_id, syllable_romaja  # noqa: E402

ROOT = Path(__file__).parent.parent
SOURCE = ROOT / "sources" / "korean" / "kaikki-korean.jsonl"
COURSE = ROOT.parent / "content" / "korean" / "words.json"
ENGLISH = ROOT / "sources" / "english" / "kaikki-english.jsonl.gz"
PAIRS = ROOT / "sources" / "english" / "ko-id-pairs.json"
MAX_ID_WORDS = 3
OUTPUT_DIR = ROOT / "output"
DB_PATH = OUTPUT_DIR / "korean.db"

DATASET_VERSION = "1.0.1"
DICT_ID_BASE = 100_000_000
DICT_ID_SPAN = 2_000_000_000

# Parts of speech kept; characters, syllables, affixes, roots and
# romanizations are not words a learner looks up.
KEEP_POS = {
    "noun", "verb", "adj", "adv", "intj", "num", "pron", "det", "particle", "phrase", "counter", "proverb",
    "contraction", "name",
}
# Meanings a study app for all ages leaves out: vulgar or offensive senses
# and slurs (the word stays when it has other meanings).
SKIP_TAGS = {"vulgar", "offensive", "derogatory", "slur", "ethnic"}
PROFANITY = re.compile(r"\b(fuck\w*|cunt\w*|sluts?|whores?)", re.IGNORECASE)
HEADWORD = re.compile(r"^[가-힣]+( [가-힣]+)*$")
MAX_GROUPS = 6
MAX_GLOSSES = 8

SCHEMA = """
CREATE TABLE words (
  id INTEGER PRIMARY KEY,
  hangul TEXT NOT NULL,
  romaja TEXT NOT NULL,            -- Revised Romanization as pronounced
  romaja_search TEXT NOT NULL,     -- romaja, a-z only
  romaja_alt TEXT NOT NULL,        -- syllable by syllable, a-z only
  hanja TEXT,                      -- hanja spelling of the first meaning
  pos TEXT NOT NULL,               -- parts of speech, comma separated
  gloss TEXT NOT NULL,             -- short English meaning for lists
  gloss_id TEXT,                   -- Indonesian meaning (course, else translation tables)
  senses TEXT NOT NULL,            -- JSON [{"pos", "hanja", "glosses": [..]}]
  topic TEXT,                      -- course topic key, course words only
  rank INTEGER NOT NULL            -- 0 = most useful; ties in search
);
CREATE INDEX words_hangul ON words(hangul);
CREATE INDEX words_romaja ON words(romaja_search);
CREATE INDEX words_romaja_alt ON words(romaja_alt);
CREATE INDEX words_topic ON words(topic) WHERE topic IS NOT NULL;
CREATE TABLE glosses (
  word_id INTEGER NOT NULL,
  sense_no INTEGER NOT NULL,       -- 0 = first meaning
  text TEXT NOT NULL               -- normalized: lower case, no brackets
);
CREATE INDEX glosses_text ON glosses(text);
CREATE VIRTUAL TABLE words_fts USING fts5(text, content='', tokenize='unicode61 remove_diacritics 2');
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
"""

_brackets = re.compile(r"\([^)]*\)|\[[^\]]*\]")
_space = re.compile(r"\s+")
_not_latin = re.compile(r"[^a-z]")


def norm_gloss(text: str) -> str:
    return _space.sub(" ", _brackets.sub("", text.lower())).strip(" .;,")


def latin_key(text: str) -> str:
    return _not_latin.sub("", text.lower())


def letter_romaja(hangul: str) -> str:
    return "".join(syllable_romaja(ch) for ch in hangul if ch != " ")


def gloss_keys(text: str) -> set[str]:
    """Exact-search keys of one meaning: itself and, for "to eat", "eat"."""
    keys = set()
    for part in re.split(r"[;,/]", text):
        key = norm_gloss(part)
        if len(key) < 2:
            continue
        keys.add(key)
        if key.startswith("to ") and len(key) > 4:
            keys.add(key[3:])
    return keys


def read_wiktionary() -> dict[str, dict]:
    """Hangul headword → merged entry."""
    merged: dict[str, dict] = {}
    with open(SOURCE, encoding="utf-8") as f:
        for line in f:
            e = json.loads(line)
            word, pos = e.get("word", ""), e.get("pos")
            if pos not in KEEP_POS or not HEADWORD.match(word):
                continue
            glosses = []
            for sense in e.get("senses", []):
                tags = set(sense.get("tags", []))
                if "form_of" in sense or "alt_of" in sense or "no-gloss" in tags or tags & SKIP_TAGS:
                    continue
                text = (sense.get("glosses") or [""])[-1].strip()
                if PROFANITY.search(text):
                    continue
                if text and text not in glosses:
                    glosses.append(text)
            if not glosses:
                continue
            forms = e.get("forms", [])
            romaja = next((f["form"] for f in forms if f.get("tags") == ["romanization"]), None)
            hanja = next((f["form"] for f in forms if "hanja" in f.get("tags", [])), None)
            entry = merged.setdefault(word, {"groups": [], "romaja": None, "ipa": False})
            entry["romaja"] = entry["romaja"] or romaja
            entry["ipa"] = entry["ipa"] or any("ipa" in s for s in e.get("sounds", []))
            entry["groups"].append({"pos": pos, "hanja": hanja, "glosses": glosses[:MAX_GLOSSES]})
    return merged


def read_pairs() -> dict[str, list]:
    """Korean word → [[English word, [Indonesian words]], …] from the English
    translation tables, in the order the tables list them."""
    if not ENGLISH.exists():
        print(f"  ⚠ {ENGLISH.name} not found: no Indonesian meanings outside the course")
        return {}
    if PAIRS.exists() and PAIRS.stat().st_mtime >= ENGLISH.stat().st_mtime:
        return json.loads(PAIRS.read_text(encoding="utf-8"))
    print("  Reading English Wiktionary translation tables (a few minutes)...")
    pairs: dict[str, list] = {}
    with gzip.open(ENGLISH, "rt", encoding="utf-8") as f:
        for line in f:
            if '"ko"' not in line or '"id"' not in line:
                continue
            e = json.loads(line)
            english = e.get("word", "")
            rows = e.get("translations", []) + [t for s in e.get("senses", []) for t in s.get("translations", [])]
            by_sense: dict[str, tuple[list, list]] = {}
            for t in rows:
                code, word = t.get("code") or t.get("lang_code"), (t.get("word") or "").strip()
                if code in ("ko", "id") and word and not set(t.get("tags", [])) & SKIP_TAGS:
                    ko, ind = by_sense.setdefault(t.get("sense") or "", ([], []))
                    (ko if code == "ko" else ind).append(word)
            for ko, ind in by_sense.values():
                if not ind:
                    continue
                for word in dict.fromkeys(ko):
                    pairs.setdefault(word, []).append([english, list(dict.fromkeys(ind))])
    PAIRS.write_text(json.dumps(pairs, ensure_ascii=False), encoding="utf-8")
    return pairs


def indonesian_meaning(glosses: list[str], candidates: list) -> str | None:
    """Indonesian words whose English pivot is one of [glosses], the word's
    main meanings (a homonym's meanings would give the wrong word), the pivot
    of the earliest meaning first."""
    order: dict[str, int] = {}
    for no, gloss in enumerate(glosses):
        for key in gloss_keys(gloss):
            order.setdefault(key, no)
    picked = []
    for english, ind in sorted(
        (c for c in candidates if norm_gloss(c[0]) in order), key=lambda c: order[norm_gloss(c[0])]
    ):
        for word in ind:
            if word.lower() not in (w.lower() for w in picked) and len(picked) < MAX_ID_WORDS:
                picked.append(word)
    return "; ".join(picked) or None


def read_course() -> dict[str, dict]:
    data = json.loads(COURSE.read_text(encoding="utf-8"))
    out = {}
    for topic in data["topics"]:
        for hangul, romaja, meaning_id, meaning_en in topic["words"]:
            out.setdefault(hangul, {"romaja": romaja, "id": meaning_id, "en": meaning_en, "topic": topic["key"]})
    return out


def main() -> None:
    if not SOURCE.exists():
        print(f"ERROR: {SOURCE} not found. Run download_sources.py first.")
        sys.exit(1)
    wiki = read_wiktionary()
    course = read_course()
    pairs = read_pairs()
    print(f"  Wiktionary headwords: {len(wiki)}, course words: {len(course)}, with translations: {len(pairs)}")

    rows = []
    for hangul in sorted(set(wiki) | set(course)):
        w, c = wiki.get(hangul), course.get(hangul)
        groups = (w["groups"] if w else [])[:MAX_GROUPS]
        if not groups:
            groups = [{"pos": None, "hanja": None, "glosses": [c["en"]]}]
        romaja = (c["romaja"] if c else None) or (w and w["romaja"]) or letter_romaja(hangul)
        pos = [g["pos"] for g in groups if g["pos"]]
        rows.append({
            "hangul": hangul,
            "romaja": romaja,
            "hanja": groups[0]["hanja"],
            "pos": list(dict.fromkeys(pos)),
            "gloss": c["en"] if c else "; ".join(groups[0]["glosses"][:2]),
            "gloss_id": c["id"] if c else indonesian_meaning(groups[0]["glosses"][:2], pairs.get(hangul, [])),
            "groups": groups,
            "topic": c["topic"] if c else None,
            "ipa": bool(w and w["ipa"]),
        })

    # Course words first, then words with a pronunciation (Wiktionary's
    # better kept entries), more meanings, everyday words over names,
    # shorter words.
    rows.sort(key=lambda r: (
        r["topic"] is None,
        r["pos"] == ["name"],
        not r["ipa"],
        -sum(len(g["glosses"]) for g in r["groups"]),
        len(r["hangul"]),
        r["hangul"],
    ))

    taken: set[int] = set()
    for r in sorted(rows, key=lambda r: (r["topic"] is None, r["hangul"])):
        if r["topic"] is not None:
            wid = ko_word_id(r["hangul"])
            assert wid not in taken, f"course id collision: {r['hangul']}"
        else:
            wid = DICT_ID_BASE + zlib.crc32(r["hangul"].encode("utf-8")) % DICT_ID_SPAN
            while wid in taken:
                wid += 1
        taken.add(wid)
        r["id"] = wid

    OUTPUT_DIR.mkdir(exist_ok=True)
    DB_PATH.unlink(missing_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.executescript(SCHEMA)
    for rank, r in enumerate(rows):
        senses = [{k: v for k, v in g.items() if v} for g in r["groups"]]
        conn.execute(
            "INSERT INTO words VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
            (
                r["id"], r["hangul"], r["romaja"], latin_key(r["romaja"]), latin_key(letter_romaja(r["hangul"])),
                r["hanja"], ",".join(r["pos"]), r["gloss"], r["gloss_id"],
                json.dumps(senses, ensure_ascii=False, separators=(",", ":")), r["topic"], rank,
            ),
        )
        meanings = [gl for g in r["groups"] for gl in g["glosses"]]
        if r["gloss_id"]:
            meanings = [r["gloss_id"], r["gloss"], *meanings]
        seen = set()
        for no, text in enumerate(meanings):
            for key in gloss_keys(text) - seen:
                seen.add(key)
                conn.execute("INSERT INTO glosses VALUES (?,?,?)", (r["id"], no, key))
        conn.execute("INSERT INTO words_fts(rowid, text) VALUES (?, ?)", (r["id"], " ; ".join(meanings)))

    meta = {
        "dataset_version": DATASET_VERSION,
        "source": "English Wiktionary via kaikki.org (wiktextract; Korean entries and English translation tables); "
        "Nihondex Korean course",
        "license": "CC BY-SA 4.0 / GFDL (Wiktionary)",
        "entries": str(len(rows)),
        "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    }
    conn.executemany("INSERT INTO meta VALUES (?, ?)", meta.items())
    translated = sum(1 for r in rows if r["topic"] is None and r["gloss_id"])
    print(f"  Indonesian meanings outside the course: {translated}")
    conn.commit()
    conn.execute("VACUUM")
    conn.close()

    gz = DB_PATH.with_suffix(".db.gz")
    with open(DB_PATH, "rb") as src, gzip.open(gz, "wb", compresslevel=9) as dst:
        shutil.copyfileobj(src, dst)
    course_n = sum(1 for r in rows if r["topic"])
    print(f"  ✓ korean.db: {len(rows)} words ({course_n} course), "
          f"{DB_PATH.stat().st_size / 1048576:.1f} MB, gz {gz.stat().st_size / 1048576:.1f} MB")


if __name__ == "__main__":
    main()
