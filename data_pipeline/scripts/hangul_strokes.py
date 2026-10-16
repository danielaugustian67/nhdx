"""
Stroke order for Hangul, in the KanjiVG 109×109 box the app already uses
for kana and kanji (char_strokes; the stroke scorer compares start, end
and shape of each stroke in order).

The 40 basic jamo are drawn by hand below, one SVG path per stroke in the
standard order (top to bottom, left to right; ㅇ counter-clockwise from the
top). Double consonants are two copies side by side. A syllable block
(가, 각, 와) is composed from its jamo, each scaled into its place: the
initial left of a vertical vowel (ㅏ) or above a horizontal one (ㅗ), a
final consonant below.

Paths use only absolute M, L and C so they can be scaled point by point.
"""

import re

# Basic jamo, full box. Each stroke: SVG path with absolute M / L / C.
JAMO: dict[str, list[str]] = {
    # Consonants
    "ㄱ": ["M22,26 L84,26 C84,52 76,74 56,92"],
    "ㄴ": ["M26,22 L26,84 L88,84"],
    "ㄷ": ["M24,24 L84,24", "M26,24 L26,84 L88,84"],
    "ㄹ": ["M24,20 L82,20 L82,50", "M24,50 L82,50", "M24,50 L24,88 L86,88"],
    "ㅁ": ["M26,24 L26,88", "M26,24 L84,24 L84,88", "M26,88 L84,88"],
    "ㅂ": ["M28,18 L28,88", "M80,18 L80,88", "M28,52 L80,52", "M28,88 L80,88"],
    "ㅅ": ["M56,18 C50,50 38,72 18,90", "M56,44 C66,64 78,78 92,90"],
    "ㅇ": ["M55,20 C34,20 20,36 20,55 C20,74 34,90 55,90 C76,90 90,74 90,55 C90,36 76,20 55,20"],
    "ㅈ": ["M22,24 L80,24 C68,52 46,76 18,92", "M56,52 C66,68 78,80 92,90"],
    "ㅊ": ["M52,10 L56,24", "M22,32 L80,32 C68,58 46,78 18,94", "M56,58 C66,72 78,84 92,94"],
    "ㅋ": ["M22,24 L84,24 C84,52 76,74 56,92", "M28,56 L82,56"],
    "ㅌ": ["M24,22 L84,22", "M24,52 L80,52", "M26,22 L26,86 L88,86"],
    "ㅍ": ["M18,24 L90,24", "M38,24 L38,84", "M70,24 L70,84", "M18,86 L90,86"],
    "ㅎ": [
        "M52,10 L56,22",
        "M24,34 L86,34",
        "M55,46 C44,46 35,55 35,66 C35,77 44,86 55,86 C66,86 75,77 75,66 C75,55 66,46 55,46",
    ],
    # Vowels
    "ㅏ": ["M44,10 L44,98", "M44,52 L76,52"],
    "ㅐ": ["M34,10 L34,98", "M34,52 L56,52", "M66,10 L66,98"],
    "ㅑ": ["M44,10 L44,98", "M44,40 L76,40", "M44,66 L76,66"],
    "ㅒ": ["M34,10 L34,98", "M34,40 L56,40", "M34,66 L56,66", "M66,10 L66,98"],
    "ㅓ": ["M34,52 L66,52", "M66,10 L66,98"],
    "ㅔ": ["M28,52 L48,52", "M48,10 L48,98", "M70,10 L70,98"],
    "ㅕ": ["M34,40 L66,40", "M34,66 L66,66", "M66,10 L66,98"],
    "ㅖ": ["M28,40 L48,40", "M28,66 L48,66", "M48,10 L48,98", "M70,10 L70,98"],
    "ㅗ": ["M54,40 L54,70", "M14,72 L94,72"],
    "ㅘ": ["M34,46 L34,70", "M10,72 L62,72", "M74,10 L74,98", "M74,52 L96,52"],
    "ㅙ": ["M30,46 L30,70", "M8,72 L54,72", "M64,10 L64,98", "M64,52 L80,52", "M88,10 L88,98"],
    "ㅚ": ["M36,46 L36,70", "M10,72 L66,72", "M80,10 L80,98"],
    "ㅛ": ["M40,42 L40,72", "M68,42 L68,72", "M14,74 L94,74"],
    "ㅜ": ["M14,40 L94,40", "M54,40 L54,82"],
    "ㅝ": ["M8,44 L60,44", "M34,44 L34,84", "M58,60 L78,60", "M78,10 L78,98"],
    "ㅞ": ["M8,44 L54,44", "M30,44 L30,84", "M54,60 L66,60", "M66,10 L66,98", "M88,10 L88,98"],
    "ㅟ": ["M8,44 L62,44", "M34,44 L34,84", "M80,10 L80,98"],
    "ㅠ": ["M14,40 L94,40", "M40,40 L40,82", "M68,40 L68,82"],
    "ㅡ": ["M14,55 L94,55"],
    "ㅢ": ["M10,60 L64,60", "M80,10 L80,98"],
    "ㅣ": ["M54,10 L54,98"],
}

BOX = 109.0
Region = tuple[float, float, float, float]  # x0, y0, x1, y1


def place(path: str, region: Region) -> str:
    """[path] (full box) scaled into [region]."""
    x0, y0, x1, y1 = region
    sx, sy = (x1 - x0) / BOX, (y1 - y0) / BOX
    out: list[str] = []
    for cmd, args in re.findall(r"([MLC])([^MLC]*)", path):
        nums = [float(n) for n in re.findall(r"-?\d+(?:\.\d+)?", args)]
        if len(nums) % 2:
            raise ValueError(f"odd coordinates in {path!r}")
        pts = [f"{_fmt(x0 + nums[i] * sx)},{_fmt(y0 + nums[i + 1] * sy)}" for i in range(0, len(nums), 2)]
        out.append(cmd + " ".join(pts))
    return " ".join(out)


def _fmt(v: float) -> str:
    return f"{v:.2f}".rstrip("0").rstrip(".")


# Double consonants: the single one twice, side by side.
_DOUBLES = {"ㄲ": "ㄱ", "ㄸ": "ㄷ", "ㅃ": "ㅂ", "ㅆ": "ㅅ", "ㅉ": "ㅈ"}
for _double, _single in _DOUBLES.items():
    JAMO[_double] = [place(p, (0, 0, 60, BOX)) for p in JAMO[_single]] + [
        place(p, (49, 0, BOX, BOX)) for p in JAMO[_single]
    ]

INITIALS = "ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ"
VOWELS = "ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ"
# Index 0 is "no final"; clusters (ㄳ, ㄺ …) have no strokes here.
FINALS = ["", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ",
          "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]

_VERTICAL = set("ㅏㅐㅑㅒㅓㅔㅕㅖㅣ")
_HORIZONTAL = set("ㅗㅛㅜㅠㅡ")

# (initial region, vowel region) by vowel shape, without and with a final.
_LAYOUT: dict[tuple[str, bool], tuple[Region, Region]] = {
    ("vertical", False): ((6, 12, 60, 98), (44, 2, 106, 107)),
    ("horizontal", False): ((20, 2, 90, 58), (2, 40, 107, 107)),
    ("mixed", False): ((4, 2, 58, 56), (2, 8, 107, 107)),
    ("vertical", True): ((6, 6, 58, 64), (44, 0, 106, 70)),
    ("horizontal", True): ((22, 0, 88, 38), (2, 22, 107, 66)),
    ("mixed", True): ((4, 0, 58, 38), (2, 2, 107, 70)),
}
_FINAL_REGION: Region = (18, 66, 92, 107)


def decompose(syllable: str) -> tuple[str, str, str]:
    """가 → (ㄱ, ㅏ, ''), 각 → (ㄱ, ㅏ, ㄱ)."""
    n = ord(syllable) - 0xAC00
    if not 0 <= n < 11172:
        raise ValueError(f"not a Hangul syllable: {syllable}")
    return INITIALS[n // 588], VOWELS[n % 588 // 28], FINALS[n % 28]


def strokes(ch: str) -> list[str]:
    """Stroke paths of a jamo or syllable block, in writing order."""
    if ch in JAMO:
        return list(JAMO[ch])
    initial, vowel, final = decompose(ch)
    if final and final not in JAMO:
        raise ValueError(f"no strokes for the final {final} in {ch}")
    shape = "vertical" if vowel in _VERTICAL else "horizontal" if vowel in _HORIZONTAL else "mixed"
    lead, mid = _LAYOUT[(shape, bool(final))]
    out = [place(p, lead) for p in JAMO[initial]] + [place(p, mid) for p in JAMO[vowel]]
    if final:
        out += [place(p, _FINAL_REGION) for p in JAMO[final]]
    return out
