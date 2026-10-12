"""
Text normalization shared by the pipeline (build time) and the app (query time).

The Dart implementation in the app MUST produce identical output. Both sides
run the cases in `data_pipeline/shared_test_cases/*.json` (PRD §7, F1.2).

- normalize_jp:     NFKC → katakana→hiragana → ぢ/づ→じ/ず → lowercase → trim
                    (used for word_forms.norm_text and Japanese queries)
- normalize_latin:  NFKC → lowercase → strip diacritics → collapse whitespace
                    (used for gloss text and Latin queries)
- romaji_search:    romaji without disambiguation marks ("on'na" → "onna")
- stem_id:          Indonesian stemming (Sastrawi / Nazief-Adriani)
"""

import re
import sys
import unicodedata
from functools import lru_cache
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from kana_to_romaji import katakana_to_hiragana

_WHITESPACE = re.compile(r"\s+")
_ROMAJI_MARKS = re.compile(r"['\-]")
_WORD = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")


_FOLD_JP = str.maketrans({"ぢ": "じ", "づ": "ず"})


def normalize_jp(text: str | None) -> str:
    """
    Normalize Japanese text for exact/prefix matching.

    ぢ/づ are folded to じ/ず: they sound the same, and a romaji query
    ("tsuzuku", "hanaji") cannot tell them apart.
    """
    if not text:
        return ""
    text = unicodedata.normalize("NFKC", text)
    text = katakana_to_hiragana(text).translate(_FOLD_JP)
    return _WHITESPACE.sub(" ", text.lower()).strip()


def normalize_latin(text: str | None) -> str:
    """Normalize Latin text (English/Indonesian glosses, romaji)."""
    if not text:
        return ""
    text = unicodedata.normalize("NFKC", text).lower()
    decomposed = unicodedata.normalize("NFD", text)
    text = "".join(c for c in decomposed if unicodedata.category(c) != "Mn")
    return _WHITESPACE.sub(" ", text).strip()


def romaji_search(romaji: str | None) -> str:
    """Romaji as users type it: no apostrophes or hyphens (kept if nothing else remains)."""
    norm = normalize_latin(romaji)
    return _ROMAJI_MARKS.sub("", norm) or norm


@lru_cache(maxsize=1)
def _stemmer():
    try:
        from Sastrawi.Stemmer.StemmerFactory import StemmerFactory
    except ImportError as e:
        raise SystemExit(
            "PySastrawi is required for Indonesian stemming: pip install -r requirements.txt"
        ) from e
    return StemmerFactory().create_stemmer()


@lru_cache(maxsize=200_000)
def _stem_word(word: str) -> str:
    return _stemmer().stem(word)


def stem_id(text: str | None) -> str:
    """Stem every word of an Indonesian gloss ("memakan nasi" → "makan nasi")."""
    norm = normalize_latin(text)
    # Replace each word in place so separators and spacing are preserved.
    return _WORD.sub(lambda m: _stem_word(m.group()), norm)
