import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/configuration/env.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/widgets/wb_states.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../../recommendations/data/recommendation_repository.dart';
import '../../recommendations/domain/recommendation.dart';
import '../../recommendations/presentation/widgets/recommendation_card.dart';
import '../data/taster_repository.dart';
import 'follow_providers.dart';

final tasterProfileProvider = FutureProvider.autoDispose
    .family<Profile?, String>(
      (ref, id) => ref.watch(profileRepositoryProvider).fetchProfile(id),
    );

final tasterStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, id) => ref.watch(tasterRepositoryProvider).stats(id),
    );

final tasterPlacesProvider = FutureProvider.autoDispose
    .family<List<TasterPlace>, String>(
      (ref, id) => ref.watch(tasterRepositoryProvider).places(id),
    );

final tasterRecsProvider = FutureProvider.autoDispose
    .family<List<Recommendation>, String>(
      (ref, id) => ref.watch(recommendationRepositoryProvider).byUser(id),
    );

/// Filter for the personal food map.
enum PlaceFilter { all, recommended, visited, saved }

/// The heart of the app: a Taster's credibility and their map of the world.
class TasterProfileScreen extends ConsumerStatefulWidget {
  const TasterProfileScreen({super.key, required this.tasterId});

  final String tasterId;

  @override
  ConsumerState<TasterProfileScreen> createState() =>
      _TasterProfileScreenState();
}

class _TasterProfileScreenState extends ConsumerState<TasterProfileScreen> {
  PlaceFilter _filter = PlaceFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(tasterProfileProvider(widget.tasterId));
    final following = (ref.watch(followingIdsProvider).value ?? {}).contains(
      widget.tasterId,
    );
    final isMe = ref.watch(sessionProvider)?.user.id == widget.tasterId;

    return Scaffold(
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WbErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(tasterProfileProvider(widget.tasterId)),
        ),
        data: (p) {
          if (p == null) {
            return const WbEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Profile not found',
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                actions: [
                  IconButton(
                    tooltip: 'Share profile',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      unawaited(
                        ref
                            .read(analyticsProvider)
                            .shareInitiated(contentType: 'taster', id: p.id),
                      );
                      unawaited(
                        SharePlus.instance.share(
                          ShareParams(
                            text:
                                'Follow @${p.username} on WanderBites for great food finds',
                          ),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: p.headerUrl != null
                      ? CachedNetworkImage(
                          imageUrl: p.headerUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: WbColors.voyage),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(WbSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: p.avatarUrl == null
                                ? null
                                : CachedNetworkImageProvider(p.avatarUrl!),
                            child: p.avatarUrl == null
                                ? Text(
                                    p.displayName.characters.first,
                                    style: theme.textTheme.headlineSmall,
                                  )
                                : null,
                          ),
                          const Spacer(),
                          if (!isMe)
                            FilledButton.icon(
                              onPressed: ref.watch(isSignedInProvider)
                                  ? () => ref
                                        .read(followingIdsProvider.notifier)
                                        .toggle(p.id)
                                  : null,
                              icon: Icon(
                                following ? Icons.check : Icons.person_add_alt,
                              ),
                              label: Text(following ? 'Following' : 'Follow'),
                            ),
                        ],
                      ),
                      const SizedBox(height: WbSpacing.sm),
                      Row(
                        children: [
                          Text(
                            p.displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (p.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.verified,
                                color: WbColors.voyageLight,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '@${p.username}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (p.bio != null) ...[
                        const SizedBox(height: WbSpacing.sm),
                        Text(p.bio!, style: theme.textTheme.bodyMedium),
                      ],
                      const SizedBox(height: WbSpacing.md),
                      _StatsRow(tasterId: p.id),
                      const Divider(height: WbSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Food map',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SegmentedButton<PlaceFilter>(
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            segments: const [
                              ButtonSegment(
                                value: PlaceFilter.all,
                                label: Text('All'),
                              ),
                              ButtonSegment(
                                value: PlaceFilter.recommended,
                                icon: Icon(Icons.thumb_up_outlined, size: 14),
                              ),
                              ButtonSegment(
                                value: PlaceFilter.visited,
                                icon: Icon(
                                  Icons.where_to_vote_outlined,
                                  size: 14,
                                ),
                              ),
                              ButtonSegment(
                                value: PlaceFilter.saved,
                                icon: Icon(Icons.bookmark_outline, size: 14),
                              ),
                            ],
                            selected: {_filter},
                            onSelectionChanged: (s) =>
                                setState(() => _filter = s.first),
                          ),
                        ],
                      ),
                      const SizedBox(height: WbSpacing.sm),
                      _PersonalMap(tasterId: p.id, filter: _filter),
                      const Divider(height: WbSpacing.xl),
                      Text(
                        'Recent recommendations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ref
                  .watch(tasterRecsProvider(widget.tasterId))
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
                        child: Text('Could not load: $e'),
                      ),
                    ),
                    data: (recs) => recs.isEmpty
                        ? const SliverToBoxAdapter(
                            child: WbEmptyState(
                              icon: Icons.rate_review_outlined,
                              title: 'No recommendations yet',
                            ),
                          )
                        : SliverList.builder(
                            itemCount: recs.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(
                                WbSpacing.md,
                                0,
                                WbSpacing.md,
                                WbSpacing.sm,
                              ),
                              child: RecommendationCard(
                                recommendation: recs[i],
                              ),
                            ),
                          ),
                  ),
              const SliverToBoxAdapter(child: SizedBox(height: WbSpacing.xl)),
            ],
          );
        },
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.tasterId});

  final String tasterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(tasterStatsProvider(tasterId)).value;
    final theme = Theme.of(context);
    Widget stat(String label, Object? value) => Expanded(
      child: Column(
        children: [
          Text(
            '${value ?? '-'}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return Row(
      children: [
        stat('Followers', stats?['followers']),
        stat('Following', stats?['following']),
        stat('Recs', stats?['recommendations']),
        stat('Cities', stats?['cities_explored']),
        stat('Score', stats?['reputation']),
      ],
    );
  }
}

class _PersonalMap extends ConsumerWidget {
  const _PersonalMap({required this.tasterId, required this.filter});

  final String tasterId;
  final PlaceFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(tasterPlacesProvider(tasterId));
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WbRadius.card),
        child: places.when(
          loading: () => const WbSkeleton(height: 220),
          error: (e, _) => Center(child: Text('Map unavailable: $e')),
          data: (all) {
            final filtered = all
                .where(
                  (p) => switch (filter) {
                    PlaceFilter.all => true,
                    PlaceFilter.recommended => p.recommended,
                    PlaceFilter.visited => p.visited,
                    PlaceFilter.saved => p.saved,
                  },
                )
                .toList();
            if (!Env.hasMapsKey) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Text(
                    '${filtered.length} places (map needs an API key)',
                  ),
                ),
              );
            }
            if (filtered.isEmpty) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: Text('No places yet')),
              );
            }
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  filtered.first.marker.lat,
                  filtered.first.marker.lng,
                ),
                zoom: 2.5,
              ),
              liteModeEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              markers: {
                for (final p in filtered)
                  Marker(
                    markerId: MarkerId(p.marker.id),
                    position: LatLng(p.marker.lat, p.marker.lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      p.recommended
                          ? BitmapDescriptor.hueGreen
                          : p.visited
                          ? BitmapDescriptor.hueViolet
                          : BitmapDescriptor.hueRed,
                    ),
                  ),
              },
            );
          },
        ),
      ),
    );
  }
}
