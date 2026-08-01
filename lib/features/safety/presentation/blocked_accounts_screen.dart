import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/wb_states.dart';
import '../data/safety_repository.dart';

/// The list of accounts the signed-in user has blocked.
///
/// Only ever shows blocks the user themselves created. Whether anyone has
/// blocked *them* is deliberately not answerable anywhere in the app.
class BlockedAccountsScreen extends ConsumerWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked accounts')),
      body: blocked.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => WbErrorState(
          message: 'Could not load your blocked accounts.',
          onRetry: () => ref.invalidate(blockedAccountsProvider),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const WbEmptyState(
              icon: Icons.block,
              title: 'No blocked accounts',
              message:
                  'When you block someone they cannot follow you or interact '
                  'with what you post, and you stop seeing them around the app.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: WbSpacing.sm),
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = accounts[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (a.avatarUrl != null && a.avatarUrl!.isNotEmpty)
                      ? NetworkImage(a.avatarUrl!)
                      : null,
                  child: (a.avatarUrl == null || a.avatarUrl!.isEmpty)
                      ? Text(
                          a.displayName.isNotEmpty
                              ? a.displayName.characters.first.toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                title: Text(
                  a.displayName.isNotEmpty ? a.displayName : a.username,
                ),
                subtitle: Text('@${a.username}'),
                trailing: TextButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref
                          .read(safetyRepositoryProvider)
                          .unblock(a.id);
                      ref.invalidate(blockedAccountsProvider);
                      ref.invalidate(isBlockedProvider(a.id));
                      messenger.showSnackBar(
                        SnackBar(content: Text('Unblocked @${a.username}')),
                      );
                    } on AppException {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Could not unblock. Try again.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
