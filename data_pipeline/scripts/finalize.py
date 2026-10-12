"""
Finalize the dictionary database: VACUUM, add final metadata, verify integrity.
Copies dictionary_raw.db → dictionary.db as the final output, plus
dictionary.db.gz for bundling as a Flutter asset (the app decompresses it to
the support directory on first launch, PRD §6).
"""

import gzip
import hashlib
import shutil
import sqlite3
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent.parent / "output"

DATASET_VERSION = "1.0.0"


def compute_checksum(filepath: Path) -> str:
    """Compute SHA-256 checksum of a file."""
    sha256 = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha256.update(chunk)
    return sha256.hexdigest()


def finalize(raw_db_path: Path, final_db_path: Path) -> dict:
    """
    Finalize the database:
    1. Copy raw → final
    2. VACUUM (compact)
    3. Update metadata
    4. Verify integrity
    """
    stats: dict = {}
    
    # Copy through the backup API so pages still in the raw DB's WAL are included
    print("Copying database...")
    final_db_path.unlink(missing_ok=True)
    src = sqlite3.connect(str(raw_db_path))
    dst = sqlite3.connect(str(final_db_path))
    src.backup(dst)
    dst.close()
    src.close()
    
    conn = sqlite3.connect(str(final_db_path))
    # parse_jmdict uses WAL for speed; the shipped file must be rollback-journal
    # so the app can open it read-only without creating -wal/-shm files.
    conn.execute("PRAGMA journal_mode = DELETE")

    # Get pre-VACUUM size
    pre_size = final_db_path.stat().st_size
    
    # VACUUM to compact
    print("Running VACUUM...")
    start = time.time()
    conn.execute("VACUUM")
    vacuum_time = time.time() - start
    
    post_size = final_db_path.stat().st_size
    stats["pre_vacuum_mb"] = round(pre_size / (1024 * 1024), 1)
    stats["post_vacuum_mb"] = round(post_size / (1024 * 1024), 1)
    stats["vacuum_time_s"] = round(vacuum_time, 1)
    
    # Update metadata
    print("Updating metadata...")
    build_date = datetime.now(timezone.utc).isoformat()
    
    conn.execute(
        "INSERT OR REPLACE INTO meta (key, value) VALUES ('dataset_version', ?)",
        (DATASET_VERSION,)
    )
    conn.execute(
        "INSERT OR REPLACE INTO meta (key, value) VALUES ('build_date', ?)",
        (build_date,)
    )
    conn.execute(
        "INSERT OR REPLACE INTO meta (key, value) VALUES ('source', ?)",
        ("JMdict (EDRDG), CC BY-SA 4.0",)
    )
    conn.execute(
        "INSERT OR REPLACE INTO meta (key, value) VALUES ('attribution', ?)",
        ("This application uses the JMdict dictionary file. "
         "This file is the property of the Electronic Dictionary Research and Development Group, "
         "and is used in conformance with the Group's licence. "
         "See https://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project",)
    )
    conn.commit()
    
    # Collect statistics
    print("Collecting statistics...")
    
    stats["word_count"] = conn.execute("SELECT COUNT(*) FROM words").fetchone()[0]
    stats["form_count"] = conn.execute("SELECT COUNT(*) FROM word_forms").fetchone()[0]
    stats["sense_count"] = conn.execute("SELECT COUNT(*) FROM word_senses").fetchone()[0]
    stats["common_count"] = conn.execute(
        "SELECT COUNT(*) FROM words WHERE is_common = 1"
    ).fetchone()[0]
    stats["jlpt_count"] = conn.execute(
        "SELECT COUNT(*) FROM words WHERE jlpt_level IS NOT NULL"
    ).fetchone()[0]
    
    # JLPT breakdown
    stats["jlpt_breakdown"] = {}
    for level in range(1, 6):
        count = conn.execute(
            "SELECT COUNT(*) FROM words WHERE jlpt_level = ?", (level,)
        ).fetchone()[0]
        stats["jlpt_breakdown"][f"N{level}"] = count
    
    # Verify FTS5
    stats["fts_jp_count"] = conn.execute("SELECT COUNT(*) FROM words_fts_jp").fetchone()[0]
    stats["fts_gloss_count"] = conn.execute("SELECT COUNT(*) FROM words_fts_gloss").fetchone()[0]
    stats["redirect_count"] = conn.execute("SELECT COUNT(*) FROM id_redirects").fetchone()[0]
    stats["gloss_id_count"] = conn.execute(
        "SELECT COUNT(*) FROM word_senses WHERE gloss_id IS NOT NULL"
    ).fetchone()[0]
    
    # Integrity check
    print("Verifying integrity...")
    integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
    stats["integrity"] = integrity
    
    conn.execute("PRAGMA optimize")
    conn.close()
    
    # Compute checksum
    stats["checksum"] = compute_checksum(final_db_path)
    
    # Compressed copy for the Flutter asset bundle
    gz_path = final_db_path.with_name(final_db_path.name + ".gz")
    with open(final_db_path, "rb") as src, gzip.open(gz_path, "wb", compresslevel=9) as dst:
        shutil.copyfileobj(src, dst)
    stats["gz_mb"] = round(gz_path.stat().st_size / (1024 * 1024), 1)
    stats["gz_checksum"] = compute_checksum(gz_path)

    # Store checksums alongside db
    checksum_path = final_db_path.with_suffix(".sha256")
    with open(checksum_path, "w") as f:
        f.write(f"{stats['checksum']}  {final_db_path.name}\n")
        f.write(f"{stats['gz_checksum']}  {gz_path.name}\n")

    return stats


def main() -> None:
    raw_db = OUTPUT_DIR / "dictionary_raw.db"
    final_db = OUTPUT_DIR / "dictionary.db"
    
    if not raw_db.exists():
        print("ERROR: dictionary_raw.db not found!")
        print("Run the pipeline first: python build_all.py")
        sys.exit(1)
    
    print("=" * 60)
    print("Finalize Dictionary Database")
    print("=" * 60)
    
    stats = finalize(raw_db, final_db)
    
    print("\n" + "=" * 60)
    print("Dictionary Database — Final Report")
    print("=" * 60)
    print(f"  Version:        {DATASET_VERSION}")
    print(f"  Words:          {stats['word_count']:>8,}")
    print(f"  Word forms:     {stats['form_count']:>8,}")
    print(f"  Senses:         {stats['sense_count']:>8,}")
    print(f"  Common words:   {stats['common_count']:>8,}")
    print(f"  JLPT labeled:   {stats['jlpt_count']:>8,}")
    for level, count in stats["jlpt_breakdown"].items():
        print(f"    {level}:           {count:>6,}")
    print(f"  Senses with ID: {stats['gloss_id_count']:>8,}")
    print(f"  FTS jp:         {stats['fts_jp_count']:>8,}")
    print(f"  FTS gloss:      {stats['fts_gloss_count']:>8,}")
    print(f"  ID redirects:   {stats['redirect_count']:>8,}")
    print(f"  Size (raw):     {stats['pre_vacuum_mb']:>7.1f} MB")
    print(f"  Size (final):   {stats['post_vacuum_mb']:>7.1f} MB")
    print(f"  Size (.gz):     {stats['gz_mb']:>7.1f} MB")
    print(f"  VACUUM time:    {stats['vacuum_time_s']:>7.1f}s")
    print(f"  Integrity:      {stats['integrity']}")
    print(f"  SHA-256:        {stats['checksum'][:16]}...")
    print(f"\n  Output:         {final_db.resolve()}")
    print("=" * 60)


if __name__ == "__main__":
    main()
