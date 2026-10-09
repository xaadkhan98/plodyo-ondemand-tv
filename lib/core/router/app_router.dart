import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ui/features/device/device_gate.dart';
import '../../ui/features/device/views/home_view.dart';
import '../../ui/features/device/views/series_detail_view.dart';
import '../../ui/features/auth/views/sign_in_view.dart';
import '../../ui/features/auth/views/forgot_password_view.dart';
import '../../ui/features/auth/views/register_venue_view.dart';
import '../../ui/features/main_layout.dart';
import '../../ui/features/home/views/console_overview_view.dart';
import '../../ui/features/partners/views/partners_view.dart';
import '../../ui/features/partners/views/partner_details_view.dart';
import '../../ui/features/partners/views/partner_form_view.dart';
import '../../ui/features/invites/views/invites_view.dart';
import '../../ui/features/invites/views/invite_someone_view.dart';
import '../../ui/features/properties/views/properties_view.dart';
import '../../ui/features/properties/views/property_details_view.dart';
import '../../ui/features/properties/views/property_form_view.dart';
import '../../data/models/property_model.dart';
import '../../ui/features/rooms/views/rooms_view.dart';
import '../../ui/features/rooms/views/room_details_view.dart';
import '../../ui/features/rooms/views/room_form_view.dart';
import '../../data/models/room_model.dart';
import '../../ui/features/rooms/views/add_many_rooms_view.dart';
import '../../ui/features/settings/views/settings_view.dart';
import '../../ui/features/people/views/people_view.dart';
import '../../ui/features/people/views/person_details_view.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/models/partner_model.dart';
import '../../data/models/person_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

/// The room TV's screens: the device gate decides what they show, so they need no session.
const _guestPaths = {'/', '/series'};

/// Reachable without a session: the ways into the console.
const _publicPaths = {'/sign-in', '/forgot-password', '/register-venue'};

/// A paired set is a TV, whoever signed in on it; an unpaired one with a session is the console, which
/// lands on its overview until it can browse the catalogue. Console screens need a session, or every call
/// behind them would 401.
String? _redirect(BuildContext context, GoRouterState state) {
  final path = state.matchedLocation;
  final signedIn = sharedAuthRepository.isAuthenticated;
  if (_guestPaths.contains(path)) {
    return !sharedDeviceRepository.isPaired && signedIn ? '/overview' : null;
  }
  return _publicPaths.contains(path) || signedIn ? null : '/sign-in';
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: _redirect,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          DeviceGate(currentPath: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeView()),
        // `?id=` is one series; the bare path becomes the series list with G6.
        GoRoute(
          path: '/series',
          redirect: (context, state) =>
              state.uri.queryParameters['id'] == null ? '/' : null,
          builder: (context, state) =>
              SeriesDetailView(seriesId: state.uri.queryParameters['id']!),
        ),
      ],
    ),
    GoRoute(path: '/sign-in', builder: (context, state) => const SignInView()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordView(),
    ),
    GoRoute(
      path: '/register-venue',
      builder: (context, state) => const RegisterVenueView(),
    ),

    // Shell Route containing Persistent Sidebar Navigation Rail
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainTvLayout(currentPath: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/overview',
          name: 'overview',
          builder: (context, state) => const ConsoleOverviewView(),
        ),
        GoRoute(
          path: '/partners',
          name: 'partners',
          builder: (context, state) => const PartnersView(),
          routes: [
            GoRoute(
              path: 'details',
              name: 'partnerDetails',
              // The record travels as `extra`; without one (a restart, a deep link) go back to the list.
              redirect: (context, state) =>
                  state.extra is PartnerModel ? null : '/partners',
              builder: (context, state) =>
                  PartnerDetailsView(partner: state.extra! as PartnerModel),
            ),
            GoRoute(
              path: 'add',
              name: 'addPartner',
              builder: (context, state) => const PartnerFormView(),
            ),
            GoRoute(
              path: 'edit',
              name: 'editPartner',
              redirect: (context, state) =>
                  state.extra is PartnerModel ? null : '/partners',
              builder: (context, state) =>
                  PartnerFormView(partner: state.extra! as PartnerModel),
            ),
          ],
        ),
        GoRoute(
          path: '/invites',
          name: 'invites',
          builder: (context, state) => const InvitesView(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addInvite',
              builder: (context, state) => const InviteSomeoneView(),
            ),
          ],
        ),
        GoRoute(
          path: '/properties',
          name: 'properties',
          builder: (context, state) => const PropertiesView(),
          routes: [
            GoRoute(
              path: 'details',
              name: 'propertyDetails',
              redirect: (context, state) =>
                  state.extra is PropertyModel ? null : '/properties',
              builder: (context, state) =>
                  PropertyDetailsView(property: state.extra! as PropertyModel),
            ),
            GoRoute(
              path: 'add',
              name: 'addProperty',
              builder: (context, state) => const PropertyFormView(),
            ),
            GoRoute(
              path: 'edit',
              name: 'editProperty',
              redirect: (context, state) =>
                  state.extra is PropertyModel ? null : '/properties',
              builder: (context, state) =>
                  PropertyFormView(property: state.extra! as PropertyModel),
            ),
          ],
        ),
        GoRoute(
          path: '/rooms',
          name: 'rooms',
          builder: (context, state) => const RoomsView(),
          routes: [
            GoRoute(
              path: 'details',
              name: 'roomDetails',
              redirect: (context, state) =>
                  state.extra is RoomModel ? null : '/rooms',
              builder: (context, state) =>
                  RoomDetailsView(room: state.extra! as RoomModel),
            ),
            // `extra` on add and add-many is the property the list was filtered to, if any.
            GoRoute(
              path: 'add',
              name: 'addRoom',
              builder: (context, state) =>
                  RoomFormView(propertyId: state.extra as String?),
            ),
            GoRoute(
              path: 'edit',
              name: 'editRoom',
              redirect: (context, state) =>
                  state.extra is RoomModel ? null : '/rooms',
              builder: (context, state) =>
                  RoomFormView(room: state.extra! as RoomModel),
            ),
            GoRoute(
              path: 'add-many',
              name: 'addManyRooms',
              builder: (context, state) =>
                  AddManyRoomsView(propertyId: state.extra as String?),
            ),
          ],
        ),
        GoRoute(
          path: '/people',
          name: 'people',
          builder: (context, state) => const PeopleView(),
          routes: [
            GoRoute(
              path: 'details',
              name: 'personDetails',
              // The record travels as `extra`; without one (a restart, a deep link) go back to the list.
              redirect: (context, state) =>
                  state.extra is PersonModel ? null : '/people',
              builder: (context, state) {
                final person = state.extra as PersonModel;
                return PersonDetailsView(person: person);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) =>
              SettingsView(authRepository: sharedAuthRepository),
        ),
      ],
    ),
  ],
);
