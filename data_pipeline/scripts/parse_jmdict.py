"""
Parse JMdict XML and insert into SQLite database.

JMdict XML structure (simplified):
<JMdict>
  <entry>
    <ent_seq>1000000</ent_seq>
    <k_ele>                          <!-- kanji element (0 or more) -->
      <keb>食べる</keb>               <!-- kanji writing -->
      <ke_pri>ichi1</ke_pri>         <!-- priority tag -->
    </k_ele>
    <r_ele>                          <!-- reading element (1 or more) -->
      <reb>たべる</reb>               <!-- kana reading -->
      <re_pri>ichi1</re_pri>
    </r_ele>
    <sense>                          <!-- sense/meaning (1 or more) -->
      <pos>&v1;</pos>                <!-- part of speech -->
      <gloss>to eat</gloss>          <!-- English meaning -->
      <gloss xml:lang="dut">eten</gloss>  <!-- other language -->
    </sense>
  </entry>
</JMdict>

Output: words, word_forms, word_senses tables in SQLite.
"""

import re
import sqlite3
import sys
import time
from pathlib import Path
from xml.etree.ElementTree import iterparse

# Add scripts dir to path for imports
sys.path.insert(0, str(Path(__file__).parent))
from kana_to_romaji import kana_to_romaji

SOURCES_DIR = Path(__file__).parent.parent / "sources"
OUTPUT_DIR = Path(__file__).parent.parent / "output"

# Priority tags that indicate a "common" word in JMdict
# news1/news2: appears in Mainichi Shimbun word frequency list
# ichi1/ichi2: appears in "Ichimango goi bunruishuu" (common words)
# spec1/spec2: special common words
# nf01-nf48: frequency ranking (nf01 = top 500 pairs, nf48 = rank 23501-24000)
COMMON_PRIORITY_TAGS = {"news1", "ichi1", "spec1", "spec2"}
ALL_PRIORITY_TAGS = COMMON_PRIORITY_TAGS | {"news2", "ichi2"} | {
    f"nf{i:02d}" for i in range(1, 49)
}

# Part of speech entity mapping (JMdict uses XML entities for POS)
# These are resolved by the XML parser when entities are defined in the DTD.
# We keep a mapping for our internal use.
POS_VERB_GROUPS = {
    # Godan (五段) = Group 1
    "Godan verb with 'u' ending": "godan",
    "Godan verb with 'tsu' ending": "godan",
    "Godan verb with 'ru' ending": "godan",
    "Godan verb with 'ku' ending": "godan",
    "Godan verb with 'gu' ending": "godan",
    "Godan verb with 'bu' ending": "godan",
    "Godan verb with 'mu' ending": "godan",
    "Godan verb with 'nu' ending": "godan",
    "Godan verb with 'su' ending": "godan",
    "Godan verb with 'ru' ending (irregular verb)": "godan",
    # Ichidan (一段) = Group 2
    "Ichidan verb": "ichidan",
    "Ichidan verb - zuru verb (alternative form of -jiru verbs)": "ichidan",
    "Ichidan verb - kureru special class": "ichidan",
    # Irregular = Group 3
    "suru verb - included": "irregular",
    "suru verb - special class": "irregular",
    "Kuru verb - special class": "irregular",
    "suru verb": "irregular",
    "kuru verb": "irregular",
}

ADJ_TYPES = {
    "adjective (keiyoushi)": "i",
    "adjective (keiyoushi) - yoi/ii class": "i",
    "adjectival nouns or quasi-adjectives (keiyodoshi)": "na",
    "'taru' adjective": "taru",
    "nouns which may take the genitive case particle 'no'": "no",
}


_ENTITY = re.compile(r'<!ENTITY\s+(\S+)\s+"([^"]*)">')


def _load_entities(xml_path: Path) -> dict[str, str]:
    """Read <!ENTITY code "label"> declarations from the JMdict DTD header."""
    header = []
    with open(xml_path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("<JMdict>"):
                break
            header.append(line)
    return dict(_ENTITY.findall("".join(header)))


def _extract_freq_rank(priority_tags: list[str]) -> int | None:
    """Extract numeric frequency rank from nfXX priority tags."""
    for tag in priority_tags:
        m = re.match(r"nf(\d{2})", tag)
        if m:
            # nf01 = 1-500 pairs, so midpoint; lower = more common
            return int(m.group(1)) * 500
    return None


def _determine_verb_group(pos_list: list[str]) -> str | None:
    """Determine verb group from list of POS strings."""
    for pos in pos_list:
        for pattern, group in POS_VERB_GROUPS.items():
            if pattern.lower() in pos.lower():
                return group
    return None


def _determine_adj_type(pos_list: list[str]) -> str | None:
    """Determine adjective type from list of POS strings."""
    for pos in pos_list:
        for pattern, adj_type in ADJ_TYPES.items():
            if pattern.lower() in pos.lower():
                return adj_type
    return None


def parse_jmdict(xml_path: Path, db_path: Path) -> dict:
    """
    Parse JMdict XML and create SQLite database.

    Returns:
        dict with statistics about the parsing.
    """
    print(f"Parsing: {xml_path.name}")
    print(f"Output:  {db_path.name}")

    # Create/overwrite database
    if db_path.exists():
        db_path.unlink()

    conn = sqlite3.connect(str(db_path))
    conn.execute("PRAGMA journal_mode = WAL")
    conn.execute("PRAGMA synchronous = NORMAL")
    conn.execute("PRAGMA foreign_keys = ON")

    # Create tables matching PRD §9.A schema
    conn.executescript("""
        CREATE TABLE words (
            id            INTEGER PRIMARY KEY,
            primary_kanji TEXT,
            primary_kana  TEXT NOT NULL,
            romaji        TEXT NOT NULL,
            romaji_search TEXT NOT NULL DEFAULT '',   -- filled by compute_derived.py
            jlpt_level    INTEGER,
            is_common     INTEGER NOT NULL DEFAULT 0,
            freq_rank     INTEGER,
            verb_group    TEXT,
            adj_type      TEXT
        );

        -- WITHOUT ROWID + PK on word_id: rows of one word are stored together,
        -- so no separate word_id index is needed (smaller DB, PRD §9.A).
        CREATE TABLE word_forms (
            word_id    INTEGER NOT NULL REFERENCES words(id),
            ord        INTEGER NOT NULL,              -- kanji forms first, then kana
            kind       TEXT NOT NULL CHECK (kind IN ('kanji','kana')),
            text       TEXT NOT NULL,
            norm_text  TEXT NOT NULL DEFAULT '',      -- filled by compute_derived.py
            is_common  INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (word_id, ord)
        ) WITHOUT ROWID;

        CREATE TABLE word_senses (
            word_id             INTEGER NOT NULL REFERENCES words(id),
            sense_no            INTEGER NOT NULL,
            pos                 TEXT,                 -- JMdict entity codes, e.g. 'v1;vt' (see pos_tags)
            gloss_en            TEXT NOT NULL,
            gloss_id            TEXT,
            gloss_id_stem       TEXT,                 -- filled by compute_derived.py
            gloss_id_is_machine INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (word_id, sense_no)
        ) WITHOUT ROWID;

        CREATE TABLE pos_tags (
            code     TEXT PRIMARY KEY,                -- JMdict entity name, e.g. 'v1'
            label_en TEXT NOT NULL                    -- e.g. 'Ichidan verb'
        ) WITHOUT ROWID;

        CREATE TABLE id_redirects (
            item_type TEXT NOT NULL,
            old_id    TEXT NOT NULL,
            new_id    TEXT,                           -- NULL = entry removed
            PRIMARY KEY (item_type, old_id)
        );

        CREATE TABLE meta (
            key   TEXT PRIMARY KEY,
            value TEXT
        );
    """)

    stats = {
        "entries": 0,
        "kanji_forms": 0,
        "kana_forms": 0,
        "senses": 0,
        "common_words": 0,
        "with_freq": 0,
        "verbs": 0,
        "adjectives": 0,
        "parse_time_s": 0,
    }

    start_time = time.time()

    # Parse XML iteratively (memory-efficient for large files)
    # JMdict XML uses DTD entities for POS; we need to handle entity resolution.
    # iterparse with 'end' events processes each complete element.

    entry_count = 0

    # The DTD maps entity codes to labels (<!ENTITY v1 "Ichidan verb">); the XML
    # parser expands them, so map labels back to the compact codes.
    entities = _load_entities(xml_path)
    label_to_code: dict[str, str] = {}
    for code, label in entities.items():
        label_to_code.setdefault(label, code)
    used_pos: set[str] = set()

    words_batch: list[tuple] = []
    forms_batch: list[tuple] = []
    senses_batch: list[tuple] = []

    BATCH_SIZE = 5000

    def flush_batch():
        nonlocal words_batch, forms_batch, senses_batch
        if words_batch:
            conn.executemany(
                "INSERT INTO words (id, primary_kanji, primary_kana, romaji, is_common, freq_rank, verb_group, adj_type) "
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                words_batch,
            )
            words_batch = []
        if forms_batch:
            conn.executemany(
                "INSERT INTO word_forms (word_id, ord, kind, text, is_common) VALUES (?, ?, ?, ?, ?)",
                forms_batch,
            )
            forms_batch = []
        if senses_batch:
            conn.executemany(
                "INSERT INTO word_senses (word_id, sense_no, pos, gloss_en, gloss_id) VALUES (?, ?, ?, ?, ?)",
                senses_batch,
            )
            senses_batch = []
        conn.commit()

    print("Parsing entries...")

    context = iterparse(str(xml_path), events=("end",))

    current_entry = None

    for event, elem in context:
        if elem.tag != "entry":
            continue

        entry_count += 1

        # Extract ent_seq (entry ID)
        ent_seq_el = elem.find("ent_seq")
        if ent_seq_el is None or ent_seq_el.text is None:
            elem.clear()
            continue

        ent_seq = int(ent_seq_el.text)

        # Extract kanji elements
        kanji_forms: list[dict] = []
        for k_ele in elem.findall("k_ele"):
            keb_el = k_ele.find("keb")
            if keb_el is not None and keb_el.text:
                pri_tags = [p.text for p in k_ele.findall("ke_pri") if p.text]
                is_common = 1 if any(t in COMMON_PRIORITY_TAGS for t in pri_tags) else 0
                kanji_forms.append({
                    "text": keb_el.text,
                    "is_common": is_common,
                    "pri_tags": pri_tags,
                })

        # Extract reading elements
        kana_forms: list[dict] = []
        for r_ele in elem.findall("r_ele"):
            reb_el = r_ele.find("reb")
            if reb_el is not None and reb_el.text:
                pri_tags = [p.text for p in r_ele.findall("re_pri") if p.text]
                is_common = 1 if any(t in COMMON_PRIORITY_TAGS for t in pri_tags) else 0
                kana_forms.append({
                    "text": reb_el.text,
                    "is_common": is_common,
                    "pri_tags": pri_tags,
                })

        if not kana_forms:
            elem.clear()
            continue

        # Determine primary forms
        primary_kanji = kanji_forms[0]["text"] if kanji_forms else None
        primary_kana = kana_forms[0]["text"]
        romaji = kana_to_romaji(primary_kana)

        # Determine commonality from all priority tags
        all_pri_tags = []
        for form in kanji_forms + kana_forms:
            all_pri_tags.extend(form["pri_tags"])
        is_common = 1 if any(t in COMMON_PRIORITY_TAGS for t in all_pri_tags) else 0
        freq_rank = _extract_freq_rank(all_pri_tags)

        # Extract senses
        all_pos: list[str] = []
        entry_senses: list[dict] = []

        for sense_no, sense_el in enumerate(elem.findall("sense"), 1):
            pos_texts = [p.text for p in sense_el.findall("pos") if p.text]
            if pos_texts:
                all_pos = pos_texts  # POS applies to subsequent senses if not specified

            # English glosses. JMdict has no Indonesian glosses; gloss_id is
            # filled later from the curated translation files (PRD §7).
            en_glosses = []
            for gloss_el in sense_el.findall("gloss"):
                lang = gloss_el.get("{http://www.w3.org/XML/1998/namespace}lang", "eng")
                if gloss_el.text and lang == "eng":
                    en_glosses.append(gloss_el.text)

            if en_glosses:
                codes = [label_to_code.get(p, p) for p in all_pos]
                used_pos.update(codes)
                entry_senses.append({
                    "sense_no": sense_no,
                    "pos_labels": list(all_pos),
                    "pos": ";".join(codes) if codes else None,
                    "gloss_en": "; ".join(en_glosses),
                    "gloss_id": None,
                })

        if not entry_senses:
            elem.clear()
            continue

        # Verb group / adjective type come from the first (main) sense
        verb_group = _determine_verb_group(entry_senses[0]["pos_labels"])
        adj_type = _determine_adj_type(entry_senses[0]["pos_labels"])

        # Add to batch
        words_batch.append((
            ent_seq, primary_kanji, primary_kana, romaji,
            is_common, freq_rank, verb_group, adj_type,
        ))

        # Add word forms (kanji first, then kana)
        forms = [("kanji", f) for f in kanji_forms] + [("kana", f) for f in kana_forms]
        for ord_no, (kind, form) in enumerate(forms, 1):
            forms_batch.append((ent_seq, ord_no, kind, form["text"], form["is_common"]))
        stats["kanji_forms"] += len(kanji_forms)
        stats["kana_forms"] += len(kana_forms)

        # Add senses
        for sense in entry_senses:
            senses_batch.append((
                ent_seq, sense["sense_no"],
                sense["pos"], sense["gloss_en"], sense["gloss_id"],
            ))
            stats["senses"] += 1

        # Update stats
        stats["entries"] += 1
        if is_common:
            stats["common_words"] += 1
        if freq_rank:
            stats["with_freq"] += 1
        if verb_group:
            stats["verbs"] += 1
        if adj_type:
            stats["adjectives"] += 1

        # Flush batch periodically
        if entry_count % BATCH_SIZE == 0:
            flush_batch()
            print(f"  Processed {entry_count} entries...", end="\r")

        # Free memory
        elem.clear()

    # Final flush
    flush_batch()

    # POS code → label lookup (labels translated to Indonesian in the app)
    conn.executemany(
        "INSERT INTO pos_tags (code, label_en) VALUES (?, ?)",
        [(code, entities.get(code, code)) for code in sorted(used_pos)],
    )

    # Search indexes are built by build_indexes.py. Only the browse-by-level
    # index lives here; it is partial because ~96% of words have no JLPT level.
    print("\nCreating indexes...")
    conn.execute(
        "CREATE INDEX idx_words_jlpt ON words(jlpt_level) WHERE jlpt_level IS NOT NULL"
    )

    stats["parse_time_s"] = round(time.time() - start_time, 1)

    # Insert metadata
    conn.execute(
        "INSERT INTO meta (key, value) VALUES ('source', 'JMdict (EDRDG)')"
    )
    conn.execute(
        "INSERT INTO meta (key, value) VALUES ('build_date', datetime('now'))"
    )
    conn.execute(
        "INSERT INTO meta (key, value) VALUES ('entry_count', ?)",
        (str(stats["entries"]),),
    )
    conn.commit()

    conn.execute("PRAGMA optimize")
    conn.close()

    return stats


def print_stats(stats: dict) -> None:
    """Print parsing statistics."""
    print("\n" + "=" * 50)
    print("JMdict Parse Statistics")
    print("=" * 50)
    print(f"  Entries:       {stats['entries']:>8,}")
    print(f"  Kanji forms:   {stats['kanji_forms']:>8,}")
    print(f"  Kana forms:    {stats['kana_forms']:>8,}")
    print(f"  Senses:        {stats['senses']:>8,}")
    print(f"  Common words:  {stats['common_words']:>8,}")
    print(f"  With freq:     {stats['with_freq']:>8,}")
    print(f"  Verbs:         {stats['verbs']:>8,}")
    print(f"  Adjectives:    {stats['adjectives']:>8,}")
    print(f"  Parse time:    {stats['parse_time_s']:>7.1f}s")
    print("=" * 50)


def main() -> None:
    OUTPUT_DIR.mkdir(exist_ok=True)

    # Determine which JMdict file to use
    jmdict_full = SOURCES_DIR / "JMdict.xml"
    jmdict_en = SOURCES_DIR / "JMdict_e.xml"

    if jmdict_full.exists():
        xml_path = jmdict_full
        print("Using JMdict full (all languages)")
    elif jmdict_en.exists():
        xml_path = jmdict_en
        print("Using JMdict English-only")
    else:
        print("ERROR: No JMdict XML file found!")
        print(f"  Expected at: {jmdict_full}")
        print(f"  Or:          {jmdict_en}")
        print("  Run download_sources.py first.")
        sys.exit(1)

    db_path = OUTPUT_DIR / "dictionary_raw.db"

    stats = parse_jmdict(xml_path, db_path)
    print_stats(stats)

    db_size_mb = db_path.stat().st_size / (1024 * 1024)
    print(f"\nOutput: {db_path} ({db_size_mb:.1f} MB)")


if __name__ == "__main__":
    main()
