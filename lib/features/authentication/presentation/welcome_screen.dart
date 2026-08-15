import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

/// First screen for signed-out users: brand moment + auth choices.
/// Guests can skip straight into browsing.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WbSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Temporary text logo until final brand asset lands.
              Text(
                'WanderBites',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: WbSpacing.sm),
              Text(
                l10n.welcomeTagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Sign in with Apple sits above Google and matches its
              // prominence: guideline 4.8 requires an equivalent option
              // wherever a third-party login is offered. iOS only, because it
              // is the platform where the system sheet exists and where the
              // requirement applies.
              if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(authRepositoryProvider).signInWithApple();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.apple, size: 24),
                  label: const Text('Continue with Apple'),
                ),
                const SizedBox(height: WbSpacing.sm),
              ],
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(authRepositoryProvider).signInWithGoogle();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: Text(l10n.continueWithGoogle),
              ),
              const SizedBox(height: WbSpacing.sm),
              FilledButton.tonal(
                onPressed: () => context.goNamed(Routes.register),
                child: Text(l10n.signUpWithEmail),
              ),
              const SizedBox(height: WbSpacing.sm),
              OutlinedButton(
                onPressed: () => context.goNamed(Routes.signIn),
                child: Text(l10n.alreadyHaveAccount),
              ),
              const SizedBox(height: WbSpacing.md),
              TextButton(
                onPressed: () => context.goNamed(Routes.map),
                child: Text(l10n.justBrowsing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
