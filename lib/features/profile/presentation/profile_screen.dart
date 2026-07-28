import 'package:cached_network_image/cached_network_image.dart';
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

final myBadgesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return [];
  return ref.watch(profileRepositoryProvider).earnedBadges(session.user.id);
});

final myListsProvider = FutureProvider.autoDispose<List<FoodList>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return [];
  return ref.watch(listRepositoryProvider).byOwner(session.user.id);
});

/// Current-user profile hub: identity, stats, badges, and jump-offs to the
/// full food map, saved, visited, lists and settings.
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
          message:
              'Save places, follow Tasters and publish recommendations.',
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
            onRetry: () => ref.read(myProfileProvider.notifier).refresh()),
        data: (p) {
          if (p == null) {
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
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(myProfileProvider.notifier).refresh();
              ref.invalidate(myBadgesProvider);
              ref.invalidate(myListsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(WbSpacing.md),
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: p.avatarUrl == null
                        ? null
                        : CachedNetworkImageProvider(p.avatarUrl!),
                    child: p.avatarUrl == null
                        ? Text(p.displayName.characters.first,
                            style: theme.textTheme.headlineSmall)
                        : null,
                  ),
                  const SizedBox(width: WbSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.displayName,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text('@${p.username}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.pushNamed(Routes.editProfile),
                    child: const Text('Edit'),
                  ),
                ]),
                if (p.bio != null) ...[
                  const SizedBox(height: WbSpacing.sm),
                  Text(p.bio!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: WbSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(WbSpacing.md),
                    child: Row(children: [
                      _Stat('Followers', stats?['followers']),
                      _Stat('Recs', stats?['recommendations']),
                      _Stat('Cities', stats?['cities_explored']),
                      _Stat('Countries', stats?['countries_visited']),
                      _Stat('Score', stats?['reputation']),
                    ]),
                  ),
                ),
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: WbSpacing.md),
                  Text('Badges',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: WbSpacing.sm),
                  Wrap(spacing: WbSpacing.sm, runSpacing: WbSpacing.sm, children: [
                    for (final b in badges)
                      Tooltip(
                        message: (b['badges'] as Map?)?['description']
                                as String? ??
                            '',
                        child: Chip(
                          avatar: const Icon(Icons.emoji_events, size: 16),
                          label: Text(
                              (b['badges'] as Map?)?['name'] as String? ?? ''),
                        ),
                      ),
                  ]),
                ],
                const SizedBox(height: WbSpacing.md),
                Card(
                  child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.map_outlined),
                      title: const Text('My food map'),
                      subtitle: const Text(
                          'Every place you recommend, save and visit'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.pushNamed(Routes.taster,
                          pathParameters: {'id': p.id}),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.bookmark_outline),
                      title: const Text('Saved restaurants'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.pushNamed(Routes.savedRestaurants),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.where_to_vote_outlined),
                      title: const Text('Visited restaurants'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.pushNamed(Routes.visitedRestaurants),
                    ),
                  ]),
                ),
                const SizedBox(height: WbSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My lists',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () => context.pushNamed(Routes.createList),
                      child: const Text('New list'),
                    ),
                  ],
                ),
                if (lists.isEmpty)
                  Text('No lists yet. Curate your first one.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant))
                else
                  for (final l in lists)
                    Card(
                      child: ListTile(
                        leading: Icon(l.visibility == 'private'
                            ? Icons.lock_outline
                            : Icons.playlist_play),
                        title: Text(l.title),
                        subtitle:
                            l.description != null ? Text(l.description!) : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.pushNamed(Routes.list,
                            pathParameters: {'id': l.id}),
                      ),
                    ),
                const SizedBox(height: WbSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(children: [
        Text('${value ?? '-'}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}
