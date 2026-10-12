"""
Kana → Hepburn Romaji converter.

Converts hiragana and katakana strings to modified Hepburn romanization.
Used by the data pipeline to generate the `romaji` column for each word.

Features:
- Full hiragana & katakana support (including rare/archaic)
- Combination kana (きゃ, しゅ, etc.)
- Sokuon (っ) → doubled consonant
- Chōon (ー) → doubled vowel
- Katakana ↔ hiragana normalization
"""

# Hiragana → romaji mapping (base characters)
_HIRAGANA_MAP: dict[str, str] = {
    # Vowels
    "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
    # K-row
    "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
    # S-row
    "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
    # T-row
    "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
    # N-row
    "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
    # H-row
    "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
    # M-row
    "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
    # Y-row
    "や": "ya", "ゆ": "yu", "よ": "yo",
    # R-row
    "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
    # W-row
    "わ": "wa", "ゐ": "wi", "ゑ": "we", "を": "wo",
    # N
    "ん": "n",
    # Dakuten (voiced)
    "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
    "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
    "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
    "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
    "ゔ": "vu",  # ヴ normalizes to ゔ
    # Handakuten (p-sounds)
    "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
    # Small kana (used in combinations)
    "ゃ": "ya", "ゅ": "yu", "ょ": "yo",
    "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
}

# Combination kana (2-char sequences) → romaji
_HIRAGANA_COMBOS: dict[str, str] = {
    # Ki + y-row
    "きゃ": "kya", "きゅ": "kyu", "きょ": "kyo",
    # Shi + y-row
    "しゃ": "sha", "しゅ": "shu", "しょ": "sho",
    # Chi + y-row
    "ちゃ": "cha", "ちゅ": "chu", "ちょ": "cho",
    # Ni + y-row
    "にゃ": "nya", "にゅ": "nyu", "にょ": "nyo",
    # Hi + y-row
    "ひゃ": "hya", "ひゅ": "hyu", "ひょ": "hyo",
    # Mi + y-row
    "みゃ": "mya", "みゅ": "myu", "みょ": "myo",
    # Ri + y-row
    "りゃ": "rya", "りゅ": "ryu", "りょ": "ryo",
    # Gi + y-row
    "ぎゃ": "gya", "ぎゅ": "gyu", "ぎょ": "gyo",
    # Ji + y-row
    "じゃ": "ja", "じゅ": "ju", "じょ": "jo",
    # Di + y-row (rare; Hepburn writes them like じゃ)
    "ぢゃ": "ja", "ぢゅ": "ju", "ぢょ": "jo",
    # Bi + y-row
    "びゃ": "bya", "びゅ": "byu", "びょ": "byo",
    # Pi + y-row
    "ぴゃ": "pya", "ぴゅ": "pyu", "ぴょ": "pyo",
}

# Build katakana maps by shifting Unicode codepoints
# Katakana block starts at 0x30A0, hiragana at 0x3040 (offset = 0x60)
_KATAKANA_OFFSET = 0x60

# Additional katakana-only combinations (foreign words)
_KATAKANA_EXTRA: dict[str, str] = {
    "ファ": "fa", "フィ": "fi", "フェ": "fe", "フォ": "fo", "フュ": "fyu",
    "ウィ": "wi", "ウェ": "we", "ウォ": "wo",
    "ヴァ": "va", "ヴィ": "vi", "ヴ": "vu", "ヴェ": "ve", "ヴォ": "vo",
    "ティ": "ti", "ディ": "di", "トゥ": "tu", "ドゥ": "du",
    "シェ": "she", "チェ": "che", "ジェ": "je",
    "ツァ": "tsa", "ツィ": "tsi", "ツェ": "tse", "ツォ": "tso",
    "イェ": "ye",
    "クァ": "kwa", "クィ": "kwi", "クェ": "kwe", "クォ": "kwo",
    "グァ": "gwa",
    "テュ": "tyu", "デュ": "dyu",
}

# Chōon mark (katakana long vowel)
_CHOON = "ー"

# Vowel prolongation map
_LAST_VOWEL: dict[str, str] = {
    "a": "a", "i": "i", "u": "u", "e": "e", "o": "o",
}


def _hiragana_to_katakana(char: str) -> str:
    """Convert a single hiragana character to katakana."""
    cp = ord(char)
    if 0x3041 <= cp <= 0x3096:
        return chr(cp + _KATAKANA_OFFSET)
    return char


def _katakana_to_hiragana(char: str) -> str:
    """Convert a single katakana character to hiragana."""
    cp = ord(char)
    if 0x30A1 <= cp <= 0x30F6:
        return chr(cp - _KATAKANA_OFFSET)
    return char


def _normalize_to_hiragana(text: str) -> str:
    """Convert all katakana in text to hiragana, preserving other characters."""
    return "".join(_katakana_to_hiragana(c) for c in text)


def _is_kana(char: str) -> bool:
    """Check if a character is hiragana or katakana."""
    cp = ord(char)
    return (
        (0x3040 <= cp <= 0x309F)  # Hiragana
        or (0x30A0 <= cp <= 0x30FF)  # Katakana
        or char == _CHOON
    )


def _is_katakana(char: str) -> bool:
    """Check if a character is katakana."""
    cp = ord(char)
    return 0x30A0 <= cp <= 0x30FF or char == _CHOON


def kana_to_romaji(text: str) -> str:
    """
    Convert a kana string to Hepburn romaji.

    Args:
        text: String containing hiragana and/or katakana.
              Non-kana characters are passed through unchanged.

    Returns:
        Romanized string in modified Hepburn.

    Examples:
        >>> kana_to_romaji("たべる")
        'taberu'
        >>> kana_to_romaji("カタカナ")
        'katakana'
        >>> kana_to_romaji("がっこう")
        'gakkou'
        >>> kana_to_romaji("しんぶん")
        'shinbun'
        >>> kana_to_romaji("コーヒー")
        'koohii'
    """
    if not text:
        return ""

    result: list[str] = []
    i = 0
    n = len(text)

    while i < n:
        char = text[i]

        # Handle non-kana characters (kanji, punctuation, etc.)
        if not _is_kana(char):
            result.append(char)
            i += 1
            continue

        # Handle chōon mark (ー) — prolong the previous vowel
        if char == _CHOON:
            last_romaji = result[-1] if result else ""
            if last_romaji and last_romaji[-1] in _LAST_VOWEL:
                result.append(_LAST_VOWEL[last_romaji[-1]])
            else:
                result.append("-")  # no vowel to prolong (e.g. the entry "ー" itself)
            i += 1
            continue

        # Handle sokuon (っ/ッ) — double the next consonant
        hiragana_char = _katakana_to_hiragana(char)
        if hiragana_char == "っ":
            # Look ahead to get the next consonant
            if i + 1 < n and _is_kana(text[i + 1]) and text[i + 1] != _CHOON:
                next_hiragana = _katakana_to_hiragana(text[i + 1])

                # Determine what romaji the next character(s) produce
                # to decide which consonant to double
                next_romaji = _HIRAGANA_MAP.get(next_hiragana, "")

                # Check 2-char combo first (e.g., っちゃ → tcha)
                if i + 2 < n:
                    next_two = next_hiragana + _katakana_to_hiragana(text[i + 2])
                    combo_romaji = _HIRAGANA_COMBOS.get(next_two)
                    if combo_romaji:
                        # For ch-/sh- combos, double with 't'/'s' respectively
                        # っちゃ → tcha, っしゃ → ssha
                        if combo_romaji.startswith("ch"):
                            result.append("t")
                        else:
                            result.append(combo_romaji[0])
                        i += 1
                        continue

                # Single character: determine consonant to double
                if next_romaji == "chi":
                    result.append("t")    # っち → tchi
                elif next_romaji == "tsu":
                    result.append("t")    # っつ → ttsu
                elif next_romaji == "shi":
                    result.append("s")    # っし → sshi
                elif next_romaji and next_romaji[0] not in "aiueo":
                    result.append(next_romaji[0])  # Double the consonant
                else:
                    result.append("っ")
            else:
                result.append("っ")
            i += 1
            continue

        # Check katakana-specific combinations first
        if _is_katakana(char) and i + 1 < n:
            kata_two = char + text[i + 1]
            if kata_two in _KATAKANA_EXTRA:
                result.append(_KATAKANA_EXTRA[kata_two])
                i += 2
                continue

        # Check 2-char hiragana combinations
        if i + 1 < n:
            hiragana_two = hiragana_char + _katakana_to_hiragana(text[i + 1])
            combo_romaji = _HIRAGANA_COMBOS.get(hiragana_two)
            if combo_romaji:
                result.append(combo_romaji)
                i += 2
                continue

        # Single character lookup
        romaji = _HIRAGANA_MAP.get(hiragana_char)
        if romaji:
            # Special handling for ん:
            # - Before vowels or ya/yu/yo: use n' to disambiguate
            # - Before n-row consonants (な行): use n' to disambiguate
            if hiragana_char == "ん" and i + 1 < n:
                next_h = _katakana_to_hiragana(text[i + 1])
                if next_h in ("あ", "い", "う", "え", "お", "や", "ゆ", "よ",
                              "な", "に", "ぬ", "ね", "の"):
                    result.append("n'")
                    i += 1
                    continue

            result.append(romaji)
        else:
            # Unknown kana — pass through
            result.append(char)

        i += 1

    return "".join(result)


def katakana_to_hiragana(text: str) -> str:
    """Convert all katakana in a string to hiragana."""
    return _normalize_to_hiragana(text)


def hiragana_to_katakana(text: str) -> str:
    """Convert all hiragana in a string to katakana."""
    return "".join(_hiragana_to_katakana(c) for c in text)


if __name__ == "__main__":
    # Quick test
    test_cases = [
        ("たべる", "taberu"),
        ("カタカナ", "katakana"),
        ("がっこう", "gakkou"),
        ("しんぶん", "shinbun"),
        ("コーヒー", "koohii"),
        ("きょう", "kyou"),
        ("ちゃ", "cha"),
        ("おんな", "on'na"),
        ("しんあい", "shin'ai"),
        ("じゃ", "ja"),
        ("っし", "sshi"),
        ("ファイル", "fairu"),
        ("パーティー", "paatii"),
        ("まっちゃ", "matcha"),
        ("つづく", "tsuzuku"),
        ("はなぢ", "hanaji"),
    ]

    print("Kana → Romaji converter test:")
    all_pass = True
    for kana, expected in test_cases:
        got = kana_to_romaji(kana)
        status = "✓" if got == expected else "✗"
        if got != expected:
            all_pass = False
        print(f"  {status} {kana} → {got} (expected: {expected})")

    print(f"\n{'All tests passed!' if all_pass else 'Some tests FAILED!'}")
