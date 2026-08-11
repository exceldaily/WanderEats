import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/auth_providers.dart';
import '../data/recommendation_repository.dart';

/// Per-card fallback: one query for one recommendation. Screens that render a
/// list of cards should watch [recommendationFeedbackBatchProvider] instead
/// and hand each card its entry, so a 30-card feed costs 1 query, not 30.
final recommendationFeedbackProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, recId) {
      final myId = ref.watch(sessionProvider)?.user.id;
      return ref
          .watch(recommendationRepositoryProvider)
          .feedbackFor(recId, myId);
    });

/// Feedback for a whole page of cards in one query, keyed by recommendation
/// id. The family argument is the stable string from [feedbackBatchKey] -
/// families need value-equal keys, and a List is compared by identity.
final recommendationFeedbackBatchProvider = FutureProvider.autoDispose
    .family<Map<String, Map<String, dynamic>>, String>((ref, joinedIds) {
      final myId = ref.watch(sessionProvider)?.user.id;
      final ids = joinedIds.isEmpty ? const <String>[] : joinedIds.split(',');
      return ref
          .watch(recommendationRepositoryProvider)
          .feedbackForMany(ids, myId);
    });

/// Builds the [recommendationFeedbackBatchProvider] key: sorted so the same
/// set of ids always maps to the same cached batch.
String feedbackBatchKey(Iterable<String> recommendationIds) =>
    (recommendationIds.toList()..sort()).join(',');
