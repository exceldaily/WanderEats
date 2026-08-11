import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../../authentication/presentation/auth_providers.dart';

/// One row of admin_user_search: everything support needs at a glance.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.isSuspended,
    required this.isDemo,
    required this.ageConfirmed,
    required this.isAdult,
    required this.entitlements,
  });

  factory AdminUser.fromRow(Map<String, dynamic> row) => AdminUser(
    id: row['id'] as String,
    username: row['username'] as String? ?? '',
    displayName: row['display_name'] as String? ?? '',
    email: row['email'] as String? ?? '',
    isSuspended: row['is_suspended'] == true,
    isDemo: row['is_demo'] == true,
    ageConfirmed: row['age_confirmed'] == true,
    isAdult: row['is_adult'] == true,
    entitlements: ((row['entitlements'] as List?) ?? const [])
        .cast<String>(),
  );

  final String id;
  final String username;
  final String displayName;
  final String email;
  final bool isSuspended;
  final bool isDemo;
  final bool ageConfirmed;
  final bool isAdult;
  final List<String> entitlements;

  bool get isPremium => entitlements.isNotEmpty;
}

class AdminReport {
  const AdminReport({
    required this.id,
    required this.targetType,
    required this.reason,
    this.details,
    required this.status,
    this.reporterUsername,
    this.reportedUsername,
    required this.createdAt,
  });

  factory AdminReport.fromRow(Map<String, dynamic> row) => AdminReport(
    id: row['id'] as String,
    targetType: row['target_type'] as String? ?? '',
    reason: row['reason'] as String? ?? '',
    details: row['details'] as String?,
    status: row['status'] as String? ?? 'open',
    reporterUsername:
        ((row['reporter'] as Map?)?['username']) as String?,
    reportedUsername:
        ((row['reported'] as Map?)?['username']) as String?,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );

  final String id;
  final String targetType;
  final String reason;
  final String? details;
  final String status;
  final String? reporterUsername;
  final String? reportedUsername;
  final DateTime createdAt;
}

/// Support operations. Everything here rides existing admin-aware RLS or the
/// is_admin()-gated search RPC, so a non-admin calling any of it gets a
/// database refusal, not data.
class AdminRepository {
  AdminRepository(this._schema, this._myId);

  final SupabaseQuerySchema _schema;
  final String? _myId;

  static const _allEntitlements = [
    'direct_messaging',
    'create_taste_groups',
    'premium_profile_layouts',
    'advanced_trip_planning',
  ];

  Future<List<AdminUser>> search(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final rows = await _schema.rpc<List<dynamic>>(
        'admin_user_search',
        params: {'p_query': query.trim()},
      );
      return [
        for (final row in rows) AdminUser.fromRow(row as Map<String, dynamic>),
      ];
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> setSuspended(String userId, bool suspended) async {
    try {
      await _schema
          .from('profiles')
          .update({'is_suspended': suspended})
          .eq('id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> grantComp(String userId, {String reason = 'support comp'}) async {
    try {
      await _schema.from('entitlement_overrides').insert([
        for (final e in _allEntitlements)
          {
            'user_id': userId,
            'entitlement': e,
            'granted_by': _myId,
            'reason': reason,
          },
      ]);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> revokeComp(String userId) async {
    try {
      await _schema
          .from('entitlement_overrides')
          .update({'revoked_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', userId)
          .isFilter('revoked_at', null);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> setDateOfBirth(String userId, DateTime dob) async {
    try {
      await _schema.from('profile_private').upsert({
        'user_id': userId,
        'date_of_birth':
            '${dob.year.toString().padLeft(4, '0')}-'
            '${dob.month.toString().padLeft(2, '0')}-'
            '${dob.day.toString().padLeft(2, '0')}',
      }, onConflict: 'user_id');
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<AdminReport>> openReports() async {
    try {
      final rows = await _schema
          .from('content_reports')
          .select(
            'id, target_type, reason, details, status, created_at, '
            'reporter:profiles!reporter_id(username), '
            'reported:profiles!reported_user_id(username)',
          )
          .inFilter('status', ['open', 'reviewing'])
          .order('created_at', ascending: false)
          .limit(50);
      return [for (final row in rows) AdminReport.fromRow(row)];
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> resolveReport(String reportId, String status) async {
    try {
      await _schema
          .from('content_reports')
          .update({
            'status': status,
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
            'reviewed_by': _myId,
          })
          .eq('id', reportId);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(
    ref.watch(wbSchemaProvider),
    ref.watch(sessionProvider)?.user.id,
  ),
);

final adminReportsProvider = FutureProvider.autoDispose<List<AdminReport>>(
  (ref) => ref.watch(adminRepositoryProvider).openReports(),
);
