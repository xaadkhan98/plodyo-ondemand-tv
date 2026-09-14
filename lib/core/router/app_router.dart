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
import '../../ui/features/partners/views/add_partner_view.dart';
import '../../ui/features/invites/views/invites_view.dart';
import '../../ui/features/invites/views/invite_someone_view.dart';
import '../../ui/features/properties/views/properties_view.dart';
import '../../ui/features/properties/views/add_property_view.dart';
import '../../ui/features/rooms/views/rooms_view.dart';
import '../../ui/features/rooms/views/add_room_view.dart';
import '../../ui/features/rooms/views/add_many_rooms_view.dart';
import '../../ui/features/settings/views/settings_view.dart';
import '../../ui/features/people/views/people_view.dart';
import '../../ui/features/people/views/person_details_view.dart';
import '../../ui/features/details/views/details_view.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/media_item.dart';
import '../../data/models/partner_model.dart';
import '../../data/models/person_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Declarative GoRouter configuration for the TV app
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
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

    // Details View (Full Screen on TV)
    GoRoute(
      path: '/details',
      name: 'details',
      builder: (context, state) {
        final item = state.extra as MediaItem? ??
            const MediaItem(
              id: 'm1',
              title: 'Neon Odyssey 2099',
              category: 'Sci-Fi & Cyberpunk',
              posterUrl: 'https://picsum.photos/seed/neon/400/600',
              backdropUrl: 'https://picsum.photos/seed/neon_hero/1280/720',
              rating: 8.9,
              duration: '2h 18m',
              releaseYear: 2025,
              description:
                  'In a rain-soaked metropolis ruled by rogue AI corporations, a synthetic detective is pulled into one final case.',
            );
        return DetailsView(
          item: item,
          onBack: () => context.pop(),
          onMediaSelected: (newItem) {
            context.pushReplacement('/details', extra: newItem);
          },
        );
      },
    ),

    // Shell Route containing Persistent Sidebar Navigation Rail
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainTvLayout(
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) => '/overview',
        ),
        GoRoute(
          path: '/home',
          redirect: (context, state) => '/overview',
        ),
        GoRoute(
          path: '/overview',
          name: 'overview',
          builder: (context, state) => const ConsoleOverviewView(),
        ),
        GoRoute(
          path: '/partners',
          name: 'partners',
          builder: (context, state) => PartnersView(
            onPartnerSelected: (partner) {
              context.push('/partners/details', extra: partner);
            },
          ),
          routes: [
            GoRoute(
              path: 'details',
              name: 'partnerDetails',
              builder: (context, state) {
                final partner = state.extra as PartnerModel? ??
                    const PartnerModel(
                      id: 'p2',
                      name: 'HotelA1',
                      partnerType: 'INDEPENDENT',
                      contactEmail: 'mudsr3@gmail.com',
                      contactName: 'Ali',
                      phone: null,
                      roomLimit: 0,
                      status: 'PENDING_APPROVAL',
                      createdAt: '10 Sept 2026, 21:33',
                    );
                return PartnerDetailsView(partner: partner);
              },
            ),
            GoRoute(
              path: 'add',
              name: 'addPartner',
              builder: (context, state) => const AddPartnerView(),
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
              path: 'add',
              name: 'addProperty',
              builder: (context, state) => const AddPropertyView(),
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
              builder: (context, state) {
                final person = state.extra as PersonModel? ??
                    const PersonModel(
                      id: 'person-1',
                      fullName: 'Super Admin',
                      email: 'superadmin@email.com',
                      role: 'SUPER_ADMIN',
                      status: 'ACTIVE',
                      lastLoginAt: '12 Sept 2026, 16:13',
                      createdAt: '10 Sept 2026, 23:56',
                      isCurrentUser: false,
                    );
                return PersonDetailsView(person: person);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => SettingsView(
            authRepository: sharedAuthRepository,
          ),
        ),
      ],
    ),
  ],
);
