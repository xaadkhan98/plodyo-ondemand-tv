import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ui/features/auth/views/sign_in_view.dart';
import '../../ui/features/main_layout.dart';
import '../../ui/features/home/views/home_view.dart';
import '../../ui/features/home/view_models/home_view_model.dart';
import '../../ui/features/search/views/search_view.dart';
import '../../ui/features/categories/views/categories_view.dart';
import '../../ui/features/partners/views/partners_view.dart';
import '../../ui/features/invites/views/invites_view.dart';
import '../../ui/features/properties/views/properties_view.dart';
import '../../ui/features/rooms/views/rooms_view.dart';
import '../../ui/features/settings/views/settings_view.dart';
import '../../ui/features/details/views/details_view.dart';
import '../../data/repositories/mock_vod_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/media_item.dart';
import '../widgets/plodyo_header.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final VodRepository _sharedRepository = MockVodRepository();
final HomeViewModel _sharedHomeViewModel = HomeViewModel(repository: _sharedRepository)..loadCatalog();

/// Declarative GoRouter configuration for the TV app
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/sign-in',
  routes: [
    // Standalone Sign In Route
    GoRoute(
      path: '/sign-in',
      name: 'signIn',
      builder: (context, state) => SignInView(
        onSignedIn: () {
          context.go('/home');
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
          redirect: (context, state) => '/home',
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => HomeView(
            viewModel: _sharedHomeViewModel,
            onMediaSelected: (item) {
              context.push('/details', extra: item);
            },
          ),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => SearchView(
            onMediaSelected: (item) {
              context.push('/details', extra: item);
            },
          ),
        ),
        GoRoute(
          path: '/categories',
          name: 'categories',
          builder: (context, state) => const CategoriesView(),
        ),
        GoRoute(
          path: '/stories',
          name: 'stories',
          builder: (context, state) => const _PlaceholderScreen(
            title: 'All stories',
            icon: Icons.bar_chart_rounded,
          ),
        ),
        GoRoute(
          path: '/partners',
          name: 'partners',
          builder: (context, state) => const PartnersView(),
        ),
        GoRoute(
          path: '/invites',
          name: 'invites',
          builder: (context, state) => const InvitesView(),
        ),
        GoRoute(
          path: '/properties',
          name: 'properties',
          builder: (context, state) => const PropertiesView(),
        ),
        GoRoute(
          path: '/rooms',
          name: 'rooms',
          builder: (context, state) => const RoomsView(),
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

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalSpacing = screenWidth * 0.10;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: PlodyoHeader(),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 56,
                        color: const Color(0xFF9333EA).withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This screen will be populated in an upcoming update.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
