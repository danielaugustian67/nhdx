import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/widgets/app_tab_bar.dart';

void main() {
  // Rough label widths of Today, Kana, Dictionary, Collection, Me.
  const labels = [38.0, 31.0, 66.0, 66.0, 20.0];

  test('the space between labels is the same, short or long', () {
    final widths = AppTabBar.widths(labels, 411);
    expect(widths.fold<double>(0, (s, w) => s + w), closeTo(411, 0.001));
    // Gap between neighbours = half the spare room on each side.
    double gap(int i) => (widths[i] - labels[i]) / 2 + (widths[i + 1] - labels[i + 1]) / 2;
    for (var i = 0; i < 3; i++) {
      expect(gap(i), closeTo(gap(0), 0.5), reason: 'gap after tab $i');
    }
    expect(widths.last, greaterThanOrEqualTo(AppTabBar.minTab), reason: 'a short label keeps a tap target');
  });

  test('a narrow screen falls back to equal tabs', () {
    expect(AppTabBar.widths(labels, 300), List.filled(5, 60.0));
  });

  test('labels wider than the screen share it by width', () {
    final widths = AppTabBar.widths([200, 200, 200, 200, 200], 400);
    expect(widths, List.filled(5, 80.0));
  });
}
