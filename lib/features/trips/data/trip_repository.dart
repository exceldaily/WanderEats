import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/trip_models.dart';

/// The server refused a trip action; `code` is the `trip_denied:` suffix.
class TripException implements Exception {
  TripException(this.code, this.message);

  final String code;
  final String message;

  bool get premiumRequired => code == 'premium_required';

  @override
  String toString() => 'TripException: $message';
}

/// Trips are owner-only: creation is a gated RPC, everything else is plain
/// RLS-guarded table access.
class TripRepository {
  TripRepository(this._schema);

  final SupabaseQuerySchema _schema;

  Future<List<FoodTrip>> myTrips() async {
    try {
      final rows = await _schema
          .from('food_trips')
          .select('id, name, destination, starts_on, notes, food_trip_stops(id)')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return [for (final row in rows) FoodTrip.fromRow(row)];
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<String> create({
    required String name,
    String? destination,
    DateTime? startsOn,
    String? notes,
  }) async {
    try {
      final id = await _schema.rpc<dynamic>(
        'create_food_trip',
        params: {
          'p_name': name,
          'p_destination': destination,
          'p_starts_on': startsOn == null
              ? null
              : '${startsOn.year.toString().padLeft(4, '0')}-'
                    '${startsOn.month.toString().padLeft(2, '0')}-'
                    '${startsOn.day.toString().padLeft(2, '0')}',
          'p_notes': notes,
        },
      );
      return id as String;
    } on PostgrestException catch (e) {
      final match = RegExp('trip_denied:([a-z_]+)').firstMatch(e.message);
      if (match == null) throw ServerException(cause: e);
      final code = match.group(1)!;
      throw TripException(code, switch (code) {
        'premium_required' =>
          'Food-trip planning is a WanderBites Premium feature.',
        'limit_reached' => 'You have reached the limit of 20 trips.',
        'not_signed_in' => 'Sign in to plan trips.',
        _ => 'This trip is not available.',
      });
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _schema
          .from('food_trips')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', tripId);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<TripStop>> stops(String tripId) async {
    try {
      final rows = await _schema
          .from('food_trip_stops')
          .select('id, note, position, restaurants(id, name, cover_photo_url)')
          .eq('trip_id', tripId)
          .order('position', ascending: true)
          .order('created_at', ascending: true);
      return [for (final row in rows) TripStop.fromRow(row)];
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> addStop(
    String tripId,
    String restaurantId, {
    String? note,
    required int position,
  }) async {
    try {
      await _schema.from('food_trip_stops').upsert({
        'trip_id': tripId,
        'restaurant_id': restaurantId,
        'position': position,
        if (note != null && note.isNotEmpty) 'note': note,
      }, onConflict: 'trip_id,restaurant_id');
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> removeStop(String stopId) async {
    try {
      await _schema.from('food_trip_stops').delete().eq('id', stopId);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> reorder(String tripId, List<String> stopIds) async {
    try {
      await _schema.rpc<dynamic>(
        'reorder_trip_stops',
        params: {'p_trip': tripId, 'p_stop_ids': stopIds},
      );
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  /// Same lightweight restaurant search the Taste Groups pick sheet uses.
  Future<List<Map<String, dynamic>>> searchRestaurants(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final rows = await _schema
          .from('restaurants')
          .select('id, name, cover_photo_url')
          .ilike('name', '%${query.trim()}%')
          .isFilter('deleted_at', null)
          .limit(20);
      return rows;
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }
}

final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => TripRepository(ref.watch(wbSchemaProvider)),
);

final myTripsProvider = FutureProvider.autoDispose<List<FoodTrip>>((ref) async {
  if (ref.watch(sessionProvider) == null) return const [];
  return ref.watch(tripRepositoryProvider).myTrips();
});

final tripStopsProvider = FutureProvider.autoDispose
    .family<List<TripStop>, String>(
      (ref, tripId) => ref.watch(tripRepositoryProvider).stops(tripId),
    );
