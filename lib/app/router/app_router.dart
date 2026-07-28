import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/discovery/presentation/discover_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/recommendations/presentation/create_menu_screen.dart';
import 'routes.dart';
import 'shell_scaffold.dart';

/// Router lives in a provider so auth-driven redirects can be tested and the
/// tree can rebuild on session changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier();
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/map',
    refreshListenable: refresh,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/map',
              name: Routes.map,
              builder: (_, _) => const MapScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/discover',
              name: Routes.discover,
              builder: (_, _) => const DiscoverScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/create',
              name: Routes.create,
              builder: (_, _) => const CreateMenuScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/notifications',
              name: Routes.notifications,
              builder: (_, _) => const NotificationsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              name: Routes.profile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
      // Detail + auth routes are registered by their milestones and pushed
      // above the shell. Placeholder-free by Definition of Done.
    ],
  );
});

/// Bridges Supabase auth state changes into GoRouter refreshes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange
          .listen((_) => notifyListeners());
    } catch (_) {
      // Supabase not initialized (missing env): router works without auth.
    }
  }

  StreamSubscription<AuthState>? _sub;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
