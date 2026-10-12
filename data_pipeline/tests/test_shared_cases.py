"""
Run the shared normalization/stemming/romaji cases against the Python side.
The Dart app runs the same JSON files (development_plan.md, Fase 0).

    python -m unittest discover -s tests
"""

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

from kana_to_romaji import kana_to_romaji  # noqa: E402
from textnorm import normalize_jp, normalize_latin, romaji_search, stem_id  # noqa: E402

CASES_DIR = ROOT / "shared_test_cases"
FUNCTIONS = {
    "normalize_jp": normalize_jp,
    "normalize_latin": normalize_latin,
    "romaji_search": romaji_search,
    "stem_id": stem_id,
    "kana_to_romaji": kana_to_romaji,
}


class SharedCases(unittest.TestCase):
    def test_all_case_files(self):
        files = sorted(CASES_DIR.glob("*.json"))
        self.assertTrue(files, "no shared test case files")
        for path in files:
            data = json.loads(path.read_text(encoding="utf-8"))
            for name, cases in data.items():
                if name.startswith("_"):
                    continue
                fn = FUNCTIONS[name]
                for given, expected in cases:
                    with self.subTest(file=path.name, fn=name, given=given):
                        self.assertEqual(fn(given), expected)


if __name__ == "__main__":
    unittest.main()
