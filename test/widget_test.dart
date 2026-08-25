import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/actor.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_response.dart';
import 'package:plodyo_ondemand_tv/data/repositories/auth_repository.dart';
import 'package:plodyo_ondemand_tv/main.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/cubit/sign_in_cubit.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/views/sign_in_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/widgets/tv_keyboard.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    this.shouldSucceed = true,
    this.authResponse,
    this.errorToThrow,
  });

  final bool shouldSucceed;
  final AuthResponse? authResponse;
  final Exception? errorToThrow;

  AuthResponse? _auth;

  @override
  AuthResponse? get currentAuth => _auth;

  @override
  Actor? get currentUser => _auth?.actor;

  @override
  bool get isAuthenticated => _auth != null;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (shouldSucceed) {
      final res = authResponse ??
          const AuthResponse(
            accessToken: 'mock_jwt_token',
            refreshToken: 'mock_refresh_token',
            tokenType: 'Bearer',
            expiresIn: 900,
            actor: Actor(
              userId: '9f1c7d2e',
              email: 'ops@grandhotel.com',
              fullName: 'Dana Okafor',
              role: 'PARTNER_ADMIN',
            ),
          );
      _auth = res;
      return res;
    } else {
      throw errorToThrow ??
          const AuthException(
            message: 'Invalid credentials',
            statusCode: 401,
          );
    }
  }

  @override
  Future<void> signOut() async {
    _auth = null;
  }
}

void main() {
  testWidgets('TV App loads Sign In view as first screen without initial error', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const PlodyoTvApp());
    await tester.pump();

    // Verify Title and Subtitle
    expect(find.text('Sign in to start reading'), findsOneWidget);
    expect(find.text('Plodyo for TV'), findsOneWidget);
    expect(find.text('Use the remote to enter the account details for this device.'), findsOneWidget);

    // Verify Form Fields
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    // Verify Virtual Keyboard
    expect(find.text('Entering email address'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('z'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('Virtual TV Keyboard typing and Shift toggle test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    String text = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TvKeyboard(
            onKeyPress: (char) => text += char,
            onBackspace: () {
              if (text.isNotEmpty) text = text.substring(0, text.length - 1);
            },
            onSpace: () => text += ' ',
            onClear: () => text = '',
          ),
        ),
      ),
    );

    // Tap key 'a'
    await tester.tap(find.text('a'));
    await tester.pump();
    expect(text, 'a');

    // Tap Shift
    await tester.tap(find.text('↑ abc'));
    await tester.pump();

    // Tap key 'B'
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(text, 'aB');

    // Tap Space
    await tester.tap(find.text('␣ Space'));
    await tester.pump();
    expect(text, 'aB ');

    // Tap Clear
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(text, '');
  });

  testWidgets('SignInView triggers sign in with Cubit and notifies onSignedIn', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool signedIn = false;
    final cubit = SignInCubit(
      authRepository: MockAuthRepository(shouldSucceed: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SignInView(
          cubit: cubit,
          onSignedIn: () {
            signedIn = true;
          },
        ),
      ),
    );

    // Type email
    await tester.tap(find.text('u'));
    await tester.pump();
    await tester.tap(find.text('s'));
    await tester.pump();

    // Focus password field
    await tester.tap(find.text('Password'));
    await tester.pump();

    // Type password
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();

    // Tap Sign in button
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(signedIn, isTrue);
  });

  testWidgets('SignInView displays error banner on failed login', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final cubit = SignInCubit(
      authRepository: MockAuthRepository(
        shouldSucceed: false,
        errorToThrow: const AuthException(
          message: 'Invalid credentials',
          statusCode: 401,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SignInView(cubit: cubit),
      ),
    );

    // Enter credentials
    await tester.tap(find.text('a'));
    await tester.pump();
    await tester.tap(find.text('Password'));
    await tester.pump();
    await tester.tap(find.text('b'));
    await tester.pump();

    // Click Sign In
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // Error banner should be displayed
    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
