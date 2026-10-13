import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../l10n/app_localizations.dart';
import '../learn/study_language.dart';
import '../learn/vocab_path.dart';
import 'free_study_providers.dart';
import 'free_study_session_screen.dart';

/// Hafalan Bebas (free study): pick any groups of kana, kanji or words and go
/// through them as flashcards, with no lock, score or daily limit. Groups are
/// the "Kenali" lessons of the path; each tile shows how many of its items are
/// marked "Hafal".
class FreeStudyScreen extends ConsumerStatefulWidget {
  const FreeStudyScreen({super.key});

  @override
  ConsumerState<FreeStudyScreen> createState() => _FreeStudyScreenState();
}

class _FreeStudyScreenState extends ConsumerState<FreeStudyScreen> {
  StudyKind? _kind;
  final _selected = <String>{};

  /// The sources of the language being learned.
  List<StudyKind> get kinds => StudyKind.of(ref.watch(studyLanguageProvider).value ?? StudyLanguage.ja);

  /// The source picked here, else the last one used if it belongs to the
  /// language being learned, else its first.
  StudyKind get kind {
    final kinds = this.kinds;
    final k = _kind ?? ref.watch(studyChoiceProvider).kind;
    return kinds.contains(k) ? k : kinds.first;
  }

  void _setKind(StudyKind k) => setState(() {
    _kind = k;
    _selected.clear();
  });

  void _toggle(String id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));

  Future<void> _start(StudyKind kind, List<StudyGroup> groups, {bool notYetOnly = false}) async {
    final choice = ref.read(studyChoiceProvider);
    final marks = ref.read(studyMarksProvider);
    var items = [
      for (final g in groups)
        for (final item in g.items)
          if (!notYetOnly || marks[studyKey(item)] == StudyMark.notYet) item,
    ];
    if (items.isEmpty) return;
    if (choice.shuffle) items = [...items]..shuffle(math.Random());
    if (!notYetOnly) {
      ref
          .read(studyChoiceProvider.notifier)
          .update(choice.copyWith(kind: kind, groups: [for (final g in groups) g.id]));
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FreeStudySessionScreen(items: items, meaningFirst: choice.meaningFirst),
        fullscreenDialog: true,
      ),
    );
    if (mounted) setState(_selected.clear);
  }

  Future<void> _confirmReset(Set<String> keys, String body) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.freeStudyResetTitle),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.freeStudyResetConfirm)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ref.read(studyMarksProvider.notifier).clear(keys);
    setState(_selected.clear);
    messenger.showSnackBar(SnackBar(content: Text(l10n.freeStudyResetDone)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final kind = this.kind;
    final choice = ref.watch(studyChoiceProvider);
    final marks = ref.watch(studyMarksProvider);
    final groups = ref.watch(studyGroupsProvider(kind)).value;

    final selectedGroups = [
      for (final g in groups ?? const <StudyGroup>[])
        if (_selected.contains(g.id)) g,
    ];
    final selectedCount = selectedGroups.fold(0, (n, g) => n + g.items.length);
    final notYet = [
      for (final g in groups ?? const <StudyGroup>[])
        for (final item in g.items)
          if (marks[studyKey(item)] == StudyMark.notYet) item,
    ];
    final last = [
      if (choice.kind == kind)
        for (final g in groups ?? const <StudyGroup>[])
          if (choice.groups.contains(g.id)) g,
    ];
    final lastItems = [for (final g in last) ...g.items];
    final lastKnown = lastItems.where((i) => marks[studyKey(i)] == StudyMark.known).length;

    final labels = {
      StudyKind.hiragana: l10n.hiragana,
      StudyKind.katakana: l10n.katakana,
      StudyKind.kanji: l10n.trackKanji,
      StudyKind.word: l10n.trackVocab,
      StudyKind.hangul: l10n.hangul,
      StudyKind.koWord: l10n.koreanVocab,
      StudyKind.collection: l10n.freeStudyCollection,
      StudyKind.forgotten: l10n.freeStudyForgotten,
    };
    // Marks the reset would clear: the picked groups, else the whole kind.
    final resetKeys = {
      for (final g in selectedGroups.isEmpty ? groups ?? const <StudyGroup>[] : selectedGroups)
        for (final item in g.items)
          if (marks.containsKey(studyKey(item))) studyKey(item),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.freeStudy),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: l10n.freeStudyReset,
            onPressed: resetKeys.isEmpty
                ? null
                : () => _confirmReset(
                    resetKeys,
                    selectedGroups.isEmpty
                        ? l10n.freeStudyResetAll(labels[kind]!)
                        : l10n.freeStudyResetSelected(selectedGroups.length),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.m),
                    sliver: SliverList.list(
                      children: [
                        Text(l10n.freeStudyHint, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                        const SizedBox(height: AppSpace.m),
                        Wrap(
                          spacing: AppSpace.s,
                          runSpacing: AppSpace.s,
                          children: [
                            for (final k in kinds)
                              ChoiceChip(label: Text(labels[k]!), selected: k == kind, onSelected: (_) => _setKind(k)),
                          ],
                        ),
                        const SizedBox(height: AppSpace.s),
                        Wrap(
                          spacing: AppSpace.s,
                          runSpacing: AppSpace.s,
                          children: [
                            FilterChip(
                              label: Text(l10n.freeStudyShuffle),
                              selected: choice.shuffle,
                              onSelected: (v) =>
                                  ref.read(studyChoiceProvider.notifier).update(choice.copyWith(shuffle: v)),
                            ),
                            FilterChip(
                              label: Text(l10n.freeStudyMeaningFirst),
                              selected: choice.meaningFirst,
                              onSelected: (v) =>
                                  ref.read(studyChoiceProvider.notifier).update(choice.copyWith(meaningFirst: v)),
                            ),
                          ],
                        ),
                        if (last.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.m),
                          _Shortcut(
                            icon: Icons.play_arrow_rounded,
                            label: l10n.freeStudyContinue(
                              '${_title(last.first)}${last.length > 1 ? ' +${last.length - 1}' : ''}',
                            ),
                            trailing: '$lastKnown/${lastItems.length}',
                            onTap: () => _start(kind, last),
                          ),
                        ],
                        if (notYet.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.s),
                          _Shortcut(
                            icon: Icons.star_rounded,
                            label: l10n.freeStudyNotYetGroup(notYet.length),
                            onTap: () => _start(kind, groups!, notYetOnly: true),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (groups == null)
                    const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  else if (groups.isEmpty && !kind.fromPath)
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpace.screen),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          kind == StudyKind.collection ? l10n.freeStudyCollectionEmpty : l10n.freeStudyForgottenEmpty,
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(color: c.inkMuted),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.l),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: AppSpace.s,
                          crossAxisSpacing: AppSpace.s,
                          // Grows with the text size so large fonts still fit.
                          mainAxisExtent: MediaQuery.textScalerOf(context).scale(96) + 2 * AppSpace.m,
                        ),
                        itemCount: groups.length,
                        itemBuilder: (context, i) {
                          final g = groups[i];
                          final known = g.items.where((it) => marks[studyKey(it)] == StudyMark.known).length;
                          return _GroupTile(
                            key: ValueKey(g.id),
                            title: _title(g),
                            unit: g.label ?? l10n.unitNumber(g.unit),
                            known: known,
                            total: g.items.length,
                            selected: _selected.contains(g.id),
                            onTap: () => _toggle(g.id),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s, AppSpace.screen, AppSpace.screen),
              child: ChunkyButton(
                label: selectedCount == 0 ? l10n.freeStudyPickFirst : l10n.freeStudyStart(selectedCount),
                icon: Icons.style_rounded,
                onPressed: selectedCount == 0 ? null : () => _start(kind, selectedGroups),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What a group holds, short enough for a tile: "あいうえお", "日月火水木",
/// "学生・先生・…".
String _title(StudyGroup g) {
  if (g.items.any((i) => i is VocabWord)) {
    final words = g.items.take(2).map((w) => w.literal).join('・');
    return g.items.length > 2 ? '$words…' : words;
  }
  return g.items.map((i) => i.literal).join();
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.label, required this.onTap, this.trailing});
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: BorderSide(color: c.primaryText.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTap + 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
            child: Row(
              children: [
                Icon(icon, color: c.primaryText),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: Text(
                    label,
                    locale: const Locale('ja'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                  ),
                ),
                if (trailing != null) Text(trailing!, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A group to pick: its items, unit, and one dot per item (filled = "Hafal").
class _GroupTile extends StatelessWidget {
  const _GroupTile({
    super.key,
    required this.title,
    required this.unit,
    required this.known,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String unit;
  final int known;
  final int total;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final all = known == total;
    return Semantics(
      selected: selected,
      button: true,
      label: l10n.freeStudyGroupLabel(title, known, total),
      excludeSemantics: true,
      child: Material(
        color: selected ? c.primary.withValues(alpha: 0.18) : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(color: selected ? c.primaryText : c.line, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(unit, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                    ),
                    Icon(
                      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 20,
                      color: selected ? c.primaryText : c.line,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  locale: const Locale('ja'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyJp.copyWith(fontSize: 22, color: c.ink, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpace.xs),
                Row(
                  children: [
                    if (total <= 12)
                      for (var i = 0; i < total; i++)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 3),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: i < known ? (all ? c.success : c.primaryText) : c.line,
                          ),
                        )
                    else
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: known / total,
                            minHeight: 6,
                            color: all ? c.success : c.primaryText,
                            backgroundColor: c.line,
                          ),
                        ),
                      ),
                    if (total <= 12) const Spacer(),
                    const SizedBox(width: AppSpace.xs),
                    Text('$known/$total', style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
