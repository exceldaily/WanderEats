import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/widgets/wb_states.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/notification_repository.dart';

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) async {
    final session = ref.watch(sessionProvider);
    if (session == null) return [];
    return ref.watch(notificationRepositoryProvider).list(session.user.id);
  },
);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _label(AppNotification n) {
    final who = n.actorName ?? 'Someone';
    return switch (n.type) {
      'follow' => '$who started following you',
      'rec_feedback' =>
        '$who rated your recommendation: ${n.payload['rating'] ?? ''}',
      'comment' => '$who commented',
      'like' => '$who liked your content',
      'list_invite' => '$who invited you to collaborate on a list',
      'list_update' => 'A list you collaborate on was updated',
      'saved_list_update' => 'A list you follow got a new place',
      'badge' => 'Badge unlocked: ${n.payload['badge_slug'] ?? ''}',
      'message' => '$who sent you a message',
      _ => 'Activity',
    };
  }

  IconData _icon(String type) => switch (type) {
    'follow' => Icons.person_add_alt,
    'rec_feedback' => Icons.fact_check_outlined,
    'comment' => Icons.chat_bubble_outline,
    'like' => Icons.favorite_outline,
    'list_invite' ||
    'list_update' ||
    'saved_list_update' => Icons.playlist_add_check,
    'badge' => Icons.emoji_events_outlined,
    'message' => Icons.forum_outlined,
    _ => Icons.notifications_none,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final items = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          if (session != null)
            IconButton(
              tooltip: 'Messages',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => context.pushNamed(Routes.messages),
            ),
          if (session != null)
            TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(notificationRepositoryProvider)
                      .markAllRead(session.user.id);
                  ref.invalidate(notificationsProvider);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not mark all read. Try again.'),
                    ),
                  );
                }
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: session == null
          ? const WbEmptyState(
              icon: Icons.notifications_none,
              title: 'Sign in to see activity',
              message: 'Follows, feedback and list updates land here.',
            )
          : items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => WbErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(notificationsProvider),
              ),
              data: (notifications) => notifications.isEmpty
                  ? const WbEmptyState(
                      icon: Icons.notifications_none,
                      title: 'No activity yet',
                      message:
                          'Follow Tasters and publish recommendations to get things moving.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(notificationsProvider),
                      child: ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, i) {
                          final n = notifications[i];
                          return ListTile(
                            tileColor: n.unread
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.05)
                                : null,
                            leading: n.actorAvatarUrl != null
                                ? CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                      n.actorAvatarUrl!,
                                    ),
                                  )
                                : CircleAvatar(child: Icon(_icon(n.type))),
                            title: Text(
                              _label(n),
                              style: TextStyle(
                                fontWeight: n.unread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat.yMMMd().add_jm().format(n.createdAt),
                            ),
                            trailing: n.unread
                                ? const Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: WbColors.ember,
                                  )
                                : null,
                            onTap: () async {
                              final repo = ref.read(
                                notificationRepositoryProvider,
                              );
                              try {
                                await repo.markRead(n.id);
                                ref.invalidate(notificationsProvider);
                                final target = await repo.resolveTarget(n);
                                if (!context.mounted) return;
                                if (target != null) {
                                  unawaited(
                                    context.pushNamed(
                                      target.$1,
                                      pathParameters: target.$2,
                                    ),
                                  );
                                } else if (n.type == 'badge') {
                                  // Badges live on the profile tab.
                                  context.goNamed(Routes.profile);
                                }
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open that notification.',
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
            ),
    );
  }
}
