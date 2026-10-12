import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../search/search_service.dart';
import '../search/widgets/word_row.dart';
import 'bookmark_button.dart';
import 'word_detail_screen.dart';
import 'word_providers.dart';

/// A word in a list (search, browse, collection): tap opens the detail
/// page, the star toggles the bookmark, swiping right bookmarks quickly
/// (ui-design §4.5).
class WordTile extends ConsumerWidget {
  const WordTile({super.key, required this.hit, this.onOpen});

  final SearchHit hit;

  /// Called before the detail page opens (e.g. to store the query).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(bookmarkedIdsProvider.select((ids) => ids.contains(hit.wordId)));
    return Dismissible(
      key: ValueKey('word-${hit.wordId}'),
      direction: DismissDirection.startToEnd,
      // The row stays; the swipe only toggles the bookmark.
      confirmDismiss: (_) async {
        HapticFeedback.selectionClick();
        setBookmark(ref, hit.wordId, on: !on, label: hit.headword);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(on ? l10n.bookmarkRemove : l10n.bookmarked), duration: const Duration(seconds: 2)),
          );
        return false;
      },
      background: Container(
        color: c.gold.withValues(alpha: .18),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
        child: Icon(on ? Icons.star_outline_rounded : Icons.star_rounded, color: c.gold),
      ),
      child: WordRow(
        hit: hit,
        onTap: () {
          onOpen?.call();
          openWord(context, hit.wordId);
        },
        trailing: BookmarkButton(wordId: hit.wordId, label: hit.headword),
      ),
    );
  }
}
