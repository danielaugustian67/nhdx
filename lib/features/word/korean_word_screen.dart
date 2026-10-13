import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/korean_dict_db.dart';
import '../../core/database/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/speak_button.dart';
import '../../l10n/app_localizations.dart';
import '../learn/path_providers.dart';
import '../srs/srs_providers.dart';
import 'bookmark_button.dart';

/// One Korean dictionary entry for its page.
final koEntryProvider = FutureProvider.family<KoEntry?, int>(
  (ref, id) async => (await ref.watch(koreanDictProvider.future)).entry(id),
);

/// Korean word page, the twin of the Japanese word detail: Hangul, its
/// romanization and hanja, the course meaning (Indonesian for course words)
/// and Wiktionary's meanings grouped by homonym and part of speech.
class KoreanWordScreen extends ConsumerWidget {
  const KoreanWordScreen({super.key, required this.wordId});

  final int wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entry = ref.watch(koEntryProvider(wordId));
    final word = entry.value;
    return Scaffold(
      appBar: AppBar(
        actions: [if (word != null) BookmarkButton(wordId: wordId, label: word.hangul)],
      ),
      body: switch (entry) {
        AsyncData(value: null) => _Message(l10n.entryMissing),
        AsyncData(value: final w?) => _Body(word: w),
        AsyncError() => _Message(l10n.dictionaryFailed),
        _ => const SizedBox.shrink(),
      },
      bottomNavigationBar: word == null ? null : _StudyBar(word: word),
    );
  }
}

/// "Tambah ke belajar" adds a `ko_word` card, the same card the course gives.
class _StudyBar extends ConsumerWidget {
  const _StudyBar({required this.word});
  final KoEntry word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inStudy = ref.watch(studyKoWordIdsProvider.select((ids) => ids.value?.contains(word.id) ?? false));
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s, AppSpace.screen, AppSpace.l),
      child: AnimatedSwitcher(
        duration: AppDurations.crossFade,
        child: inStudy
            ? OutlinedButton.icon(
                key: const ValueKey('in'),
                onPressed: null,
                icon: const Icon(Icons.check_rounded),
                label: Text(l10n.inStudy),
              )
            : ChunkyButton(
                key: const ValueKey('add'),
                icon: Icons.add_rounded,
                label: l10n.addToStudy,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  addWordCard(ref, word.id, word.hangul);
                },
              ),
      ),
    );
  }
}

/// Wiktionary's part of speech in the app language (Settings → Language).
String? posLabel(AppLocalizations l10n, String? pos) => switch (pos) {
  null => null,
  'noun' => l10n.posNoun,
  'verb' => l10n.posVerb,
  'adj' => l10n.posAdjective,
  'adv' => l10n.posAdverb,
  'intj' => l10n.posInterjection,
  'num' => l10n.posNumeral,
  'pron' => l10n.posPronoun,
  'det' => l10n.posDeterminer,
  'particle' => l10n.posParticle,
  'phrase' => l10n.posPhrase,
  'counter' => l10n.posCounter,
  'proverb' => l10n.posProverb,
  'contraction' => l10n.posContraction,
  'name' => l10n.posName,
  _ => pos,
};

class _Body extends ConsumerWidget {
  const _Body({required this.word});
  final KoEntry word;

  static const _ko = Locale('ko');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final muted = AppText.bodySmall.copyWith(color: c.inkMuted);
    final topic = word.topic == null ? null : ref.watch(koWordsProvider).value?.topics[word.topic];
    // The course meaning comes first; Wiktionary's numbered meanings follow.
    final courseMeaning = word.inCourse ? word.meaning(l10n.localeName) : null;
    var number = 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xxl),
      children: [
        if (word.hanja case final hanja?)
          _Copyable(
            text: hanja,
            child: Text(
              hanja,
              locale: _ko,
              style: AppText.body.copyWith(fontSize: 22, color: c.inkMuted),
            ),
          ),
        _Copyable(
          text: word.hangul,
          child: Text(
            word.hangul,
            locale: _ko,
            style: AppText.displayWord.copyWith(color: c.ink),
          ),
        ),
        const SizedBox(height: AppSpace.s),
        Wrap(
          spacing: AppSpace.m,
          runSpacing: AppSpace.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(word.romaja, style: AppText.body.copyWith(color: c.inkMuted)),
            if (topic != null) _Tag(l10n.koreanCourseWord(topic.of(l10n.localeName))),
            SpeakButton(word.hangul, size: 24),
          ],
        ),
        if (courseMeaning != null) ...[
          const SizedBox(height: AppSpace.m),
          Text(courseMeaning, style: AppText.title2.copyWith(color: c.ink)),
        ],
        const SizedBox(height: AppSpace.l),
        Divider(color: c.line),
        const SizedBox(height: AppSpace.s),
        Text(l10n.wiktionaryMeanings, style: muted),
        for (final (g, sense) in word.senses.indexed) ...[
          if (sense.pos != null || sense.hanja != null)
            Padding(
              padding: EdgeInsets.only(top: g == 0 ? AppSpace.s : AppSpace.m, bottom: AppSpace.xs),
              child: Text(
                [?posLabel(l10n, sense.pos), ?sense.hanja].join(' · '),
                locale: _ko,
                style: AppText.label.copyWith(color: c.primaryText),
              ),
            ),
          for (final gloss in sense.glosses)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${++number}', style: AppText.body.copyWith(color: c.inkMuted)),
                  ),
                  Expanded(
                    child: Text(gloss, style: AppText.body.copyWith(color: c.ink)),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppSpace.xl),
        Text(l10n.wiktionarySource, style: muted),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: context.colors.line),
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: Text(text, style: AppText.label.copyWith(color: context.colors.inkMuted)),
  );
}

/// Long-press copies [text].
class _Copyable extends StatelessWidget {
  const _Copyable({required this.text, required this.child});
  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onLongPress: () {
      Clipboard.setData(ClipboardData(text: text));
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).copied}: $text')));
    },
    child: child,
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpace.screen),
    child: Text(text, style: AppText.body.copyWith(color: context.colors.inkMuted)),
  );
}
