import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Text normalization shared with the data pipeline
/// (`data_pipeline/scripts/textnorm.py`). Both sides must produce identical
/// output; they run the same cases in `data_pipeline/shared_test_cases/`.

final _whitespace = RegExp(r'\s+');
final _combiningMarks = RegExp(r'\p{Mn}', unicode: true);
final _romajiMarks = RegExp(r"['\-]");

/// Katakana → hiragana (ァ..ヶ, same range as the pipeline).
String katakanaToHiragana(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    out.writeCharCode(rune >= 0x30A1 && rune <= 0x30F6 ? rune - 0x60 : rune);
  }
  return out.toString();
}

/// Hiragana → katakana (ぁ..ゖ).
String hiraganaToKatakana(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    out.writeCharCode(rune >= 0x3041 && rune <= 0x3096 ? rune + 0x60 : rune);
  }
  return out.toString();
}

/// NFKC → katakana→hiragana → ぢ/づ→じ/ず → lowercase → collapsed whitespace.
/// Matches `word_forms.norm_text`. ぢ/づ are folded because a romaji query
/// ("tsuzuku", "hanaji") cannot distinguish them from じ/ず.
String normalizeJp(String? text) {
  if (text == null || text.isEmpty) return '';
  final folded = katakanaToHiragana(unorm.nfkc(text)).replaceAll('ぢ', 'じ').replaceAll('づ', 'ず').toLowerCase();
  return folded.replaceAll(_whitespace, ' ').trim();
}

/// NFKC → lowercase → strip diacritics → collapsed whitespace.
String normalizeLatin(String? text) {
  if (text == null || text.isEmpty) return '';
  // NFKC/NFD leave ASCII unchanged; skipping them keeps ranking fast (unorm
  // is pure Dart and runs for every gloss item of every candidate).
  if (_isAscii(text)) return text.toLowerCase().replaceAll(_whitespace, ' ').trim();
  final lowered = unorm.nfkc(text).toLowerCase();
  final stripped = unorm.nfd(lowered).replaceAll(_combiningMarks, '');
  return stripped.replaceAll(_whitespace, ' ').trim();
}

bool _isAscii(String s) {
  for (var i = 0; i < s.length; i++) {
    if (s.codeUnitAt(i) > 0x7F) return false;
  }
  return true;
}

/// Romaji as users type it: no apostrophes or hyphens (kept if nothing else
/// remains). Matches `words.romaji_search`.
String romajiSearch(String? romaji) {
  final norm = normalizeLatin(romaji);
  final stripped = norm.replaceAll(_romajiMarks, '');
  return stripped.isEmpty ? norm : stripped;
}

final _japanese = RegExp(r'[぀-ヿ㐀-鿿ｦ-ﾟ]');

/// True when the text contains kana or kanji (input came from a Japanese IME
/// or was pasted), so the romaji converter must be skipped (PRD F1.1b).
bool hasJapanese(String text) => _japanese.hasMatch(text);
