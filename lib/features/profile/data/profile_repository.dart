import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  /// Schema-scoped query builder (wanderbites), never the raw client.
  final SupabaseQueryBuilder Function(String table) _db;

  Future<Profile?> fetchProfile(String userId) async {
    try {
      final row = await _db('profiles')
          .select()
          .eq('id', userId)
          .isFilter('deleted_at', null)
          .maybeSingle();
      return row == null ? null : Profile.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<Profile?> fetchByUsername(String username) async {
    try {
      final row = await _db('profiles')
          .select()
          .eq('username', username)
          .isFilter('deleted_at', null)
          .maybeSingle();
      return row == null ? null : Profile.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    final row = await _db('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return row == null;
  }

  /// Creates the WanderBites profile during onboarding. RLS only allows
  /// inserting your own row.
  Future<Profile> createProfile({
    required String userId,
    required String username,
    required String displayName,
    String? bio,
    String? homeCityId,
    List<String> favoriteCuisines = const [],
    String? avatarUrl,
  }) async {
    try {
      final row = await _db('profiles').insert({
        'id': userId,
        'username': username,
        'display_name': displayName,
        if (bio != null && bio.isNotEmpty) 'bio': bio,
        'home_city_id': ?homeCityId,
        'favorite_cuisines': favoriteCuisines,
        'avatar_url': ?avatarUrl,
        'onboarding_completed': true,
      }).select().single();
      // Default settings row (owner-only by RLS).
      await _db('user_settings').upsert({'user_id': userId});
      return Profile.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationException('That username is already taken.');
      }
      throw ServerException(cause: e);
    }
  }

  Future<Profile> updateProfile(String userId, Map<String, dynamic> patch) async {
    try {
      final row = await _db('profiles')
          .update(patch)
          .eq('id', userId)
          .select()
          .single();
      return Profile.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final schema = ref.watch(wbSchemaProvider);
  return ProfileRepository(schema.from);
});
