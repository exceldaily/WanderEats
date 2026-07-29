import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/analytics/analytics_service.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/taster_repository.dart';

/// Who the current user follows, with optimistic toggling.
final followingIdsProvider =
    AsyncNotifierProvider<FollowingIdsController, Set<String>>(
      FollowingIdsController.new,
    );

class FollowingIdsController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final session = ref.watch(sessionProvider);
    if (session == null) return {};
    return ref.read(tasterRepositoryProvider).myFollowingIds(session.user.id);
  }

  Future<void> toggle(String tasterId) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final current = state.value ?? {};
    final following = !current.contains(tasterId);
    state = AsyncData(
      following
          ? {...current, tasterId}
          : current.where((id) => id != tasterId).toSet(),
    );
    try {
      final repo = ref.read(tasterRepositoryProvider);
      if (following) {
        await repo.follow(session.user.id, tasterId);
        await ref.read(analyticsProvider).tasterFollowed(tasterId: tasterId);
      } else {
        await repo.unfollow(session.user.id, tasterId);
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
