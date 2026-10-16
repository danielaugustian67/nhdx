import 'normalize.dart';

/// Kana → modified Hepburn romaji, a port of
/// data_pipeline/scripts/kana_to_romaji.py (same shared test cases): yōon
/// (きょ → kyo), sokuon (がっこう → gakkou), chōon (コーヒー → koohii) and
/// ん before a vowel, y or n written n'. Anything else passes through.
String kanaToRomaji(String text) {
  final out = StringBuffer();
  var last = '';
  void add(String s) {
    out.write(s);
    if (s.isNotEmpty) last = s;
  }

  final chars = text.split('');
  final n = chars.length;
  var i = 0;
  while (i < n) {
    final char = chars[i];
    if (!_isKana(char)) {
      add(char);
      i++;
      continue;
    }

    // ー prolongs the previous vowel.
    if (char == _choon) {
      add(last.isNotEmpty && 'aiueo'.contains(last[last.length - 1]) ? last[last.length - 1] : '-');
      i++;
      continue;
    }

    final hira = katakanaToHiragana(char);

    // っ doubles the next consonant.
    if (hira == 'っ') {
      if (i + 1 < n && _isKana(chars[i + 1]) && chars[i + 1] != _choon) {
        final next = katakanaToHiragana(chars[i + 1]);
        final nextRomaji = _map[next] ?? '';
        if (i + 2 < n) {
          final combo = _combos[next + katakanaToHiragana(chars[i + 2])];
          if (combo != null) {
            add(combo.startsWith('ch') ? 't' : combo[0]);
            i++;
            continue;
          }
        }
        if (nextRomaji == 'chi' || nextRomaji == 'tsu') {
          add('t');
        } else if (nextRomaji == 'shi') {
          add('s');
        } else if (nextRomaji.isNotEmpty && !'aiueo'.contains(nextRomaji[0])) {
          add(nextRomaji[0]);
        } else {
          add('っ');
        }
      } else {
        add('っ');
      }
      i++;
      continue;
    }

    if (_isKatakana(char) && i + 1 < n) {
      final extra = _katakanaExtra[char + chars[i + 1]];
      if (extra != null) {
        add(extra);
        i += 2;
        continue;
      }
    }

    if (i + 1 < n) {
      final combo = _combos[hira + katakanaToHiragana(chars[i + 1])];
      if (combo != null) {
        add(combo);
        i += 2;
        continue;
      }
    }

    final romaji = _map[hira];
    if (romaji == null) {
      add(char);
    } else if (hira == 'ん' && i + 1 < n && _beforeApostrophe.contains(katakanaToHiragana(chars[i + 1]))) {
      add("n'");
    } else {
      add(romaji);
    }
    i++;
  }
  return out.toString();
}

const _choon = 'ー';
const _beforeApostrophe = {'あ', 'い', 'う', 'え', 'お', 'や', 'ゆ', 'よ', 'な', 'に', 'ぬ', 'ね', 'の'};

bool _isKana(String c) {
  final cp = c.codeUnitAt(0);
  return (cp >= 0x3040 && cp <= 0x309F) || (cp >= 0x30A0 && cp <= 0x30FF) || c == _choon;
}

bool _isKatakana(String c) {
  final cp = c.codeUnitAt(0);
  return (cp >= 0x30A0 && cp <= 0x30FF) || c == _choon;
}

const _map = {
  'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o', //
  'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
  'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
  'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
  'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
  'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
  'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
  'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
  'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
  'わ': 'wa', 'ゐ': 'wi', 'ゑ': 'we', 'を': 'wo',
  'ん': 'n',
  'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
  'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
  'だ': 'da', 'ぢ': 'ji', 'づ': 'zu', 'で': 'de', 'ど': 'do',
  'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
  'ゔ': 'vu',
  'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',
  'ゃ': 'ya', 'ゅ': 'yu', 'ょ': 'yo',
  'ぁ': 'a', 'ぃ': 'i', 'ぅ': 'u', 'ぇ': 'e', 'ぉ': 'o',
};

const _combos = {
  'きゃ': 'kya', 'きゅ': 'kyu', 'きょ': 'kyo', //
  'しゃ': 'sha', 'しゅ': 'shu', 'しょ': 'sho',
  'ちゃ': 'cha', 'ちゅ': 'chu', 'ちょ': 'cho',
  'にゃ': 'nya', 'にゅ': 'nyu', 'にょ': 'nyo',
  'ひゃ': 'hya', 'ひゅ': 'hyu', 'ひょ': 'hyo',
  'みゃ': 'mya', 'みゅ': 'myu', 'みょ': 'myo',
  'りゃ': 'rya', 'りゅ': 'ryu', 'りょ': 'ryo',
  'ぎゃ': 'gya', 'ぎゅ': 'gyu', 'ぎょ': 'gyo',
  'じゃ': 'ja', 'じゅ': 'ju', 'じょ': 'jo',
  'ぢゃ': 'ja', 'ぢゅ': 'ju', 'ぢょ': 'jo',
  'びゃ': 'bya', 'びゅ': 'byu', 'びょ': 'byo',
  'ぴゃ': 'pya', 'ぴゅ': 'pyu', 'ぴょ': 'pyo',
};

const _katakanaExtra = {
  'ファ': 'fa', 'フィ': 'fi', 'フェ': 'fe', 'フォ': 'fo', 'フュ': 'fyu', //
  'ウィ': 'wi', 'ウェ': 'we', 'ウォ': 'wo',
  'ヴァ': 'va', 'ヴィ': 'vi', 'ヴ': 'vu', 'ヴェ': 've', 'ヴォ': 'vo',
  'ティ': 'ti', 'ディ': 'di', 'トゥ': 'tu', 'ドゥ': 'du',
  'シェ': 'she', 'チェ': 'che', 'ジェ': 'je',
  'ツァ': 'tsa', 'ツィ': 'tsi', 'ツェ': 'tse', 'ツォ': 'tso',
  'イェ': 'ye',
  'クァ': 'kwa', 'クィ': 'kwi', 'クェ': 'kwe', 'クォ': 'kwo',
  'グァ': 'gwa',
  'テュ': 'tyu', 'デュ': 'dyu',
};

/// Romaji of a KANJIDIC reading: okurigana marks ('.', '-') and brackets are
/// kept, and a reading cut short by っ (ジッ in 十本) ends in "t": jit.
String readingToRomaji(String reading) {
  final r = kanaToRomaji(reading);
  return r.endsWith('っ') ? '${r.substring(0, r.length - 1)}t' : r;
}
