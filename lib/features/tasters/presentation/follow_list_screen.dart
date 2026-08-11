import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/networking/supabase_provider.dart';
import '../../../core/widgets/wb_states.dart';
import '../../authentication/presentation/auth_providers.dart';
import 'follow_providers.dart';

/// One row of a follow list: the person, plus whether *I* follow them.
class _FollowEntry {
  const _FollowEntry({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isDemo = false,
  });

  factory _FollowEntry.fromRow(Map<String, dynamic> row) {
    final p = (row['profile'] as Map?)?.cast<String, dynamic>() ?? const {};
    return _FollowEntry(
      id: p['id'] as String? ?? '',
      username: p['username'] as String? ?? '',
      displayName: p['display_name'] as String? ?? '',
      avatarUrl: p['avatar_url'] as String?,
      isDemo: p['is_demo'] == true,
    );
  }

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isDemo;
}

/// (userId, followers: true = who follows them, false = who they follow)
typedef _FollowQuery = ({String userId, bool followers});

final _followListProvider = FutureProvider.autoDispose
    .family<List<_FollowEntry>, _FollowQuery>((ref, q) async {
      // Blocks sever follow edges at block time, so no filtering is needed
      // here; deleted profiles drop out via the inner join.
      final rows = await ref
          .watch(wbSchemaProvider)
          .from('follows')
          .select(
            q.followers
                ? 'profile:profiles!follower_id(id, username, display_name, avatar_url, is_demo, deleted_at)'
                : 'profile:profiles!followee_id(id, username, display_name, avatar_url, is_demo, deleted_at)',
          )
          .eq(q.followers ? 'followee_id' : 'follower_id', q.userId)
          .order('created_at', ascending: false);
      return [
        for (final row in rows)
          if ((row['profile'] as Map?)?['deleted_at'] == null)
            _FollowEntry.fromRow(row),
      ];
    });

/// Followers / Following lists for any Taster, reached from the numbers on
/// their profile card.
class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    super.key,
    required this.userId,
    this.displayName,
    this.initialTab = 0,
  });

  final String userId;
  final String? displayName;

  /// 0 = Followers, 1 = Following.
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          title: Text(displayName ?? 'Follows'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FollowList(query: (userId: userId, followers: true)),
            _FollowList(query: (userId: userId, followers: false)),
          ],
        ),
      ),
    );
  }
}

class _FollowList extends ConsumerWidget {
  const _FollowList({required this.query});

  final _FollowQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(_followListProvider(query));
    final myId = ref.watch(sessionProvider)?.user.id;
    final followingIds = ref.watch(followingIdsProvider).value ?? const {};

    return RefreshIndicator(
      onRefresh: () => ref.refresh(_followListProvider(query).future),
      child: list.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(WbSpacing.md),
          children: [
            for (var i = 0; i < 6; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: WbSpacing.md),
                child: Row(
                  children: [
                    WbSkeleton(height: 44, width: 44, radius: 22),
                    SizedBox(width: WbSpacing.md),
                    Expanded(child: WbSkeleton(height: 14)),
                  ],
                ),
              ),
          ],
        ),
        error: (e, _) => WbErrorState(
          message: 'The list could not be loaded.',
          onRetry: () => ref.invalidate(_followListProvider(query)),
        ),
        data: (entries) => entries.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  WbEmptyState(
                    icon: Icons.group_outlined,
                    title: query.followers
                        ? 'No followers yet'
                        : 'Not following anyone yet',
                    message: query.followers
                        ? 'Share great recommendations and they will come.'
                        : 'Find Tasters with great taste on Discover.',
                  ),
                ],
              )
            : ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final isMe = e.id == myId;
                  final following = followingIds.contains(e.id);
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: e.avatarUrl == null
                          ? null
                          : CachedNetworkImageProvider(e.avatarUrl!),
                      child: e.avatarUrl == null
                          ? Text(
                              e.displayName.isEmpty ? '?' : e.displayName[0],
                            )
                          : null,
                    ),
                    title: Text(
                      e.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '@${e.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isMe || myId == null
                        ? null
                        : following
                        ? OutlinedButton(
                            onPressed: () => ref
                                .read(followingIdsProvider.notifier)
                                .toggle(e.id),
                            child: const Text('Following'),
                          )
                        : FilledButton.tonal(
                            onPressed: () => ref
                                .read(followingIdsProvider.notifier)
                                .toggle(e.id),
                            child: const Text('Follow'),
                          ),
                    onTap: () => context.pushNamed(
                      Routes.taster,
                      pathParameters: {'id': e.id},
                    ),
                  );
                },
              ),
      ),
    );
  }
}
