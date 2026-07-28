import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/configuration/env.dart';
import 'core/networking/supabase_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isConfigured) {
    await initSupabase();
  }
  // When env is missing the app still boots into a configuration notice
  // instead of crashing (see WanderBitesApp), so a fresh checkout always runs.

  runApp(const ProviderScope(child: WanderBitesApp()));
}
