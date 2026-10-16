import 'dart:math';

import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import '../../core/text/hangul.dart';
import '../../core/text/normalize.dart';
import '../../core/text/romaji_to_kana.dart';
import '../kana/games/kana_quiz.dart';
import 'vocab_path.dart';

/// How a "Kenali" lesson is put together (ui-design §5.2).
enum LessonMode {
  /// All exercise types shuffled, like a Duolingo lesson (default).
  mixed,

  /// Multiple choice only.
  choice,

  /// Writing with stroke scoring only.
  write,

  /// Typing only: spell a dictionary word with tiles, read one in romaji
  /// (vocabulary: type a word's reading, or the word for a meaning).
  type,

  /// Vocabulary only: match words to their meanings.
  match,

  /// The graded quiz after an intro's practice: writing (at most
  /// [LessonBuilder.maxQuizWrites]), reading both ways, and words that use
  /// the node's own characters.
  quiz,
}

sealed class Exercise {
  const Exercise();

  /// Kana or kanji this exercise practises (weak-item tracking).
  List<Glyph> get items;
}

/// What a multiple-choice question shows and asks for.
enum ChoiceKind {
  /// Kana → romaji.
  kanaReading,

  /// Romaji → kana.
  pickKana,

  /// Kanji → meaning.
  kanjiMeaning,

  /// Meaning → kanji.
  pickKanji,

  /// Vocabulary word → meaning.
  wordMeaning,

  /// Meaning → vocabulary word.
  pickWord;

  /// Whether the big prompt is Japanese (otherwise the options are).
  bool get promptIsJapanese => this == kanaReading || this == kanjiMeaning || this == wordMeaning;

  /// Options or prompt are dictionary meanings, which can be long.
  bool get hasGloss => this == wordMeaning || this == pickWord;
}

/// One question with 4 options.
class ChoiceExercise extends Exercise {
  const ChoiceExercise({
    required this.item,
    required this.kind,
    required this.prompt,
    required this.options,
    required this.answerIndex,
  });

  ChoiceExercise.kana(QuizQuestion q)
    : this(
        item: q.kana,
        kind: q.direction == QuizDirection.kanaToRomaji ? ChoiceKind.kanaReading : ChoiceKind.pickKana,
        prompt: q.prompt,
        options: q.options,
        answerIndex: q.answerIndex,
      );

  final Glyph item;
  final ChoiceKind kind;
  final String prompt;
  final List<String> options;
  final int answerIndex;

  String get answer => options[answerIndex];

  @override
  List<Glyph> get items => [item];
}

/// Write one character over a guide; scored by the PRD F6 stroke scorer.
class WriteExercise extends Exercise {
  const WriteExercise(this.target, {required this.hint});
  final Glyph target;

  /// Romaji of a kana, meaning of a kanji.
  final String hint;

  @override
  List<Glyph> get items => [target];
}

/// A dictionary word's reading + meaning → tap its tiles in order: kana
/// tiles for the kana course, kanji (+ okurigana) tiles for the kanji course.
class BuildExercise extends Exercise {
  const BuildExercise({
    required this.word,
    required this.prompt,
    required this.target,
    required this.script,
    required this.answer,
    required this.tiles,
  });
  final DictWord word;

  /// Shown big: romaji (kana course) or the kana reading (kanji course).
  final String prompt;

  /// The spelling to build, e.g. "あか" or "青い".
  final String target;

  /// 'hiragana' | 'katakana' | 'kanji' | 'hangul', for the instruction.
  final String script;

  /// [target] split into tiles (きゃ and every kanji count as one).
  final List<Glyph> answer;

  /// [answer] plus distractors, shuffled.
  final List<Glyph> tiles;

  @override
  List<Glyph> get items => [
    for (final g in answer)
      if (g is Kanji || script != 'kanji') g,
  ];

  bool check(List<Glyph> picked) => picked.map((g) => g.literal).join() == target;
}

/// A dictionary word in kana or kanji → type its reading in romaji. With
/// [fromMeaning] the meaning is shown instead and the word is recalled.
class ReadExercise extends Exercise {
  const ReadExercise({
    required this.word,
    required this.shown,
    required this.items,
    this.hint,
    this.fromMeaning = false,
  });
  final DictWord word;

  /// The spelling shown: the kana (kana course) or kanji form (kanji
  /// course), or the meaning when [fromMeaning].
  final String shown;
  final bool fromMeaning;

  /// Meaning under the word, so a kanji with several readings is not a guess.
  final String? hint;

  @override
  final List<Glyph> items;

  /// Accepts any spelling that converts to the same kana (shi/si, ō/ou,
  /// "ookii"), so only the reading is tested, not one romanisation. A
  /// Korean word takes its romanization as pronounced ("hangugeo") or
  /// syllable by syllable ("hangukeo"), without spaces or hyphens.
  bool check(String typed) {
    if (word.isKorean) {
      final t = normalizeRomaja(typed);
      return t.isNotEmpty && (t == normalizeRomaja(word.romaji) || t == normalizeRomaja(romanizeHangul(word.kana)));
    }
    final t = typed.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (t.isEmpty) return false;
    if (t == word.romaji.toLowerCase()) return true;
    return RomajiToKana.toHiragana(t) == katakanaToHiragana(word.kana);
  }
}

/// One character → type its reading (romaji, or romaja for Hangul).
class GlyphReadExercise extends Exercise {
  const GlyphReadExercise(this.glyph, {required this.answers, this.korean = false});
  final Glyph glyph;

  /// Accepted readings; the first is shown as the answer.
  final List<String> answers;
  final bool korean;

  String get answer => answers.first;

  @override
  List<Glyph> get items => [glyph];

  /// Case and spaces are ignored. Kana also take any romanisation of the
  /// same kana (si/shi, tu/tsu); Hangul takes any listed variant ("eo").
  bool check(String typed) {
    final t = normalizeRomaja(typed);
    if (t.isEmpty) return false;
    if (answers.any((a) => normalizeRomaja(a) == t)) return true;
    if (korean) return false;
    return RomajiToKana.toHiragana(t) == katakanaToHiragana(glyph.literal);
  }
}

/// Vocabulary: tap a word, then its meaning, until every pair is matched.
class MatchExercise extends Exercise {
  const MatchExercise({required this.words, required this.meaningOrder});
  final List<VocabWord> words;

  /// Indices into [words] in the order the meanings are listed.
  final List<int> meaningOrder;

  /// Wrong pairs allowed for the exercise to count as correct: with five
  /// pairs a slipped tap is easy and not a sign of not knowing the words.
  static const allowedMistakes = 1;

  @override
  List<Glyph> get items => words;
}

/// A dictionary word spelled with what was learned so far.
typedef SpelledWord = ({DictWord word, List<Glyph> glyphs});

/// Splits [text] into glyphs from [byLiteral] (two-character yōon first), or
/// null when some part has not been learned.
List<T>? spellWith<T extends Glyph>(String text, Map<String, T> byLiteral) {
  final out = <T>[];
  var i = 0;
  while (i < text.length) {
    final two = i + 2 <= text.length ? byLiteral[text.substring(i, i + 2)] : null;
    final g = two ?? byLiteral[text[i]];
    if (g == null) return null;
    out.add(g);
    i += two != null ? 2 : 1;
  }
  return out;
}

/// Builds the lessons of one path node. [focus] are the characters being
/// introduced, [pool] everything learned so far in the course (including
/// [focus]). The mix is the same for kana and kanji (ui-design §5.2).
abstract class LessonBuilder {
  LessonBuilder({Random? random}) : random = random ?? Random();

  final Random random;

  /// Dictionary words for "Ketik", words with the new characters first.
  List<SpelledWord> get words;

  /// Characters that can be written (stroke data).
  List<Glyph> get writable;

  /// Items the node introduces.
  List<Glyph> get focusItems;

  /// Writing questions in a quiz; writing is slow.
  static const maxQuizWrites = 3;

  /// Reading practice for [g] in an intro, or null when there is none.
  GlyphReadExercise? readGlyph(Glyph g) => null;

  /// Ungraded practice after [g]'s intro card: write it, then read it.
  List<Exercise> practice(Glyph g) => [if (writable.contains(g)) write(g), ?readGlyph(g)];

  List<Exercise> choices(int n, Set<int> weakIds);
  WriteExercise write(Glyph g);
  BuildExercise buildWord(SpelledWord w);
  ReadExercise readWord(SpelledWord w);

  bool available(LessonMode mode) => switch (mode) {
    LessonMode.mixed || LessonMode.choice => true,
    LessonMode.write => writable.isNotEmpty,
    LessonMode.type => words.isNotEmpty,
    LessonMode.match => false,
    LessonMode.quiz => true,
  };

  /// [count] exercises (fewer for [LessonMode.write], which is slower).
  /// [weakIds] characters are asked first in choice questions.
  List<Exercise> build(LessonMode mode, {int count = 10, Set<int> weakIds = const {}}) {
    switch (mode) {
      case LessonMode.choice:
        return choices(count, weakIds);
      case LessonMode.write:
        return _writes(writable.length.clamp(3, 6));
      case LessonMode.type:
        return _typed(count);
      case LessonMode.match:
        return const [];
      case LessonMode.quiz:
        final focus = focusItems.toSet();
        // Only words with a character of this node, so the quiz never asks
        // about what the intro did not show.
        final ownWords = words.where((w) => w.glyphs.any(focus.contains)).toList();
        final rest = [
          ..._writes(min(LessonBuilder.maxQuizWrites, writable.length)),
          ..._typed(min(2, ownWords.length), from: ownWords),
        ];
        final qs = choices((focus.length * 2).clamp(4, 8), weakIds);
        final head = qs.take(2).toList();
        final tail = [...qs.skip(2), ...rest]..shuffle(random);
        return [...head, ...tail];
      case LessonMode.mixed:
        final share = (count * 0.2).round();
        final rest = [..._writes(writable.isEmpty ? 0 : share), ..._typed(words.isEmpty ? 0 : share * 2)];
        final qs = choices(count - rest.length, weakIds);
        // Two recognition questions first to warm up, then everything shuffled.
        final head = qs.take(2).toList();
        final tail = [...qs.skip(2), ...rest]..shuffle(random);
        return [...head, ...tail];
    }
  }

  List<Exercise> _writes(int n) {
    final pick = writable.toList()..shuffle(random);
    if (pick.isEmpty) return const [];
    return [for (var i = 0; i < n; i++) write(pick[i % pick.length])];
  }

  /// [n] word exercises from the easiest dozen words, alternating spelling
  /// and reading, without repeats while possible.
  List<Exercise> _typed(int n, {List<SpelledWord>? from}) {
    final source = from ?? words;
    if (source.isEmpty || n == 0) return const [];
    final candidates = source.take(max(12, n)).toList()..shuffle(random);
    return [
      for (var i = 0; i < n; i++)
        i.isEven ? buildWord(candidates[i % candidates.length]) : readWord(candidates[i % candidates.length]),
    ];
  }

  /// Words that use a [focus] character first; dictionary order (N5,
  /// frequent) within.
  static List<SpelledWord> focusFirst(List<SpelledWord> spelled, Set<Glyph> focus) => [
    ...spelled.where((s) => s.glyphs.any(focus.contains)),
    ...spelled.where((s) => !s.glyphs.any(focus.contains)),
  ];

  /// [answer] plus distractors from [extra] (never a character of the
  /// answer), [size] tiles in all, shuffled.
  List<Glyph> tiles(List<Glyph> answer, Iterable<Glyph> extra, int size) {
    final used = answer.map((g) => g.literal).toSet();
    final more = extra.where((g) => !used.contains(g.literal)).toSet().toList()..shuffle(random);
    return [...answer, ...more.take(max(0, size - answer.length))]..shuffle(random);
  }
}

/// Kana course: kana ↔ romaji questions, writing, and words spelled with
/// kana tiles / read in romaji. The Hangul course works the same with
/// Korean words, without writing (no stroke data for Hangul yet).
class KanaLessonBuilder extends LessonBuilder {
  KanaLessonBuilder({required this.focus, required this.pool, List<DictWord> dictionary = const [], super.random}) {
    final byLiteral = {for (final k in pool) k.literal: k};
    final seen = <String>{};
    words = LessonBuilder.focusFirst([
      for (final w in dictionary)
        if (seen.add(w.kana))
          if (spellWith(w.kana, byLiteral) case final kana? when kana.length >= 2) (word: w, glyphs: kana),
    ], focus.toSet());
  }

  final List<Kana> focus;
  final List<Kana> pool;

  @override
  late final List<SpelledWord> words;

  /// Yōon are written one kana after the other (き, then ゃ).
  @override
  List<Glyph> get writable => focus.where((k) => !k.isHangul).toList();

  @override
  List<Glyph> get focusItems => focus;

  @override
  GlyphReadExercise readGlyph(Glyph g) {
    final k = g as Kana;
    return GlyphReadExercise(
      k,
      // Some Hangul romanizations list variants ("g/k").
      answers: k.romaji.split(RegExp(r'\s*[/,]\s*')).where((a) => a.isNotEmpty).toList(),
      korean: k.isHangul,
    );
  }

  @override
  List<Exercise> choices(int n, Set<int> weakIds) => [
    for (final q in KanaQuizGenerator(
      focus,
      distractors: pool,
      random: random,
    ).session(count: n, focus: focus.where((k) => weakIds.contains(k.id)).toSet()))
      ChoiceExercise.kana(q),
  ];

  @override
  WriteExercise write(Glyph g) => WriteExercise(g, hint: (g as Kana).romaji);

  @override
  BuildExercise buildWord(SpelledWord w) => BuildExercise(
    word: w.word,
    prompt: w.word.romaji,
    target: w.word.kana,
    script: (w.glyphs.first as Kana).script,
    answer: w.glyphs,
    tiles: tiles(w.glyphs, pool, (w.glyphs.length + 3).clamp(6, 8)),
  );

  @override
  ReadExercise readWord(SpelledWord w) => ReadExercise(word: w.word, shown: w.word.kana, items: w.glyphs);
}

/// Kanji course: kanji ↔ meaning questions, writing, and words written with
/// the kanji learned so far (okurigana as hiragana tiles). Hiragana is
/// assumed known.
class KanjiLessonBuilder extends LessonBuilder {
  KanjiLessonBuilder({
    required this.focus,
    required this.pool,
    required List<Kana> hiragana,
    List<DictWord> dictionary = const [],
    super.random,
  }) : _hiragana = hiragana {
    final byLiteral = <String, Glyph>{for (final k in hiragana) k.literal: k, for (final k in pool) k.literal: k};
    final seen = <String>{};
    words = LessonBuilder.focusFirst([
      for (final w in dictionary)
        if (w.kanji case final kanji? when seen.add(kanji))
          if (spellWith(kanji, byLiteral) case final glyphs? when glyphs.any((g) => g is Kanji))
            (word: w, glyphs: glyphs),
    ], focus.toSet());
  }

  final List<Kanji> focus;
  final List<Kanji> pool;
  final List<Kana> _hiragana;

  @override
  late final List<SpelledWord> words;

  /// Every course kanji has KanjiVG strokes (build_content_db.py fails otherwise).
  @override
  List<Glyph> get writable => focus;

  @override
  List<Glyph> get focusItems => focus;

  @override
  List<Exercise> choices(int n, Set<int> weakIds) {
    final ordered = [
      ...(focus.where((k) => weakIds.contains(k.id)).toList()..shuffle(random)),
      ...(focus.where((k) => !weakIds.contains(k.id)).toList()..shuffle(random)),
    ];
    return [
      for (var i = 0; i < n; i++)
        _question(ordered[i % ordered.length], i.isEven ? ChoiceKind.kanjiMeaning : ChoiceKind.pickKanji),
    ];
  }

  ChoiceExercise _question(Kanji k, ChoiceKind kind) {
    String show(Kanji x) => kind == ChoiceKind.kanjiMeaning ? x.meaning : x.literal;
    final candidates = {...pool, ...focus}.where((x) => x != k).toList()..shuffle(random);
    // Distinct meanings too: two kanji glossed "day" would make the
    // meaning → kanji question ambiguous.
    final seenShown = {show(k)}, seenMeaning = {k.meaning};
    final wrong = <Kanji>[];
    for (final x in candidates) {
      if (wrong.length == 3) break;
      if (seenShown.contains(show(x)) || seenMeaning.contains(x.meaning)) continue;
      seenShown.add(show(x));
      seenMeaning.add(x.meaning);
      wrong.add(x);
    }
    final options = [k, ...wrong]..shuffle(random);
    return ChoiceExercise(
      item: k,
      kind: kind,
      prompt: kind == ChoiceKind.kanjiMeaning ? k.literal : k.meaning,
      options: [for (final x in options) show(x)],
      answerIndex: options.indexOf(k),
    );
  }

  @override
  WriteExercise write(Glyph g) => WriteExercise(g, hint: (g as Kanji).meaning);

  @override
  BuildExercise buildWord(SpelledWord w) {
    final kanjiCount = w.glyphs.whereType<Kanji>().length;
    // Mostly other kanji as distractors, plus a little kana when the word
    // has okurigana so the kana tiles are not a giveaway.
    final kanaInWord = w.glyphs.length > kanjiCount;
    final extra = [...pool, if (kanaInWord) ...(_hiragana.toList()..shuffle(random)).take(3)];
    return BuildExercise(
      word: w.word,
      prompt: w.word.kana,
      target: w.word.kanji!,
      script: 'kanji',
      answer: w.glyphs,
      tiles: tiles(w.glyphs, extra, (w.glyphs.length + 3).clamp(5, 8)),
    );
  }

  @override
  ReadExercise readWord(SpelledWord w) =>
      ReadExercise(word: w.word, shown: w.word.kanji!, hint: w.word.gloss, items: w.glyphs.whereType<Kanji>().toList());
}

/// Vocabulary course (PRD F7): word ↔ meaning questions, typing a word's
/// reading or recalling it from its meaning, and matching pairs. No writing.
class VocabLessonBuilder extends LessonBuilder {
  VocabLessonBuilder({required this.focus, required this.pool, super.random});

  /// Words this lesson teaches or reviews.
  final List<VocabWord> focus;

  /// Words of the course so far, for distractors.
  final List<VocabWord> pool;

  /// Pairs in one matching exercise.
  static const pairs = 5;

  @override
  List<SpelledWord> get words => const [];

  @override
  List<Glyph> get writable => const [];

  @override
  List<Glyph> get focusItems => focus;

  @override
  bool available(LessonMode mode) => mode != LessonMode.write && focus.isNotEmpty;

  @override
  List<Exercise> build(LessonMode mode, {int count = 10, Set<int> weakIds = const {}}) {
    switch (mode) {
      case LessonMode.choice:
        return choices(count, weakIds);
      case LessonMode.type:
        return _typedWords(count, weakIds);
      case LessonMode.match:
        return [for (var i = 0; i < (count / 3).ceil().clamp(2, 4); i++) _match()];
      case LessonMode.write:
        return const [];
      case LessonMode.mixed || LessonMode.quiz:
        final rest = [_match(), if (count >= 10) _match(), ..._typedWords((count * 0.25).round(), weakIds)];
        final qs = choices(count - rest.length, weakIds);
        final head = qs.take(2).toList();
        final tail = [...qs.skip(2), ...rest]..shuffle(random);
        return [...head, ...tail];
    }
  }

  /// [focus] with weak words first, each part shuffled.
  List<VocabWord> _ordered(Set<int> weakIds) => [
    ...(focus.where((w) => weakIds.contains(w.id)).toList()..shuffle(random)),
    ...(focus.where((w) => !weakIds.contains(w.id)).toList()..shuffle(random)),
  ];

  @override
  List<Exercise> choices(int n, Set<int> weakIds) {
    final ordered = _ordered(weakIds);
    if (ordered.isEmpty) return const [];
    return [
      for (var i = 0; i < n; i++)
        _question(ordered[i % ordered.length], i.isEven ? ChoiceKind.wordMeaning : ChoiceKind.pickWord),
    ];
  }

  ChoiceExercise _question(VocabWord w, ChoiceKind kind) {
    String show(VocabWord x) => kind == ChoiceKind.wordMeaning ? x.word.gloss : x.literal;
    final candidates = {...pool, ...focus}.where((x) => x != w).toList()..shuffle(random);
    // Distinct meanings and spellings, so no option is also right.
    final seenGloss = {w.word.gloss}, seenLiteral = {w.literal};
    final wrong = <VocabWord>[];
    for (final x in candidates) {
      if (wrong.length == 3) break;
      if (seenGloss.contains(x.word.gloss) || seenLiteral.contains(x.literal)) continue;
      seenGloss.add(x.word.gloss);
      seenLiteral.add(x.literal);
      wrong.add(x);
    }
    final options = [w, ...wrong]..shuffle(random);
    return ChoiceExercise(
      item: w,
      kind: kind,
      prompt: kind == ChoiceKind.wordMeaning ? w.literal : w.word.gloss,
      options: [for (final x in options) show(x)],
      answerIndex: options.indexOf(w),
    );
  }

  /// Alternates reading a kanji word and recalling a word from its meaning;
  /// kana-only words are always recalled (reading them is the kana course).
  List<Exercise> _typedWords(int n, Set<int> weakIds) {
    final ordered = _ordered(weakIds);
    if (ordered.isEmpty) return const [];
    return [
      for (var i = 0; i < n; i++)
        if (ordered[i % ordered.length] case final w)
          i.isOdd && w.word.kanji != null
              ? ReadExercise(word: w.word, shown: w.literal, hint: w.word.gloss, items: [w])
              : ReadExercise(word: w.word, shown: w.word.gloss, items: [w], fromMeaning: true),
    ];
  }

  /// Up to [pairs] focus words with distinct meanings, topped up from the
  /// pool when the lesson is small.
  MatchExercise _match() {
    final seen = <String>{};
    final picked = <VocabWord>[];
    for (final w in [...(focus.toList()..shuffle(random)), ...(pool.toList()..shuffle(random))]) {
      if (picked.length == pairs) break;
      if (seen.add(w.word.gloss) && !picked.contains(w)) picked.add(w);
    }
    return MatchExercise(words: picked, meaningOrder: List.generate(picked.length, (i) => i)..shuffle(random));
  }

  @override
  WriteExercise write(Glyph g) => throw UnsupportedError('vocabulary has no writing');

  @override
  BuildExercise buildWord(SpelledWord w) => throw UnsupportedError('vocabulary has no tiles');

  @override
  ReadExercise readWord(SpelledWord w) => throw UnsupportedError('use _typedWords');
}
