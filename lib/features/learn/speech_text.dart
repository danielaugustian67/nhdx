import '../../core/database/content_db.dart';
import 'vocab_path.dart';

/// What to read aloud for an item: kana as written, a word by its kana
/// reading (its kanji could be read several ways), a kanji by its main
/// readings.
String speechText(Glyph g) => switch (g) {
  VocabWord w => w.word.kana,
  Kanji k => kanjiSpeech(k),
  _ => g.literal,
};

/// Up to two on'yomi and two kun'yomi, okurigana joined: "ゴ、いつ、いつつ".
String kanjiSpeech(Kanji k) => {
  for (final r in [...k.onyomi.take(2), ...k.kunyomi.take(2)]) r.replaceAll(RegExp(r'[.\-]'), ''),
}.where((r) => r.isNotEmpty).join('、');
