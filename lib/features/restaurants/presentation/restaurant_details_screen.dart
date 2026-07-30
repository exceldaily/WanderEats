import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/wb_tokens.dart';
import '../../../core/links/safe_link.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/utils/plural.dart';
import '../../../core/widgets/wb_photo.dart';
import '../../../core/widgets/wb_states.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../recommendations/data/recommendation_repository.dart';
import '../../recommendations/domain/recommendation.dart';
import '../../recommendations/presentation/widgets/recommendation_card.dart';
import '../data/restaurant_repository.dart';
import '../domain/restaurant.dart';
import 'restaurant_actions.dart';
import 'widgets/taster_avatars.dart';

final _restaurantProvider = FutureProvider.autoDispose
    .family<Restaurant, String>(
      (ref, id) => ref.watch(restaurantRepositoryProvider).fetchRestaurant(id),
    );

final _summaryProvider = FutureProvider.autoDispose
    .family<RestaurantSummary, String>(
      (ref, id) => ref.watch(restaurantRepositoryProvider).fetchSummary(id),
    );

final _cuisinesProvider = FutureProvider.autoDispose
    .family<List<String>, String>(
      (ref, id) =>
          ref.watch(restaurantRepositoryProvider).fetchCuisineNames(id),
    );

final _recsProvider = FutureProvider.autoDispose
    .family<List<Recommendation>, String>(
      (ref, id) =>
          ref.watch(recommendationRepositoryProvider).forRestaurant(id),
    );

class RestaurantDetailsScreen extends ConsumerWidget {
  const RestaurantDetailsScreen({super.key, required this.restaurantId});

  final String restaurantId;

  Future<void> _openDirections(
    BuildContext context,
    WidgetRef ref,
    Restaurant r,
  ) async {
    unawaited(
      ref.read(analyticsProvider).directionsOpened(restaurantId: restaurantId),
    );
    final query = Uri.encodeComponent('${r.name} ${r.address ?? ''}');
    // geo: hands off to whatever map app the user actually has; the web URL is
    // the fallback for a device with none installed.
    if (await SafeLink.open('geo:0,0?q=$query') != null) {
      await SafeLink.open(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
    }
  }

  /// Opens an untrusted link, and says something specific when it is refused.
  ///
  /// Restaurant URLs arrive from Google Places today and from claimed business
  /// owners later. Both are untrusted input, so they go through validation
  /// instead of straight to the OS.
  Future<void> _openExternal(BuildContext context, String? url) async {
    final rejection = await SafeLink.open(url);
    if (rejection != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(rejection.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final restaurant = ref.watch(_restaurantProvider(restaurantId));
    final saved = (ref.watch(savedIdsProvider).value ?? {}).contains(
      restaurantId,
    );
    final visited = (ref.watch(visitedIdsProvider).value ?? {}).contains(
      restaurantId,
    );
    final signedIn = ref.watch(isSignedInProvider);

    return Scaffold(
      body: restaurant.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WbErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(_restaurantProvider(restaurantId)),
        ),
        data: (r) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              actions: [
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    unawaited(
                      ref
                          .read(analyticsProvider)
                          .shareInitiated(
                            contentType: 'restaurant',
                            id: restaurantId,
                          ),
                    );
                    unawaited(
                      SharePlus.instance.share(
                        ShareParams(text: 'Check out ${r.name} on WanderBites'),
                      ),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'report') {
                      unawaited(_report(context, ref));
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'report',
                      child: Text('Report incorrect information'),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: r.coverPhotoUrl == null
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.restaurant, size: 64),
                        ),
                      )
                    : WbPhoto(
                        source: r.coverPhotoUrl,
                        semanticLabel: 'Photo of ${r.name}',
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(WbSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: WbSpacing.xs),
                    _CuisineRow(
                      restaurantId: restaurantId,
                      price: r.priceLevel,
                    ),
                    const SizedBox(height: WbSpacing.sm),
                    if (r.address != null)
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              r.address!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    if (r.score != null || r.recCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: WbSpacing.xs),
                        child: Text(
                          [
                            if (r.score != null)
                              'Score ${r.score!.toStringAsFixed(1)}/10',
                            countOf(r.recCount, 'recommendation'),
                            countOf(r.saveCount, 'save'),
                          ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: WbSpacing.md),
                    // Directions is the primary action and gets the full width:
                    // three side-by-side buttons squeezed long labels
                    // ("Directions", "Mark visited") into ~1/3 of the screen,
                    // which wrapped them mid-word.
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openDirections(context, ref, r),
                        icon: const Icon(Icons.directions_outlined),
                        label: const Text('Directions'),
                      ),
                    ),
                    const SizedBox(height: WbSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: signedIn
                                ? () => ref
                                      .read(savedIdsProvider.notifier)
                                      .toggle(restaurantId)
                                : null,
                            icon: Icon(
                              saved ? Icons.bookmark : Icons.bookmark_outline,
                            ),
                            label: Text(
                              saved ? 'Saved' : 'Save',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: WbSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: signedIn
                                ? () => ref
                                      .read(visitedIdsProvider.notifier)
                                      .toggle(restaurantId)
                                : null,
                            icon: Icon(
                              visited
                                  ? Icons.where_to_vote
                                  : Icons.where_to_vote_outlined,
                            ),
                            label: Text(
                              visited ? 'Visited' : 'Mark visited',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (r.website != null || r.phone != null)
                      Padding(
                        padding: const EdgeInsets.only(top: WbSpacing.sm),
                        child: Wrap(
                          spacing: WbSpacing.sm,
                          children: [
                            if (r.website != null)
                              ActionChip(
                                avatar: const Icon(Icons.language, size: 16),
                                label: const Text('Website'),
                                onPressed: () =>
                                    _openExternal(context, r.website),
                              ),
                            if (r.phone != null)
                              ActionChip(
                                avatar: const Icon(
                                  Icons.call_outlined,
                                  size: 16,
                                ),
                                label: Text(r.phone!),
                                onPressed: () =>
                                    _openExternal(context, 'tel:${r.phone}'),
                              ),
                          ],
                        ),
                      ),
                    const Divider(height: WbSpacing.xl),

                    // The hero section of the product.
                    Text(
                      'Recommended by people you trust',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: WbSpacing.sm),
                    ref
                        .watch(_summaryProvider(restaurantId))
                        .when(
                          loading: () => const WbSkeleton(height: 36),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (s) => s.tasters.isEmpty
                              ? Text(
                                  'No recommendations yet. Be the first.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : TasterAvatars(tasters: s.tasters, size: 40),
                        ),
                  ],
                ),
              ),
            ),
            ref
                .watch(_recsProvider(restaurantId))
                .when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(WbSpacing.md),
                      child: WbSkeleton(height: 120),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(WbSpacing.md),
                      child: Text('Could not load recommendations: $e'),
                    ),
                  ),
                  data: (recs) => SliverList.builder(
                    itemCount: recs.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(
                        WbSpacing.md,
                        0,
                        WbSpacing.md,
                        WbSpacing.sm,
                      ),
                      child: RecommendationCard(recommendation: recs[i]),
                    ),
                  ),
                ),
            const SliverToBoxAdapter(child: SizedBox(height: WbSpacing.xl)),
          ],
        ),
      ),
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to report content.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report incorrect information'),
        content: const Text(
          'Flag this restaurant for review? Our moderators will take a look.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(restaurantRepositoryProvider)
        .reportRestaurant(
          reporterId: session.user.id,
          restaurantId: restaurantId,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks, report submitted.')),
      );
    }
  }
}

class _CuisineRow extends ConsumerWidget {
  const _CuisineRow({required this.restaurantId, this.price});

  final String restaurantId;
  final int? price;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuisines = ref.watch(_cuisinesProvider(restaurantId)).value ?? [];
    return Wrap(
      spacing: WbSpacing.xs,
      runSpacing: WbSpacing.xs,
      children: [
        for (final c in cuisines) Chip(label: Text(c)),
        if (price != null) Chip(label: Text('\$' * price!)),
      ],
    );
  }
}
