import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/actor.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_response.dart';
import 'package:plodyo_ondemand_tv/data/models/invite_model.dart';
import 'package:plodyo_ondemand_tv/data/models/partner_model.dart';
import 'package:plodyo_ondemand_tv/data/repositories/auth_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/auth_api_service.dart';
import 'package:plodyo_ondemand_tv/main.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/cubit/sign_in_cubit.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/views/sign_in_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/widgets/tv_keyboard.dart';
import 'package:plodyo_ondemand_tv/ui/features/search/views/search_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/home/views/home_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/categories/views/categories_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/partners/views/partners_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/invites/views/invites_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/properties/views/properties_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/rooms/views/rooms_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/settings/views/settings_view.dart';

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

  @override
  Future<AuthResponse> refreshToken() async {
    return _auth!;
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    return 'Reset link sent';
  }

  @override
  Future<String> resetPassword({required String token, required String newPassword}) async {
    return 'Password updated';
  }

  @override
  Future<AuthMeResponse> getMe() async {
    return AuthMeResponse(
      actor: _auth?.actor ??
          const Actor(userId: 'u1', email: 'a@b.com', fullName: 'A', role: 'SUPER_ADMIN'),
      memberships: const [],
    );
  }

  @override
  Future<InviteModel> previewInvite(String token) async {
    return const InviteModel(
      id: 'i1',
      email: 'a@b.com',
      role: 'SUPER_ADMIN',
      status: 'PENDING',
      createdAt: '',
    );
  }

  @override
  Future<String> acceptInvite({required String token, required String password, String? fullName}) async {
    return 'Invite accepted';
  }

  @override
  Future<Map<String, dynamic>> registerVenue({
    required String name,
    required String partnerType,
    required String contactEmail,
    String? contactName,
    String? phone,
  }) async {
    return {'status': 'PENDING_APPROVAL'};
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
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Register a new venue'), findsOneWidget);

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
    await tester.tap(find.text('— Space'));
    await tester.pump();
    expect(text, 'aB ');

    // Tap key '@'
    await tester.tap(find.text('@'));
    await tester.pump();
    expect(text, 'aB @');

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

  testWidgets('SignInView shows validation error on empty credentials and signs in on valid credentials', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool navigated = false;
    final cubit = SignInCubit(
      authRepository: MockAuthRepository(shouldSucceed: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SignInView(
          cubit: cubit,
          onSignedIn: () {
            navigated = true;
          },
        ),
      ),
    );

    // Tap Sign In with empty inputs
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // Verify validation banner is displayed
    expect(find.text('Please enter both email and password.'), findsOneWidget);
    expect(navigated, isFalse);

    // Enter email using on-screen keyboard
    await tester.tap(find.text('a'));
    await tester.pump();
    await tester.tap(find.text('b'));
    await tester.pump();

    // Focus password field and enter password
    await tester.tap(find.text('Password'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();

    // Tap Sign in
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(navigated, isTrue);
  });

  testWidgets('SignInView opens dialog when tapping Forgot password or Register venue', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SignInView(),
      ),
    );

    // Tap Forgot Password
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('To reset your password, please visit plodyo.com/forgot on your phone or computer.'), findsOneWidget);

    // Dismiss Dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Tap Register Venue
    await tester.tap(find.text('Register a new venue'));
    await tester.pumpAndSettle();

    expect(find.text('Register Venue'), findsOneWidget);
    expect(find.text('To register a new venue, please visit plodyo.com/register on your phone or computer.'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('SearchView renders 6-column keyboard and empty prompt state', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchView(
            onMediaSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Search stories...'), findsOneWidget);
    expect(find.text('What would you like to read?'), findsOneWidget);
    expect(find.text('Use the keyboard to search by title.'), findsOneWidget);

    // Virtual keyboard keys present
    expect(find.text('a'), findsOneWidget);
    expect(find.text('z'), findsOneWidget);
    expect(find.text('— Space'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    // Type 'Neon' into search
    await tester.tap(find.text('n'));
    await tester.pump();
    await tester.tap(find.text('e'));
    await tester.pump();
    await tester.tap(find.text('o'));
    await tester.pump();
    await tester.tap(find.text('n'));
    await tester.pumpAndSettle();

    // Results found
    expect(find.textContaining('Stories Found'), findsWidgets);
  });

  testWidgets('HomeView renders Plodyo header, New this week, and shimmer placeholders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeView(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Plodyo'), findsOneWidget);
    expect(find.text('New this week'), findsOneWidget);
  });

  testWidgets('CategoriesView renders 8 category cards with Magic selected by default', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    CategoryItemData? selectedCategory;

    await tester.pumpWidget(
      MaterialApp(
        home: CategoriesView(
          onCategorySelected: (cat) {
            selectedCategory = cat;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Pick a theme to explore.'), findsOneWidget);
    expect(find.text('Nature'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Adventure'), findsOneWidget);
    expect(find.text('Magic'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
    expect(find.text('Animals'), findsOneWidget);
    expect(find.text('Space'), findsOneWidget);

    // Tap on Space card
    await tester.tap(find.text('Space'));
    await tester.pumpAndSettle();

    expect(selectedCategory?.id, 'space');
  });

  testWidgets('PartnersView renders filter pills, partner cards, and details dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    PartnerModel? selectedPartner;

    await tester.pumpWidget(
      MaterialApp(
        home: PartnersView(
          onPartnerSelected: (p) {
            selectedPartner = p;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Partners'), findsOneWidget);
    expect(find.textContaining('Venues on OnDemand'), findsOneWidget);

    // Verify Filter Pills
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Pending approval'), findsWidgets);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Suspended'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);

    // Verify initial partner items
    expect(find.text('Indie Test Hotel'), findsOneWidget);
    expect(find.text('rl4'), findsOneWidget);

    // Filter by Pending approval
    await tester.tap(find.text('Pending approval').first);
    await tester.pumpAndSettle();

    expect(find.text('Indie Test Hotel'), findsOneWidget);
    expect(find.text('rl4'), findsNothing);

    // Tap on Indie Test Hotel to open dialog
    await tester.tap(find.text('Indie Test Hotel'));
    await tester.pumpAndSettle();

    expect(selectedPartner?.name, 'Indie Test Hotel');
    expect(find.text('Room Limit:'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Close Dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Room Limit:'), findsNothing);
  });

  testWidgets('InvitesView renders filter pills, invite cards, and action buttons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    String? lastAction;

    await tester.pumpWidget(
      MaterialApp(
        home: InvitesView(
          onInviteAction: (action) {
            lastAction = action;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title, Subtitle, and Invite button
    expect(find.text('Invites'), findsOneWidget);
    expect(find.textContaining('People invited to administer'), findsOneWidget);
    expect(find.text('Invite someone'), findsOneWidget);

    // Verify Filter Pills
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Revoked'), findsOneWidget);

    // Verify Initial Invites and Action buttons
    expect(find.text('rl4@example.com'), findsOneWidget);
    expect(find.text('Resend'), findsWidgets);
    expect(find.text('Revoke'), findsWidgets);

    // Click Resend
    await tester.tap(find.text('Resend').first);
    await tester.pumpAndSettle();
    expect(lastAction, 'resend_inv-1');

    // Click Revoke
    await tester.tap(find.text('Revoke').first);
    await tester.pumpAndSettle();
    expect(lastAction, 'revoke_inv-1');
    expect(find.text('Revoked'), findsWidgets);

    // Tap + Invite someone to open modal
    await tester.tap(find.text('Invite someone'));
    await tester.pumpAndSettle();

    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Send Invite'), findsOneWidget);

    // Close Dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('PropertiesView renders filter pills, property cards, and switches to AddPropertyView screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: PropertiesView(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title, Subtitle, and Add property button
    expect(find.text('Properties'), findsOneWidget);
    expect(find.textContaining('The buildings and sites rooms are created under'), findsOneWidget);
    expect(find.text('Add property'), findsOneWidget);

    // Verify Filter Pills
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Suspended'), findsOneWidget);

    // Verify Initial properties
    expect(find.text('Grand Hotel Downtown - Riverside'), findsOneWidget);

    // Tap + Add property to switch to AddPropertyView screen
    await tester.tap(find.text('Add property'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Add a property UI
    expect(find.text('Add a property'), findsOneWidget);
    expect(find.text('Entering Property name'), findsOneWidget);
    expect(find.text('Create property'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Type on virtual keyboard "a", "b", "c"
    await tester.tap(find.text('a'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('b'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('c'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('abc'), findsOneWidget);

    // Tap Create property
    await tester.tap(find.text('Create property'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify newly added property card is shown on PropertiesView
    expect(find.text('abc'), findsOneWidget);
    expect(find.text('Suspend'), findsWidgets);

    // Suspend property
    await tester.tap(find.text('Suspend').first);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Activate'), findsWidgets);
  });

  testWidgets('RoomsView renders filter pills, room cards, and switches to AddRoomView screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: RoomsView(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title, Subtitle, and + Add room button
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.textContaining('One row per TV'), findsOneWidget);
    expect(find.text('+ Add room'), findsOneWidget);

    // Verify Filter Pills
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Not set up'), findsWidgets);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Revoked'), findsOneWidget);

    // Verify Initial Room
    expect(find.text('Room 101 - King Suite'), findsOneWidget);

    // Tap + Add room to switch to AddRoomView screen
    await tester.tap(find.text('+ Add room'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Add a room UI
    expect(find.text('Add a room'), findsOneWidget);
    expect(find.text('Entering Room name'), findsOneWidget);
    expect(find.text('Create room'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Type on virtual keyboard "2", "1", "4"
    await tester.tap(find.text('2'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('1'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('4'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('214'), findsOneWidget);

    // Tap Create room
    await tester.tap(find.text('Create room'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify newly added room card
    expect(find.text('214'), findsOneWidget);

    // Tap room card to open details modal
    await tester.tap(find.text('214'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Status:'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('SettingsView renders account info cards and sign out flow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool signedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsView(
          name: 'Saad Khan',
          email: 'xaadkhan98@gmail.com',
          role: 'Super admin',
          scope: 'All partners and properties',
          onSignOut: () {
            signedOut = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('The account this TV is signed in with.'), findsOneWidget);

    // Verify Account Section Cards
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Saad Khan'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('xaadkhan98@gmail.com'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Super admin'), findsOneWidget);
    expect(find.text('Scope'), findsOneWidget);
    expect(find.text('All partners and properties'), findsOneWidget);

    // Verify Sign out this TV section & button
    expect(find.text('Sign out this TV'), findsOneWidget);
    expect(find.textContaining('Ends every session started'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    // Tap Sign out button
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    // Verify Confirmation Dialog
    expect(find.text('Sign out this TV?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Confirm Sign Out in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
  });
}
