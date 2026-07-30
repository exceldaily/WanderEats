import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/wb_states.dart';
import '../data/recommendation_repository.dart';
import '../domain/recommendation.dart';
import 'create_recommendation_screen.dart';

/// Loads the recommendation behind `/recommendation/:id/edit` and hands it to
/// the compose form in edit mode.
///
/// The route carries only an id so it survives a cold start, which means the
/// object has to be fetched here rather than passed in. RLS restricts updates
/// to the owner, so a stranger reaching this screen can read the form but the
/// save is refused by the database, not by a check in the UI.
final recommendationByIdProvider = FutureProvider.autoDispose
    .family<Recommendation, String>((ref, id) {
      return ref.watch(recommendationRepositoryProvider).byId(id);
    });

class EditRecommendationLoader extends ConsumerWidget {
  const EditRecommendationLoader({super.key, required this.recommendationId});

  final String recommendationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(recommendationByIdProvider(recommendationId));

    return rec.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit recommendation')),
        body: WbErrorState(
          message: 'That recommendation could not be loaded.',
          onRetry: () => ref.invalidate(
            recommendationByIdProvider(recommendationId),
          ),
        ),
      ),
      data: (r) => CreateRecommendationScreen(existing: r),
    );
  }
}
