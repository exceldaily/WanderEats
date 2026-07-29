import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'configuration/env.dart';
import 'router/app_router.dart';
import 'theme/wb_theme.dart';

class WanderBitesApp extends ConsumerWidget {
  const WanderBitesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.isConfigured) {
      return MaterialApp(
        title: 'WanderBites',
        theme: WbTheme.light(),
        home: const _MissingConfigScreen(),
      );
    }

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'WanderBites',
      debugShowCheckedModeBanner: false,
      theme: WbTheme.light(),
      darkTheme: WbTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

/// Shown when the app was built without --dart-define-from-file. Keeps a
/// fresh checkout bootable instead of crashing on a missing URL.
class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_suggest_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Configuration missing',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Build with:\nflutter run --dart-define-from-file=dart_defines/dev.json\n\nSee SETUP.md for details.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
