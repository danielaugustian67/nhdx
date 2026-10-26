import '../../core/database/content_db.dart';
import '../../core/text/hangul.dart';
import '../../core/text/kana_romaji.dart';
import 'vocab_path.dart';

/// What to read aloud for an item: kana as written, a word by its kana
/// reading (its kanji could be read several ways), a kanji by its main
/// readings, a Hangul letter by its sound (ㄱ → 가).
String speechText(Glyph g) => switch (g) {
  VocabWord w => w.word.kana,
  Kanji k => kanjiSpeech(k),
  Kana k when k.isHangul => hangulSpeech(k.literal),
  _ => g.literal,
};

/// Up to two on'yomi and two kun'yomi, okurigana joined: "ゴ、いつ、いつつ".
String kanjiSpeech(Kanji k) => {
  for (final r in [...k.onyomi.take(2), ...k.kunyomi.take(2)]) r.replaceAll(RegExp(r'[.\-]'), ''),
}.where((r) => r.isNotEmpty).join('、');

/// How to read an item in Latin letters: a kana's romaji, a word's romaji,
/// a kanji's main readings ("go, itsu, itsutsu").
String romajiText(Glyph g) => switch (g) {
  VocabWord w => w.word.romaji,
  Kanji k => kanjiSpeech(k).split('、').map(readingToRomaji).join(', '),
  Kana k => k.romaji,
  _ => '',
};
