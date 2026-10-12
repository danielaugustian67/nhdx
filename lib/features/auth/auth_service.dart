import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

/// The signed-in account, as much as the app needs of it.
typedef Account = ({String id, String? email});

/// Email sign-in (PRD F4). Anyone can sign up from the app; the email is
/// confirmed with a code. Anyone who forgot their password (or was invited
/// from the dashboard) asks for a code by email and chooses a password with
/// it. Codes instead of links need no deep links.
abstract class AuthService {
  Account? get currentUser;
  Stream<Account?> get userChanges;
  Future<void> signIn(String email, String password);

  /// Creates an account. True when the emailed code still has to confirm it
  /// (Supabase "Confirm email" on); false when it is signed in already.
  Future<bool> signUp(String email, String password);
  Future<void> confirmSignUp(String email, String code);
  Future<void> resendSignUpCode(String email);

  /// Emails a one-time code that signs in once and allows a new password.
  Future<void> sendCode(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> setPassword(String password);
  Future<void> signOut();

  /// Deletes the account and everything saved to it, on every device
  /// (Edge Function `delete-account`), then signs out here.
  Future<void> deleteAccount();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);
  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  static Account? _user(User? u) => u == null ? null : (id: u.id, email: u.email);

  @override
  Account? get currentUser => _user(_auth.currentUser);

  @override
  Stream<Account?> get userChanges => _auth.onAuthStateChange.map((s) => _user(s.session?.user));

  @override
  Future<void> signIn(String email, String password) => _auth.signInWithPassword(email: email, password: password);

  @override
  Future<bool> signUp(String email, String password) async {
    final res = await _auth.signUp(email: email, password: password);
    // With confirmation on, an email that already has an account comes back
    // as a user without identities, and no email is sent.
    if (res.user?.identities?.isEmpty ?? false) {
      throw const AuthApiException('User already registered', statusCode: '422', code: 'user_already_exists');
    }
    return res.session == null;
  }

  @override
  Future<void> confirmSignUp(String email, String code) =>
      _auth.verifyOTP(type: OtpType.signup, email: email, token: code);

  @override
  Future<void> resendSignUpCode(String email) => _auth.resend(type: OtpType.signup, email: email);

  @override
  Future<void> sendCode(String email) => _auth.resetPasswordForEmail(email);

  @override
  Future<void> verifyCode(String email, String code) =>
      _auth.verifyOTP(type: OtpType.recovery, email: email, token: code);

  @override
  Future<void> setPassword(String password) => _auth.updateUser(UserAttributes(password: password));

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    // After a long time offline the saved token may have run out.
    if (_auth.currentSession?.isExpired ?? false) await _auth.refreshSession();
    await _client.functions.invoke('delete-account', method: HttpMethod.post);
    try {
      await _auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      // The session died with the account; it is removed here either way.
    }
  }
}

/// Null without a Supabase project (tests, builds without env): no sign-in.
final authServiceProvider = Provider<AuthService?>(
  (ref) => Env.hasSupabase ? SupabaseAuthService(Supabase.instance.client) : null,
);

final authUserProvider = StreamProvider<Account?>((ref) async* {
  final auth = ref.watch(authServiceProvider);
  if (auth == null) return;
  yield auth.currentUser;
  yield* auth.userChanges;
});

/// True while a sign-in is being finished (password still to be saved, or
/// this phone's data being handed to the account): the sign-in screen stays
/// up until then.
class SigningIn extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final signingInProvider = NotifierProvider<SigningIn, bool>(SigningIn.new);

/// Whether the sign-in screen covers the app: an auth backend is set up and
/// nobody is signed in yet (or a sign-in is still being finished). A saved
/// session counts offline too (PRD F4).
final signInNeededProvider = Provider<bool>((ref) {
  final auth = ref.watch(authServiceProvider);
  if (auth == null) return false;
  final user = ref.watch(authUserProvider).value ?? auth.currentUser;
  return user == null || ref.watch(signingInProvider);
});

enum AuthFailure {
  wrongPassword,
  notConfirmed,
  badCode,
  weakPassword,
  samePassword,
  alreadyRegistered,
  signUpClosed,
  tooMany,
  offline,
  unknown,
}

AuthFailure authFailure(Object e) => switch (e) {
  AuthRetryableFetchException() || SocketException() || TimeoutException() => AuthFailure.offline,
  AuthException(code: 'invalid_credentials') => AuthFailure.wrongPassword,
  AuthException(code: 'email_not_confirmed') => AuthFailure.notConfirmed,
  AuthException(code: 'otp_expired' || 'otp_disabled') => AuthFailure.badCode,
  AuthException(code: 'weak_password') || AuthWeakPasswordException() => AuthFailure.weakPassword,
  AuthException(code: 'same_password') => AuthFailure.samePassword,
  AuthException(code: 'user_already_exists' || 'email_exists') => AuthFailure.alreadyRegistered,
  AuthException(code: 'signup_disabled') => AuthFailure.signUpClosed,
  AuthException(statusCode: '429') => AuthFailure.tooMany,
  AuthException(code: final String code) when code.startsWith('over_') => AuthFailure.tooMany,
  _ when '$e'.contains('SocketException') || '$e'.contains('Failed host lookup') => AuthFailure.offline,
  _ => AuthFailure.unknown,
};
