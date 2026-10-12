import 'normalize.dart';

/// Romaji → kana converter for the search field (PRD F1.1).
///
/// Accepts Hepburn and Kunrei spellings (shi/si, chi/ti, tsu/tu, fu/hu,
/// ji/zi, sha/sya, cha/tya, ja/zya/jya), x/l-prefixed small kana, macrons and
/// `-` for ー. Incomplete trailing consonants are kept as typed ("tab" →
/// "たb") so live search works while the user is still typing.
///
/// `n` rules:
/// - `n'` → ん
/// - `nn` → ん; when followed by a vowel or `y` only one `n` is consumed, so
///   both "konnichiwa" and IME-style "konnnichiha" give こんにち…
/// - `n` before a consonant or at the end → ん
/// - `m` before `b`/`p` → ん (Hepburn "sempai", "shimbun")
abstract final class RomajiToKana {
  static String toHiragana(String input) => _convert(_expandMacrons(input.toLowerCase()));

  static String toKatakana(String input) => hiraganaToKatakana(toHiragana(input));

  static const _vowels = 'aeiou';

  // Expanded before conversion so "tō" reads as "tou" (とう).
  static const _macrons = {
    'ā': 'aa',
    'ī': 'ii',
    'ū': 'uu',
    'ē': 'ee',
    'ō': 'ou',
    'â': 'aa',
    'î': 'ii',
    'û': 'uu',
    'ê': 'ee',
    'ô': 'ou',
  };

  static String _expandMacrons(String s) {
    final out = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      out.write(_macrons[ch] ?? ch);
    }
    return out.toString();
  }

  static bool _isConsonant(String c) =>
      c.length == 1 && c.codeUnitAt(0) >= 0x61 && c.codeUnitAt(0) <= 0x7A && !_vowels.contains(c);

  static String _convert(String s) {
    final out = StringBuffer();
    var i = 0;
    while (i < s.length) {
      final c = s[i];
      final next = i + 1 < s.length ? s[i + 1] : '';
      final after = i + 2 < s.length ? s[i + 2] : '';

      if (c == '-') {
        out.write('ー');
        i++;
        continue;
      }

      if (c == 'n') {
        if (next == "'") {
          out.write('ん');
          i += 2;
          continue;
        }
        if (next == 'n') {
          out.write('ん');
          // "nna" → ん + な; "nn" + consonant/end → ん
          i += (_vowels.contains(after) && after.isNotEmpty) || after == 'y' ? 1 : 2;
          continue;
        }
        if (next.isEmpty || (_isConsonant(next) && next != 'y')) {
          out.write('ん');
          i++;
          continue;
        }
      }
      if (c == 'm' && (next == 'b' || next == 'p')) {
        out.write('ん');
        i++;
        continue;
      }

      // Sokuon: doubled consonant (kk, tt, ss, pp…) or "tch" (matcha)
      if (_isConsonant(c) && c != 'n' && (next == c || (c == 't' && next == 'c' && after == 'h'))) {
        out.write('っ');
        i++;
        continue;
      }

      var matched = false;
      for (var len = 4; len >= 1; len--) {
        if (i + len > s.length) continue;
        final kana = _table[s.substring(i, i + len)];
        if (kana != null) {
          out.write(kana);
          i += len;
          matched = true;
          break;
        }
      }
      if (!matched) {
        out.write(c); // incomplete consonant, digit, space, punctuation…
        i++;
      }
    }
    return out.toString();
  }

  static const _table = <String, String>{
    'a': 'あ',
    'i': 'い',
    'u': 'う',
    'e': 'え',
    'o': 'お',
    'ka': 'か',
    'ki': 'き',
    'ku': 'く',
    'ke': 'け',
    'ko': 'こ',
    'kya': 'きゃ',
    'kyu': 'きゅ',
    'kyo': 'きょ',
    'ga': 'が',
    'gi': 'ぎ',
    'gu': 'ぐ',
    'ge': 'げ',
    'go': 'ご',
    'gya': 'ぎゃ',
    'gyu': 'ぎゅ',
    'gyo': 'ぎょ',
    'sa': 'さ',
    'shi': 'し',
    'si': 'し',
    'su': 'す',
    'se': 'せ',
    'so': 'そ',
    'sha': 'しゃ',
    'shu': 'しゅ',
    'sho': 'しょ',
    'she': 'しぇ',
    'sya': 'しゃ',
    'syu': 'しゅ',
    'syo': 'しょ',
    'za': 'ざ',
    'ji': 'じ',
    'zi': 'じ',
    'zu': 'ず',
    'ze': 'ぜ',
    'zo': 'ぞ',
    'ja': 'じゃ',
    'ju': 'じゅ',
    'jo': 'じょ',
    'je': 'じぇ',
    'jya': 'じゃ',
    'jyu': 'じゅ',
    'jyo': 'じょ',
    'zya': 'じゃ',
    'zyu': 'じゅ',
    'zyo': 'じょ',
    'ta': 'た',
    'chi': 'ち',
    'ti': 'ち',
    'tsu': 'つ',
    'tu': 'つ',
    'te': 'て',
    'to': 'と',
    'cha': 'ちゃ',
    'chu': 'ちゅ',
    'cho': 'ちょ',
    'che': 'ちぇ',
    'tya': 'ちゃ',
    'tyu': 'ちゅ',
    'tyo': 'ちょ',
    'cya': 'ちゃ',
    'cyu': 'ちゅ',
    'cyo': 'ちょ',
    'da': 'だ',
    'di': 'ぢ',
    'du': 'づ',
    'de': 'で',
    'do': 'ど',
    'na': 'な',
    'ni': 'に',
    'nu': 'ぬ',
    'ne': 'ね',
    'no': 'の',
    'nya': 'にゃ',
    'nyu': 'にゅ',
    'nyo': 'にょ',
    'ha': 'は',
    'hi': 'ひ',
    'fu': 'ふ',
    'hu': 'ふ',
    'he': 'へ',
    'ho': 'ほ',
    'hya': 'ひゃ',
    'hyu': 'ひゅ',
    'hyo': 'ひょ',
    'fa': 'ふぁ',
    'fi': 'ふぃ',
    'fe': 'ふぇ',
    'fo': 'ふぉ',
    'ba': 'ば',
    'bi': 'び',
    'bu': 'ぶ',
    'be': 'べ',
    'bo': 'ぼ',
    'bya': 'びゃ',
    'byu': 'びゅ',
    'byo': 'びょ',
    'pa': 'ぱ',
    'pi': 'ぴ',
    'pu': 'ぷ',
    'pe': 'ぺ',
    'po': 'ぽ',
    'pya': 'ぴゃ',
    'pyu': 'ぴゅ',
    'pyo': 'ぴょ',
    'ma': 'ま',
    'mi': 'み',
    'mu': 'む',
    'me': 'め',
    'mo': 'も',
    'mya': 'みゃ',
    'myu': 'みゅ',
    'myo': 'みょ',
    'ya': 'や',
    'yu': 'ゆ',
    'yo': 'よ',
    'ye': 'いぇ',
    'ra': 'ら',
    'ri': 'り',
    'ru': 'る',
    're': 'れ',
    'ro': 'ろ',
    'rya': 'りゃ',
    'ryu': 'りゅ',
    'ryo': 'りょ',
    'wa': 'わ',
    'wo': 'を',
    'wi': 'うぃ',
    'we': 'うぇ',
    'va': 'ゔぁ',
    'vi': 'ゔぃ',
    'vu': 'ゔ',
    've': 'ゔぇ',
    'vo': 'ゔぉ',
    'xa': 'ぁ',
    'xi': 'ぃ',
    'xu': 'ぅ',
    'xe': 'ぇ',
    'xo': 'ぉ',
    'la': 'ぁ',
    'li': 'ぃ',
    'lu': 'ぅ',
    'le': 'ぇ',
    'lo': 'ぉ',
    'xya': 'ゃ',
    'xyu': 'ゅ',
    'xyo': 'ょ',
    'lya': 'ゃ',
    'lyu': 'ゅ',
    'lyo': 'ょ',
    'xtsu': 'っ',
    'ltsu': 'っ',
    'xtu': 'っ',
    'ltu': 'っ',
    'xwa': 'ゎ',
    'lwa': 'ゎ',
  };
}
