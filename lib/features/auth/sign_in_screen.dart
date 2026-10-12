import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/learning_level.dart';
import '../sync/sync_controller.dart';
import '../sync/sync_engine.dart';
import 'auth_service.dart';

/// First screen of a new install (PRD F9 onboarding step 1): sign in with
/// email and password. "Daftar" creates an account and confirms the email
/// with a code; "Lupa kata sandi?" emails a code and sets a new password with
/// it (also for accounts invited from the dashboard). All on this screen.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

enum _Mode { signIn, signUp, forgot }

class _SignInScreenState extends ConsumerState<SignInScreen> {
  static const minPassword = 8;
  static const resendAfter = 60;
  static const restoreTimeout = Duration(seconds: 30);

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();

  _Mode _mode = _Mode.signIn;
  bool _codeSent = false;
  bool _verified = false;
  bool _busy = false;
  bool _restoring = false;
  bool _showPassword = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_email, _password, _code, _newPassword]) {
      c.dispose();
    }
    super.dispose();
  }

  AuthService get _auth => ref.read(authServiceProvider)!;
  String get _emailText => _email.text.trim();
  bool get _emailValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailText);

  void _switch(_Mode mode) => setState(() {
    _mode = mode;
    _codeSent = false;
    _error = null;
    _code.clear();
    _newPassword.clear();
  });

  String _message(AppLocalizations l10n, AuthFailure f) => switch (f) {
    AuthFailure.wrongPassword => l10n.authWrongPassword,
    AuthFailure.notConfirmed => l10n.authNotConfirmed,
    AuthFailure.badCode => l10n.authBadCode,
    AuthFailure.weakPassword => l10n.authWeakPassword,
    AuthFailure.samePassword => l10n.authSamePassword,
    AuthFailure.alreadyRegistered => l10n.authAlreadyRegistered,
    AuthFailure.signUpClosed => l10n.authSignUpClosed,
    AuthFailure.tooMany => l10n.authTooMany,
    AuthFailure.offline => l10n.authOffline,
    AuthFailure.unknown => l10n.authUnknown,
  };

  /// Runs [action] with the buttons disabled and the error shown below.
  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      debugPrint('auth failed: $e');
      if (mounted) setState(() => _error = _message(l10n, authFailure(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Hands this phone's data to the account and restores what the account
  /// already has (PRD §8 "Login & pemulihan"), then lets the app open. An
  /// account with data skips onboarding. Offline, the app opens anyway and
  /// sync catches up later.
  Future<void> _finish() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final db = await ref.read(userDbProvider.future);
        await db.claimFor(user.id);
        if (ref.read(syncRemoteProvider) case final remote?) {
          if (mounted) setState(() => _restoring = true);
          await SyncEngine(db, remote).sync(full: true).timeout(restoreTimeout);
        }
      } catch (e) {
        debugPrint('account not restored: $e');
      }
      ref.invalidate(onboardingNeededProvider);
    }
    ref.read(signingInProvider.notifier).set(false);
  }

  Future<void> _signIn() => _run(() async {
    final signing = ref.read(signingInProvider.notifier)..set(true);
    try {
      await _auth.signIn(_emailText, _password.text);
    } catch (_) {
      signing.set(false);
      rethrow;
    }
    await _finish();
  });

  Future<void> _sendCode() => _run(() async {
    await _auth.sendCode(_emailText);
    _codeOnItsWay();
  });

  Future<void> _resendSignUpCode() => _run(() async {
    await _auth.resendSignUpCode(_emailText);
    _codeOnItsWay();
  });

  Future<void> _signUp() => _run(() async {
    final signing = ref.read(signingInProvider.notifier)..set(true);
    final bool needsCode;
    try {
      needsCode = await _auth.signUp(_emailText, _newPassword.text);
    } catch (_) {
      signing.set(false);
      rethrow;
    }
    if (!needsCode) return _finish();
    signing.set(false);
    _codeOnItsWay();
  });

  Future<void> _confirmSignUp() => _run(() async {
    final signing = ref.read(signingInProvider.notifier)..set(true);
    try {
      await _auth.confirmSignUp(_emailText, _code.text.trim());
    } catch (_) {
      signing.set(false);
      rethrow;
    }
    await _finish();
  });

  /// Shows the code field and holds "Kirim ulang" back for a minute.
  void _codeOnItsWay() {
    if (!mounted) return;
    setState(() {
      _codeSent = true;
      _resendIn = resendAfter;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _resendIn <= 1) t.cancel();
      if (mounted) setState(() => _resendIn--);
    });
  }

  Future<void> _savePassword() => _run(() async {
    final signing = ref.read(signingInProvider.notifier)..set(true);
    if (!_verified) {
      try {
        await _auth.verifyCode(_emailText, _code.text.trim());
      } catch (_) {
        signing.set(false);
        rethrow;
      }
      _verified = true;
    }
    // Signed in by the code now; the app stays covered until the password is
    // saved, so a failure here can be retried with another password.
    await _auth.setPassword(_newPassword.text);
    await _finish();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final signIn = _mode == _Mode.signIn;
    final signUp = _mode == _Mode.signUp;
    // Sign in and the first sign-up step show the brand; the code steps are
    // a detour with a back button.
    final entry = signIn || (signUp && !_codeSent);
    final codeOk = RegExp(r'^\d{6,8}$').hasMatch(_code.text.trim());

    final canSignIn = !_busy && _emailValid && _password.text.isNotEmpty;
    final canSave = !_busy && (codeOk || _verified) && _newPassword.text.length >= minPassword;
    final canSignUp = !_busy && _emailValid && _newPassword.text.length >= minPassword;
    final Widget button;
    if (signIn) {
      button = ChunkyButton(label: l10n.signIn, onPressed: canSignIn ? _signIn : null);
    } else if (signUp) {
      button = _codeSent
          ? ChunkyButton(label: l10n.confirmSignUp, onPressed: !_busy && codeOk ? _confirmSignUp : null)
          : ChunkyButton(label: l10n.signUp, onPressed: canSignUp ? _signUp : null);
    } else if (!_codeSent) {
      button = ChunkyButton(label: l10n.sendCode, onPressed: _busy || !_emailValid ? null : _sendCode);
    } else {
      button = ChunkyButton(label: l10n.savePassword, onPressed: canSave ? _savePassword : null);
    }

    final title = switch (_mode) {
      _Mode.signIn => l10n.signInTitle,
      _Mode.signUp => _codeSent ? l10n.confirmEmailTitle : l10n.signUpTitle,
      _Mode.forgot => l10n.forgotTitle,
    };
    final note = signIn
        ? l10n.signInNote
        : _codeSent
        ? l10n.codeSent(_emailText)
        : signUp
        ? l10n.signUpNote
        : l10n.codeNote;

    final card = _AuthCard(
      children: [
        if (entry) ...[
          Semantics(
            header: true,
            child: Text(title, style: AppText.title2.copyWith(color: c.ink)),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(note, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
          const SizedBox(height: AppSpace.xl),
        ],
        if (!_codeSent) ...[
          TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              fillColor: c.bg,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (signIn || signUp) const SizedBox(height: AppSpace.m),
        ],
        if (signIn) ...[
          _PasswordField(
            controller: _password,
            label: l10n.passwordLabel,
            hints: const [AutofillHints.password],
            visible: _showPassword,
            enabled: !_busy,
            onToggle: () => setState(() => _showPassword = !_showPassword),
            onChanged: () => setState(() {}),
            onSubmitted: () => canSignIn ? _signIn() : null,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: _busy ? null : () => _switch(_Mode.forgot), child: Text(l10n.forgotPassword)),
          ),
        ] else if (signUp && !_codeSent)
          _PasswordField(
            controller: _newPassword,
            label: l10n.passwordLabel,
            helper: l10n.passwordRule(minPassword),
            hints: const [AutofillHints.newPassword],
            visible: _showPassword,
            enabled: !_busy,
            onToggle: () => setState(() => _showPassword = !_showPassword),
            onChanged: () => setState(() {}),
            onSubmitted: () => canSignUp ? _signUp() : null,
          )
        else if (signUp)
          _CodeField(controller: _code, enabled: !_busy, onChanged: () => setState(() {}))
        else if (_codeSent) ...[
          if (!_verified) ...[
            _CodeField(controller: _code, enabled: !_busy, onChanged: () => setState(() {})),
            const SizedBox(height: AppSpace.m),
          ],
          _PasswordField(
            controller: _newPassword,
            label: l10n.newPasswordLabel,
            helper: l10n.passwordRule(minPassword),
            hints: const [AutofillHints.newPassword],
            visible: _showPassword,
            enabled: !_busy,
            onToggle: () => setState(() => _showPassword = !_showPassword),
            onChanged: () => setState(() {}),
            onSubmitted: () => canSave ? _savePassword() : null,
          ),
        ],
        if (_error case final error?) ...[const SizedBox(height: AppSpace.m), _ErrorBox(error)],
        SizedBox(height: signIn ? AppSpace.s : AppSpace.xl),
        button,
        if (_busy) ...[
          const SizedBox(height: AppSpace.l),
          const Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))),
          if (_restoring) ...[
            const SizedBox(height: AppSpace.s),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.restoringData,
                textAlign: TextAlign.center,
                style: AppText.bodySmall.copyWith(color: c.inkMuted),
              ),
            ),
          ],
        ],
        if (_codeSent && !_verified) ...[
          const SizedBox(height: AppSpace.s),
          Center(
            child: TextButton(
              onPressed: _busy || _resendIn > 0 ? null : (signUp ? _resendSignUpCode : _sendCode),
              child: Text(_resendIn > 0 ? l10n.resendIn(_resendIn) : l10n.resendCode),
            ),
          ),
        ],
      ],
    );

    final List<Widget> content;
    if (entry) {
      content = [
        const _Brand(),
        const SizedBox(height: AppSpace.xxl),
        card,
        const SizedBox(height: AppSpace.l),
        _SwitchPrompt(
          question: signIn ? l10n.noAccountYet : l10n.haveAccount,
          action: signIn ? l10n.signUp : l10n.signIn,
          onPressed: _busy ? null : () => _switch(signIn ? _Mode.signUp : _Mode.signIn),
        ),
      ];
    } else {
      content = [
        _StepIcon(_codeSent ? Icons.mark_email_unread_outlined : Icons.lock_reset_rounded),
        const SizedBox(height: AppSpace.l),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.title1.copyWith(color: c.ink),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          note,
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: AppSpace.xl),
        card,
      ];
    }

    final back = !entry && !_verified;
    return PopScope(
      canPop: signIn,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_verified) _switch(_Mode.signIn);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: back
            ? AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => _switch(_Mode.signIn),
                ),
              )
            : null,
        body: _NightGlow(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final side = math.max(AppSpace.screen, (box.maxWidth - _maxWidth) / 2);
                final top = back ? kToolbarHeight + AppSpace.s : AppSpace.xl;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(side, top, side, AppSpace.xl),
                  child: ConstrainedBox(
                    // Centered on tall screens, scrolls when the keyboard is up.
                    constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - top - AppSpace.xl)),
                    child: AutofillGroup(
                      child: Column(
                        mainAxisAlignment: entry ? MainAxisAlignment.center : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: content,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static const _maxWidth = 440.0;
}

/// Soft sakura light from the top of the night sky (ui-design §1.2).
class _NightGlow extends StatelessWidget {
  const _NightGlow({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        gradient: RadialGradient(
          center: const Alignment(0, -1.15),
          radius: 1.1,
          colors: [
            c.primary.withValues(alpha: dark ? 0.30 : 0.14),
            c.bg.withValues(alpha: 0),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// App mark: a red hanko with 日本, the stamp that rewards every session.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const size = 72.0;
    return ExcludeSemantics(
      child: Column(
        children: [
          Transform.rotate(
            angle: -0.07,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.seal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: c.seal, width: 3),
                boxShadow: [BoxShadow(color: c.seal.withValues(alpha: 0.35), blurRadius: 24)],
              ),
              // 日本 stacked, like the name on a real seal.
              child: Text(
                '日\n本',
                locale: const Locale('ja'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.jpUi,
                  fontSize: 25,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: c.seal,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.m),
          Text(
            'Nihondex',
            style: AppText.title1.copyWith(color: c.ink, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

/// The form, on a raised card.
class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.xl, AppSpace.l, AppSpace.l),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: c.line),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// "Belum punya akun? Daftar" under the card.
class _SwitchPrompt extends StatelessWidget {
  const _SwitchPrompt({required this.question, required this.action, required this.onPressed});
  final String question;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: AppText.body.copyWith(color: c.inkMuted)),
        TextButton(
          onPressed: onPressed,
          child: Text(action, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

/// Round icon above a code step.
class _StepIcon extends StatelessWidget {
  const _StepIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.primary.withValues(alpha: 0.16),
          border: Border.all(color: c.primary.withValues(alpha: 0.45), width: 2),
        ),
        child: Icon(icon, size: 34, color: c.primaryText),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.m),
        decoration: BoxDecoration(
          color: c.seal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: c.seal.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 20, color: c.seal),
            const SizedBox(width: AppSpace.s),
            Expanded(
              child: Text(message, style: AppText.bodySmall.copyWith(color: c.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one-time code from the email (6 to 8 digits).
class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller, required this.enabled, required this.onChanged});

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    textAlign: TextAlign.center,
    style: AppText.title1.copyWith(color: context.colors.ink, letterSpacing: 8),
    keyboardType: TextInputType.number,
    autofillHints: const [AutofillHints.oneTimeCode],
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: AppLocalizations.of(context).codeLabel,
      fillColor: context.colors.bg,
      floatingLabelAlignment: FloatingLabelAlignment.center,
    ),
    onChanged: (_) => onChanged(),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hints,
    required this.visible,
    required this.enabled,
    required this.onToggle,
    required this.onChanged,
    required this.onSubmitted,
    this.helper,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final List<String> hints;
  final bool visible;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: !visible,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: hints,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        fillColor: context.colors.bg,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: visible ? l10n.hidePassword : l10n.showPassword,
          icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
      ),
      onChanged: (_) => onChanged(),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}
