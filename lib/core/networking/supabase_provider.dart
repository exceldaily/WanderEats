import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/configuration/env.dart';

/// Single access point for the Supabase client. All repositories read the
/// schema-scoped query builder from here; widgets never import this.
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// WanderBites lives in its own schema inside a shared Supabase project.
/// Every table query must go through this, never `client.from()` directly,
/// or it would hit the `public` schema of the shared project.
final wbSchemaProvider = Provider((ref) {
  return ref.watch(supabaseProvider).schema(Env.supabaseSchema);
});

/// Initializes Supabase once at startup. Called from bootstrap, kept here so
/// tests can swap it out.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
    postgrestOptions: PostgrestClientOptions(schema: Env.supabaseSchema),
  );
}
