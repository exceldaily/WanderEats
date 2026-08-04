import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/authentication/presentation/onboarding_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/authentication/presentation/sign_in_screen.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/authentication/presentation/welcome_screen.dart';
import '../../features/biteswipe/presentation/biteswipe_screen.dart';
import '../../features/discovery/presentation/discover_screen.dart';
import '../../features/discovery/presentation/search_screen.dart';
import '../../features/lists/presentation/create_list_screen.dart';
import '../../features/lists/presentation/list_details_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../features/messaging/presentation/conversations_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/restaurant_collection_screen.dart';
import '../../features/recommendations/presentation/create_menu_screen.dart';
import '../../features/recommendations/presentation/create_recommendation_screen.dart';
import '../../features/recommendations/presentation/edit_recommendation_loader.dart';
import '../../features/restaurants/presentation/restaurant_details_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/taste_groups/presentation/group_detail_screen.dart';
import '../../features/taste_groups/presentation/taste_groups_screen.dart';
import '../../features/tasters/presentation/taster_profile_screen.dart';
import '../../features/trips/presentation/trip_detail_screen.dart';
import '../../features/trips/presentation/trips_screen.dart';
import 'routes.dart';
import 'shell_scaffold.dart';

/// Routes that require a signed-in user; everything else supports guests.
const _authRequiredPaths = {'/create', '/notifications'};

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier();
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = _hasSession();
      final path = state.uri.path;
      if (!signedIn && _authRequiredPaths.contains(path)) {
        return '/welcome';
      }
      if (signedIn &&
          (path == '/welcome' || path == '/sign-in' || path == '/register')) {
        return '/map';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: Routes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: Routes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        name: Routes.signIn,
        builder: (_, _) => const SignInScreen(),
      ),
      GoRoute(
        path: '/register',
        name: Routes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                name: Routes.map,
                builder: (_, _) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                name: Routes.discover,
                builder: (_, _) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/create',
                name: Routes.create,
                builder: (_, _) => const CreateMenuScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                name: Routes.notifications,
                builder: (_, _) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Detail routes push above the shell.
      GoRoute(
        path: '/restaurant/:id',
        name: Routes.restaurant,
        builder: (_, state) =>
            RestaurantDetailsScreen(restaurantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/taster/:id',
        name: Routes.taster,
        builder: (_, state) =>
            TasterProfileScreen(tasterId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/list/:id',
        name: Routes.list,
        builder: (_, state) =>
            ListDetailsScreen(listId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/create/recommendation',
        name: Routes.createRecommendation,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) => const CreateRecommendationScreen(),
      ),
      // Editing takes an id and loads the recommendation itself, rather than
      // being handed the object, so the route survives a deep link or a cold
      // start.
      GoRoute(
        path: '/recommendation/:id/edit',
        name: Routes.editRecommendation,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, state) => EditRecommendationLoader(
          recommendationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/create/list',
        name: Routes.createList,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) => const CreateListScreen(),
      ),
      GoRoute(
        path: '/search',
        name: Routes.search,
        builder: (_, _) => const SearchScreen(),
      ),
      GoRoute(
        path: '/biteswipe',
        name: Routes.biteswipe,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) => const BiteSwipeScreen(),
      ),
      GoRoute(
        path: '/saved',
        name: Routes.savedRestaurants,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) =>
            const RestaurantCollectionScreen(kind: CollectionKind.saved),
      ),
      GoRoute(
        path: '/visited',
        name: Routes.visitedRestaurants,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) =>
            const RestaurantCollectionScreen(kind: CollectionKind.visited),
      ),
      GoRoute(
        path: '/settings',
        name: Routes.settings,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: Routes.editProfile,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/premium',
        name: Routes.premium,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/trips',
        name: Routes.trips,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) => const TripsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: Routes.trip,
            builder: (_, state) => TripDetailScreen(
              tripId: state.pathParameters['id']!,
              tripName: state.uri.queryParameters['name'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/groups',
        name: Routes.tasteGroups,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) => const TasteGroupsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: Routes.tasteGroup,
            builder: (_, state) =>
                GroupDetailScreen(groupId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/messages',
        name: Routes.messages,
        redirect: (context, state) => _hasSession() ? null : '/welcome',
        builder: (_, _) => const ConversationsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: Routes.chat,
            builder: (_, state) => ChatScreen(
              conversationId: state.pathParameters['id']!,
              peerName: state.uri.queryParameters['peer'],
            ),
          ),
        ],
      ),
    ],
  );
});

bool _hasSession() {
  try {
    return Supabase.instance.client.auth.currentSession != null;
  } catch (_) {
    return false; // Supabase not initialized (missing env)
  }
}

/// Bridges Supabase auth state changes into GoRouter refreshes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen(
        (_) => notifyListeners(),
      );
    } catch (_) {
      // Supabase not initialized: router works without auth.
    }
  }

  StreamSubscription<AuthState>? _sub;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
