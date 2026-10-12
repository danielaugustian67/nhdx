import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/speech.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import 'conjugation.dart';
import 'conjugation_drill_screen.dart';
import 'conjugation_practice.dart';

/// Conjugation table of a verb or adjective on its detail page (PRD F14):
/// the common forms, "Semua bentuk" for the rest, a tap reads a form aloud,
/// and a drill on this word.
class ConjugationTable extends ConsumerStatefulWidget {
  const ConjugationTable({super.key, required this.word});
  final ConjWord word;

  @override
  ConsumerState<ConjugationTable> createState() => _ConjugationTableState();
}

class _ConjugationTableState extends ConsumerState<ConjugationTable> {
  bool _all = false;

  /// Shown before "Semua bentuk".
  static const _common = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final conj = widget.word.conj;
    // A verb's dictionary form is the headword above; a na-adjective's 〜だ is not.
    final forms = [
      for (final f in conj.forms)
        if (f != ConjForm.plain || conj.cls == WordClass.adjNa) f,
    ];
    final shown = _all ? forms : forms.take(_common).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Column(
            children: [
              for (final (i, f) in shown.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.line),
                _Row(form: f, cls: conj.cls, value: conj.conjugate(f)),
              ],
            ],
          ),
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (forms.length > _common)
              TextButton.icon(
                onPressed: () => setState(() => _all = !_all),
                icon: Icon(_all ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                label: Text(_all ? l10n.conjShowLess : l10n.conjShowAll(forms.length)),
              ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ConjugationDrillScreen.word(widget.word), fullscreenDialog: true),
              ),
              icon: const Icon(Icons.quiz_rounded),
              label: Text(l10n.conjPracticeWord),
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.form, required this.cls, required this.value});
  final ConjForm form;
  final WordClass cls;
  final Conjugated value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final hint = conjFormHint(form, cls);
    return InkWell(
      onTap: () => ref.read(speechProvider).speak(value.kana),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.m, vertical: AppSpace.s),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conjFormLabel(l10n, form), style: AppText.bodySmall.copyWith(color: c.ink)),
                  if (hint.isNotEmpty)
                    Text(
                      hint,
                      locale: const Locale('ja'),
                      style: AppText.bodySmall.copyWith(color: c.inkMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.written,
                    locale: const Locale('ja'),
                    style: AppText.bodyJp.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                  ),
                  if (value.kana != value.written)
                    Text(
                      value.kana,
                      locale: const Locale('ja'),
                      style: AppText.bodySmallJp.copyWith(color: c.inkMuted),
                    ),
                ],
              ),
            ),
            Icon(Icons.volume_up_rounded, size: 18, color: c.primaryText),
          ],
        ),
      ),
    );
  }
}
