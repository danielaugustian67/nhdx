"""
Hangul stroke composition (scripts/hangul_strokes.py).

    python -m unittest discover -s tests
"""

import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "scripts"))

from hangul_strokes import BOX, FINALS, INITIALS, JAMO, VOWELS, decompose, place, strokes  # noqa: E402


def points(path: str) -> list[tuple[float, float]]:
    nums = [float(n) for n in re.findall(r"-?\d+(?:\.\d+)?", path)]
    return list(zip(nums[::2], nums[1::2]))


class HangulStrokesTest(unittest.TestCase):
    def test_every_jamo_is_drawn(self):
        for ch in INITIALS + VOWELS:
            self.assertIn(ch, JAMO, ch)
            for p in JAMO[ch]:
                self.assertRegex(p, r"^M[^MLC]+( ?[LC][^MLC]+)*$", ch)

    def test_decompose(self):
        self.assertEqual(decompose("가"), ("ㄱ", "ㅏ", ""))
        self.assertEqual(decompose("각"), ("ㄱ", "ㅏ", "ㄱ"))
        self.assertEqual(decompose("와"), ("ㅇ", "ㅘ", ""))
        self.assertEqual(decompose("힣"), ("ㅎ", "ㅣ", "ㅎ"))
        with self.assertRaises(ValueError):
            decompose("a")

    def test_place_scales_into_the_region(self):
        self.assertEqual(place("M0,0 L109,109", (10, 20, 30, 40)), "M10,20 L30,40")

    def test_syllables_stay_in_the_box_and_keep_stroke_counts(self):
        simple_finals = [f for f in FINALS if f in JAMO]
        for initial in INITIALS:
            for vowel in VOWELS:
                for final in ["", *simple_finals]:
                    n = 0xAC00 + (INITIALS.index(initial) * 21 + VOWELS.index(vowel)) * 28 + FINALS.index(final)
                    ch = chr(n)
                    paths = strokes(ch)
                    expected = len(JAMO[initial]) + len(JAMO[vowel]) + (len(JAMO[final]) if final else 0)
                    self.assertEqual(len(paths), expected, ch)
                    for p in paths:
                        for x, y in points(p):
                            self.assertTrue(0 <= x <= BOX and 0 <= y <= BOX, f"{ch} {x},{y}")

    def test_cluster_finals_are_reported(self):
        with self.assertRaises(ValueError):
            strokes("닭")  # ㄺ


if __name__ == "__main__":
    unittest.main()
