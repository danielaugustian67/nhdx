"""
Nihondx Data Pipeline — Master build script.

Runs the complete pipeline to generate dictionary.db and content.db:
 1. Download sources (JMdict, JLPT lists, KanjiVG)
 2. Parse JMdict XML → SQLite
 3. Merge JLPT levels
 4. Merge curated Indonesian translations (content/translations/id)
 5. Compute derived columns (norm_text, romaji_search, gloss_id_stem)
 6. Build search indexes (B-tree + FTS5 trigram + FTS5 unicode61)
 7. Build ID redirects against the previous release (output/previous/)
 8. Finalize dictionary.db (+ .gz, checksum)
 9. Test & benchmark dictionary.db
10. Build content.db (kana, kana strokes, curriculum)
11. Build korean.db (Korean dictionary: Wiktionary + the course words)
12. Download + subset the OFL fonts into ../assets/fonts
13. Export .gz + manifest.json to ../assets/db for the Flutter app

Usage:
    python build_all.py                  # Run full pipeline
    python build_all.py --skip-download  # Skip download step
    python build_all.py --full           # Download JMdict with all languages
"""

import subprocess
import sys
import time
from pathlib import Path

SCRIPTS_DIR = Path(__file__).parent / "scripts"

PIPELINE_STEPS = [
    {
        "name": "Download Sources",
        "script": "download_sources.py",
        "args": [],
        "skippable": True,
    },
    {
        "name": "Parse JMdict",
        "script": "parse_jmdict.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Merge JLPT Levels",
        "script": "merge_jlpt.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Merge Indonesian Translations",
        "script": "merge_translations.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Compute Derived Columns",
        "script": "compute_derived.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Build Search Indexes",
        "script": "build_indexes.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Build ID Redirects",
        "script": "build_redirects.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Finalize Database",
        "script": "finalize.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Test & Benchmark",
        "script": "test_db.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Build content.db",
        "script": "build_content_db.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Build korean.db",
        "script": "build_korean_dict.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Build fonts (subset)",
        "script": "build_fonts.py",
        "args": [],
        "skippable": False,
    },
    {
        "name": "Export Flutter assets",
        "script": "export_assets.py",
        "args": [],
        "skippable": False,
    },
]


def run_step(step: dict, extra_args: list[str]) -> bool:
    """Run a single pipeline step. Returns True if successful."""
    script_path = SCRIPTS_DIR / step["script"]

    if not script_path.exists():
        print(f"  ✗ Script not found: {script_path}")
        return False

    cmd = [sys.executable, str(script_path)] + step["args"] + extra_args
    print(f"\n{'─' * 60}")
    print(f"Running: {step['script']}")
    print(f"{'─' * 60}")

    start = time.time()
    result = subprocess.run(cmd, cwd=str(SCRIPTS_DIR.parent))
    elapsed = time.time() - start

    if result.returncode == 0:
        print(f"\n  ✓ {step['name']} completed in {elapsed:.1f}s")
        return True
    else:
        print(f"\n  ✗ {step['name']} FAILED (exit code: {result.returncode})")
        return False


def main() -> None:
    skip_download = "--skip-download" in sys.argv
    use_full = "--full" in sys.argv

    extra_args = []
    if use_full:
        extra_args.append("--full")

    print("=" * 60)
    print("Nihondx Data Pipeline — Full Build")
    print("=" * 60)

    total_start = time.time()
    failed = False

    for i, step in enumerate(PIPELINE_STEPS, 1):
        if skip_download and step["skippable"] and step["script"] == "download_sources.py":
            print(f"\n  ⏭ Skipping: {step['name']}")
            continue

        print(f"\n[{i}/{len(PIPELINE_STEPS)}] {step['name']}")

        if not run_step(step, extra_args if step["script"] == "download_sources.py" else []):
            failed = True
            print(f"\n⚠️  Pipeline stopped at step {i}: {step['name']}")
            break

    total_time = time.time() - total_start

    print(f"\n{'=' * 60}")
    if failed:
        print(f"Pipeline FAILED after {total_time:.1f}s")
    else:
        print(f"Pipeline completed successfully in {total_time:.1f}s")
        for name in ("dictionary.db", "dictionary.db.gz", "content.db.gz"):
            output = Path(__file__).parent / "output" / name
            if output.exists():
                size_mb = output.stat().st_size / (1024 * 1024)
                print(f"Output: {output.resolve()} ({size_mb:.1f} MB)")
    print("=" * 60)

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
