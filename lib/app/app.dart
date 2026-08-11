import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'configuration/env.dart';
import 'router/app_router.dart';
import 'router/routes.dart';
import 'theme/wb_theme.dart';

class WanderBitesApp extends ConsumerStatefulWidget {
  const WanderBitesApp({super.key});

  @override
  ConsumerState<WanderBitesApp> createState() => _WanderBitesAppState();
}

class _WanderBitesAppState extends ConsumerState<WanderBitesApp> {
  StreamSubscription<RemoteMessage>? _pushTapSub;

  @override
  void initState() {
    super.initState();
    unawaited(_wirePushTaps());
  }

  /// Routes notification taps into the app. Every push corresponds to a row
  /// in the in-app notification feed, so the feed is the always-valid landing
  /// spot; per-item deep linking continues from the feed's own tap routing.
  /// Without this, tapping a push just opened the app at the map.
  Future<void> _wirePushTaps() async {
    if (Firebase.apps.isEmpty) return; // dev clones run the no-op push stack
    _pushTapSub = FirebaseMessaging.onMessageOpenedApp.listen(_openFromTap);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _openFromTap(initial);
  }

  void _openFromTap(RemoteMessage message) {
    if (!mounted || !Env.isConfigured) return;
    ref.read(appRouterProvider).goNamed(Routes.notifications);
  }

  @override
  void dispose() {
    unawaited(_pushTapSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      // Thai is the flagship first language: WanderBites' own seed data and
      // early content are Thailand-based, so it is where translation pays
      // off before any other locale does. More locales are additive from
      // here - add the delegate list is fixed, only supportedLocales grows.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
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
