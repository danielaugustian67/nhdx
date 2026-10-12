import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/level_badge.dart';
import '../../l10n/app_localizations.dart';
import '../learn/path_providers.dart';
import '../srs/srs_providers.dart';
import 'bookmark_button.dart';
import 'word_providers.dart';

/// Opens the detail page of a word above the current tab.
Future<void> openWord(BuildContext context, int wordId) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => WordDetailScreen(wordId: wordId)));

/// Word detail (PRD F2, ui-design §5.4): reading above a large headword,
/// romaji, JLPT, word class, numbered senses grouped by part of speech,
/// other spellings and the course kanji in the word. Long-press on Japanese
/// text copies it. Sections that have no data are left out, not greyed.
class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({super.key, required this.wordId, this.bottom});

  final int wordId;

  /// Pinned action below the content ("Tambah ke belajar").
  final Widget? bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entry = ref.watch(wordEntryProvider(wordId));
    final word = entry.value;
    return Scaffold(
      appBar: AppBar(
        actions: [if (word != null) BookmarkButton(wordId: wordId, label: word.headword)],
      ),
      body: switch (entry) {
        AsyncData(value: null) => _Message(l10n.entryMissing),
        AsyncData(value: final w?) => _Body(word: w),
        AsyncError() => _Message(l10n.dictionaryFailed),
        _ => const SizedBox.shrink(),
      },
      bottomNavigationBar: bottom ?? (word == null ? null : _StudyBar(word: word)),
    );
  }
}

/// "Tambah ke belajar" → "Sudah di belajar" (PRD F7).
class _StudyBar extends ConsumerWidget {
  const _StudyBar({required this.word});
  final WordEntry word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inStudy = ref.watch(studyWordIdsProvider.select((ids) => ids.value?.contains(word.id) ?? false));
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
                  addWordCard(ref, word.id, word.headword);
                },
              ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.word});
  final WordEntry word;

  static const _ja = Locale('ja');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final muted = AppText.bodySmall.copyWith(color: c.inkMuted);
    final kanjiByLiteral = {for (final k in ref.watch(allKanjiProvider).value ?? const <Kanji>[]) k.literal: k};
    final wordKanji = <Kanji>[
      for (final ch in {...word.headword.split('')}) ?kanjiByLiteral[ch],
    ];
    final wordClass = switch ((word.verbGroup, word.adjType)) {
      ('godan', _) => l10n.verbGodan,
      ('ichidan', _) => l10n.verbIchidan,
      ('irregular', _) => l10n.verbIrregular,
      (_, 'i') => l10n.adjI,
      (_, 'na') => l10n.adjNa,
      _ => null,
    };
    final others = [...word.kanjiForms, ...word.kanaForms].where((f) => f != word.headword && f != word.kana);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xxl),
      children: [
        if (word.kanji != null)
          _Copyable(
            text: word.kana,
            child: Text(
              word.kana,
              locale: _ja,
              style: AppText.bodyJp.copyWith(fontSize: 22, color: c.inkMuted),
            ),
          ),
        _Copyable(
          text: word.headword,
          child: Text(
            word.headword,
            locale: _ja,
            style: AppText.displayWord.copyWith(color: c.ink),
          ),
        ),
        const SizedBox(height: AppSpace.s),
        Wrap(
          spacing: AppSpace.m,
          runSpacing: AppSpace.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(word.romaji, style: AppText.body.copyWith(color: c.inkMuted)),
            if (word.jlpt case final level?) LevelBadge(level),
            if (word.isCommon) _Tag(l10n.commonWord),
          ],
        ),
        if (wordClass != null) ...[const SizedBox(height: AppSpace.xs), Text(wordClass, style: muted)],
        const SizedBox(height: AppSpace.l),
        Divider(color: c.line),
        const SizedBox(height: AppSpace.s),
        for (final (i, sense) in word.senses.indexed) ...[
          // Part of speech once per group of senses that share it.
          if (sense.pos.isNotEmpty && (i == 0 || sense.pos.join() != word.senses[i - 1].pos.join()))
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.m, bottom: AppSpace.xs),
              child: Text(sense.pos.join(' · '), style: AppText.label.copyWith(color: c.primaryText)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text('${sense.number}', style: AppText.body.copyWith(color: c.inkMuted)),
                ),
                Expanded(
                  child: Text(sense.gloss, style: AppText.body.copyWith(color: c.ink)),
                ),
              ],
            ),
          ),
        ],
        if (others.isNotEmpty) ...[
          _Section(l10n.otherForms),
          Wrap(
            spacing: AppSpace.l,
            runSpacing: AppSpace.xs,
            children: [
              for (final f in others)
                _Copyable(
                  text: f,
                  child: Text(
                    f,
                    locale: _ja,
                    style: AppText.bodyJp.copyWith(color: c.ink),
                  ),
                ),
            ],
          ),
        ],
        if (wordKanji.isNotEmpty) ...[
          _Section(l10n.trackKanji),
          for (final k in wordKanji)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Copyable(
                    text: k.literal,
                    child: Text(
                      k.literal,
                      locale: _ja,
                      style: AppText.rowHeadword.copyWith(fontSize: 28, height: 1.2, color: c.ink),
                    ),
                  ),
                  const SizedBox(width: AppSpace.l),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(k.meanings.take(3).join(', '), style: AppText.body.copyWith(color: c.ink)),
                        Text(
                          [
                            ...k.onyomi.take(2),
                            // KANJIDIC marks okurigana with a dot: た.べる → た(べる)
                            for (final r in k.kunyomi.take(2)) r.contains('.') ? '${r.replaceFirst('.', '(')})' : r,
                          ].join('、'),
                          locale: _ja,
                          style: AppText.bodySmallJp.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  LevelBadge(k.jlpt),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.s),
    child: Text(title, style: AppText.title2.copyWith(fontSize: 18, color: context.colors.ink)),
  );
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

/// Long-press copies [text] (ui-design §5.4).
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
