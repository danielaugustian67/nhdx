import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/l10n/app_localizations.dart';

void main() {
  test('English counts use the singular for one', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.reviewLeft(1), '1 card left');
    expect(en.reviewLeft(3), '3 cards left');
    expect(en.matchMistakes(1), '1 wrong pair');
    expect(en.activityTotal(1, 170), '1 card · 170 XP');
    expect(en.nodeWords(10, '意味、一つ…'), '10 words: 意味、一つ…');
    // Indonesian has no plural form.
    final id = await AppLocalizations.delegate.load(const Locale('id'));
    expect(id.cardsCount(1), '1 kartu');
  });
}
