import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/configuration/env.dart';
import 'core/networking/supabase_provider.dart';
import 'core/services/analytics/analytics_service.dart';
import 'core/services/analytics/firebase_analytics_service.dart';
import 'core/services/push/firebase_push_service.dart';
import 'core/services/push/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isConfigured) {
    await initSupabase();
  }
  // When env is missing the app still boots into a configuration notice
  // instead of crashing (see WanderBitesApp), so a fresh checkout always runs.

  // Reads android/app/google-services.json natively; absent on a fresh
  // clone without that gitignored file, in which case we fall back to the
  // debug-log analytics and no-op push services already wired as defaults.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[firebase] not configured, using dev fallbacks: $e');
    }
  }

  runApp(ProviderScope(
    overrides: [
      if (firebaseReady) ...[
        analyticsProvider.overrideWithValue(
            FirebaseAnalyticsServiceImpl(FirebaseAnalytics.instance)),
        pushServiceProvider.overrideWith(
            (ref) => FirebasePushService(ref.watch(wbSchemaProvider))),
      ],
    ],
    child: const WanderBitesApp(),
  ));
}
