import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/text/romaji_to_kana.dart';

/// PRD §12 v1.0 #1: ≥ 50 conversion cases incl. nn, kk, ou, shi/si.
void main() {
  const hiragana = <String, String>{
    // basics
    'taberu': 'たべる',
    'neko': 'ねこ',
    'sakura': 'さくら',
    'arigatou': 'ありがとう',
    'TABERU': 'たべる',
    // n / nn / n'
    'hon': 'ほん',
    'shinbun': 'しんぶん',
    'konnichiwa': 'こんにちわ',
    'konnnichiha': 'こんにちは',
    'onna': 'おんな',
    'kan\'i': 'かんい',
    'kani': 'かに',
    'shin\'you': 'しんよう',
    'shinyou': 'しにょう',
    'kinnen': 'きんねん',
    'nn': 'ん',
    'sannin': 'さんにん',
    'sempai': 'せんぱい',
    'shimbun': 'しんぶん',
    'senpai': 'せんぱい',
    // sokuon
    'gakkou': 'がっこう',
    'kitte': 'きって',
    'zasshi': 'ざっし',
    'ippai': 'いっぱい',
    'matcha': 'まっちゃ',
    'kissaten': 'きっさてん',
    'kekka': 'けっか',
    'motto': 'もっと',
    // long vowels and macrons
    'ou': 'おう',
    'oo': 'おお',
    'uu': 'うう',
    'tōkyō': 'とうきょう',
    'kūki': 'くうき',
    'okāsan': 'おかあさん',
    'ko-hi-': 'こーひー',
    // Hepburn / Kunrei variants
    'shi': 'し',
    'si': 'し',
    'chi': 'ち',
    'ti': 'ち',
    'tsu': 'つ',
    'tu': 'つ',
    'fu': 'ふ',
    'hu': 'ふ',
    'ji': 'じ',
    'zi': 'じ',
    'sha': 'しゃ',
    'sya': 'しゃ',
    'cha': 'ちゃ',
    'tya': 'ちゃ',
    'ja': 'じゃ',
    'zya': 'じゃ',
    'jya': 'じゃ',
    'kyou': 'きょう',
    'ryokou': 'りょこう',
    'gyuunyuu': 'ぎゅうにゅう',
    'byouin': 'びょういん',
    // particles / special kana
    'wo': 'を',
    // ず/づ cannot be told apart from Hepburn; normalizeJp folds づ→ず so
    // "tsuzuku" still finds つづく.
    'tsuzuku': 'つずく',
    'tsuduku': 'つづく',
    'fairu': 'ふぁいる',
    'xtsu': 'っ',
    'ltu': 'っ',
    'xya': 'ゃ',
    // incomplete input while typing
    'tab': 'たb',
    'k': 'k',
    'ky': 'ky',
    // non-letters pass through
    'taberu 2': 'たべる 2',
  };

  group('RomajiToKana.toHiragana', () {
    test('has at least 50 cases', () => expect(hiragana.length, greaterThanOrEqualTo(50)));
    hiragana.forEach((input, expected) {
      test('$input → $expected', () => expect(RomajiToKana.toHiragana(input), expected));
    });
  });

  group('RomajiToKana.toKatakana', () {
    const katakana = {'ko-hi-': 'コーヒー', 'su-pa-': 'スーパー', 'fairu': 'ファイル', 'terebi': 'テレビ', 'vaiorin': 'ヴァイオリン'};
    katakana.forEach((input, expected) {
      test('$input → $expected', () => expect(RomajiToKana.toKatakana(input), expected));
    });
  });
}
