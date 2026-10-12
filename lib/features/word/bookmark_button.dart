import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import 'word_providers.dart';

/// Star toggle for a dictionary word (48 dp target). [label] is stored as
/// the bookmark's label_snapshot, shown if the entry ever disappears.
class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({super.key, required this.wordId, required this.label});

  final int wordId;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(bookmarkedIdsProvider.select((ids) => ids.contains(wordId)));
    return IconButton(
      tooltip: on ? l10n.bookmarkRemove : l10n.bookmarkAdd,
      isSelected: on,
      onPressed: () {
        HapticFeedback.selectionClick();
        setBookmark(ref, wordId, on: !on, label: label);
      },
      icon: AnimatedSwitcher(
        duration: AppDurations.bookmark,
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: Icon(
          on ? Icons.star_rounded : Icons.star_outline_rounded,
          key: ValueKey(on),
          color: on ? context.colors.gold : context.colors.inkMuted,
        ),
      ),
    );
  }
}
