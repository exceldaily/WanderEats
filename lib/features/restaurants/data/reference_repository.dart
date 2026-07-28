import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../domain/reference_models.dart';

/// Cities, countries and cuisines: small, world-readable reference sets.
class ReferenceRepository {
  ReferenceRepository(this._db);

  final SupabaseQueryBuilder Function(String table) _db;

  Future<List<City>> fetchCities() async {
    try {
      final rows = await _db('cities').select().order('name', ascending: true);
      return rows.map(City.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<Cuisine>> fetchCuisines() async {
    try {
      final rows = await _db('cuisines').select().order('name', ascending: true);
      return rows.map(Cuisine.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }
}

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return ReferenceRepository(ref.watch(wbSchemaProvider).from);
});

final citiesProvider = FutureProvider<List<City>>((ref) {
  return ref.watch(referenceRepositoryProvider).fetchCities();
});

final cuisinesProvider = FutureProvider<List<Cuisine>>((ref) {
  return ref.watch(referenceRepositoryProvider).fetchCuisines();
});
