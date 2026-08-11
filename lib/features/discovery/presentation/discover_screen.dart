import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/location/location_service.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/utils/plural.dart';
import '../../../core/widgets/wb_states.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../lists/data/list_repository.dart';
import '../../lists/domain/food_list.dart';
import '../../profile/presentation/widgets/profile_header.dart';
import '../../recommendations/domain/recommendation.dart';
import '../../recommendations/presentation/widgets/recommendation_card.dart';
import '../../restaurants/domain/restaurant.dart';
import '../../tasters/presentation/follow_providers.dart';
import '../data/discovery_repository.dart';

final trendingTastersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => ref.watch(discoveryRepositoryProvider).trendingTasters(),
    );

/// Best-effort current position for "near you" ranking. Never prompts on its
/// own initiative beyond what LocationService already gates behind an actual
/// permission flow, and a denial or a cold GPS fix just means
/// suggestedTastersProvider falls back to the caller's home city server-side
/// - so this is safe to watch unconditionally.
final _currentPositionProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(locationServiceProvider).currentPosition();
});

/// Who to follow next, ranked by shared taste and by whether they recommend
/// places near you - not by raw popularity. See suggested_tasters() for the
/// scoring; trending Tasters below is the separate popularity-only list.
final suggestedTastersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final signedIn = ref.watch(isSignedInProvider);
      if (!signedIn) return [];
      // Hoist the repo watch above the await: watching after an async gap is
      // unsupported in Riverpod 3 and can throw on a disposed container.
      final repo = ref.watch(discoveryRepositoryProvider);
      final position = await ref.watch(_currentPositionProvider.future);
      return repo.suggestedTasters(
        nearLat: position?.latitude,
        nearLng: position?.longitude,
      );
    });

final trendingRestaurantsProvider =
    FutureProvider.autoDispose<List<Restaurant>>(
      (ref) => ref.watch(discoveryRepositoryProvider).trendingRestaurants(),
    );

final newListsProvider = FutureProvider.autoDispose<List<FoodList>>(
  (ref) => ref.watch(listRepositoryProvider).publicLists(limit: 10),
);

final followingFeedProvider = FutureProvider.autoDispose<List<Recommendation>>((
  ref,
) async {
  final following = ref.watch(followingIdsProvider).value ?? {};
  return ref.watch(discoveryRepositoryProvider).followingFeed(following);
});

/// Discover: For You (modular sections) + Following (the feed).
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discover'),
          actions: [
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search),
              onPressed: () => context.pushNamed(Routes.search),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'For you'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: const TabBarView(children: [_ForYouTab(), _FollowingTab()]),
      ),
    );
  }
}

class _ForYouTab extends ConsumerWidget {
  const _ForYouTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(trendingTastersProvider);
        ref.invalidate(suggestedTastersProvider);
        ref.invalidate(trendingRestaurantsProvider);
        ref.invalidate(newListsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: WbSpacing.md),
        children: [
          // BiteSwipe entry: prominent but one card, not a takeover.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WbSpacing.md,
              0,
              WbSpacing.md,
              WbSpacing.sm,
            ),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(
                  Icons.style_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('BiteSwipe'),
                subtitle: const Text(
                  'Looking for somewhere to eat? Swipe through nearby picks.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  unawaited(
                    ref.read(analyticsProvider).deckOpened(from: 'discover'),
                  );
                  context.pushNamed(Routes.biteswipe);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WbSpacing.md,
              0,
              WbSpacing.md,
              WbSpacing.sm,
            ),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(
                  Icons.groups_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Taste Groups'),
                subtitle: const Text(
                  'Small crews around a shared appetite. Join one, or start '
                  'your own.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(Routes.tasteGroups),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WbSpacing.md,
              0,
              WbSpacing.md,
              WbSpacing.sm,
            ),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(
                  Icons.map_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Food Trips'),
                subtitle: const Text(
                  'Plan an eating itinerary: ordered stops and notes.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(Routes.trips),
              ),
            ),
          ),
          _SectionHeader(title: 'Trending Tasters'),
          SizedBox(
            height: 120,
            child: ref
                .watch(trendingTastersProvider)
                .when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(WbSpacing.md),
                    child: WbSkeleton(height: 100),
                  ),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (tasters) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: WbSpacing.md,
                    ),
                    itemCount: tasters.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: WbSpacing.sm),
                    itemBuilder: (context, i) {
                      final t = tasters[i];
                      return InkWell(
                        onTap: () => context.pushNamed(
                          Routes.taster,
                          pathParameters: {'id': t['id'] as String},
                        ),
                        borderRadius: BorderRadius.circular(WbRadius.card),
                        child: SizedBox(
                          width: 88,
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: t['avatar_url'] == null
                                        ? null
                                        : CachedNetworkImageProvider(
                                            t['avatar_url'] as String,
                                          ),
                                    child: t['avatar_url'] == null
                                        ? Text(
                                            (t['display_name'] as String)
                                                .characters
                                                .first,
                                          )
                                        : null,
                                  ),
                                  if (t['is_popular'] == true)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.local_fire_department,
                                          size: 14,
                                          color: WbColors.ember,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: WbSpacing.xs),
                              Text(
                                t['display_name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium,
                              ),
                              Text(
                                countOfDynamic(t['followers'], 'follower'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
          if (ref.watch(isSignedInProvider)) ...[
            _SectionHeader(title: 'Suggested for you'),
            ref
                .watch(suggestedTastersProvider)
                .when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: WbSpacing.md,
                    ),
                    child: WbSkeleton(height: 108),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (suggestions) => suggestions.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          height: 132,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: WbSpacing.md,
                            ),
                            itemCount: suggestions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: WbSpacing.sm),
                            itemBuilder: (context, i) =>
                                _SuggestedTasterCard(taster: suggestions[i]),
                          ),
                        ),
                ),
          ],
          _SectionHeader(title: 'Trending restaurants'),
          ref
              .watch(trendingRestaurantsProvider)
              .when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(WbSpacing.md),
                  child: WbSkeleton(height: 200),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(WbSpacing.md),
                  child: Text('$e'),
                ),
                data: (restaurants) => Column(
                  children: [
                    for (final r in restaurants.take(6))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          WbSpacing.md,
                          0,
                          WbSpacing.md,
                          WbSpacing.sm,
                        ),
                        child: Card(
                          child: ListTile(
                            onTap: () => context.pushNamed(
                              Routes.restaurant,
                              pathParameters: {'id': r.id},
                            ),
                            leading: const Icon(
                              Icons.local_fire_department,
                              color: WbColors.markerTrending,
                            ),
                            title: Text(
                              r.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (r.priceLevel != null) '\$' * r.priceLevel!,
                                countOf(r.recCount, 'rec'),
                                if (r.score != null)
                                  '${r.score!.toStringAsFixed(1)}/10',
                              ].join(' · '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          _SectionHeader(title: 'New lists'),
          SizedBox(
            height: 140,
            child: ref
                .watch(newListsProvider)
                .when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(WbSpacing.md),
                    child: WbSkeleton(height: 120),
                  ),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (lists) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: WbSpacing.md,
                    ),
                    itemCount: lists.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: WbSpacing.sm),
                    itemBuilder: (context, i) => SizedBox(
                      width: 200,
                      child: Card(
                        color: WbColors.voyage,
                        child: InkWell(
                          onTap: () => context.pushNamed(
                            Routes.list,
                            pathParameters: {'id': lists[i].id},
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(WbSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  lists[i].title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'by @${lists[i].owner?['username'] ?? ''}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ),
          const SizedBox(height: WbSpacing.xl),
        ],
      ),
    );
  }
}

class _FollowingTab extends ConsumerWidget {
  const _FollowingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);
    if (!signedIn) {
      return WbEmptyState(
        icon: Icons.group_outlined,
        title: 'Sign in to build your feed',
        message: 'Follow Tasters and their finds show up here.',
        actionLabel: 'Sign in',
        onAction: () => context.goNamed(Routes.welcome),
      );
    }
    final feed = ref.watch(followingFeedProvider);
    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => WbErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(followingFeedProvider),
      ),
      data: (recs) => recs.isEmpty
          ? const WbEmptyState(
              icon: Icons.rss_feed,
              title: 'Quiet in here',
              message:
                  'Follow some Tasters from Discover and their recommendations will appear.',
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(followingFeedProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(WbSpacing.md),
                itemCount: recs.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: WbSpacing.sm),
                  child: InkWell(
                    onTap: () => context.pushNamed(
                      Routes.restaurant,
                      pathParameters: {'id': recs[i].restaurantId},
                    ),
                    child: RecommendationCard(recommendation: recs[i]),
                  ),
                ),
              ),
            ),
    );
  }
}

/// One suggested Taster: who they are, *why* they were suggested, and a
/// one-tap follow. The "why" line is what makes this a suggestion rather than
/// just a second trending list - it's built from whichever signal actually
/// fired in suggested_tasters(), in the order a person would find most
/// convincing.
class _SuggestedTasterCard extends ConsumerWidget {
  const _SuggestedTasterCard({required this.taster});

  final Map<String, dynamic> taster;

  String get _reason {
    final tags = (taster['shared_tags'] as List?)?.cast<String>() ?? const [];
    if (tags.isNotEmpty) {
      return 'Shares your ${tags.take(2).join(' & ')}';
    }
    final nearby = (taster['nearby_recs'] as num?)?.toInt() ?? 0;
    if (nearby > 0) {
      return 'Recommends ${countOf(nearby, 'place')} near you';
    }
    return 'Similar taste to yours';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final id = taster['id'] as String;
    final following = (ref.watch(followingIdsProvider).value ?? {}).contains(
      id,
    );

    return InkWell(
      onTap: () =>
          context.pushNamed(Routes.taster, pathParameters: {'id': id}),
      borderRadius: BorderRadius.circular(WbRadius.card),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(WbSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(WbRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: taster['avatar_url'] == null
                      ? null
                      : CachedNetworkImageProvider(
                          taster['avatar_url'] as String,
                        ),
                  child: taster['avatar_url'] == null
                      ? Text((taster['display_name'] as String).characters.first)
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
                              taster['display_name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (taster['is_verified'] == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 3),
                              child: Icon(
                                Icons.verified,
                                size: 13,
                                color: WbColors.voyageLight,
                              ),
                            ),
                        ],
                      ),
                      if (taster['is_demo'] == true) const DemoBadge(compact: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: WbSpacing.xs),
            Text(
              _reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                onPressed: () =>
                    ref.read(followingIdsProvider.notifier).toggle(id),
                child: Text(following ? 'Following' : 'Follow'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WbSpacing.md,
        WbSpacing.md,
        WbSpacing.md,
        WbSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
