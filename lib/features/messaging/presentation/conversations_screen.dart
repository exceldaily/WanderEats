import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/widgets/wb_states.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/messaging_repository.dart';
import '../domain/messaging_models.dart';

/// The inbox. Readable by any signed-in user - someone whose subscription
/// lapsed keeps their history; only sending is premium-gated (by the server).
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(conversationsProvider.future),
        child: conversations.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(WbSpacing.md),
            children: [
              for (var i = 0; i < 6; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: WbSpacing.md),
                  child: Row(
                    children: [
                      WbSkeleton(height: 48, width: 48, radius: 24),
                      SizedBox(width: WbSpacing.md),
                      Expanded(child: WbSkeleton(height: 16)),
                    ],
                  ),
                ),
            ],
          ),
          error: (e, _) => WbErrorState(
            message: 'Messages could not be loaded.',
            onRetry: () => ref.invalidate(conversationsProvider),
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  // ListView so pull-to-refresh works on the empty state too.
                  children: const [
                    SizedBox(height: 120),
                    WbEmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No messages yet',
                      message:
                          'Start a conversation from a Taster\'s profile.',
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      _ConversationTile(conversation: list[i]),
                ),
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = conversation;
    final mine = c.lastMessageSenderId == ref.watch(sessionProvider)?.user.id;
    final preview = c.lastMessageBody == null
        ? ''
        : '${mine ? 'You: ' : ''}${c.lastMessageBody}';
    final hasUnread = c.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage: c.peerAvatarUrl == null
            ? null
            : CachedNetworkImageProvider(c.peerAvatarUrl!),
        child: c.peerAvatarUrl == null
            ? Text(c.peerDisplayName.isEmpty ? '?' : c.peerDisplayName[0])
            : null,
      ),
      title: Text(
        c.peerDisplayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: hasUnread
            ? const TextStyle(fontWeight: FontWeight.w700)
            : null,
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: hasUnread
            ? TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              )
            : null,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (c.lastMessageAt != null)
            Text(_relative(c.lastMessageAt!), style: theme.textTheme.bodySmall),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(
                color: WbColors.ember,
                borderRadius: BorderRadius.all(Radius.circular(WbRadius.pill)),
              ),
              child: Text(
                '${c.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () => context.pushNamed(
        Routes.chat,
        pathParameters: {'id': c.id},
        queryParameters: {'peer': c.peerDisplayName},
      ),
    );
  }

  static String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${t.day}/${t.month}/${t.year % 100}';
  }
}
