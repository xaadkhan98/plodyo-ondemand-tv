import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/data/models/paginated_response.dart';
import 'package:plodyo_ondemand_tv/data/models/person_model.dart';
import 'package:plodyo_ondemand_tv/data/repositories/people_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/api_client.dart';
import 'package:plodyo_ondemand_tv/data/services/people_api_service.dart';
import 'package:plodyo_ondemand_tv/ui/features/people/views/people_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/people/views/person_details_view.dart';

class _MockTestPeopleRepo implements PeopleRepository {
  final List<PersonModel> _people = [
    const PersonModel(
      id: 'person-1',
      fullName: 'Super Admin',
      email: 'superadmin@email.com',
      role: 'SUPER_ADMIN',
      status: 'ACTIVE',
      lastLoginAt: '12 Sept 2026',
      isCurrentUser: false,
    ),
    const PersonModel(
      id: 'person-2',
      fullName: 'Saad Hotel1',
      email: 'xaadkhan98+hotel1@gmail.com',
      role: 'PARTNER_ADMIN',
      status: 'ACTIVE',
      lastLoginAt: '4 Sept 2026',
      isCurrentUser: false,
    ),
    const PersonModel(
      id: 'person-3',
      fullName: 'Saad Khan',
      email: 'xaadkhan98@gmail.com',
      role: 'SUPER_ADMIN',
      status: 'ACTIVE',
      lastLoginAt: '13 Sept 2026',
      isCurrentUser: true,
    ),
  ];

  @override
  Future<PaginatedResponse<PersonModel>> getPeople({
    required String accessToken,
    String? status,
    String? role,
    int? page,
    int? pageSize,
  }) async {
    return PaginatedResponse(
      data: _people,
      total: _people.length,
      page: 1,
      pageSize: 25,
    );
  }

  @override
  Future<PersonModel> getPerson({
    required String accessToken,
    required String personId,
  }) async {
    return _people.firstWhere((p) => p.id == personId);
  }

  @override
  Future<PersonModel> updateName({
    required String accessToken,
    required String personId,
    required String fullName,
  }) async {
    return _people.firstWhere((p) => p.id == personId);
  }

  @override
  Future<PersonModel> updateStatus({
    required String accessToken,
    required String personId,
    required String status,
  }) async {
    return _people.firstWhere((p) => p.id == personId);
  }

  @override
  Future<PersonModel> updateRole({
    required String accessToken,
    required String personId,
    required String role,
  }) async {
    return _people.firstWhere((p) => p.id == personId);
  }

  @override
  Future<String> deletePerson({
    required String accessToken,
    required String personId,
  }) async {
    return 'Person deleted';
  }
}

void main() {
  group('PeopleApiService & Repository Tests', () {
    test('getPeople returns paginated people on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/admin/users');
        expect(request.headers['Authorization'], 'Bearer test_token');

        final payload = {
          'data': [
            {
              'id': 'person-1',
              'full_name': 'Super Admin',
              'email': 'superadmin@email.com',
              'role': 'SUPER_ADMIN',
              'status': 'ACTIVE',
              'last_login_at': '12 Sept 2026',
              'is_current_user': false,
            },
            {
              'id': 'person-2',
              'full_name': 'Saad Hotel1',
              'email': 'xaadkhan98+hotel1@gmail.com',
              'role': 'PARTNER_ADMIN',
              'status': 'ACTIVE',
              'last_login_at': '4 Sept 2026',
              'is_current_user': false,
            },
            {
              'id': 'person-3',
              'full_name': 'Saad Khan',
              'email': 'xaadkhan98@gmail.com',
              'role': 'SUPER_ADMIN',
              'status': 'ACTIVE',
              'last_login_at': '13 Sept 2026',
              'is_current_user': true,
            },
          ],
          'total': 3,
          'page': 1,
          'page_size': 25,
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = PeopleApiService(
        apiClient: ApiClient(httpClient: mockClient),
      );
      final repo = PeopleRepositoryImpl(apiService: service);

      final response = await repo.getPeople(accessToken: 'test_token');
      expect(response.total, 3);
      expect(response.data.length, 3);
      expect(response.data[0].fullName, 'Super Admin');
      expect(response.data[0].email, 'superadmin@email.com');
      expect(response.data[0].roleDisplayName, 'Super admin');
      expect(response.data[0].isActive, isTrue);

      expect(response.data[1].fullName, 'Saad Hotel1');
      expect(response.data[1].email, 'xaadkhan98+hotel1@gmail.com');
      expect(response.data[1].roleDisplayName, 'Partner admin');

      expect(response.data[2].fullName, 'Saad Khan');
      expect(response.data[2].email, 'xaadkhan98@gmail.com');
      expect(response.data[2].isCurrentUser, isTrue);
    });

    test('updateStatus changes status for person', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/admin/users/person-1');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['status'], 'DISABLED');

        final payload = {
          'id': 'person-1',
          'full_name': 'Super Admin',
          'email': 'superadmin@email.com',
          'status': 'DISABLED',
          'last_login_at': '12 Sept 2026',
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = PeopleApiService(
        apiClient: ApiClient(httpClient: mockClient),
      );
      final repo = PeopleRepositoryImpl(apiService: service);

      final updated = await repo.updateStatus(
        accessToken: 'token',
        personId: 'person-1',
        status: 'DISABLED',
      );

      expect(updated.id, 'person-1');
      expect(updated.status, 'DISABLED');
      expect(updated.isDisabled, isTrue);
    });

    test('updateName changes person name', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/admin/users/person-1');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['full_name'], 'Saad Updated');

        final payload = {
          'id': 'person-1',
          'full_name': 'Saad Updated',
          'email': 'superadmin@email.com',
          'status': 'ACTIVE',
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = PeopleApiService(
        apiClient: ApiClient(httpClient: mockClient),
      );
      final repo = PeopleRepositoryImpl(apiService: service);

      final updated = await repo.updateName(
        accessToken: 'token',
        personId: 'person-1',
        fullName: 'Saad Updated',
      );

      expect(updated.id, 'person-1');
      expect(updated.fullName, 'Saad Updated');
    });
  });

  group('PeopleView Widget Tests', () {
    testWidgets('renders People title, subtitle, filter chips and cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      PersonModel? selectedPerson;

      await tester.pumpWidget(
        MaterialApp(
          home: PeopleView(
            peopleRepository: _MockTestPeopleRepo(),
            onPersonSelected: (p) => selectedPerson = p,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Verify Title & Subtitle
      expect(find.text('People'), findsOneWidget);
      expect(
        find.text(
          'Everyone who can sign in within your scope. Disabling an account ends its sessions on every device at once.',
        ),
        findsOneWidget,
      );

      // Verify Filter Pills
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Invited'), findsWidgets);
      expect(find.text('Disabled'), findsWidgets);

      // Verify Person names from design
      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('Saad Hotel1'), findsOneWidget);
      expect(find.text('Saad Khan'), findsOneWidget);

      // Verify Emails
      expect(find.text('superadmin@email.com'), findsOneWidget);
      expect(find.text('xaadkhan98+hotel1@gmail.com'), findsOneWidget);
      expect(find.text('xaadkhan98@gmail.com'), findsOneWidget);

      // Tap on a person card to trigger callback
      await tester.tap(find.text('Saad Hotel1'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(selectedPerson, isNotNull);
      expect(selectedPerson!.fullName, 'Saad Hotel1');
    });
  });

  group('PersonDetailsView Widget Tests', () {
    testWidgets('renders 2x2 grid, Access section, and action buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const samplePerson = PersonModel(
        id: 'person-1',
        fullName: 'Super Admin',
        email: 'superadmin@email.com',
        role: 'SUPER_ADMIN',
        status: 'ACTIVE',
        lastLoginAt: '12 Sept 2026, 16:13',
        createdAt: '10 Sept 2026, 23:56',
        isCurrentUser: false,
      );

      bool backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PersonDetailsView(
            person: samplePerson,
            onBack: () => backPressed = true,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Verify Back Button
      expect(find.text('All people'), findsOneWidget);

      // Verify Header Title & Status Badge
      expect(find.text('Super Admin'), findsWidgets);
      expect(find.text('Active'), findsOneWidget);

      // Verify 2x2 Cards Grid
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('superadmin@email.com'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Last signed in'), findsOneWidget);
      expect(find.text('12 Sept 2026, 16:13'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('10 Sept 2026, 23:56'), findsOneWidget);

      // Verify Access Section
      expect(find.text('Access'), findsOneWidget);
      expect(
        find.text(
          'Only the scopes inside your own are listed. This account may hold others elsewhere that you cannot see.',
        ),
        findsOneWidget,
      );
      expect(find.text('All partners and properties'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text('Change name'), findsOneWidget);
      expect(find.text('Disable account'), findsOneWidget);

      // Test Back button
      await tester.tap(find.text('All people'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(backPressed, isTrue);
    });

    testWidgets(
      'clicking Change Name shows inline UI with TV keyboard and hides action buttons',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const samplePerson = PersonModel(
          id: 'person-1',
          fullName: 'Super Admin',
          email: 'superadmin@email.com',
          role: 'SUPER_ADMIN',
          status: 'ACTIVE',
        );

        await tester.pumpWidget(
          const MaterialApp(home: PersonDetailsView(person: samplePerson)),
        );

        await tester.pump(const Duration(milliseconds: 300));

        // Initially action buttons are visible
        expect(find.text('Change name'), findsOneWidget);
        expect(find.text('Disable account'), findsOneWidget);

        // Click "Change name"
        await tester.tap(find.text('Change name'));
        await tester.pump(const Duration(milliseconds: 300));

        // Now "Disable account" should be hidden
        expect(find.text('Disable account'), findsNothing);

        // Inline Change Name header & description should be visible
        expect(
          find.text(
            'This is the only route in the API that can set a display name — there is no self-service profile screen.',
          ),
          findsOneWidget,
        );
        expect(find.text('Full name'), findsOneWidget);
        expect(find.text('Save name'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Dedicated TV keyboard should be visible
        expect(find.text('Clear'), findsOneWidget);
        expect(find.text('↑ abc'), findsOneWidget);
        expect(find.text('!#?'), findsOneWidget);

        // Test Cancel button restores the original action buttons
        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Change name'), findsOneWidget);
        expect(find.text('Disable account'), findsOneWidget);
        expect(find.text('Full name'), findsNothing);
      },
    );
  });
}
