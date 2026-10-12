"""
Reference implementation of the app's search (PRD F1.2).

Used by test_db.py to check acceptance criteria and benchmark latency with the
same query shapes the Flutter app will run. The Dart implementation should
follow the same tiers and ordering.

Ranking (ascending tier, then tie-breakers):
  0  exact kanji/kana form (or exact romaji)
  1  prefix kanji/kana form
  2  Japanese substring (trigram, query ≥ 3 chars)
  3  meaning: a gloss item equals the query ("eat" / "to eat")
  4  romaji prefix — below exact meanings, otherwise "eat" ranks
     エアタヒチ (eatahichi) above 食べる
  5  meaning: query is a whole word in a gloss
  6  meaning: word prefix in a gloss
  tie-breakers: earliest matching sense (meaning tiers) → common first →
                easier JLPT level first (N5 before N1, unlabelled last) →
                shorter headword → freq_rank
"""

import re
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from textnorm import normalize_jp, normalize_latin, romaji_search, stem_id

MAX_CANDIDATES = 300
MIN_MEANING_LENGTH = 2         # meaning search needs ≥ 2 chars
MIN_MEANING_PREFIX_LENGTH = 3  # meaning prefix (eat*) needs a last token ≥ 3 chars
_HAS_JAPANESE = re.compile(r"[぀-ヿ㐀-鿿ｦ-ﾟ]")
_FTS_TOKEN = re.compile(r"[^\w]+", re.UNICODE)


def _prefix_bounds(text: str) -> tuple[str, str]:
    return text, text + "\U0010ffff"


def _fts_phrase(text: str) -> str:
    return '"' + text.replace('"', '""') + '"'


def _gloss_items(gloss: str) -> set[str]:
    items = set()
    for item in gloss.split(";"):
        item = re.sub(r"\(.*?\)", "", normalize_latin(item)).strip()
        if item:
            items.add(item)
            if item.startswith("to "):
                items.add(item[3:])
    return items


def search(conn: sqlite3.Connection, query: str, limit: int = 20) -> list[int]:
    """Return word ids in ranked order."""
    tiers: dict[int, int] = {}
    sense_rank: dict[int, int] = {}  # earliest sense whose gloss item equals the query

    def add(ids, tier: int) -> None:
        for (wid,) in ids:
            if tier < tiers.get(wid, 99):
                tiers[wid] = tier

    if _HAS_JAPANESE.search(query):
        q = normalize_jp(query)
        if not q:
            return []
        add(conn.execute("SELECT word_id FROM word_forms WHERE norm_text = ?", (q,)), 0)
        add(conn.execute(
            "SELECT word_id FROM word_forms WHERE norm_text >= ? AND norm_text < ? LIMIT ?",
            (*_prefix_bounds(q), MAX_CANDIDATES)), 1)
        if len(q) >= 3:
            add(conn.execute(
                "SELECT rowid FROM words_fts_jp WHERE words_fts_jp MATCH ? LIMIT ?",
                (_fts_phrase(q), MAX_CANDIDATES)), 2)
    else:
        q = normalize_latin(query)
        if not q:
            return []
        # Dual path (F1.1): Latin text is tried as romaji AND as a meaning.
        r = romaji_search(q).replace(" ", "")
        if r:
            add(conn.execute("SELECT id FROM words WHERE romaji_search = ?", (r,)), 0)
            if len(r) >= 2:
                add(conn.execute(
                    "SELECT id FROM words WHERE romaji_search >= ? AND romaji_search < ? LIMIT ?",
                    (*_prefix_bounds(r), MAX_CANDIDATES)), 4)

        tokens = [t for t in _FTS_TOKEN.split(q) if t]
        # A 1-letter meaning ("a") matches nearly every entry and BM25-ranking
        # that set is the slowest query; it is never a useful meaning search.
        if tokens and len(q) >= MIN_MEANING_LENGTH:
            stems = [t for t in _FTS_TOKEN.split(stem_id(q)) if t]
            phrase = _fts_phrase(" ".join(tokens))
            stem_phrase = _fts_phrase(" ".join(stems)) if stems else phrase
            word_match = f"({{gloss_en gloss_id}} : {phrase}) OR (gloss_id_stem : {stem_phrase})"
            word_ids = conn.execute(
                "SELECT rowid FROM words_fts_gloss WHERE words_fts_gloss MATCH ? ORDER BY rank LIMIT ?",
                (word_match, MAX_CANDIDATES)).fetchall()
            add(word_ids, 5)
            if len(tokens[-1]) >= MIN_MEANING_PREFIX_LENGTH:
                prefix_match = " ".join([*map(_fts_phrase, tokens[:-1]), _fts_phrase(tokens[-1]) + "*"])
                add(conn.execute(
                    "SELECT rowid FROM words_fts_gloss WHERE words_fts_gloss MATCH ? ORDER BY rank LIMIT ?",
                    (f"{{gloss_en gloss_id}} : ({prefix_match})", MAX_CANDIDATES)), 6)

            # Promote candidates whose gloss item equals the query exactly.
            if word_ids:
                ids = [wid for (wid,) in word_ids]
                marks = ",".join("?" * len(ids))
                for wid, sense_no, en, id_ in conn.execute(
                    f"SELECT word_id, sense_no, gloss_en, coalesce(gloss_id, '') FROM word_senses "
                    f"WHERE word_id IN ({marks})", ids):
                    if q in _gloss_items(en) or q in _gloss_items(id_):
                        tiers[wid] = min(tiers[wid], 3)
                        sense_rank[wid] = min(sense_rank.get(wid, sense_no), sense_no)

    if not tiers:
        return []

    ids = list(tiers)
    marks = ",".join("?" * len(ids))
    rows = conn.execute(
        f"SELECT id, coalesce(primary_kanji, primary_kana), is_common, jlpt_level, freq_rank "
        f"FROM words WHERE id IN ({marks})", ids).fetchall()
    rows.sort(key=lambda r: (
        tiers[r[0]],
        sense_rank.get(r[0], 0),  # primary meaning before secondary ones
        -r[2],                    # common first
        -(r[3] or 0),             # easier JLPT level first, unlabelled last
        len(r[1]),                # shorter headword
        r[4] if r[4] is not None else 1_000_000,
    ))
    return [r[0] for r in rows[:limit]]
