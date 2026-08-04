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

  Future<AgeStatus> ageStatus() async {
    try {
      final json = await _schema.rpc<Map<String, dynamic>>('my_age_status');
      return AgeStatus.fromJson(json);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  /// Records the date of birth, once. The server refuses owner-side changes
  /// afterwards, which is why there is no corresponding update method.
  Future<void> confirmDateOfBirth(String userId, DateTime dateOfBirth) async {
    try {
      await _schema.from('profile_private').insert({
        'user_id': userId,
        'date_of_birth':
            '${dateOfBirth.year.toString().padLeft(4, '0')}-'
            '${dateOfBirth.month.toString().padLeft(2, '0')}-'
            '${dateOfBirth.day.toString().padLeft(2, '0')}',
      });
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

/// The current user's age status. Fails closed the same way entitlements do:
/// an unreachable backend reads as "unconfirmed", never as "adult".
final ageStatusProvider = FutureProvider<AgeStatus>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return const AgeStatus.unknown();
  try {
    return await ref.watch(entitlementServiceProvider).ageStatus();
  } on AppException {
    return const AgeStatus.unknown();
  }
});

/// Why [entitlement] is unavailable right now, or null when it is usable.
///
/// This is THE gate every age-restricted or premium surface must consult
/// before showing an upgrade path: when the result's `canBeSolvedByUpgrading`
/// is false, routing to the paywall is a bug, not a sales opportunity. The
/// server re-checks everything on each privileged call, so a stale answer here
/// can only under-promise, never over-grant.
EntitlementDenial? denialFor(WidgetRef ref, PremiumEntitlement entitlement) {
  return computeDenial(
    signedIn: ref.watch(isSignedInProvider),
    age: ref.watch(ageStatusProvider).value ?? const AgeStatus.unknown(),
    entitlements: ref.watch(entitlementsProvider).value ?? const Entitlements.none(),
    entitlement: entitlement,
  );
}
