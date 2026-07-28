import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/widgets/wb_states.dart';
import '../../restaurants/data/restaurant_repository.dart';
import '../../restaurants/domain/restaurant.dart';
import '../../restaurants/presentation/restaurant_actions.dart';

enum CollectionKind { saved, visited }

final _collectionProvider = FutureProvider.autoDispose
    .family<List<Restaurant>, CollectionKind>((ref, kind) async {
  final ids = switch (kind) {
    CollectionKind.saved => ref.watch(savedIdsProvider).value ?? {},
    CollectionKind.visited => ref.watch(visitedIdsProvider).value ?? {},
  };
  return ref.watch(restaurantRepositoryProvider).fetchByIds(ids.toList());
});

/// Saved and Visited share one collection screen.
class RestaurantCollectionScreen extends ConsumerWidget {
  const RestaurantCollectionScreen({super.key, required this.kind});

  final CollectionKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(_collectionProvider(kind));
    final title = kind == CollectionKind.saved ? 'Saved' : 'Visited';
    return Scaffold(
      appBar: AppBar(title: Text('$title restaurants')),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WbErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_collectionProvider(kind))),
        data: (restaurants) => restaurants.isEmpty
            ? WbEmptyState(
                icon: kind == CollectionKind.saved
                    ? Icons.bookmark_outline
                    : Icons.where_to_vote_outlined,
                title: 'Nothing here yet',
                message: kind == CollectionKind.saved
                    ? 'Save places from the map and they collect here.'
                    : 'Mark places visited to grow your food map.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(WbSpacing.md),
                itemCount: restaurants.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: WbSpacing.sm),
                itemBuilder: (context, i) {
                  final r = restaurants[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.restaurant),
                      title: Text(r.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text([
                        if (r.priceLevel != null) '\$' * r.priceLevel!,
                        '${r.recCount} recs',
                        if (r.score != null)
                          '${r.score!.toStringAsFixed(1)}/10',
                      ].join(' · ')),
                      trailing: IconButton(
                        tooltip: kind == CollectionKind.saved
                            ? 'Remove from saved'
                            : 'Remove from visited',
                        icon: const Icon(Icons.close),
                        onPressed: () => switch (kind) {
                          CollectionKind.saved => ref
                              .read(savedIdsProvider.notifier)
                              .toggle(r.id),
                          CollectionKind.visited => ref
                              .read(visitedIdsProvider.notifier)
                              .toggle(r.id),
                        },
                      ),
                      onTap: () => context.pushNamed(Routes.restaurant,
                          pathParameters: {'id': r.id}),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
