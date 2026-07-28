import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import 'auth_providers.dart';

/// Session restoration gate. Supabase restores the persisted session during
/// initialize; this screen resolves the profile and forwards:
///   signed out            -> map (guest browsing)
///   signed in, no profile -> onboarding
///   signed in, profile    -> map
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(myProfileProvider, (_, next) {
      if (!next.isLoading) {
        final signedIn = ref.read(isSignedInProvider);
        final hasProfile = next.value != null;
        if (signedIn && !hasProfile) {
          context.goNamed(Routes.onboarding);
        } else {
          context.goNamed(Routes.map);
        }
      }
    });

    // Already resolved (e.g. hot reload): forward immediately.
    final profile = ref.watch(myProfileProvider);
    if (!profile.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final signedIn = ref.read(isSignedInProvider);
        if (signedIn && profile.value == null) {
          context.goNamed(Routes.onboarding);
        } else {
          context.goNamed(Routes.map);
        }
      });
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WanderBites',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
