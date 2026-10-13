import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../l10n/app_localizations.dart';
import '../learn/path_providers.dart';
import 'ko_conjugation.dart';

/// Forms of the Korean drill, in table order.
const koDrillForms = KoForm.values;

/// Forms picked when the drill opens: the first ones a beginner learns.
const koStarterForms = {KoForm.polite, KoForm.past, KoForm.formal, KoForm.negative};

String koFormLabel(AppLocalizations l10n, KoForm f) => l10n.koConjForm(f.name);

/// A course verb or adjective with its conjugator.
class KoConjWord {
  const KoConjWord(this.word, this.conj);
  final KoWord word;
  final KoConjugator conj;

  bool get adjective => conj.adjective;
}

/// Put [word] in [form]: one of [options] is right.
class KoConjQuestion {
  const KoConjQuestion({required this.word, required this.form, required this.options, required this.answer});
  final KoConjWord word;
  final KoForm form;
  final List<String> options;
  final int answer;

  String get right => options[answer];

  /// Item id of its `ko_conjugation` card: "wordId:form".
  String get cardItemId => koConjItemId(word.word.id, form);
}

String koConjItemId(int wordId, KoForm form) => '$wordId:${form.name}';

/// Up to [count] questions over [words] in [forms]: a new word each time
/// while there are any, the least asked form first.
List<KoConjQuestion> buildKoConjQuestions(List<KoConjWord> words, Set<KoForm> forms, {int count = 10, Random? random}) {
  final rnd = random ?? Random();
  final pairs = <(KoConjWord, KoForm, List<String>)>[];
  for (final w in words) {
    for (final f in forms) {
      if (!w.conj.forms.contains(f)) continue;
      final wrong = w.conj.distractors(f);
      if (wrong.length == 3) pairs.add((w, f, wrong));
    }
  }
  pairs.shuffle(rnd);
  final picked = <(KoConjWord, KoForm, List<String>)>[];
  final usedWords = <int>{};
  final formCount = <KoForm, int>{};
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
        final right = w.conj.conjugate(f);
        final options = [right, ...wrong]..shuffle(rnd);
        return KoConjQuestion(word: w, form: f, options: options, answer: options.indexOf(right));
      }(),
  ];
}

/// The course's verbs and adjectives (이다 and 아니다 are left out: they go
/// with nouns and are taught as grammar).
List<KoConjWord> koConjWords(List<KoWord> words) => [
  for (final w in words)
    if (w.topic == 'verbs' || w.topic == 'adjectives')
      if (KoConjugator.of(w.hangul, adjective: w.topic == 'adjectives') case final conj?) KoConjWord(w, conj),
];

final koConjWordsProvider = FutureProvider<List<KoConjWord>>((ref) async {
  final words = (await ref.watch(koWordsProvider.future)).words;
  return koConjWords(words);
});
