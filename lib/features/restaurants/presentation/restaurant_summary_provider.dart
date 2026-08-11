import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/restaurant_repository.dart';
import '../domain/restaurant.dart';

/// Shared per-restaurant summary cache. The map card, details screen and
/// BiteSwipe widgets previously each declared a private copy of this family,
/// so navigating between them refetched the same summary up to four times.
final restaurantSummaryProvider = FutureProvider.autoDispose
    .family<RestaurantSummary, String>(
      (ref, id) => ref.watch(restaurantRepositoryProvider).fetchSummary(id),
    );
