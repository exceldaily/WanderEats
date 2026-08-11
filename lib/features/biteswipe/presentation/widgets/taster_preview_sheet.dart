import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/wb_tokens.dart';
import '../../../../core/services/analytics/analytics_service.dart';
import '../../../restaurants/domain/restaurant.dart';
import '../../../restaurants/presentation/restaurant_summary_provider.dart';
import '../../../tasters/presentation/follow_providers.dart';

/// Compact draggable sheet over the deck: who vouches for this place, with a
/// follow button that works in place. Deliberately not a full profile — the
/// deck keeps moving; the full page is one tap further.
Future<void> showTasterPreviewSheet(
  BuildContext context, {
  required String restaurantId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      builder: (context, scrollController) => _TasterPreviewBody(
        restaurantId: restaurantId,
        scrollController: scrollController,
      ),
    ),
  );
}

class _TasterPreviewBody extends ConsumerWidget {
  const _TasterPreviewBody({
    required this.restaurantId,
    required this.scrollController,
  });

  final String restaurantId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(restaurantSummaryProvider(restaurantId));
    final following = ref.watch(followingIdsProvider).value ?? {};

    return summary.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(WbSpacing.lg),
        child: Text(
          'Could not load Tasters right now.',
          style: theme.textTheme.bodyMedium,
        ),
      ),
      data: (s) {
        if (s.tasters.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(WbSpacing.lg),
            child: Text(
              'No Taster recommendations here yet.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        final quote = s.topQuote;
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(WbSpacing.md),
          children: [
            Text(
              'Recommended by',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: WbSpacing.sm),
            for (final t in s.tasters.take(3))
              _TasterTile(
                taster: t,
                followed: following.contains(t.id),
                quote: quote != null && quote['username'] == t.username
                    ? quote['body'] as String?
                    : null,
              ),
          ],
        );
      },
    );
  }
}

class _TasterTile extends ConsumerWidget {
  const _TasterTile({required this.taster, required this.followed, this.quote});

  final RecommendingTaster taster;
  final bool followed;
  final String? quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: WbSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(WbSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundImage: taster.avatarUrl != null
                      ? NetworkImage(taster.avatarUrl!)
                      : null,
                  child: Text(taster.displayName.characters.first),
                ),
                const SizedBox(width: WbSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              taster.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (taster.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: theme.colorScheme.primary,
                              semanticLabel: 'Verified Taster',
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '@${taster.username}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Follow works right here; the deck stays put behind the sheet.
                FilledButton.tonal(
                  onPressed: () {
                    unawaited(
                      ref.read(followingIdsProvider.notifier).toggle(taster.id),
                    );
                    if (!followed) {
                      unawaited(
                        ref
                            .read(analyticsProvider)
                            .deckTasterFollowed(tasterId: taster.id),
                      );
                    }
                  },
                  child: Text(followed ? 'Following' : 'Follow'),
                ),
              ],
            ),
            if (quote != null) ...[
              const SizedBox(height: WbSpacing.xs),
              Text(
                '"$quote"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.pushNamed(
                  Routes.taster,
                  pathParameters: {'id': taster.id},
                ),
                child: const Text('Open profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
