"""
Copy the built databases into the Flutter asset folder (PRD §6, "Siklus hidup
database lokal"):

    assets/db/dictionary.db.gz
    assets/db/content.db.gz
    assets/db/manifest.json   {"dictionary.db": {"sha256": …, "dataset_version": …}, …}

The app compares the manifest sha256 with the one recorded at install time and
re-extracts a database only when it changed.
"""

import hashlib
import json
import shutil
import sqlite3
import sys
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent.parent / "output"
ASSETS_DIR = Path(__file__).parent.parent.parent / "assets" / "db"
DATABASES = ("dictionary.db", "content.db")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> None:
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for name in DATABASES:
        db, gz = OUTPUT_DIR / name, OUTPUT_DIR / f"{name}.gz"
        if not (db.exists() and gz.exists()):
            print(f"ERROR: {gz} not found. Run the pipeline first.")
            sys.exit(1)
        conn = sqlite3.connect(f"{db.resolve().as_uri()}?mode=ro", uri=True)
        meta = dict(conn.execute("SELECT key, value FROM meta"))
        conn.close()
        shutil.copyfile(gz, ASSETS_DIR / gz.name)
        manifest[name] = {
            "asset": f"assets/db/{gz.name}",
            "sha256": sha256(gz),
            "size": gz.stat().st_size,
            "version": meta.get("dataset_version") or meta.get("content_version"),
        }
        print(f"  ✓ {gz.name} ({gz.stat().st_size / 1048576:.1f} MB)")

    (ASSETS_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"  ✓ manifest.json → {ASSETS_DIR}")


if __name__ == "__main__":
    main()
