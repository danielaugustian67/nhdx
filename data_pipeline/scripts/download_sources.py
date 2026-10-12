"""
Download source data files for the Nihondx dictionary pipeline.

Sources:
- JMdict (EDRDG): Japanese-English dictionary, CC BY-SA 4.0
- JLPT vocabulary lists (community-curated)
- KanjiVG: stroke order data for kana and kanji, CC BY-SA 3.0
- KANJIDIC2 (EDRDG): kanji meanings, readings, grade, frequency, JLPT; CC BY-SA 4.0
"""

import gzip
import io
import re
import shutil
import sys
from pathlib import Path

import requests
from tqdm import tqdm

SOURCES_DIR = Path(__file__).parent.parent / "sources"

DOWNLOADS = {
    "jmdict": {
        "url": "http://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz",
        "filename": "JMdict_e.xml",
        "description": "JMdict English dictionary (EDRDG)",
        "compressed": True,
    },
    "jmdict_full": {
        "url": "http://ftp.edrdg.org/pub/Nihongo/JMdict.gz",
        "filename": "JMdict.xml",
        "description": "JMdict full (all languages, EDRDG)",
        "compressed": True,
    },
    "kanjidic": {
        "url": "http://www.edrdg.org/kanjidic/kanjidic2.xml.gz",
        "filename": "kanjidic2.xml",
        "description": "KANJIDIC2 (EDRDG)",
        "compressed": True,
    },
}


def download_file(url: str, dest: Path, description: str, compressed: bool = False) -> None:
    """Download a file with progress bar. Decompress if gzipped."""
    if dest.exists():
        print(f"  ✓ {description} already exists: {dest.name}")
        return

    print(f"  ↓ Downloading {description}...")
    print(f"    URL: {url}")

    response = requests.get(url, stream=True, timeout=120)
    response.raise_for_status()

    total_size = int(response.headers.get("content-length", 0))

    if compressed:
        # Download to memory, then decompress
        buffer = io.BytesIO()
        with tqdm(total=total_size, unit="B", unit_scale=True, desc="    ") as pbar:
            for chunk in response.iter_content(chunk_size=8192):
                buffer.write(chunk)
                pbar.update(len(chunk))

        print("    Decompressing...")
        buffer.seek(0)
        with gzip.open(buffer, "rb") as gz_file:
            with open(dest, "wb") as out_file:
                shutil.copyfileobj(gz_file, out_file)
    else:
        with open(dest, "wb") as f:
            with tqdm(total=total_size, unit="B", unit_scale=True, desc="    ") as pbar:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
                    pbar.update(len(chunk))

    size_mb = dest.stat().st_size / (1024 * 1024)
    print(f"  ✓ Saved: {dest.name} ({size_mb:.1f} MB)")


def download_jlpt_lists() -> None:
    """
    Download community-curated JLPT vocabulary lists.
    These map word IDs to JLPT levels (N5-N1).
    
    We use the tanos.co.uk-derived lists that are commonly used
    in open-source Japanese learning projects.
    """
    jlpt_dir = SOURCES_DIR / "jlpt"
    jlpt_dir.mkdir(exist_ok=True)

    # Jonathan Waller's JLPT lists (tanos.co.uk, CC BY), with JMdict ent_seq
    # added per word by stephenmk/yomitan-jlpt-vocab.
    # CSV columns: jmdict_seq,kana,kanji,waller_definition
    base_url = "https://raw.githubusercontent.com/stephenmk/yomitan-jlpt-vocab/main/original_data"

    for level in range(5, 0, -1):
        filename = f"n{level}.csv"
        dest = jlpt_dir / filename

        if dest.exists():
            print(f"  ✓ JLPT N{level} list already exists")
            continue

        url = f"{base_url}/{filename}"
        print(f"  ↓ Downloading JLPT N{level} list...")

        try:
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            with open(dest, "wb") as f:
                f.write(response.content)
            print(f"  ✓ Saved: {filename}")
        except requests.RequestException as e:
            print(f"  ⚠ Could not download JLPT N{level}: {e}")
            print(f"    You can manually place JLPT data in: {jlpt_dir}")


KANJIVG_RELEASE_API = "https://api.github.com/repos/KanjiVG/kanjivg/releases/latest"
KANJIVG_ASSET = re.compile(r"^kanjivg-\d+\.xml\.gz$")


def download_kanjivg() -> None:
    """
    Download the single-file KanjiVG release (kanjivg-YYYYMMDD.xml.gz).
    KanjiVG is CC BY-SA 3.0 and contains both kana and kanji stroke data.
    """
    dest = SOURCES_DIR / "kanjivg.xml"
    if dest.exists():
        print(f"  ✓ KanjiVG already exists: {dest.name}")
        return

    response = requests.get(KANJIVG_RELEASE_API, timeout=30)
    response.raise_for_status()
    release = response.json()
    asset = next(
        (a for a in release.get("assets", []) if KANJIVG_ASSET.match(a["name"])),
        None,
    )
    if asset is None:
        print(f"  ⚠ No kanjivg-*.xml.gz asset in release {release.get('tag_name')}")
        print(f"    Download it manually to: {dest}")
        return

    download_file(
        url=asset["browser_download_url"],
        dest=dest,
        description=f"KanjiVG {release.get('tag_name')}",
        compressed=True,
    )


def main() -> None:
    SOURCES_DIR.mkdir(exist_ok=True)

    print("=" * 60)
    print("Nihondx Data Pipeline — Download Sources")
    print("=" * 60)

    # Determine which JMdict to download
    # JMdict_e = English only (smaller, faster to parse)
    # JMdict = all languages (no Indonesian; only useful for other languages)
    use_full = "--full" in sys.argv

    if use_full:
        print("\n[1/4] JMdict (full, all languages)")
        info = DOWNLOADS["jmdict_full"]
    else:
        print("\n[1/4] JMdict (English only)")
        info = DOWNLOADS["jmdict"]

    download_file(
        url=info["url"],
        dest=SOURCES_DIR / info["filename"],
        description=info["description"],
        compressed=info["compressed"],
    )

    print("\n[2/4] JLPT vocabulary lists")
    download_jlpt_lists()

    print("\n[3/4] KanjiVG (stroke order for kana and kanji)")
    download_kanjivg()

    print("\n[4/4] KANJIDIC2 (kanji course)")
    info = DOWNLOADS["kanjidic"]
    download_file(info["url"], SOURCES_DIR / info["filename"], info["description"], info["compressed"])

    print("\n" + "=" * 60)
    print("Download complete!")
    print(f"Source files in: {SOURCES_DIR.resolve()}")
    print("=" * 60)


if __name__ == "__main__":
    main()
