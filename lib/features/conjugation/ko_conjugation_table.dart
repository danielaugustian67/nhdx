import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/speech.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import 'ko_conjugation.dart';
import 'ko_conjugation_practice.dart';

/// Conjugation table of a Korean verb or adjective on its word page: every
/// form that applies, a tap reads it aloud.
class KoConjugationTable extends ConsumerWidget {
  const KoConjugationTable({super.key, required this.conj});
  final KoConjugator conj;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        children: [
          for (final (i, f) in conj.forms.indexed) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            InkWell(
              onTap: () => ref.read(speechProvider).speak(conj.conjugate(f)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.m, vertical: AppSpace.s),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        koFormLabel(l10n, f),
                        locale: const Locale('ko'),
                        style: AppText.bodySmall.copyWith(color: c.ink),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s),
                    Expanded(
                      flex: 6,
                      child: Text(
                        conj.conjugate(f),
                        locale: const Locale('ko'),
                        style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.volume_up_rounded, size: 18, color: c.primaryText),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The conjugator of a dictionary word whose first verb or adjective sense
/// says which it is; null for other words, 이다 and 아니다.
KoConjugator? koConjugatorOf(String hangul, Iterable<String?> partsOfSpeech) {
  final pos = partsOfSpeech.where((p) => p == 'verb' || p == 'adj').firstOrNull;
  return pos == null ? null : KoConjugator.of(hangul, adjective: pos == 'adj');
}
