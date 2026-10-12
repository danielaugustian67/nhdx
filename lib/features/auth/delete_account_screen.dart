import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../l10n/app_localizations.dart';
import 'auth_service.dart';

/// Saya → Akun → Hapus akun (PRD F4, UI §6): says what goes, then asks for
/// the keyword to be typed. Needs a connection; afterwards this phone is
/// cleared like after signing out.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _keyword = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider)!;
    try {
      final db = await ref.read(userDbProvider.future);
      await auth.deleteAccount();
      // The sign-in screen covers the app now; leave nothing of the account.
      await db.clearAccountData();
      if (navigator.mounted) navigator.pop();
    } catch (e) {
      debugPrint('delete account: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authFailure(e) == AuthFailure.offline ? l10n.deleteAccountOffline : l10n.deleteAccountFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final keyword = l10n.deleteAccountKeyword;
    final matches = _keyword.text.trim().toUpperCase() == keyword.toUpperCase();

    Widget point(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.inkMuted, size: 22),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Text(text, style: AppText.body.copyWith(color: c.ink)),
          ),
        ],
      ),
    );

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.deleteAccount)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: [
              Semantics(
                header: true,
                child: Text(l10n.deleteAccountTitle, style: AppText.title2.copyWith(color: c.ink)),
              ),
              const SizedBox(height: AppSpace.l),
              point(Icons.school_outlined, l10n.deleteAccountProgress),
              point(Icons.devices_outlined, l10n.deleteAccountDevices),
              point(Icons.no_accounts_outlined, l10n.deleteAccountSignIn),
              point(Icons.history_rounded, l10n.deleteAccountUndo),
              const SizedBox(height: AppSpace.m),
              TextField(
                controller: _keyword,
                enabled: !_busy,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: l10n.deleteAccountType(keyword)),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => matches && !_busy ? _delete() : null,
              ),
              if (_error case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.m),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(error, style: AppText.body.copyWith(color: c.seal)),
                  ),
                ),
              const SizedBox(height: AppSpace.xl),
              ChunkyButton(
                label: l10n.deleteAccountButton,
                color: c.seal,
                textColor: c.onSeal,
                onPressed: matches && !_busy ? _delete : null,
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpace.m),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
