import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/widgets/wb_states.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../lists/data/list_repository.dart';
import '../../lists/domain/food_list.dart';
import '../../tasters/presentation/taster_profile_screen.dart';
import '../data/profile_repository.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_stats.dart';
import 'widgets/taste_personality_card.dart';

final myBadgesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final session = ref.watch(sessionProvider);
    if (session == null) return [];
    return ref.watch(profileRepositoryProvider).earnedBadges(session.user.id);
  },
);

final myListsProvider = FutureProvider.autoDispose<List<FoodList>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return [];
  return ref.watch(listRepositoryProvider).byOwner(session.user.id);
});

/// Current-user profile hub: identity with cover banner, taste identity,
/// stats, and jump-offs into the food map, collections and lists — each with
/// an intentional empty state instead of a bare row.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(myProfileProvider);
    final signedIn = ref.watch(isSignedInProvider);

    if (!signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: WbEmptyState(
          icon: Icons.person_outline,
          title: 'Sign in to build your food map',
          message: 'Save places, follow Tasters and publish recommendations.',
          actionLabel: 'Sign in',
          onAction: () => context.goNamed(Routes.welcome),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed(Routes.settings),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WbErrorState(
          message: e.toString(),
          onRetry: () => ref.read(myProfileProvider.notifier).refresh(),
        ),
        data: (p) {
          if (p == null) {
            // Two different nulls: a guest has no account at all, while a
            // signed-in user without a profile abandoned onboarding partway.
            final signedIn = ref.watch(isSignedInProvider);
            if (!signedIn) {
              return WbEmptyState(
                icon: Icons.badge_outlined,
                title: 'Sign in to build your taste profile',
                actionLabel: 'Sign in',
                onAction: () => context.goNamed(Routes.welcome),
              );
            }
            return WbEmptyState(
              icon: Icons.badge_outlined,
              title: 'Finish setting up your profile',
              actionLabel: 'Complete onboarding',
              onAction: () => context.goNamed(Routes.onboarding),
            );
          }
          final stats = ref.watch(tasterStatsProvider(p.id)).value;
          final badges = ref.watch(myBadgesProvider).value ?? [];
          final lists = ref.watch(myListsProvider).value ?? [];
          final recCount = (stats?['recommendations'] as num?)?.toInt() ?? 0;
          final saveCount = (stats?['saves'] as num?)?.toInt() ?? 0;
          final visitCount = (stats?['visits'] as num?)?.toInt() ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(myProfileProvider.notifier).refresh();
              ref.invalidate(myBadgesProvider);
              ref.invalidate(myListsProvider);
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ProfileHeader(
                  profile: p,
                  actions: [
                    FilledButton.tonalIcon(
                      onPressed: () => context.pushNamed(Routes.editProfile),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(WbSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileStats(
                        stats: stats,
                        onFollowersTap: () => context.pushNamed(
                          Routes.follows,
                          pathParameters: {'id': p.id},
                          queryParameters: {'name': p.displayName, 'tab': '0'},
                        ),
                        onFollowingTap: () => context.pushNamed(
                          Routes.follows,
                          pathParameters: {'id': p.id},
                          queryParameters: {'name': p.displayName, 'tab': '1'},
                        ),
                      ),
                      const SizedBox(height: WbSpacing.sm + 4),
                      TastePersonalityCard(
                        personality: p.tastePersonality,
                        onEdit: () => context.pushNamed(Routes.editProfile),
                      ),
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: WbSpacing.md),
                        Text(
                          'Badges',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: WbSpacing.sm),
                        Wrap(
                          spacing: WbSpacing.sm,
                          runSpacing: WbSpacing.sm,
                          children: [
                            for (final b in badges)
                              Tooltip(
                                message:
                                    (b['badges'] as Map?)?['description']
                                        as String? ??
                                    '',
                                child: Chip(
                                  avatar: const Icon(
                                    Icons.emoji_events,
                                    size: 16,
                                    color: WbColors.warning,
                                  ),
                                  label: Text(
                                    (b['badges'] as Map?)?['name'] as String? ??
                                        '',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: WbSpacing.md),
                      _SectionCard(
                        entries: [
                          _SectionEntry(
                            icon: Icons.map_outlined,
                            iconColor: theme.colorScheme.primary,
                            title: 'My food map',
                            subtitle: recCount + saveCount + visitCount == 0
                                ? 'Your first recommendation will appear here.'
                                : 'Every place you recommend, save and visit',
                            onTap: () => context.pushNamed(
                              Routes.taster,
                              pathParameters: {'id': p.id},
                            ),
                          ),
                          _SectionEntry(
                            icon: Icons.bookmark_outline,
                            iconColor: WbColors.ember,
                            title: 'Saved restaurants',
                            subtitle: saveCount == 0
                                ? 'Save a restaurant to build your future '
                                      'food list.'
                                : '$saveCount saved',
                            onTap: () =>
                                context.pushNamed(Routes.savedRestaurants),
                          ),
                          _SectionEntry(
                            icon: Icons.where_to_vote_outlined,
                            iconColor: WbColors.success,
                            title: 'Visited restaurants',
                            subtitle: visitCount == 0
                                ? 'Mark places you have eaten at to track '
                                      'your travels.'
                                : '$visitCount visited',
                            onTap: () =>
                                context.pushNamed(Routes.visitedRestaurants),
                          ),
                        ],
                      ),
                      const SizedBox(height: WbSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My lists',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (lists.isNotEmpty)
                            TextButton.icon(
                              onPressed: () =>
                                  context.pushNamed(Routes.createList),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('New list'),
                            ),
                        ],
                      ),
                      if (lists.isEmpty)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(WbRadius.card),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(WbSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create a list for date nights, street '
                                  'food, or places worth traveling for.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: WbSpacing.sm),
                                FilledButton.icon(
                                  onPressed: () =>
                                      context.pushNamed(Routes.createList),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Create your first list'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        for (final l in lists)
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                WbRadius.card,
                              ),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                l.visibility == 'private'
                                    ? Icons.lock_outline
                                    : Icons.playlist_play,
                                color: theme.colorScheme.primary,
                              ),
                              title: Text(l.title),
                              subtitle: l.description != null
                                  ? Text(
                                      l.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.pushNamed(
                                Routes.list,
                                pathParameters: {'id': l.id},
                              ),
                            ),
                          ),
                      const SizedBox(height: WbSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionEntry {
  const _SectionEntry({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

/// Collection jump-offs with a tinted icon treatment so each row reads at a
/// glance, and subtitles that double as empty-state guidance.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.entries});

  final List<_SectionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WbRadius.card),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          for (final (i, e) in entries.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 64,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: e.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(WbRadius.chip + 2),
                ),
                child: Icon(e.icon, color: e.iconColor, size: 20),
              ),
              title: Text(
                e.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                e.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: e.onTap,
            ),
          ],
        ],
      ),
    );
  }
}
