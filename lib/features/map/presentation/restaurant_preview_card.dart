import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/widgets/wb_photo.dart';
import '../../../core/widgets/wb_states.dart';
import '../../restaurants/data/restaurant_repository.dart';
import '../../restaurants/domain/restaurant.dart';
import '../../restaurants/presentation/restaurant_actions.dart';
import '../../restaurants/presentation/widgets/taster_avatars.dart';

final _summaryProvider = FutureProvider.autoDispose
    .family<RestaurantSummary, String>((ref, id) {
      return ref.watch(restaurantRepositoryProvider).fetchSummary(id);
    });

/// Draggable bottom card over the map: collapsed, medium, expanded.
class RestaurantPreviewCard extends ConsumerWidget {
  const RestaurantPreviewCard({
    super.key,
    required this.marker,
    required this.onClose,
  });

  final RestaurantMarker marker;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(_summaryProvider(marker.id));
    final saved = (ref.watch(savedIdsProvider).value ?? {}).contains(marker.id);

    return DraggableScrollableSheet(
      key: ValueKey(marker.id),
      initialChildSize: 0.32,
      minChildSize: 0.18,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.18, 0.32, 0.85],
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(WbRadius.sheet),
          ),
          elevation: WbElevation.sheet,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: WbSpacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(WbSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(WbRadius.chip),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: WbPhoto(
                          source: marker.coverPhotoUrl,
                          semanticLabel: 'Photo of ${marker.name}',
                        ),
                      ),
                    ),
                    const SizedBox(width: WbSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marker.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (marker.priceLevel != null)
                                '\$' * marker.priceLevel!,
                              if (marker.distanceM != null)
                                '${(marker.distanceM! / 1000).toStringAsFixed(1)} km',
                              if (marker.score != null)
                                '${marker.score!.toStringAsFixed(1)}/10',
                              '${marker.recCount} recs',
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: WbSpacing.md),
                child: summary.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: WbSpacing.sm),
                    child: WbSkeleton(height: 40),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (s) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.tasters.isNotEmpty) ...[
                        Text(
                          'Recommended by',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: WbSpacing.xs),
                        TasterAvatars(tasters: s.tasters),
                      ],
                      if (s.topQuote != null) ...[
                        const SizedBox(height: WbSpacing.sm),
                        Text(
                          '"${s.topQuote!['body']}"',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          '@${s.topQuote!['username']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(WbSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => ref
                            .read(savedIdsProvider.notifier)
                            .toggle(marker.id),
                        icon: Icon(
                          saved ? Icons.bookmark : Icons.bookmark_outline,
                        ),
                        label: Text(saved ? 'Saved' : 'Save'),
                      ),
                    ),
                    const SizedBox(width: WbSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.pushNamed(
                          Routes.restaurant,
                          pathParameters: {'id': marker.id},
                        ),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
