import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/database/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/game_card.dart';
import '../../l10n/app_localizations.dart';

/// "1.0.0 (1)": pubspec version and build number.
final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty ? info.version : '${info.version} (${info.buildNumber})';
});

/// About & attribution (PRD F9): every dataset and font the app ships, with
/// its license, plus Flutter's license page (fonts are registered there in
/// `licenses.dart`).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const _sources = [
    (
      'JMdict',
      'Electronic Dictionary Research and Development Group (EDRDG)',
      'CC BY-SA 4.0',
      'This application uses the JMdict dictionary file, the property of the EDRDG, '
          'used in conformance with the Group\'s licence. edrdg.org',
    ),
    ('KANJIDIC2', 'EDRDG', 'CC BY-SA 4.0', 'Kanji meanings and readings. edrdg.org'),
    ('KanjiVG', '© Ulrich Apel', 'CC BY-SA 3.0', 'Stroke order data for kana and kanji. kanjivg.tagaini.net'),
    (
      'JLPT levels',
      'Jonathan Waller (tanos.co.uk), stephenmk/yomitan-jlpt-vocab',
      'CC BY',
      'Word levels are community estimates; the official JLPT publishes no word lists.',
    ),
    (
      'Wiktionary (Korean)',
      'Wiktionary contributors, extracted by kaikki.org (wiktextract)',
      'CC BY-SA 4.0 / GFDL',
      'Korean dictionary meanings, romanization and hanja. en.wiktionary.org',
    ),
    (
      'Fonts',
      'Plus Jakarta Sans, Zen Kaku Gothic New, Shippori Mincho, Klee One',
      'SIL Open Font License 1.1',
      'Bundled as subsets.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final app = ref.watch(_appVersionProvider).value;
    final dataset = ref.watch(dictionaryProvider).value?.meta('dataset_version');
    final content = ref.watch(contentProvider).value?.meta('content_version');
    final schema = ref.watch(userDbProvider).value?.schemaVersion;
    final muted = AppText.bodySmall.copyWith(color: c.inkMuted);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutAttribution)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          Text(l10n.appTitle, style: AppText.title1.copyWith(color: c.ink)),
          if (app != null) Text(l10n.appVersion(app), style: AppText.body.copyWith(color: c.ink)),
          // Quoted in support requests: which data and schema this install has.
          SelectableText(
            [
              if (dataset != null) l10n.datasetVersion(dataset),
              if (content != null) l10n.contentVersion(content),
              if (schema != null) l10n.schemaVersion(schema),
            ].join(' · '),
            style: muted,
          ),
          const SizedBox(height: AppSpace.l),
          Text(l10n.dataSources, style: AppText.label.copyWith(color: c.inkMuted)),
          const SizedBox(height: AppSpace.s),
          for (final (name, owner, license, note) in _sources)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s),
              child: GameCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(license, style: AppText.label.copyWith(color: c.primaryText)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(owner, style: AppText.bodySmall.copyWith(color: c.ink)),
                    Text(note, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpace.s),
          OutlinedButton(
            onPressed: () => showLicensePage(context: context, applicationName: l10n.appTitle),
            child: Text(l10n.openSourceLicenses),
          ),
        ],
      ),
    );
  }
}
