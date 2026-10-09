import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/actor.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_response.dart';
import 'package:plodyo_ondemand_tv/data/models/invite_model.dart';
import 'package:plodyo_ondemand_tv/data/models/paginated_response.dart';
import 'package:plodyo_ondemand_tv/data/models/partner_model.dart';
import 'package:plodyo_ondemand_tv/data/models/property_model.dart';
import 'package:plodyo_ondemand_tv/data/models/room_model.dart';
import 'package:plodyo_ondemand_tv/data/repositories/auth_repository.dart';
import 'package:plodyo_ondemand_tv/data/repositories/invites_repository.dart';
import 'package:plodyo_ondemand_tv/data/repositories/partners_repository.dart';
import 'package:plodyo_ondemand_tv/data/repositories/properties_repository.dart';
import 'package:plodyo_ondemand_tv/data/repositories/rooms_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/auth_api_service.dart';
import 'package:plodyo_ondemand_tv/main.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/cubit/sign_in_cubit.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/views/sign_in_view.dart';
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
      final res =
          authResponse ??
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
          const AuthException(message: 'Invalid credentials', statusCode: 401);
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
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return 'Password updated';
  }

  @override
  Future<AuthMeResponse> getMe({String? accessToken}) async {
    return AuthMeResponse(
      actor:
          _auth?.actor ??
          const Actor(
            userId: 'u1',
            email: 'a@b.com',
            fullName: 'A',
            role: 'SUPER_ADMIN',
          ),
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
  Future<String> acceptInvite({
    required String token,
    required String password,
    String? fullName,
  }) async {
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

class _MockPartnersRepo implements PartnersRepository {
  final List<PartnerModel> _partners = [
    const PartnerModel(
      id: 'p1',
      name: 'Indie Test Hotel',
      partnerType: 'INDEPENDENT',
      status: 'PENDING_APPROVAL',
      contactEmail: 'indie@test.com',
      roomLimit: 10,
      createdAt: '12 Sept 2026',
    ),
    const PartnerModel(
      id: 'p2',
      name: 'rl4',
      partnerType: 'CHAIN',
      status: 'ACTIVE',
      contactEmail: 'rl4@test.com',
      roomLimit: 20,
      createdAt: '10 Sept 2026',
    ),
  ];

  @override
  Future<PaginatedResponse<PartnerModel>> getPartners({
    required String accessToken,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    var list = _partners;
    if (status != null && status.isNotEmpty) {
      list = list
          .where((p) => p.status.toUpperCase() == status.toUpperCase())
          .toList();
    }
    return PaginatedResponse(
      data: list,
      total: list.length,
      page: 1,
      pageSize: 25,
    );
  }

  @override
  Future<PartnerModel> getPartner({
    required String accessToken,
    required String partnerId,
  }) async {
    return _partners.firstWhere((p) => p.id == partnerId);
  }

  @override
  Future<PartnerModel> approvePartner({
    required String accessToken,
    required String partnerId,
    int? roomLimit,
  }) async {
    return _partners.firstWhere((p) => p.id == partnerId);
  }

  @override
  Future<PartnerModel> rejectPartner({
    required String accessToken,
    required String partnerId,
    String? rejectionReason,
  }) async {
    return _partners.firstWhere((p) => p.id == partnerId);
  }

  @override
  Future<PartnerModel> updateRoomLimit({
    required String accessToken,
    required String partnerId,
    required int roomLimit,
  }) async {
    return _partners.firstWhere((p) => p.id == partnerId);
  }

  @override
  Future<PartnerModel> createPartner({
    required String accessToken,
    required String name,
    required String partnerType,
    required String contactEmail,
    String? contactName,
    String? phone,
    String? contractReference,
    required int roomLimit,
    String? contentTier,
  }) async {
    return _partners.first;
  }

  @override
  Future<PartnerModel> updatePartner({
    required String accessToken,
    required String partnerId,
    String? name,
    String? contactName,
    String? contactEmail,
    String? phone,
    String? contractReference,
    String? contentTier,
  }) async {
    return _partners.firstWhere((p) => p.id == partnerId);
  }

  @override
  Future<PartnerModel> activatePartner({
    required String accessToken,
    required String partnerId,
  }) async {
    return _partners.firstWhere((p) => p.id == partnerId);
  }

  @override
  Future<PartnerModel> suspendPartner({
    required String accessToken,
    required String partnerId,
  }) async {
    return _partners.firstWhere((p) => p.id == partnerId);
  }
}

class _MockInvitesRepo implements InvitesRepository {
  /// Row actions in the order the screen made them.
  final calls = <String>[];

  final List<InviteModel> _invites = [
    const InviteModel(
      id: 'inv-1',
      email: 'mudsr3@gmail.com',
      role: 'PROPERTY_ADMIN',
      partnerId: 'p1',
      propertyId: 'prop1',
      status: 'PENDING',
      sentAt: '12 Sept 2026',
      createdAt: '12 Sept 2026',
    ),
  ];

  @override
  Future<PaginatedResponse<InviteModel>> getInvites({
    required String accessToken,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    var list = _invites;
    if (status != null && status.isNotEmpty) {
      list = list
          .where((i) => i.status.toUpperCase() == status.toUpperCase())
          .toList();
    }
    return PaginatedResponse(
      data: list,
      total: list.length,
      page: 1,
      pageSize: 25,
    );
  }

  @override
  Future<InviteModel> createInvite({
    required String accessToken,
    required String email,
    required String role,
    required String partnerId,
    String? propertyId,
  }) async {
    return _invites.first;
  }

  @override
  Future<InviteModel> resendInvite({
    required String accessToken,
    required String inviteId,
  }) async {
    calls.add('resend:$inviteId');
    return _invites.firstWhere((i) => i.id == inviteId);
  }

  @override
  Future<String> revokeInvite({
    required String accessToken,
    required String inviteId,
  }) async {
    calls.add('revoke:$inviteId');
    return 'Invite revoked.';
  }
}

class _MockPropertiesRepo implements PropertiesRepository {
  final List<PropertyModel> _props = [
    const PropertyModel(
      id: 'prop-1',
      partnerId: 'p1',
      name: 'Grand Hotel Downtown - Riverside',
      status: 'ACTIVE',
      country: 'US',
      city: 'Austin',
      timezone: 'America/Chicago',
      defaultLanguage: 'ENG',
      createdAt: '12 Sept 2026',
    ),
  ];

  @override
  Future<PaginatedResponse<PropertyModel>> getProperties({
    required String accessToken,
    String? partnerId,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    return PaginatedResponse(
      data: _props,
      total: _props.length,
      page: 1,
      pageSize: 25,
    );
  }

  @override
  Future<PropertyModel> getProperty({
    required String accessToken,
    required String propertyId,
  }) async {
    return _props.first;
  }

  @override
  Future<PropertyModel> createProperty({
    required String accessToken,
    required String partnerId,
    required String name,
    String? country,
    String? city,
    String? timezone,
    String? defaultLanguage,
  }) async {
    return _props.first;
  }

  @override
  Future<PropertyModel> updateProperty({
    required String accessToken,
    required String propertyId,
    String? name,
    String? country,
    String? city,
    String? timezone,
    String? defaultLanguage,
  }) async {
    return _props.first;
  }

  @override
  Future<PropertyModel> suspendProperty({
    required String accessToken,
    required String propertyId,
  }) async {
    return _props.first;
  }

  @override
  Future<PropertyModel> activateProperty({
    required String accessToken,
    required String propertyId,
  }) async {
    return _props.first;
  }
}

class _MockRoomsRepo implements RoomsRepository {
  final List<RoomModel> _rooms = [
    const RoomModel(
      id: 'r1',
      propertyId: 'prop-1',
      roomLabel: 'Room 101',
      status: 'ACTIVE',
      defaultLanguage: 'ENG',
      createdAt: '12 Sept 2026',
    ),
  ];

  @override
  Future<PaginatedResponse<RoomModel>> getRooms({
    required String accessToken,
    String? propertyId,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    return PaginatedResponse(
      data: _rooms,
      total: _rooms.length,
      page: 1,
      pageSize: 25,
    );
  }

  @override
  Future<RoomModel> getRoom({
    required String accessToken,
    required String roomId,
  }) async {
    return _rooms.first;
  }

  @override
  Future<RoomModel> createRoom({
    required String accessToken,
    required String propertyId,
    required String roomLabel,
    String? defaultLanguage,
  }) async {
    return _rooms.first;
  }

  @override
  Future<BulkCreateRoomsResponse> createRoomsBulk({
    required String accessToken,
    required String propertyId,
    required List<Map<String, dynamic>> rooms,
    String? defaultLanguage,
  }) async {
    return BulkCreateRoomsResponse(created: _rooms.length, rooms: _rooms);
  }

  @override
  Future<RoomModel> updateRoom({
    required String accessToken,
    required String roomId,
    String? roomLabel,
    String? defaultLanguage,
  }) async {
    return _rooms.first;
  }

  @override
  Future<String> deleteRoom({
    required String accessToken,
    required String roomId,
  }) async {
    return 'Room deleted.';
  }

  @override
  Future<ProvisionRoomResponse> provisionRoom({
    required String accessToken,
    required String roomId,
  }) async {
    return const ProvisionRoomResponse(
      pairingCode: '4F7K-92QT',
      expiresAt: '2026-08-28T10:30:00.000Z',
    );
  }

  @override
  Future<String> revokeRoom({
    required String accessToken,
    required String roomId,
  }) async {
    return 'Device revoked.';
  }
}

void main() {
  testWidgets(
    'TV App loads Splash view as first screen without initial error',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const PlodyoTvApp());
      await tester.pump();

      expect(find.text('This TV is not set up yet'), findsOneWidget);
      expect(find.text('Set up this TV'), findsOneWidget);
      expect(find.text('Sign in to the console'), findsOneWidget);
    },
  );

  testWidgets(
    'SplashView navigates to SignInView on "Sign in to the console" button press',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const PlodyoTvApp());
      await tester.pump();

      final consoleButton = find.text('Sign in to the console');
      expect(consoleButton, findsOneWidget);

      await tester.tap(consoleButton);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sign in to the TV'), findsOneWidget);
    },
  );

  testWidgets(
    'SignInView shows validation error on empty credentials and signs in on valid credentials',
    (WidgetTester tester) async {
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

      await tester.tap(find.text('Sign in'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Enter both an email address and a password.'),
        findsOneWidget,
      );
      expect(navigated, isFalse);

      await tester.tap(find.text('a'));
      await tester.pump();
      await tester.tap(find.text('b'));
      await tester.pump();

      await tester.tap(find.text('Password'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();

      await tester.tap(find.text('Sign in'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(navigated, isTrue);
    },
  );

  testWidgets(
    'SignInView triggers onForgotPassword and onRegisterVenue callbacks',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool forgotPasswordCalled = false;
      bool registerVenueCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SignInView(
            onForgotPassword: () {
              forgotPasswordCalled = true;
            },
            onRegisterVenue: () {
              registerVenueCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Forgot password?'));
      await tester.pump();
      expect(forgotPasswordCalled, isTrue);

      await tester.tap(find.text('Register a new venue'));
      await tester.pump();
      expect(registerVenueCalled, isTrue);
    },
  );

  testWidgets('PartnersView renders filter pills and partner cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    PartnerModel? selectedPartner;

    await tester.pumpWidget(
      MaterialApp(
        home: PartnersView(
          partnersRepository: _MockPartnersRepo(),
          onPartnerSelected: (p) {
            selectedPartner = p;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Partners'), findsOneWidget);
    expect(find.textContaining('Venues on Plodyo TV'), findsOneWidget);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Pending approval'), findsWidgets);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Suspended'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);

    expect(find.text('Indie Test Hotel'), findsOneWidget);
    expect(find.text('rl4'), findsOneWidget);

    await tester.tap(find.text('Pending approval').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Indie Test Hotel'), findsOneWidget);
    expect(find.text('rl4'), findsNothing);

    await tester.tap(find.text('Indie Test Hotel'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(selectedPartner?.name, 'Indie Test Hotel');
  });

  testWidgets(
    'InvitesView renders filter pills, invite cards, and action buttons',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final invites = _MockInvitesRepo();

      await tester.pumpWidget(
        MaterialApp(home: InvitesView(invitesRepository: invites)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Invites'), findsOneWidget);
      expect(
        find.textContaining('People invited to administer'),
        findsOneWidget,
      );
      expect(find.text('Invite someone'), findsOneWidget);

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Accepted'), findsWidgets);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Revoked'), findsWidgets);

      expect(find.text('mudsr3@gmail.com'), findsOneWidget);
      expect(find.text('Resend'), findsWidgets);
      expect(find.text('Revoke'), findsWidgets);

      await tester.tap(find.text('Resend').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(invites.calls.last, 'resend:inv-1');

      await tester.tap(find.text('Revoke').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(invites.calls.last, 'revoke:inv-1');
    },
  );

  testWidgets('PropertiesView renders filter pills and property cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // A partner admin may add properties; the button is hidden from a property admin.
    final auth = MockAuthRepository();
    await auth.signIn(email: 'ops@grandhotel.com', password: 'secret');

    await tester.pumpWidget(
      MaterialApp(
        home: PropertiesView(
          propertiesRepository: _MockPropertiesRepo(),
          partnersRepository: _MockPartnersRepo(),
          authRepository: auth,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Properties'), findsOneWidget);
    expect(
      find.textContaining('The buildings and sites rooms are created under'),
      findsOneWidget,
    );
    expect(find.text('Add property'), findsOneWidget);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Suspended'), findsOneWidget);

    expect(find.text('Grand Hotel Downtown - Riverside'), findsOneWidget);
  });

  testWidgets('RoomsView renders filter pills and room cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: RoomsView(
          roomsRepository: _MockRoomsRepo(),
          propertiesRepository: _MockPropertiesRepo(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Rooms'), findsOneWidget);
    expect(find.textContaining('One row per TV'), findsOneWidget);
    expect(find.text('Add room'), findsOneWidget);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Not set up'), findsWidgets);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Revoked'), findsOneWidget);

    expect(find.text('Room 101'), findsOneWidget);
  });

  testWidgets('SettingsView shows the signed-in account and signs out', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final auth = MockAuthRepository(
      authResponse: const AuthResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        tokenType: 'Bearer',
        expiresIn: 900,
        actor: Actor(
          userId: 'u1',
          email: 'xaadkhan98@gmail.com',
          fullName: 'Saad Khan',
          role: 'SUPER_ADMIN',
        ),
      ),
    );
    await auth.signIn(email: 'xaadkhan98@gmail.com', password: 'secret');
    var signedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsView(
          authRepository: auth,
          onSignOut: () => signedOut = true,
        ),
      ),
    );
    // The page title's sticker floats forever, so pump a fixed time rather than settling.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Settings'), findsOneWidget);
    expect(
      find.text('The account this console session is signed in with.'),
      findsOneWidget,
    );
    expect(find.text('Saad Khan'), findsOneWidget);
    expect(find.text('xaadkhan98@gmail.com'), findsOneWidget);
    expect(find.text('Super admin'), findsOneWidget);
    expect(find.text('All partners and properties'), findsOneWidget);
    expect(find.textContaining('Ends every session started'), findsOneWidget);

    // Signs out at once, as in the reference: no confirmation dialog.
    await tester.tap(find.text('Sign out').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(signedOut, isTrue);
    expect(auth.currentUser, isNull);
  });
}
