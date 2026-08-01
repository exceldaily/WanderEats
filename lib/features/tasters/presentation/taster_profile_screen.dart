import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/configuration/env.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/utils/plural.dart';
import '../../../core/widgets/wb_states.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../map/presentation/map_controller.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../../profile/presentation/widgets/profile_header.dart';
import '../../profile/presentation/widgets/profile_stats.dart';
import '../../profile/presentation/widgets/taste_personality_card.dart';
import '../../recommendations/data/recommendation_repository.dart';
import '../../recommendations/domain/recommendation.dart';
import '../../recommendations/presentation/widgets/recommendation_card.dart';
import '../../safety/domain/safety.dart';
import '../../safety/presentation/safety_sheet.dart';
import '../data/taster_repository.dart';
import 'follow_providers.dart';
import 'widgets/mutual_taste_card.dart';

final tasterProfileProvider = FutureProvider.autoDispose
    .family<Profile?, String>(
      (ref, id) => ref.watch(profileRepositoryProvider).fetchProfile(id),
    );

final tasterStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, id) => ref.watch(tasterRepositoryProvider).stats(id),
    );

final isPopularTasterProvider = FutureProvider.autoDispose
    .family<bool, String>(
      (ref, id) => ref.watch(tasterRepositoryProvider).isPopular(id),
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

  void _share(Profile p) {
    unawaited(
      ref
          .read(analyticsProvider)
          .shareInitiated(contentType: 'taster', id: p.id),
    );
    unawaited(
      SharePlus.instance.share(
        ShareParams(
          text: 'Follow @${p.username} on WanderBites for great food finds',
        ),
      ),
    );
  }

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
          final stats = ref.watch(tasterStatsProvider(p.id)).value;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ProfileHeader(
                      profile: p,
                      isPopular:
                          ref.watch(isPopularTasterProvider(p.id)).value ??
                          false,
                      actions: [
                        if (!isMe)
                          _FollowButton(
                            following: following,
                            enabled: ref.watch(isSignedInProvider),
                            onPressed: () => ref
                                .read(followingIdsProvider.notifier)
                                .toggle(p.id),
                          ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(WbSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileStats(stats: stats),
                          if (p.tastePersonality.values.any(
                            (v) => (v as String?)?.trim().isNotEmpty ?? false,
                          )) ...[
                            const SizedBox(height: WbSpacing.sm + 4),
                            TastePersonalityCard(
                              personality: p.tastePersonality,
                            ),
                          ],
                          if (!isMe && ref.watch(isSignedInProvider))
                            MutualTasteCard(tasterId: p.id),
                          const SizedBox(height: WbSpacing.lg),
                          Text(
                            'Food map',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: WbSpacing.sm),
                          _MapFilters(
                            selected: _filter,
                            onChanged: (f) => setState(() => _filter = f),
                          ),
                          const SizedBox(height: WbSpacing.sm),
                          _PersonalMap(tasterId: p.id, filter: _filter),
                          const SizedBox(height: WbSpacing.lg),
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
                            ? SliverToBoxAdapter(
                                child: WbEmptyState(
                                  icon: Icons.rate_review_outlined,
                                  title: isMe
                                      ? 'Your first recommendation will '
                                            'appear here.'
                                      : 'No recommendations yet',
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
                  const SliverToBoxAdapter(
                    child: SizedBox(height: WbSpacing.xl),
                  ),
                ],
              ),
              // Back + share float over the banner with a soft scrim so they
              // stay visible on any cover image.
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: WbSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ScrimIconButton(
                        icon: Icons.arrow_back,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ScrimIconButton(
                            icon: Icons.share_outlined,
                            tooltip: 'Share profile',
                            onPressed: () => _share(p),
                          ),
                          // Blocking and reporting are available to everyone,
                          // signed-in or not, free or paid. Deliberately sits
                          // next to Share rather than buried, and is only
                          // hidden on your own profile where it is meaningless.
                          if (!isMe)
                            _ScrimIconButton(
                              icon: Icons.more_vert,
                              tooltip: 'Report or block',
                              onPressed: () => showSafetySheet(
                                context,
                                target: ReportTarget.profile,
                                targetId: p.id,
                                subjectUserId: p.id,
                                subjectName: p.displayName.isNotEmpty
                                    ? p.displayName
                                    : '@${p.username}',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Follow with a quick state cross-fade; skipped when animations are off.
class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.following,
    required this.enabled,
    required this.onPressed,
  });

  final bool following;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final child = following
        ? FilledButton.tonalIcon(
            key: const ValueKey('following'),
            onPressed: enabled ? onPressed : null,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Following'),
          )
        : FilledButton.icon(
            key: const ValueKey('follow'),
            onPressed: enabled ? onPressed : null,
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('Follow'),
          );
    if (reduceMotion) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
      child: child,
    );
  }
}

class _ScrimIconButton extends StatelessWidget {
  const _ScrimIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _MapFilters extends StatelessWidget {
  const _MapFilters({required this.selected, required this.onChanged});

  final PlaceFilter selected;
  final ValueChanged<PlaceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(PlaceFilter f, String label, IconData icon) {
      final isSelected = selected == f;
      return Padding(
        padding: const EdgeInsets.only(right: WbSpacing.sm),
        child: FilterChip(
          avatar: isSelected ? null : Icon(icon, size: 15),
          showCheckmark: isSelected,
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(f),
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(PlaceFilter.all, 'All', Icons.layers_outlined),
          chip(
            PlaceFilter.recommended,
            'Recommended',
            Icons.rate_review_outlined,
          ),
          chip(PlaceFilter.visited, 'Visited', Icons.where_to_vote_outlined),
          chip(PlaceFilter.saved, 'Saved', Icons.bookmark_outline),
        ],
      ),
    );
  }
}

class _PersonalMap extends ConsumerWidget {
  const _PersonalMap({required this.tasterId, required this.filter});

  final String tasterId;
  final PlaceFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final places = ref.watch(tasterPlacesProvider(tasterId));

    return places.when(
      loading: () => const WbSkeleton(height: 190),
      error: (e, _) => Text('Map unavailable: $e'),
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

        final cityIds = {
          for (final p in filtered)
            if (p.marker.cityId != null) p.marker.cityId!,
        };
        final summary = filtered.isEmpty
            ? null
            : '${filtered.length} ${filtered.length == 1 ? 'place' : 'places'}'
                  '${cityIds.isEmpty ? '' : ' across ${cityIds.length} '
                            '${cityIds.length == 1 ? 'city' : 'cities'}'}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(WbRadius.card),
              child: SizedBox(
                height: 190,
                child: !Env.hasMapsKey
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Text(
                            '${countOf(filtered.length, 'place')} '
                            '(map needs an API key)',
                          ),
                        ),
                      )
                    : filtered.isEmpty
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Text(switch (filter) {
                            PlaceFilter.all => 'No places yet',
                            PlaceFilter.recommended => 'No recommendations yet',
                            PlaceFilter.visited => 'No visits yet',
                            PlaceFilter.saved => 'No saves yet',
                          }),
                        ),
                      )
                    : GoogleMap(
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
                              // Hues match the main map: recommended green,
                              // visited violet, saved ember-red. The legend
                              // below repeats this with icons, so color is
                              // never the only signal.
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                p.recommended
                                    ? BitmapDescriptor.hueGreen
                                    : p.visited
                                    ? BitmapDescriptor.hueViolet
                                    : BitmapDescriptor.hueRed,
                              ),
                            ),
                        },
                      ),
              ),
            ),
            const SizedBox(height: WbSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: WbSpacing.md,
                    runSpacing: 4,
                    children: const [
                      _LegendEntry(
                        color: WbColors.success,
                        icon: Icons.rate_review_outlined,
                        label: 'Recommended',
                      ),
                      _LegendEntry(
                        color: Color(0xFF5C6BC0),
                        icon: Icons.where_to_vote_outlined,
                        label: 'Visited',
                      ),
                      _LegendEntry(
                        color: WbColors.ember,
                        icon: Icons.bookmark_outline,
                        label: 'Saved',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (summary != null || filtered.isNotEmpty) ...[
              const SizedBox(height: WbSpacing.xs),
              Row(
                children: [
                  if (summary != null)
                    Expanded(
                      child: Text(
                        summary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (filtered.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        final first = filtered.first.marker;
                        ref
                            .read(mapDestinationProvider.notifier)
                            .go(
                              MapDestination(
                                lat: first.lat,
                                lng: first.lng,
                                label: 'this food map',
                              ),
                            );
                        // Switch to the Map tab. This has to be a named `go`,
                        // not Navigator.popUntil: each shell branch owns its
                        // own Navigator, so popping only unwinds the current
                        // branch's stack and never actually switches tabs -
                        // that was the bug (see search_screen.dart for the
                        // same working pattern).
                        context.goNamed(Routes.map);
                      },
                      icon: const Icon(Icons.open_in_full, size: 16),
                      label: const Text('View full map'),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
