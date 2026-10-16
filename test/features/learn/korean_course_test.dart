import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/audio/speech.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/core/text/hangul.dart';
import 'package:nihondx/features/free_study/free_study_providers.dart';
import 'package:nihondx/features/learn/hangul_path.dart';
import 'package:nihondx/features/learn/kana_path.dart';
import 'package:nihondx/features/learn/lesson.dart';
import 'package:nihondx/features/learn/path_providers.dart';
import 'package:nihondx/features/learn/speech_text.dart';
import 'package:nihondx/features/learn/study_language.dart';
import 'package:nihondx/features/learn/vocab_path.dart';
import 'package:nihondx/features/srs/srs_providers.dart';

void main() {
  group('Hangul helpers', () {
    test('find Hangul in text', () {
      expect(hasHangul('한국어'), isTrue);
      expect(hasHangul('ㄱ'), isTrue);
      expect(hasHangul('にほんご'), isFalse);
      expect(hasHangul('abc'), isFalse);
    });

    test('a letter alone is read by its sound', () {
      expect(hangulSpeech('ㄱ'), '가');
      expect(hangulSpeech('ㅎ'), '하');
      expect(hangulSpeech('ㅓ'), '어');
      expect(hangulSpeech('ㅢ'), '의');
      expect(hangulSpeech('ㅇ'), '이응');
      expect(hangulSpeech('가'), '가');
      expect(hangulSpeech('한국어'), '한국어');
    });

    test('romanize syllable by syllable, and compare typed romanizations', () {
      expect(romanizeHangul('한국어'), 'hangukeo');
      expect(romanizeHangul('감사합니다'), 'gamsahapnida');
      expect(romanizeHangul('꽃'), 'kkot');
      expect(normalizeRomaja(" An-nyeong Ha'seyo "), 'annyeonghaseyo');
    });

    test('Korean text is spoken in Korean', () {
      expect(speechLanguageOf('안녕하세요'), 'ko-KR');
      expect(speechLanguageOf('こんにちは'), 'ja-JP');
    });
  });

  test('a Korean word takes its romanization as pronounced or letter by letter', () {
    final word = DictWord(id: koWordIdBase + 1, kana: '한국어', romaji: 'hangugeo', jlpt: 0, gloss: 'Korean');
    final ex = ReadExercise(word: word, shown: '한국어', items: [VocabWord(word)]);
    expect(word.isKorean, isTrue);
    expect(ex.check('hangugeo'), isTrue);
    expect(ex.check('Han-gu geo'), isTrue);
    expect(ex.check('hangukeo'), isTrue);
    expect(ex.check('hanguk'), isFalse);
    expect(ex.check(''), isFalse);
  });

  test('cards and study marks keep each language apart', () {
    expect(cardTypesOf(StudyLanguage.ko), (types: koreanCardTypes, exceptTypes: false));
    expect(cardTypesOf(StudyLanguage.ja), (types: koreanCardTypes, exceptTypes: true));
    const ga = Kana(
      id: 1,
      literal: '가',
      romaji: 'ga',
      script: 'hangul',
      rowGroup: 'syllables_a',
      kind: 'syllable',
      orderNo: 1,
    );
    final word = VocabWord(DictWord(id: koWordIdBase + 5, kana: '물', romaji: 'mul', jlpt: 0, gloss: 'air'));
    expect(studyKey(ga), 'hangul:가');
    expect(studyKey(word), 'ko_word:${koWordIdBase + 5}');
    expect(isKoreanItem(ga), isTrue);
    expect(isKoreanItem(word), isTrue);
    expect(speechText(ga), '가');
    expect(StudyKind.of(StudyLanguage.ko), [StudyKind.hangul, StudyKind.koWord, StudyKind.forgotten]);
    expect(StudyKind.of(StudyLanguage.ja), isNot(contains(StudyKind.hangul)));
    expect(StudyKind.koWord.fromPath, isTrue);
    expect(StudyKind.forgotten.fromPath, isFalse);
  });

  const contentPath = 'data_pipeline/output/content.db';
  final skip = File(contentPath).existsSync() ? false : 'content.db not built';

  group('course data', skip: skip, () {
    late ContentDb content;
    late List<Kana> letters;
    late List<KoWord> words;

    setUpAll(() {
      content = ContentDb.open(contentPath);
      letters = content.hangul();
      words = content.koreanWords();
    });

    tearDownAll(() => content.close());

    test('Hangul letters and syllables in unit order, each with a romanization', () {
      expect(letters.length, greaterThanOrEqualTo(100));
      expect(letters.every((k) => k.isHangul && k.romaji.isNotEmpty), isTrue);
      expect(letters.map((k) => k.literal).toSet(), hasLength(letters.length));
      expect(letters.first.literal, 'ㅏ');
      expect(letters.firstWhere((k) => k.literal == '강').romaji, 'gang');
      expect(content.koreanGroups('hangul').keys.first, 'vowels');
      expect(content.koreanGroups('hangul')['vowels']!.of('id'), isNotEmpty);
    });

    test('basic Korean words with Indonesian and English meanings and unique ids', () {
      expect(words.length, greaterThanOrEqualTo(300));
      expect(words.map((w) => w.id).toSet(), hasLength(words.length));
      expect(words.every((w) => w.id >= koWordIdBase && hasHangul(w.hangul) && w.romaja.isNotEmpty), isTrue);
      expect(words.every((w) => w.meaning.of('id').isNotEmpty && w.meaning.of('en').isNotEmpty), isTrue);
      final topics = content.koreanGroups('words');
      expect(words.every((w) => topics.containsKey(w.topic)), isTrue);
    });

    test('the Hangul path teaches every letter once, without writing', () {
      final units = buildHangulPath(letters, content.koreanGroups('hangul'));
      final taught = [
        for (final u in units)
          for (final n in u.nodes)
            if (n.type == NodeType.intro) ...n.items,
      ];
      expect(taught.map((k) => k.literal).toList()..sort(), letters.map((k) => k.literal).toList()..sort());
      expect(units.every((u) => u.script == 'hangul' && u.title != null), isTrue);
      expect(units.expand((u) => u.nodes).map((n) => n.id).toSet(), hasLength(units.expand((u) => u.nodes).length));
      for (final u in units) {
        for (final n in u.nodes.where((n) => n.type == NodeType.intro)) {
          expect(n.items.length, lessThanOrEqualTo(hangulPerIntro));
          final builder = KanaLessonBuilder(
            focus: n.items.cast<Kana>(),
            pool: n.reviewPool.cast<Kana>(),
            dictionary: [for (final w in words) koDictWord(w, 'id')],
            random: Random(1),
          );
          expect(builder.writable, isEmpty);
          expect(builder.available(LessonMode.write), isFalse);
          final lesson = builder.build(LessonMode.mixed);
          expect(lesson, isNotEmpty, reason: n.id);
          expect(lesson.whereType<WriteExercise>(), isEmpty);
        }
      }
    });

    test('with stroke data each unit gets a writing node that does not lock old progress', () {
      final groups = content.koreanGroups('hangul');
      expect(
        buildHangulPath(letters, groups).expand((u) => u.nodes).where((n) => n.type == NodeType.write),
        isEmpty,
      );
      final units = buildHangulPath(letters, groups, hasStrokes: (k) => content.strokes(k.literal).isNotEmpty);
      for (final u in units) {
        final write = u.nodes.singleWhere((n) => n.type == NodeType.write, orElse: () => fail('${u.id}: no write'));
        expect(write.id, '${u.id}-write');
        expect(write.catchUp, isTrue);
        expect(write.items.toSet(), u.nodes.where((n) => n.type == NodeType.intro).expand((n) => n.items).toSet());
        // Writing comes after the unit's lessons.
        expect(u.nodes.indexOf(write), u.nodes.lastIndexWhere((n) => n.type == NodeType.intro) + 1);
      }

      // Someone who finished unit 1 before writing existed: unit 2 stays
      // current, the new writing node is open.
      final unit1 = units[0].nodes.where((n) => n.type != NodeType.write).map((n) => n.id).toSet();
      final states = nodeStates(units, unit1);
      expect(states['${units[0].id}-write'], NodeState.open);
      expect(states[units[1].nodes.first.id], NodeState.current);
      expect(states[units[1].nodes[1].id], NodeState.locked);

      // A new learner meets it in order.
      final intros = units[0].nodes.where((n) => n.type == NodeType.intro).map((n) => n.id).toSet();
      final fresh = nodeStates(units, intros);
      expect(fresh['${units[0].id}-write'], NodeState.current);
      expect(fresh['${units[0].id}-match'], NodeState.locked);
    });

    test('the Korean word path covers every word, with meanings in the app language', () {
      final units = buildKoreanVocabPath(words, content.koreanGroups('words'), language: 'en');
      final taught = [
        for (final u in units)
          for (final n in u.nodes)
            if (n.type == NodeType.intro) ...n.items.cast<VocabWord>(),
      ];
      expect(taught.map((w) => w.id).toSet(), words.map((w) => w.id).toSet());
      expect(taught.every((w) => w.word.isKorean), isTrue);
      final hello = words.firstWhere((w) => w.hangul == '안녕하세요');
      expect(taught.firstWhere((w) => w.id == hello.id).word.gloss, hello.meaning.en);
      final node = units.first.nodes.first;
      final lesson = VocabLessonBuilder(
        focus: node.items.cast<VocabWord>(),
        pool: node.reviewPool.cast<VocabWord>(),
        random: Random(2),
      ).build(LessonMode.mixed);
      expect(lesson, isNotEmpty);
      for (final ex in lesson.whereType<ReadExercise>()) {
        expect(ex.check(ex.word.romaji), isTrue);
      }
    });
  });
}
