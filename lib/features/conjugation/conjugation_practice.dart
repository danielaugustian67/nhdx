import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../../l10n/app_localizations.dart';
import 'conjugation.dart';

/// Name of a form in the table and the drill.
String conjFormLabel(AppLocalizations l10n, ConjForm f) => switch (f) {
  ConjForm.plain => l10n.conjPlain,
  ConjForm.polite => l10n.conjPolite,
  ConjForm.negative => l10n.conjNegative,
  ConjForm.politeNegative => l10n.conjPoliteNegative,
  ConjForm.past => l10n.conjPast,
  ConjForm.politePast => l10n.conjPolitePast,
  ConjForm.pastNegative => l10n.conjPastNegative,
  ConjForm.politePastNegative => l10n.conjPolitePastNegative,
  ConjForm.te => l10n.conjTe,
  ConjForm.potential => l10n.conjPotential,
  ConjForm.passive => l10n.conjPassive,
  ConjForm.causative => l10n.conjCausative,
  ConjForm.imperative => l10n.conjImperative,
  ConjForm.volitional => l10n.conjVolitional,
  ConjForm.conditionalBa => l10n.conjConditionalBa,
  ConjForm.conditionalTara => l10n.conjConditionalTara,
  ConjForm.want => l10n.conjWant,
  ConjForm.adverb => l10n.conjAdverb,
};

/// The ending a form is known by, shown next to its name: 〜ます, 〜ない.
String conjFormHint(ConjForm f, WordClass cls) => switch (f) {
  ConjForm.polite => cls.isAdjective ? '〜です' : '〜ます',
  ConjForm.negative => cls == WordClass.adjNa ? '〜じゃない' : '〜ない',
  ConjForm.politeNegative => cls.isAdjective ? '' : '〜ません',
  ConjForm.past => cls == WordClass.adjNa ? '〜だった' : (cls.isAdjective ? '〜かった' : '〜た'),
  ConjForm.politePast => cls.isAdjective ? '' : '〜ました',
  ConjForm.pastNegative => '〜なかった',
  ConjForm.te => '〜て',
  ConjForm.volitional => '〜よう',
  _ => '',
};

/// Forms the drill offers, most useful first. The first four are on by
/// default.
const drillForms = [
  ConjForm.polite,
  ConjForm.negative,
  ConjForm.past,
  ConjForm.te,
  ConjForm.politeNegative,
  ConjForm.politePast,
  ConjForm.pastNegative,
  ConjForm.want,
  ConjForm.potential,
  ConjForm.volitional,
  ConjForm.conditionalBa,
  ConjForm.conditionalTara,
  ConjForm.passive,
  ConjForm.causative,
  ConjForm.imperative,
  ConjForm.adverb,
];

/// A dictionary word with its conjugator.
class ConjWord {
  const ConjWord(this.word, this.conj);
  final DictWord word;
  final Conjugator conj;
}

/// The word as a drill word, or null when it does not conjugate.
ConjWord? conjWordOf(WordEntry e) {
  final conj = Conjugator.fromPos(e.posCodes, written: e.headword, kana: e.kana);
  if (conj == null) return null;
  final gloss = e.senses.isEmpty ? '' : e.senses.first.gloss.split('; ').take(2).join(', ');
  return ConjWord(
    DictWord(id: e.id, kana: e.kana, kanji: e.kanji, romaji: e.romaji, jlpt: e.jlpt ?? 0, gloss: gloss),
    conj,
  );
}

/// One drill question: a word, the form to put it in and four answers.
class ConjQuestion {
  const ConjQuestion({required this.word, required this.form, required this.options, required this.answer});
  final ConjWord word;
  final ConjForm form;
  final List<Conjugated> options;

  /// Index of the right option.
  final int answer;

  Conjugated get right => options[answer];

  /// SRS item id of this word + form: "1358280:polite".
  String get cardItemId => '${word.word.id}:${form.name}';
}

/// [count] questions over [words] in [forms], each word at most once while
/// enough remain, forms spread evenly. Words with too few distinct wrong
/// answers for a form are skipped for it.
List<ConjQuestion> buildConjQuestions(List<ConjWord> words, Set<ConjForm> forms, {int count = 10, Random? random}) {
  final rnd = random ?? Random();
  final pairs = <(ConjWord, ConjForm, List<Conjugated>)>[];
  for (final w in words) {
    for (final f in forms) {
      if (!w.conj.forms.contains(f)) continue;
      final wrong = w.conj.distractors(f);
      if (wrong.length == 3) pairs.add((w, f, wrong));
    }
  }
  pairs.shuffle(rnd);
  final picked = <(ConjWord, ConjForm, List<Conjugated>)>[];
  final usedWords = <int>{};
  final formCount = <ConjForm, int>{};
  // Fewest-used form first, a new word when possible.
  while (picked.length < count && pairs.isNotEmpty) {
    pairs.sort((a, b) {
      final byWord = (usedWords.contains(a.$1.word.id) ? 1 : 0) - (usedWords.contains(b.$1.word.id) ? 1 : 0);
      if (byWord != 0) return byWord;
      return (formCount[a.$2] ?? 0) - (formCount[b.$2] ?? 0);
    });
    final next = pairs.removeAt(0);
    picked.add(next);
    usedWords.add(next.$1.word.id);
    formCount[next.$2] = (formCount[next.$2] ?? 0) + 1;
    pairs.shuffle(rnd);
  }
  return [
    for (final (w, f, wrong) in picked)
      () {
        final options = [w.conj.conjugate(f), ...wrong]..shuffle(rnd);
        return ConjQuestion(word: w, form: f, options: options, answer: options.indexOf(w.conj.conjugate(f)));
      }(),
  ];
}

/// Drill words of the chosen levels; words whose spelling the engine cannot
/// conjugate are left out.
final conjWordsProvider = FutureProvider.family<List<ConjWord>, String>((ref, levelsKey) async {
  final dict = await ref.watch(dictionaryProvider.future);
  final levels = [for (final l in levelsKey.split(',')) ?int.tryParse(l)];
  return [
    for (final (:word, :pos) in dict.conjugableWords(levels))
      if (Conjugator.fromPos(pos, written: word.kanji ?? word.kana, kana: word.kana) case final c?) ConjWord(word, c),
  ];
});

/// The drill setup, remembered on this device.
class ConjChoice {
  const ConjChoice({
    this.verbs = true,
    this.adjectives = true,
    this.levels = const {5},
    this.forms = const {ConjForm.polite, ConjForm.negative, ConjForm.past, ConjForm.te},
  });

  final bool verbs;
  final bool adjectives;
  final Set<int> levels;
  final Set<ConjForm> forms;

  ConjChoice copyWith({bool? verbs, bool? adjectives, Set<int>? levels, Set<ConjForm>? forms}) => ConjChoice(
    verbs: verbs ?? this.verbs,
    adjectives: adjectives ?? this.adjectives,
    levels: levels ?? this.levels,
    forms: forms ?? this.forms,
  );

  /// Provider key for [conjWordsProvider]: "5,4".
  String get levelsKey => (levels.toList()..sort((a, b) => b - a)).join(',');

  bool accepts(ConjWord w) => w.conj.cls.isAdjective ? adjectives : verbs;

  String toJson() => jsonEncode({
    'verbs': verbs,
    'adjectives': adjectives,
    'levels': levels.toList(),
    'forms': [for (final f in forms) f.name],
  });

  static ConjChoice fromJson(String? json) {
    if (json == null) return const ConjChoice();
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      final levels = {for (final l in (m['levels'] as List? ?? const [])) ?(l is int && l >= 1 && l <= 5 ? l : null)};
      final forms = {for (final f in (m['forms'] as List? ?? const [])) ?ConjForm.parse('$f')};
      return ConjChoice(
        verbs: m['verbs'] as bool? ?? true,
        adjectives: m['adjectives'] as bool? ?? true,
        levels: levels.isEmpty ? const {5} : levels,
        forms: forms.isEmpty ? const ConjChoice().forms : forms,
      );
    } catch (_) {
      return const ConjChoice();
    }
  }
}

class ConjChoiceNotifier extends Notifier<ConjChoice> {
  static const settingKey = 'device.conjugation.choice';

  @override
  ConjChoice build() {
    _load();
    return const ConjChoice();
  }

  Future<void> _load() async {
    try {
      final saved = await (await ref.read(userDbProvider.future)).setting(settingKey);
      if (saved != null && ref.mounted) state = ConjChoice.fromJson(saved);
    } catch (e) {
      debugPrint('ConjChoice: user.db not available ($e)');
    }
  }

  void update(ConjChoice choice) {
    state = choice;
    writeUserDb(ref.read(userDbProvider.future), (db) => db.setSetting(settingKey, choice.toJson()));
  }
}

final conjChoiceProvider = NotifierProvider<ConjChoiceNotifier, ConjChoice>(ConjChoiceNotifier.new);
