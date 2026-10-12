"""
Download the four OFL fonts from google/fonts and subset them for bundling
(ui-design.md §4.2, development_plan.md Fase 0):

  PlusJakartaSans   UI/Latin text   variable font → static 400/500/600, Latin subset
  ZenKakuGothicNew  Japanese UI     kana + CJK punctuation + kanji used in the app
  ShipporiMincho    headwords/cards same set as Zen Kaku
  KleeOne           stroke module   kana + kanji course (content.db); --with-kanji adds the full kanji set

Kanji set = every CJK ideograph that appears in a common or JLPT-labelled
word form in dictionary.db. Rarer characters fall back to the platform font.

Output: ../assets/fonts/*.ttf, ../assets/fonts/licenses/*-OFL.txt and a size report.
"""

import argparse
import sqlite3
import sys
from pathlib import Path

import requests
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

sys.path.insert(0, str(Path(__file__).parent))
from build_content_db import kana_rows

ROOT = Path(__file__).parent.parent
SOURCES_DIR = ROOT / "sources" / "fonts"
OUTPUT_DB = ROOT / "output" / "dictionary.db"
CONTENT_DB = ROOT / "output" / "content.db"
ASSETS_DIR = ROOT.parent / "assets" / "fonts"
GOOGLE_FONTS = "https://raw.githubusercontent.com/google/fonts/main/ofl"

FONTS = {
    "PlusJakartaSans": {"dir": "plusjakartasans", "file": "PlusJakartaSans[wght].ttf", "weights": [400, 500, 600], "set": "latin"},
    "ZenKakuGothicNew": {"dir": "zenkakugothicnew", "file": "ZenKakuGothicNew-Regular.ttf", "weights": [400], "set": "jp"},
    "ShipporiMincho": {"dir": "shipporimincho", "file": "ShipporiMincho-Regular.ttf", "weights": [400], "set": "jp"},
    "KleeOne": {"dir": "kleeone", "file": "KleeOne-Regular.ttf", "weights": [400], "set": "kana"},
}

LATIN_RANGES = [
    (0x0020, 0x007E),  # ASCII
    (0x00A0, 0x017F),  # Latin-1 + Latin Extended-A (macrons ā ē ī ō ū)
    (0x2010, 0x2027),  # dashes, quotes, bullet, ellipsis
    (0x2030, 0x203A),
    (0x20AC, 0x20AC),  # €
    (0x2122, 0x2122),  # ™
]
KANA_RANGES = [
    (0x0020, 0x007E),
    (0x3000, 0x303F),  # CJK symbols & punctuation (、。「」々〆)
    (0x3040, 0x309F),  # hiragana
    (0x30A0, 0x30FF),  # katakana
    (0x31F0, 0x31FF),  # katakana phonetic extensions
    (0xFF01, 0xFF60),  # fullwidth ASCII
    (0xFF61, 0xFF9F),  # halfwidth katakana
]
WEIGHT_NAMES = {400: "Regular", 500: "Medium", 600: "SemiBold"}

# Every kana shown by the kana module (content.db) must be in the Japanese
# fonts; other gaps (unassigned codepoints, archaic ゟ ヿ) fall back silently.
APP_KANA = {ord(ch) for row in kana_rows() for ch in row[1]}


def expand(ranges: list[tuple[int, int]]) -> set[int]:
    return {cp for lo, hi in ranges for cp in range(lo, hi + 1)}


def app_kanji() -> set[int]:
    if not OUTPUT_DB.exists():
        raise SystemExit(f"ERROR: {OUTPUT_DB} not found. Run build_all.py first.")
    conn = sqlite3.connect(f"{OUTPUT_DB.resolve().as_uri()}?mode=ro", uri=True)
    rows = conn.execute("""
        SELECT f.text FROM word_forms f JOIN words w ON w.id = f.word_id
        WHERE f.kind = 'kanji' AND (w.is_common = 1 OR w.jlpt_level IS NOT NULL)
    """)
    kanji = {ord(c) for (text,) in rows for c in text if 0x3400 <= ord(c) <= 0x9FFF or 0xF900 <= ord(c) <= 0xFAFF}
    conn.close()
    return kanji


def course_kanji() -> set[int]:
    """Kanji taught by the kanji course; written and animated in Klee One."""
    if not CONTENT_DB.exists():
        raise SystemExit(f"ERROR: {CONTENT_DB} not found. Run build_content_db.py first.")
    conn = sqlite3.connect(f"{CONTENT_DB.resolve().as_uri()}?mode=ro", uri=True)
    ids = {cp for (cp,) in conn.execute("SELECT id FROM kanji")}
    conn.close()
    return ids


def download(font_dir: str, name: str) -> Path:
    dest = SOURCES_DIR / font_dir / name
    if dest.exists():
        return dest
    dest.parent.mkdir(parents=True, exist_ok=True)
    url = f"{GOOGLE_FONTS}/{font_dir}/{requests.utils.quote(name)}"
    response = requests.get(url, timeout=120)
    response.raise_for_status()
    dest.write_bytes(response.content)
    print(f"  ↓ {font_dir}/{name} ({len(response.content) / 1024:,.0f} KB)")
    return dest


def subset_font(font: TTFont, codepoints: set[int], out: Path) -> None:
    options = subset.Options()
    options.layout_features = ["*"]  # keep kerning, vertical forms, ligatures
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    options.notdef_outline = True
    options.glyph_names = False
    options.hinting = False  # mobile renderers ignore TrueType hinting; saves space
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=sorted(codepoints))
    subsetter.subset(font)
    font.save(out)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--with-kanji", action="store_true", help="add the kanji set to KleeOne (v1.1)")
    args = parser.parse_args()

    print("=" * 50)
    print("Build Fonts")
    print("=" * 50)

    kanji = app_kanji()
    sets = {
        "latin": expand(LATIN_RANGES),
        "kana": expand(KANA_RANGES) | course_kanji() | ({*kanji} if args.with_kanji else set()),
        "jp": expand(KANA_RANGES) | kanji,
    }
    print(f"  Kanji in app set: {len(kanji):,}")

    (ASSETS_DIR / "licenses").mkdir(parents=True, exist_ok=True)
    report = []
    for family, spec in FONTS.items():
        source = download(spec["dir"], spec["file"])
        license_text = download(spec["dir"], "OFL.txt").read_text(encoding="utf-8")
        # The OFL body always defines the term; only the copyright header
        # (before "This Font Software is licensed…") can declare an RFN.
        header = license_text.split("This Font Software is licensed", 1)[0]
        if "Reserved Font Name" in header:
            # OFL forbids modified (subset) versions from using a Reserved Font Name.
            raise SystemExit(f"ERROR: {family} declares a Reserved Font Name; rename before subsetting")
        (ASSETS_DIR / "licenses" / f"{family}-OFL.txt").write_text(license_text, encoding="utf-8")

        for weight in spec["weights"]:
            font = TTFont(source)
            if "fvar" in font:
                font = instancer.instantiateVariableFont(font, {"wght": weight})
            covered = set(font.getBestCmap())
            wanted = sets[spec["set"]]
            out = ASSETS_DIR / f"{family}-{WEIGHT_NAMES[weight]}.ttf"
            subset_font(font, wanted, out)
            missing = len(APP_KANA - covered) if spec["set"] != "latin" else 0
            report.append((out.name, source.stat().st_size, out.stat().st_size, len(wanted & covered), missing))

    print(f"\n  {'File':<34}{'Original':>10}{'Subset':>10}{'Glyphs':>8}")
    total = 0
    for name, original, size, glyphs, missing in report:
        total += size
        note = f"  ✗ {missing} app kana missing" if missing else ""
        print(f"  {name:<34}{original / 1024:>8,.0f}KB{size / 1024:>8,.0f}KB{glyphs:>8,}{note}")
    print(f"  {'Total bundled':<44}{total / 1024:>8,.0f}KB")
    if any(missing for *_, missing in report):
        sys.exit(1)


if __name__ == "__main__":
    main()
