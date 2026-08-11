import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../domain/safety.dart';

/// Blocking and reporting.
///
/// Every method here goes through a `SECURITY DEFINER` function rather than
/// writing tables directly. That is deliberate: blocking is a single intent
/// with several consequences (sever follows both ways, withdraw collaboration
/// invitations, drop notifications), and doing that from the client would mean
/// several round trips, any one of which could fail and leave a half-applied
/// block. Reporting goes the same way so the client cannot choose its own
/// urgency.
class SafetyRepository {
  SafetyRepository(this._schema);

  final SupabaseQuerySchema _schema;

  /// Blocks [userId]. Safe to call when already blocked; the reason is updated.
  Future<void> block(String userId, {BlockReason? reason}) async {
    try {
      await _schema.rpc<void>(
        'block_user',
        params: {'target': userId, 'reason_category': reason?.wire},
      );
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> unblock(String userId) async {
    try {
      await _schema.rpc<void>('unblock_user', params: {'target': userId});
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  /// The signed-in user's own block list. Never exposes anything about who has
  /// blocked *them*, which is not something the app should be able to answer.
  Future<List<BlockedAccount>> blockedAccounts() async {
    try {
      final rows = await _schema.rpc<List<dynamic>>('blocked_accounts');
      return rows
          .cast<Map<String, dynamic>>()
          .map(BlockedAccount.fromRow)
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  /// Whether an interaction between the current user and [userId] is blocked in
  /// either direction. Used to decide what a profile screen offers, never as
  /// the thing that actually enforces the block.
  Future<bool> isBlocked(String userId) async {
    try {
      // Point lookup; the old version downloaded the whole block list and
      // only checked one direction.
      final blocked = await _schema.rpc<bool>(
        'is_blocked',
        params: {'target': userId},
      );
      return blocked;
    } on PostgrestException {
      // A failed lookup should not make the profile unusable. The server
      // enforces the block regardless of what this returns.
      return false;
    }
  }

  /// Files a report. Returns the report id.
  ///
  /// Priority is assigned server-side from the reason, so a caller cannot mark
  /// its own report urgent and safety categories escalate automatically.
  Future<String> report({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) async {
    try {
      final id = await _schema.rpc<String>(
        'report_content',
        params: {
          'p_target_type': target.wire,
          'p_target_id': targetId,
          'p_reason': reason.wire,
          'p_details': details,
        },
      );
      return id;
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }
}

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepository(ref.watch(wbSchemaProvider)),
);

/// The signed-in user's block list, for the settings screen.
final blockedAccountsProvider = FutureProvider.autoDispose<List<BlockedAccount>>(
  (ref) => ref.watch(safetyRepositoryProvider).blockedAccounts(),
);

/// Whether the current user has blocked [userId]. Drives whether a profile
/// offers "Block" or "Unblock"; it is not what stops the interaction.
final isBlockedProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, userId) => ref.watch(safetyRepositoryProvider).isBlocked(userId),
);
