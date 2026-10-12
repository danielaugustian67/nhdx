import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/widgets/app_tab_bar.dart';
import 'package:nihondx/app.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/widgets/chunky_button.dart';
import 'package:nihondx/features/auth/auth_service.dart';
import 'package:nihondx/features/auth/delete_account_screen.dart';
import 'package:nihondx/features/auth/sign_in_screen.dart';
import 'package:nihondx/features/onboarding/onboarding_screen.dart';
import 'package:nihondx/features/sync/sync_controller.dart';
import 'package:nihondx/features/sync/sync_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fonts.dart';
import '../sync/fake_cloud.dart';

class _FakeAuth implements AuthService {
  final _changes = StreamController<Account?>.broadcast();
  Account? user;
  String password = 'rahasia123';
  final calls = <String>[];

  void _signedIn(String email) {
    user = (id: 'user-1', email: email);
    _changes.add(user);
  }

  @override
  Account? get currentUser => user;

  @override
  Stream<Account?> get userChanges => _changes.stream;

  @override
  Future<void> signIn(String email, String password) async {
    calls.add('signIn');
    if (password != this.password) {
      throw const AuthApiException('Invalid login credentials', statusCode: '400', code: 'invalid_credentials');
    }
    _signedIn(email);
  }

  /// Emails that already have an account.
  final registered = {'ana@contoh.id'};

  /// Whether sign-up signs in at once (Supabase "Confirm email" off).
  bool autoConfirm = false;

  @override
  Future<bool> signUp(String email, String password) async {
    calls.add('signUp $email');
    if (registered.contains(email)) {
      throw const AuthApiException('User already registered', statusCode: '422', code: 'user_already_exists');
    }
    this.password = password;
    if (autoConfirm) _signedIn(email);
    return !autoConfirm;
  }

  @override
  Future<void> confirmSignUp(String email, String code) async {
    calls.add('confirm $code');
    if (code != '123456') throw const AuthApiException('expired', statusCode: '403', code: 'otp_expired');
    _signedIn(email);
  }

  @override
  Future<void> resendSignUpCode(String email) async => calls.add('resend $email');

  @override
  Future<void> sendCode(String email) async => calls.add('sendCode $email');

  @override
  Future<void> verifyCode(String email, String code) async {
    calls.add('verify $code');
    if (code != '123456') throw const AuthApiException('expired', statusCode: '403', code: 'otp_expired');
    _signedIn(email);
  }

  @override
  Future<void> setPassword(String password) async {
    calls.add('setPassword');
    this.password = password;
  }

  @override
  Future<void> signOut() async {
    user = null;
    _changes.add(null);
  }

  bool offline = false;

  @override
  Future<void> deleteAccount() async {
    calls.add('deleteAccount');
    if (offline) throw const SocketException('no route');
    await signOut();
  }
}

void main() {
  // Real fonts, so text widths match the phone.
  setUpAll(loadAppFonts);

  test('auth errors map to what the user can do about them', () {
    expect(authFailure(const AuthApiException('x', code: 'invalid_credentials')), AuthFailure.wrongPassword);
    expect(authFailure(const AuthApiException('x', code: 'otp_expired')), AuthFailure.badCode);
    expect(authFailure(const AuthApiException('x', code: 'user_already_exists')), AuthFailure.alreadyRegistered);
    expect(authFailure(const AuthApiException('x', code: 'signup_disabled')), AuthFailure.signUpClosed);
    expect(authFailure(const AuthApiException('x', code: 'over_email_send_rate_limit')), AuthFailure.tooMany);
    expect(authFailure(const AuthApiException('x', statusCode: '429')), AuthFailure.tooMany);
    expect(authFailure(AuthRetryableFetchException()), AuthFailure.offline);
    expect(authFailure(const SocketException('no route')), AuthFailure.offline);
    expect(authFailure(StateError('?')), AuthFailure.unknown);
  });

  test("the first account keeps this phone's data; another account starts empty", () async {
    final db = UserDb.memory();
    addTearDown(db.close);
    await db.addCard('vocab', '1', label: 'w');
    await db.setSetting('learning_level', 'n5');
    await db.setSetting('device.theme', 'light');
    final device = await db.deviceId();

    expect(await db.claimFor('a'), isFalse);
    expect(await db.claimFor('a'), isFalse);
    expect(await db.hasLearningData(), isTrue);

    expect(await db.claimFor('b'), isTrue);
    expect(await db.hasLearningData(), isFalse);
    expect(await db.setting('learning_level'), isNull);
    expect(await db.setting('device.theme'), 'light', reason: "this phone's own settings stay");
    expect(await db.deviceId(), device);
  });

  Future<(_FakeAuth, UserDb)> pumpApp(
    WidgetTester tester, {
    FakeCloud? cloud,
    Size size = const Size(390, 1200),
  }) async {
    tester.platformDispatcher.localesTestValue = const [Locale('id')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = _FakeAuth();
    final db = UserDb.memory();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          userDbProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
          dictionaryProvider.overrideWith((ref) => Completer<Never>().future),
          if (cloud != null) syncRemoteProvider.overrideWithValue(cloud),
        ],
        child: const NihondxApp(),
      ),
    );
    await settle(tester);
    return (auth, db);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('sign in comes first; a wrong password says so', (tester) async {
    final (auth, db) = await pumpApp(tester);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(AppTabBar), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'ana@contoh.id');
    await tester.enterText(find.widgetWithText(TextField, 'Kata sandi'), 'salah');
    await tester.pump();
    await tester.tap(find.text('Masuk'));
    await settle(tester);
    expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Kata sandi'), 'rahasia123');
    await tester.pump();
    await tester.tap(find.text('Masuk'));
    await settle(tester);
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget, reason: 'a new account goes on to onboarding');
    expect(await tester.runAsync(() => db.meta('owner_user_id')), 'user-1');
    await unmount(tester);
  });

  testWidgets('signing up confirms the email with a code, then goes on to onboarding', (tester) async {
    final (auth, db) = await pumpApp(tester);
    await tester.tap(find.text('Daftar'));
    await settle(tester);
    expect(find.text('Buat akun'), findsOneWidget);

    ChunkyButton button() => tester.widget<ChunkyButton>(find.byType(ChunkyButton));
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'ana@contoh.id');
    await tester.enterText(find.widgetWithText(TextField, 'Kata sandi'), 'pendek');
    await tester.pump();
    expect(button().onPressed, isNull, reason: 'shorter than 8 characters');
    await tester.enterText(find.widgetWithText(TextField, 'Kata sandi'), 'katasandiku');
    await tester.pump();
    await tester.tap(find.text('Daftar'));
    await settle(tester);
    expect(find.text('Email ini sudah terdaftar. Masuk, atau pilih "Lupa kata sandi?".'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'citra@contoh.id');
    await tester.pump();
    await tester.tap(find.text('Daftar'));
    await settle(tester);
    expect(find.textContaining('Kode dikirim ke citra@contoh.id'), findsOneWidget);
    expect(find.text('Cek emailmu'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Kirim ulang dalam 60 detik'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Kode dari email'), '000000');
    await tester.pump();
    await tester.tap(find.text('Konfirmasi dan masuk'));
    await settle(tester);
    expect(find.text('Kode salah atau sudah kedaluwarsa. Minta kode baru.'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Kode dari email'), '123456');
    await tester.pump();
    await tester.tap(find.text('Konfirmasi dan masuk'));
    await settle(tester);
    expect(auth.calls, ['signUp ana@contoh.id', 'signUp citra@contoh.id', 'confirm 000000', 'confirm 123456']);
    expect(auth.password, 'katasandiku');
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(await tester.runAsync(() => db.meta('owner_user_id')), 'user-1');
    await unmount(tester);
  });

  testWidgets('without email confirmation, signing up signs in at once', (tester) async {
    final (auth, _) = await pumpApp(tester);
    auth.autoConfirm = true;
    await tester.tap(find.text('Daftar'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'dewi@contoh.id');
    await tester.enterText(find.widgetWithText(TextField, 'Kata sandi'), 'katasandiku');
    await tester.pump();
    await tester.tap(find.text('Daftar'));
    await settle(tester);
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await unmount(tester);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('sign in, sign up and code steps meet tap target and label guidelines at ${scale}x text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, size: const Size(360, 780));
      Future<void> audit() async {
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }

      await audit();
      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await settle(tester);
      await audit();
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'citra@contoh.id');
      await tester.enterText(find.widgetWithText(TextField, 'Kata sandi'), 'katasandiku');
      await tester.pump();
      await tester.ensureVisible(find.byType(ChunkyButton));
      await tester.tap(find.byType(ChunkyButton));
      await settle(tester);
      expect(find.text('Cek emailmu'), findsOneWidget);
      await audit();
      semantics.dispose();
      await unmount(tester);
    });
  }
  testWidgets('a forgotten password is reset with the emailed code', (tester) async {
    final (auth, _) = await pumpApp(tester);
    await tester.tap(find.text('Lupa kata sandi?'));
    await settle(tester);
    expect(find.text('Atur ulang kata sandi'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'budi@contoh.id');
    await tester.pump();
    await tester.tap(find.text('Kirim kode'));
    await settle(tester);
    expect(auth.calls, ['sendCode budi@contoh.id']);
    expect(find.textContaining('Kode dikirim ke budi@contoh.id'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Kode dari email'), '000000');
    await tester.enterText(find.widgetWithText(TextField, 'Kata sandi baru'), 'katasandiku');
    await tester.pump();
    await tester.tap(find.text('Simpan dan masuk'));
    await settle(tester);
    expect(find.text('Kode salah atau sudah kedaluwarsa. Minta kode baru.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Kode dari email'), '123456');
    await tester.pump();
    await tester.tap(find.text('Simpan dan masuk'));
    await settle(tester);
    expect(auth.calls, ['sendCode budi@contoh.id', 'verify 000000', 'verify 123456', 'setPassword']);
    expect(auth.password, 'katasandiku');
    expect(find.byType(SignInScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets('signing in restores the account and skips onboarding', (tester) async {
    // What another phone already saved to this account.
    final cloud = FakeCloud();
    final other = UserDb.memory();
    await tester.runAsync(() async {
      await other.setSetting('learning_level', 'n4');
      await other.addCard('word', '1358280', label: '食べる');
      await SyncEngine(other, cloud).sync();
      await other.close();
    });

    final (_, db) = await pumpApp(tester, cloud: cloud);
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'ana@contoh.id');
    await tester.enterText(find.widgetWithText(TextField, 'Kata sandi'), 'rahasia123');
    await tester.pump();
    await tester.tap(find.text('Masuk'));
    await settle(tester);
    await settle(tester);

    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing, reason: 'the account already chose a level');
    expect(find.byType(AppTabBar), findsOneWidget);
    expect(await tester.runAsync(() => db.setting('learning_level')), 'n4');
    expect(await tester.runAsync(() => db.hasLearningData()), isTrue);
    await unmount(tester);
  });

  testWidgets('deleting the account asks for the keyword, needs a connection, then clears this phone', (tester) async {
    final (auth, db) = await pumpApp(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'ana@contoh.id');
    await tester.enterText(find.widgetWithText(TextField, 'Kata sandi'), 'rahasia123');
    await tester.pump();
    await tester.tap(find.text('Masuk'));
    await settle(tester);
    await tester.runAsync(() async {
      await db.addCard('word', '1358280', label: '食べる');
      await db.setSetting('device.theme', 'dark');
    });
    await settle(tester);
    expect(find.byType(AppTabBar), findsOneWidget);

    final context = tester.element(find.byType(Scaffold).first);
    unawaited(
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute<void>(builder: (_) => const DeleteAccountScreen())),
    );
    await settle(tester);
    expect(find.text('Hapus akun dan semua progresmu?'), findsOneWidget);

    ChunkyButton button() => tester.widget<ChunkyButton>(find.byType(ChunkyButton));
    final field = find.widgetWithText(TextField, 'Ketik HAPUS untuk konfirmasi');
    await tester.enterText(field, 'HAPU');
    await tester.pump();
    expect(button().onPressed, isNull);
    await tester.enterText(field, ' hapus ');
    await tester.pump();
    expect(button().onPressed, isNotNull);

    auth.offline = true;
    await tester.tap(find.byType(ChunkyButton));
    await settle(tester);
    expect(find.text('Butuh internet untuk menghapus akun. Coba lagi saat tersambung.'), findsOneWidget);
    expect(auth.user, isNotNull);
    expect(await tester.runAsync(() => db.hasLearningData()), isTrue);

    auth.offline = false;
    await tester.tap(find.byType(ChunkyButton));
    await settle(tester);
    expect(auth.calls.where((c) => c == 'deleteAccount'), hasLength(2));
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(await tester.runAsync(() => db.hasLearningData()), isFalse);
    expect(await tester.runAsync(() => db.setting('device.theme')), 'dark', reason: "this phone's own settings stay");
    await unmount(tester);
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
