import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/entitlements.dart';

/// The one place the app asks what the current user has paid for.
///
/// Reads `my_entitlements()`, which derives access from store-verified
/// subscription rows the client cannot write. There is deliberately no method
/// that takes a user id: an app should never be able to ask what somebody else
/// has bought.
class EntitlementService {
  EntitlementService(this._schema);

  final SupabaseQuerySchema _schema;

  Future<Entitlements> current() async {
    try {
      final codes = await _schema.rpc<List<dynamic>>('my_entitlements');
      return Entitlements.fromCodes(codes.cast<String>());
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }
}

final entitlementServiceProvider = Provider<EntitlementService>(
  (ref) => EntitlementService(ref.watch(wbSchemaProvider)),
);

/// The current user's entitlements.
///
/// Watches the session so signing out drops paid access immediately rather
/// than leaving the previous user's entitlements cached in memory. Failing
/// closed on error is deliberate: an unreachable backend must read as "no
/// premium", never as "assume they paid".
final entitlementsProvider = FutureProvider<Entitlements>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return const Entitlements.none();
  try {
    return await ref.watch(entitlementServiceProvider).current();
  } on AppException {
    return const Entitlements.none();
  }
});

/// Synchronous check for widget code.
///
/// Returns false while loading, which keeps a paid feature from flashing into
/// view before the answer arrives. This is a UI affordance only; the server
/// enforces the same rule again on every privileged call, so a wrong answer
/// here cannot grant access.
bool hasEntitlement(WidgetRef ref, PremiumEntitlement entitlement) {
  final e = ref.watch(entitlementsProvider).value;
  return e?.has(entitlement) ?? false;
}

/// Convenience for the "Premium" badge and settings row. Never an access check.
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(entitlementsProvider).value?.isPremium ?? false,
);
