import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/analytics/analytics_service.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/restaurant_repository.dart';

/// Saved + visited restaurant ids for the current user, with optimistic
/// toggles that roll back on failure. Widgets watch these to paint states.
final savedIdsProvider =
    AsyncNotifierProvider<SavedIdsController, Set<String>>(SavedIdsController.new);

class SavedIdsController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final session = ref.watch(sessionProvider);
    if (session == null) return {};
    return ref
        .read(restaurantRepositoryProvider)
        .fetchMySavedIds(session.user.id);
  }

  Future<void> toggle(String restaurantId) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final current = state.value ?? {};
    final saving = !current.contains(restaurantId);
    // Optimistic flip.
    state = AsyncData(saving
        ? {...current, restaurantId}
        : current.where((id) => id != restaurantId).toSet());
    try {
      final repo = ref.read(restaurantRepositoryProvider);
      if (saving) {
        await repo.save(session.user.id, restaurantId);
        await ref
            .read(analyticsProvider)
            .restaurantSaved(restaurantId: restaurantId);
      } else {
        await repo.unsave(session.user.id, restaurantId);
      }
    } catch (_) {
      state = AsyncData(current); // roll back
      rethrow;
    }
  }
}

final visitedIdsProvider =
    AsyncNotifierProvider<VisitedIdsController, Set<String>>(
        VisitedIdsController.new);

class VisitedIdsController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final session = ref.watch(sessionProvider);
    if (session == null) return {};
    return ref
        .read(restaurantRepositoryProvider)
        .fetchMyVisitedIds(session.user.id);
  }

  Future<void> toggle(String restaurantId) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final current = state.value ?? {};
    final visiting = !current.contains(restaurantId);
    state = AsyncData(visiting
        ? {...current, restaurantId}
        : current.where((id) => id != restaurantId).toSet());
    try {
      final repo = ref.read(restaurantRepositoryProvider);
      if (visiting) {
        await repo.markVisited(session.user.id, restaurantId);
        await ref
            .read(analyticsProvider)
            .restaurantVisited(restaurantId: restaurantId);
      } else {
        await repo.unmarkVisited(session.user.id, restaurantId);
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
