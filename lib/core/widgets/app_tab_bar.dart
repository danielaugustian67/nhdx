import 'package:flutter/material.dart';

/// One tab of [AppTabBar].
typedef AppTab = ({Widget icon, Widget? selectedIcon, String label});

/// The bottom tab bar. Looks like Material's NavigationBar, but each tab is
/// as wide as its label plus an even share of the rest, so the space between
/// labels is the same whether they are short ("Kana") or long ("Dictionary").
/// Equal-width tabs left wide gaps around short labels and almost none
/// between long ones.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.tabs, required this.selectedIndex, required this.onSelected});

  final List<AppTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const height = 80.0;
  static const indicatorSize = Size(64, 32);

  /// Narrowest a tab gets: the indicator's width, still a roomy tap target.
  static const minTab = 64.0;

  /// Widths that give every label the same gap, keeping each at least
  /// [minTab]; equal shares if even the minimums do not fit.
  static List<double> widths(List<double> labels, double total) {
    final n = labels.length;
    if (n * minTab >= total) return List.filled(n, total / n);
    double sum(double gap) => labels.fold(0, (s, w) => s + (w + gap < minTab ? minTab : w + gap));
    if (sum(0) > total) {
      // Labels alone are too wide: share by label width.
      final all = labels.fold<double>(0, (s, w) => s + w);
      return [for (final w in labels) total * w / all];
    }
    // The widest gap that still fits.
    var low = 0.0;
    var high = total;
    for (var i = 0; i < 40; i++) {
      final mid = (low + high) / 2;
      if (sum(mid) > total) {
        high = mid;
      } else {
        low = mid;
      }
    }
    final widths = [for (final w in labels) w + low < minTab ? minTab : w + low];
    // Hand the rounding leftover to every tab alike.
    final rest = (total - widths.fold<double>(0, (s, w) => s + w)) / n;
    return [for (final w in widths) w + rest];
  }

  @override
  Widget build(BuildContext context) {
    final theme = NavigationBarTheme.of(context);
    const selected = {WidgetState.selected};
    final labelStyle = theme.labelTextStyle?.resolve(selected) ?? Theme.of(context).textTheme.labelMedium!;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return Material(
      color: theme.backgroundColor,
      elevation: theme.elevation ?? 0,
      child: SafeArea(
        top: false,
        child: Container(
          height: height,
          // Keeps the end tabs' indicator off the screen edge.
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final labels = [
                for (final tab in tabs)
                  (TextPainter(
                    text: TextSpan(text: tab.label, style: labelStyle),
                    textScaler: scaler,
                    textDirection: direction,
                    maxLines: 1,
                  )..layout()).width,
              ];
              final sizes = widths(labels, constraints.maxWidth);
              return Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    SizedBox(
                      width: sizes[i],
                      child: _Tab(
                        tab: tabs[i],
                        selected: i == selectedIndex,
                        index: i,
                        count: tabs.length,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.index,
    required this.count,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final int index;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = NavigationBarTheme.of(context);
    final states = {if (selected) WidgetState.selected};
    final icon = theme.iconTheme?.resolve(states) ?? const IconThemeData();
    final label = theme.labelTextStyle?.resolve(states) ?? Theme.of(context).textTheme.labelMedium!;
    final localizations = MaterialLocalizations.of(context);
    return Semantics(
      container: true,
      selected: selected,
      button: true,
      label: '${tab.label}\n${localizations.tabLabel(tabIndex: index + 1, tabCount: count)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: AppTabBar.indicatorSize.width,
              height: AppTabBar.indicatorSize.height,
              decoration: ShapeDecoration(
                color: selected ? theme.indicatorColor : theme.indicatorColor?.withValues(alpha: 0),
                shape: const StadiumBorder(),
              ),
              child: IconTheme.merge(
                data: icon,
                child: Center(child: selected ? tab.selectedIcon ?? tab.icon : tab.icon),
              ),
            ),
            const SizedBox(height: 4),
            Text(tab.label, style: label, maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
          ],
        ),
      ),
    );
  }
}
