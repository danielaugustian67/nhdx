import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../audio/speech.dart';
import '../text/hangul.dart';
import '../theme/app_colors.dart';

/// 🔊 that reads [text] aloud. Without a Japanese (or, for Hangul, Korean)
/// voice on the phone it says where to install one.
class SpeakButton extends ConsumerWidget {
  const SpeakButton(this.text, {super.key, this.size = 28});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: Icon(Icons.volume_up_rounded, size: size, color: context.colors.primaryText),
      tooltip: l10n.listen,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        if (!await ref.read(speechProvider).speak(text)) {
          final message = hasHangul(text) ? l10n.speechUnavailableKorean : l10n.speechUnavailable;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );
  }
}
