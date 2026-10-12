import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

/// Quick search (ui-design §3.1): from any tab, the magnifier or a pull down
/// at the top opens Kamus with the keyboard up. The shell switches tab; the
/// search screen focuses its field and clears the request.
class QuickSearch extends Notifier<bool> {
  @override
  bool build() => false;

  void request() {
    HapticFeedback.selectionClick();
    state = true;
  }

  void done() => state = false;
}

final quickSearchProvider = NotifierProvider<QuickSearch, bool>(QuickSearch.new);

class QuickSearchButton extends ConsumerWidget {
  const QuickSearchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: AppLocalizations.of(context).quickSearch,
    icon: const Icon(Icons.search),
    onPressed: () => ref.read(quickSearchProvider.notifier).request(),
  );
}

/// Pulling down past the top of a tab's vertical list by [threshold] asks for
/// a quick search. Only a finger drag counts, not a fling hitting the top.
class PullToSearch extends ConsumerStatefulWidget {
  const PullToSearch({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  static const threshold = 120.0;

  @override
  ConsumerState<PullToSearch> createState() => _PullToSearchState();
}

class _PullToSearchState extends ConsumerState<PullToSearch> {
  double _pulled = 0;

  bool _onScroll(ScrollNotification n) {
    if (!widget.enabled || n.metrics.axis != Axis.vertical) return false;
    switch (n) {
      case OverscrollNotification(:final overscroll, dragDetails: _?) when overscroll < 0:
        _pulled -= overscroll;
        if (_pulled >= PullToSearch.threshold) {
          _pulled = double.negativeInfinity; // once per drag
          ref.read(quickSearchProvider.notifier).request();
        }
      // Scrolling back into the list undoes the pull.
      case ScrollUpdateNotification() when _pulled > 0:
      case ScrollStartNotification() || ScrollEndNotification():
        _pulled = 0;
      default:
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child);
}
