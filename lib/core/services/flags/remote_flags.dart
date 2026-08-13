import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../networking/supabase_provider.dart';

/// Server-controlled feature flags read from `app_settings` at startup.
///
/// `require_account_to_browse` closes guest browsing: when true, signed-out
/// users are routed to the welcome screen instead of the map. Flipping the
/// row in the database changes behaviour on next launch, no release needed.
///
/// Fails open: if the row is missing or the network is down, browsing stays
/// available so a config hiccup can never lock everyone out at launch.
final requireAccountToBrowseProvider = FutureProvider<bool>((ref) async {
  try {
    final row = await ref
        .watch(wbSchemaProvider)
        .from('app_settings')
        .select('value')
        .eq('key', 'require_account_to_browse')
        .maybeSingle();
    return row?['value'] == true;
  } catch (_) {
    return false;
  }
});
