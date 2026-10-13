/// Hangul helpers for the Korean course.
library;

final _hangul = RegExp(r'[ᄀ-ᇿ㄰-㆏가-힣]');

/// Whether [text] has any Hangul (letters or syllables).
bool hasHangul(String text) => _hangul.hasMatch(text);

/// Compatibility jamo in the order of the syllable initials and vowels.
const _initials = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';
const _vowels = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ';

String _syllable(int initial, int vowel) => String.fromCharCode(0xAC00 + (initial * 21 + vowel) * 28);

/// What to read aloud for a letter on its own, which a voice would read by
/// its name or not at all: a consonant with ㅏ (ㄱ → 가), a vowel after the
/// silent ㅇ (ㅓ → 어). ㅇ itself is silent at the start, so it gets its
/// name. Syllables and words are read as written.
String hangulSpeech(String text) {
  if (text.length != 1) return text;
  if (text == 'ㅇ') return '이응';
  final c = _initials.indexOf(text);
  if (c >= 0) return _syllable(c, 0);
  final v = _vowels.indexOf(text);
  if (v >= 0) return _syllable(_initials.indexOf('ㅇ'), v);
  return text;
}

const _rrInitial = ['g', 'kk', 'n', 'd', 'tt', 'r', 'm', 'b', 'pp', 's', 'ss', '', 'j', 'jj', 'ch', 'k', 't', 'p', 'h'];
const _rrVowel = [
  'a', 'ae', 'ya', 'yae', 'eo', 'e', 'yeo', 'ye', 'o', 'wa', 'wae', //
  'oe', 'yo', 'u', 'wo', 'we', 'wi', 'yu', 'eu', 'ui', 'i',
];
const _rrFinal = [
  '', 'k', 'k', 'k', 'n', 'n', 'n', 't', 'l', 'k', 'm', 'l', 'l', 'l', //
  'p', 'l', 'm', 'p', 'p', 't', 't', 'ng', 't', 't', 'k', 't', 'p', 't',
];

/// Revised Romanization syllable by syllable, without the sound changes
/// between syllables ("한국어" → "hangukeo"): a second accepted spelling
/// next to the authored one ("hangugeo").
String romanizeHangul(String text) {
  final out = StringBuffer();
  for (final r in text.runes) {
    final n = r - 0xAC00;
    if (n < 0 || n >= 11172) {
      out.writeCharCode(r);
      continue;
    }
    out
      ..write(_rrInitial[n ~/ 588])
      ..write(_rrVowel[n % 588 ~/ 28])
      ..write(_rrFinal[n % 28]);
  }
  return out.toString();
}

/// A typed romanization without case, spaces, hyphens or apostrophes.
String normalizeRomaja(String text) => text.toLowerCase().replaceAll(RegExp(r"[\s\-'’]"), '');
