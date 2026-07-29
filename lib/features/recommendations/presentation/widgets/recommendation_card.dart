import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/wb_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/analytics/analytics_service.dart';
import '../../../authentication/presentation/auth_providers.dart';
import '../../data/recommendation_repository.dart';
import '../../domain/recommendation.dart';

final _feedbackProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, recId) {
      final myId = ref.watch(sessionProvider)?.user.id;
      return ref
          .watch(recommendationRepositoryProvider)
          .feedbackFor(recId, myId);
    });

/// A single recommendation: author, quote, what to order, photos, and the
/// "was this accurate?" feedback flow for people who visited because of it.
class RecommendationCard extends ConsumerWidget {
  const RecommendationCard({super.key, required this.recommendation});

  final Recommendation recommendation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final author = recommendation.author;
    final myId = ref.watch(sessionProvider)?.user.id;
    final isMine = myId == recommendation.userId;
    final feedback = ref.watch(_feedbackProvider(recommendation.id)).value;
    final counts = (feedback?['counts'] as Map<String, dynamic>?) ?? {};
    final mine = feedback?['mine'] as String?;
    final positive =
        ((counts['exact'] as int?) ?? 0) + ((counts['great'] as int?) ?? 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(WbSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.pushNamed(
                Routes.taster,
                pathParameters: {'id': recommendation.userId},
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: author?['avatar_url'] == null
                        ? null
                        : CachedNetworkImageProvider(
                            author!['avatar_url'] as String,
                          ),
                    child: author?['avatar_url'] == null
                        ? Text(
                            ((author?['display_name'] as String?) ?? '?')
                                .characters
                                .first,
                          )
                        : null,
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
                                (author?['display_name'] as String?) ??
                                    'Taster',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (author?['is_verified'] == true)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: WbColors.voyageLight,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '@${author?['username'] ?? ''} · ${DateFormat.yMMMd().format(recommendation.createdAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (positive > 0)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                      ),
                      label: Text(
                        '$positive found this accurate',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: WbSpacing.sm),
            Text(recommendation.body, style: theme.textTheme.bodyMedium),
            if (recommendation.whatToOrder != null) ...[
              const SizedBox(height: WbSpacing.sm),
              Container(
                padding: const EdgeInsets.all(WbSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(WbRadius.chip),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.restaurant_menu, size: 16),
                    const SizedBox(width: WbSpacing.sm),
                    Expanded(
                      child: Text(
                        'Order: ${recommendation.whatToOrder}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (recommendation.photos.isNotEmpty) ...[
              const SizedBox(height: WbSpacing.sm),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendation.photos.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: WbSpacing.sm),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(WbRadius.chip),
                    child: CachedNetworkImage(
                      imageUrl:
                          recommendation.photos[i]['storage_path'] as String,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
            if (!isMine && myId != null) ...[
              const SizedBox(height: WbSpacing.sm),
              mine != null
                  ? Text(
                      'You rated this: ${RecFeedbackRating.values.firstWhere((r) => r.value == mine).label}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _rate(context, ref),
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: const Text('Visited because of this? Rate it'),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _rate(BuildContext context, WidgetRef ref) async {
    final rating = await showModalBottomSheet<RecFeedbackRating>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(WbSpacing.md),
              child: Text(
                'How was the recommendation?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final r in RecFeedbackRating.values)
              ListTile(
                title: Text(r.label),
                leading: Icon(switch (r) {
                  RecFeedbackRating.exact => Icons.verified_outlined,
                  RecFeedbackRating.great => Icons.thumb_up_outlined,
                  RecFeedbackRating.somewhat => Icons.thumbs_up_down_outlined,
                  RecFeedbackRating.mismatch => Icons.thumb_down_outlined,
                }),
                onTap: () => Navigator.pop(context, r),
              ),
          ],
        ),
      ),
    );
    if (rating == null) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    try {
      await ref
          .read(recommendationRepositoryProvider)
          .submitFeedback(
            userId: session.user.id,
            recommendationId: recommendation.id,
            rating: rating,
          );
      unawaited(
        ref
            .read(analyticsProvider)
            .recommendationFeedbackSubmitted(
              recommendationId: recommendation.id,
            ),
      );
      ref.invalidate(_feedbackProvider(recommendation.id));
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
