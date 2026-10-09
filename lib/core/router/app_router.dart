import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ui/features/splash/views/unpaired_splash_view.dart';
import '../../ui/features/splash/views/tv_pairing_view.dart';
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
import '../../ui/features/rooms/views/add_room_view.dart';
import '../../ui/features/rooms/views/add_many_rooms_view.dart';
import '../../ui/features/settings/views/settings_view.dart';
import '../../ui/features/people/views/people_view.dart';
import '../../ui/features/people/views/person_details_view.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/partner_model.dart';
import '../../data/models/person_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

/// Reachable without a session: the TV's own setup screens and the ways into the console.
const _publicPaths = {
  '/splash',
  '/pair-tv',
  '/sign-in',
  '/forgot-password',
  '/register-venue',
};

/// Declarative GoRouter configuration for the TV app
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  // The console needs a signed-in account; without one every call behind it would 401.
  redirect: (context, state) =>
      _publicPaths.contains(state.matchedLocation) ||
          sharedAuthRepository.isAuthenticated
      ? null
      : '/sign-in',
  routes: [
    // Unpaired TV Splash Screen (Initial startup screen)
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => UnpairedSplashView(
        onSignInConsole: () {
          context.push('/sign-in');
        },
      ),
    ),

    // Pair TV Screen (Enter Pairing Code)
    GoRoute(
      path: '/pair-tv',
      name: 'pairTv',
      builder: (context, state) => TvPairingView(
        onPaired: () {
          context.go('/home');
        },
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/splash');
          }
        },
      ),
    ),

    // Standalone Sign In Route
    GoRoute(
      path: '/sign-in',
      name: 'signIn',
      builder: (context, state) => SignInView(
        onSignedIn: () {
          context.go('/home');
        },
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/splash');
          }
        },
      ),
    ),

    // Forgot Password Route
    GoRoute(
      path: '/forgot-password',
      name: 'forgotPassword',
      builder: (context, state) => ForgotPasswordView(
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sign-in');
          }
        },
      ),
    ),

    // Register Venue Route
    GoRoute(
      path: '/register-venue',
      name: 'registerVenue',
      builder: (context, state) => RegisterVenueView(
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sign-in');
          }
        },
      ),
    ),

    // Shell Route containing Persistent Sidebar Navigation Rail
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainTvLayout(currentPath: state.uri.path, child: child);
      },
      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/overview'),
        GoRoute(path: '/home', redirect: (context, state) => '/overview'),
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
              path: 'add',
              name: 'addRoom',
              builder: (context, state) => const AddRoomView(),
            ),
            GoRoute(
              path: 'add-many',
              name: 'addManyRooms',
              builder: (context, state) => const AddManyRoomsView(),
            ),
          ],
        ),
        GoRoute(
          path: '/people',
          name: 'people',
          builder: (context, state) => PeopleView(
            onPersonSelected: (person) {
              context.push('/people/details', extra: person);
            },
          ),
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
