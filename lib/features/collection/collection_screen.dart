import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import '../../core/database/user_db.dart';
import '../../core/text/normalize.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../search/search_service.dart';
import '../search/widgets/word_row.dart';
import '../learn/study_language.dart';
import '../search/quick_search.dart';
import '../word/bookmark_button.dart';
import '../word/word_detail_screen.dart';
import '../word/word_providers.dart';

/// Koleksi tab (PRD F3): bookmarks newest first, JLPT filter, search inside
/// the collection, swipe left to delete with "Urungkan" (3 s).
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _search = TextEditingController();

  /// null = all levels, 0 = words without a JLPT level.
  int? _level;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches((Bookmark, WordBrief?) item) {
    final (mark, word) = item;
    if (_level != null && (word?.jlpt ?? 0) != _level) return false;
    final q = _search.text.trim();
    if (q.isEmpty) return true;
    if (word == null) return mark.labelSnapshot.contains(q);
    final latin = normalizeLatin(q);
    final jp = normalizeJp(q);
    return normalizeJp(word.headword).contains(jp) ||
        normalizeJp(word.kana).contains(jp) ||
        word.romaji.contains(latin) ||
        normalizeLatin(word.gloss).contains(latin);
  }

  void _remove(Bookmark mark) {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.selectionClick();
    setBookmark(ref, mark.wordId, on: false, label: mark.labelSnapshot);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.removedFromCollection),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => setBookmark(ref, mark.wordId, on: true, label: mark.labelSnapshot, restore: true),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final all = ref.watch(collectionProvider).value ?? const <(Bookmark, WordBrief?)>[];
    // Korean words have no JLPT level to filter by.
    final korean = ref.watch(studyLanguageProvider).value == StudyLanguage.ko;
    if (korean) _level = null;
    final items = all.where(_matches).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabCollection), actions: const [QuickSearchButton()]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (all.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: SizedBox(
                height: AppSizes.searchFieldHeight,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  autocorrect: false,
                  enableSuggestions: false,
                  style: AppText.body.copyWith(color: c.ink),
                  decoration: InputDecoration(
                    hintText: l10n.collectionSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.searchClear,
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
              ),
            ),
            if (korean)
              const SizedBox(height: AppSpace.s)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: AppSpace.s),
                child: Row(
                  spacing: AppSpace.s,
                  children: [
                    for (final level in [null, 5, 4, 3, 2, 1, 0])
                      ChoiceChip(
                        label: Text(switch (level) {
                          null => l10n.allLevels,
                          0 => l10n.noLevel,
                          _ => 'N$level',
                        }),
                        selected: _level == level,
                        onSelected: (_) => setState(() => _level = level),
                      ),
                  ],
                ),
              ),
            Divider(color: c.line, height: 1),
          ],
          Expanded(
            child: all.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpace.screen),
                    child: Text(l10n.collectionEmpty, style: AppText.body.copyWith(color: c.inkMuted)),
                  )
                : ListView.separated(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, i) {
                      final (mark, word) = items[i];
                      return Dismissible(
                        key: ValueKey('bookmark-${mark.wordId}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _remove(mark),
                        background: Container(
                          color: c.seal.withValues(alpha: .18),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                          child: Icon(Icons.delete_outline_rounded, color: c.seal),
                        ),
                        child: word == null
                            ? _Orphan(mark: mark, onRemove: () => _remove(mark))
                            : WordRow(
                                hit: SearchHit.fromBrief(word),
                                onTap: () => openWord(context, word.id),
                                trailing: BookmarkButton(wordId: word.id, label: word.headword),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// A bookmark whose entry left the dictionary (PRD §7): label snapshot,
/// explanation and a remove button.
class _Orphan extends StatelessWidget {
  const _Orphan({required this.mark, required this.onRemove});
  final Bookmark mark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.m, AppSpace.s, AppSpace.m),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mark.labelSnapshot,
                  locale: Locale(mark.wordId >= koWordIdBase ? 'ko' : 'ja'),
                  style: AppText.rowHeadword.copyWith(color: c.inkMuted),
                ),
                Text(l10n.entryMissing, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
          TextButton(onPressed: onRemove, child: Text(l10n.remove)),
        ],
      ),
    );
  }
}
