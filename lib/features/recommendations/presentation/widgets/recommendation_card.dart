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
import '../../../../core/widgets/wb_photo.dart';
import '../../../authentication/presentation/auth_providers.dart';
import '../../../profile/presentation/widgets/profile_header.dart';
import '../../../restaurants/presentation/restaurant_actions.dart';
import '../../data/recommendation_repository.dart';
import '../../domain/recommendation.dart';

final _feedbackProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, recId) {
      final myId = ref.watch(sessionProvider)?.user.id;
      return ref
          .watch(recommendationRepositoryProvider)
          .feedbackFor(recId, myId);
    });

/// A recommendation, restaurant-first: the place leads (photo, name, where,
/// price), the Taster's words follow, and the reviewer metadata sits in a
/// quiet footer. Keeps the accuracy-feedback flow for visitors.
class RecommendationCard extends ConsumerWidget {
  const RecommendationCard({super.key, required this.recommendation});

  final Recommendation recommendation;

  void _openRestaurant(BuildContext context) => context.pushNamed(
    Routes.restaurant,
    pathParameters: {'id': recommendation.restaurantId},
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final author = recommendation.author;
    final restaurant = recommendation.restaurant;
    final myId = ref.watch(sessionProvider)?.user.id;
    final isMine = myId == recommendation.userId;
    final feedback = ref.watch(_feedbackProvider(recommendation.id)).value;
    final counts = (feedback?['counts'] as Map<String, dynamic>?) ?? {};
    final mine = feedback?['mine'] as String?;
    final positive =
        ((counts['exact'] as int?) ?? 0) + ((counts['great'] as int?) ?? 0);

    final saved = (ref.watch(savedIdsProvider).value ?? {}).contains(
      recommendation.restaurantId,
    );
    final visited = (ref.watch(visitedIdsProvider).value ?? {}).contains(
      recommendation.restaurantId,
    );

    final city = (restaurant?['cities'] as Map?)?['name'] as String?;
    final country =
        ((restaurant?['cities'] as Map?)?['countries'] as Map?)?['name']
            as String?;
    final where = [city, country].whereType<String>().join(', ');
    final price = restaurant?['price_level'] as int?;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WbRadius.card),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── The restaurant leads ─────────────────────────────────────────
          InkWell(
            onTap: () => _openRestaurant(context),
            child: Padding(
              padding: const EdgeInsets.all(WbSpacing.sm + 2),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(WbRadius.chip + 2),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: WbPhoto(
                        source: restaurant?['cover_photo_url'] as String?,
                        semanticLabel:
                            'Photo of ${restaurant?['name'] ?? 'restaurant'}',
                      ),
                    ),
                  ),
                  const SizedBox(width: WbSpacing.sm + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (restaurant?['name'] as String?) ?? 'Restaurant',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (where.isNotEmpty || price != null)
                          Text(
                            [
                              if (where.isNotEmpty) where,
                              if (price != null) '\$' * price,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (visited)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.where_to_vote,
                                  size: 14,
                                  color: WbColors.success,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'You visited',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: WbColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: saved ? 'Saved' : 'Save restaurant',
                    onPressed: myId == null
                        ? null
                        : () => ref
                              .read(savedIdsProvider.notifier)
                              .toggle(recommendation.restaurantId),
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_outline,
                      color: saved ? WbColors.ember : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── The Taster's words ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WbSpacing.md,
              0,
              WbSpacing.md,
              WbSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recommendation.body, style: theme.textTheme.bodyMedium),
                if (recommendation.whatToOrder != null) ...[
                  const SizedBox(height: WbSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(WbSpacing.sm),
                    decoration: BoxDecoration(
                      color: WbColors.emberSoft.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.12 : 1,
                      ),
                      borderRadius: BorderRadius.circular(WbRadius.chip),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          size: 16,
                          color: WbColors.ember,
                        ),
                        const SizedBox(width: WbSpacing.sm),
                        Expanded(
                          child: Text(
                            'Order: ${recommendation.whatToOrder}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (recommendation.photos.isNotEmpty) ...[
                  const SizedBox(height: WbSpacing.sm),
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendation.photos.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: WbSpacing.sm),
                      itemBuilder: (context, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(WbRadius.chip),
                        child: CachedNetworkImage(
                          imageUrl:
                              recommendation.photos[i]['storage_path']
                                  as String,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          // ── Quiet reviewer footer ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WbSpacing.sm + 2,
              WbSpacing.xs,
              WbSpacing.sm,
              WbSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(WbRadius.pill),
                    onTap: () => context.pushNamed(
                      Routes.taster,
                      pathParameters: {'id': recommendation.userId},
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: author?['avatar_url'] == null
                                ? null
                                : CachedNetworkImageProvider(
                                    author!['avatar_url'] as String,
                                  ),
                            child: author?['avatar_url'] == null
                                ? Text(
                                    ((author?['display_name'] as String?) ??
                                            '?')
                                        .characters
                                        .first,
                                    style: theme.textTheme.labelSmall,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${(author?['display_name'] as String?) ?? 'Taster'}'
                              ' · ${DateFormat.yMMMd().format(recommendation.createdAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (author?['is_verified'] == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 3),
                              child: Icon(
                                Icons.verified,
                                size: 13,
                                color: WbColors.voyageLight,
                              ),
                            ),
                          if (author?['is_demo'] == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: DemoBadge(compact: true),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (positive > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: WbSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 13,
                          color: WbColors.success,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$positive accurate',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: WbColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!isMine && myId != null && mine == null)
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _rate(context, ref),
                    child: const Text('Rate it'),
                  ),
                if (mine != null)
                  Padding(
                    padding: const EdgeInsets.only(left: WbSpacing.sm),
                    child: Text(
                      'Rated',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
