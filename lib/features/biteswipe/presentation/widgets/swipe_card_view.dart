import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/wb_tokens.dart';
import '../../../../core/widgets/wb_photo.dart';
import '../../../restaurants/domain/restaurant.dart';
import '../../../restaurants/presentation/restaurant_summary_provider.dart';
import '../../../restaurants/presentation/widgets/taster_avatars.dart';
import '../../domain/swipe_card.dart';

/// One restaurant card: photo-led, the three questions in order —
/// what is it, why is it worth it, who says so.
class SwipeCardView extends ConsumerWidget {
  const SwipeCardView({
    super.key,
    required this.card,
    required this.onTap,
    required this.onTasters,
  });

  final SwipeCard card;
  final VoidCallback onTap;
  final VoidCallback onTasters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(restaurantSummaryProvider(card.id));

    return Semantics(
      label:
          '${card.name}. ${card.subtitle}. ${card.reason}. '
          'Double tap to open details.',
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(WbRadius.card),
        elevation: WbElevation.raisedCard,
        color: theme.colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WbPhoto(
                      source: card.coverPhotoUrl,
                      semanticLabel: 'Photo of ${card.name}',
                    ),
                    // Reason ribbon: why this card exists, always visible.
                    Positioned(
                      top: WbSpacing.sm,
                      left: WbSpacing.sm,
                      child: Material(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(WbRadius.chip),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WbSpacing.sm,
                            vertical: 4,
                          ),
                          child: Text(
                            card.reason,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(WbSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (card.subtitle.isNotEmpty)
                      Text(
                        card.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: WbSpacing.sm),
                    summary.when(
                      loading: () => const SizedBox(height: 40),
                      error: (_, _) => const SizedBox(height: 40),
                      data: (s) => _TrustRow(
                        summary: s,
                        recCount: card.recCount,
                        onTasters: onTasters,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({
    required this.summary,
    required this.recCount,
    required this.onTasters,
  });

  final RestaurantSummary summary;
  final int recCount;
  final VoidCallback onTasters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quote = summary.topQuote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (quote != null) ...[
          Text(
            '"${quote['body']}"',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: WbSpacing.xs),
        ],
        if (summary.tasters.isNotEmpty)
          Semantics(
            button: true,
            label:
                'Recommended by $recCount '
                '${recCount == 1 ? 'Taster' : 'Tasters'}. '
                'Tap to preview them.',
            child: InkWell(
              onTap: onTasters,
              borderRadius: BorderRadius.circular(WbRadius.chip),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    TasterAvatars(
                      tasters: summary.tasters.take(3).toList(),
                      size: 28,
                    ),
                    const SizedBox(width: WbSpacing.sm),
                    Expanded(
                      child: Text(
                        recCount == 1
                            ? 'Recommended by 1 Taster'
                            : 'Recommended by $recCount Tasters',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 28,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No Taster recommendations yet — be the first',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
