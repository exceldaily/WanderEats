import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../profile/data/profile_repository.dart';

final settingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  return ref.watch(profileRepositoryProvider).fetchSettings(session.user.id);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _update(
      WidgetRef ref, String key, Object? value) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    await ref
        .read(profileRepositoryProvider)
        .updateSettings(session.user.id, {key: value});
    ref.invalidate(settingsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    bool flag(String key, [bool fallback = true]) =>
        (settings?[key] as bool?) ?? fallback;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: WbSpacing.sm),
              children: [
                const _Header('Notifications'),
                SwitchListTile(
                  title: const Text('Push notifications'),
                  value: flag('push_enabled'),
                  onChanged: (v) => _update(ref, 'push_enabled', v),
                ),
                SwitchListTile(
                  title: const Text('New followers'),
                  value: flag('notif_follows'),
                  onChanged: (v) => _update(ref, 'notif_follows', v),
                ),
                SwitchListTile(
                  title: const Text('Comments'),
                  value: flag('notif_comments'),
                  onChanged: (v) => _update(ref, 'notif_comments', v),
                ),
                SwitchListTile(
                  title: const Text('List activity'),
                  value: flag('notif_list_activity'),
                  onChanged: (v) => _update(ref, 'notif_list_activity', v),
                ),
                SwitchListTile(
                  title: const Text('Taster activity'),
                  value: flag('notif_taster_activity'),
                  onChanged: (v) =>
                      _update(ref, 'notif_taster_activity', v),
                ),
                SwitchListTile(
                  title: const Text('Badge unlocks'),
                  value: flag('notif_badges'),
                  onChanged: (v) => _update(ref, 'notif_badges', v),
                ),
                const _Header('Privacy'),
                SwitchListTile(
                  title: const Text('Public profile'),
                  subtitle:
                      const Text('Others can view your profile and maps'),
                  value: flag('profile_public'),
                  onChanged: (v) => _update(ref, 'profile_public', v),
                ),
                SwitchListTile(
                  title: const Text('Show visited places publicly'),
                  value: flag('show_visited_publicly'),
                  onChanged: (v) =>
                      _update(ref, 'show_visited_publicly', v),
                ),
                const _Header('Account'),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit profile'),
                  onTap: () => context.pushNamed(Routes.editProfile),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.goNamed(Routes.welcome);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined,
                      color: Theme.of(context).colorScheme.error),
                  title: Text('Delete account',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  subtitle: const Text(
                      'Removes your WanderBites profile, recommendations, lists and photos'),
                  onTap: () => _confirmDelete(context, ref),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
            'This permanently removes your WanderBites profile and everything you have published. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (context.mounted) context.goNamed(Routes.welcome);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WbSpacing.md, WbSpacing.md, WbSpacing.md, WbSpacing.xs),
      child: Text(title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}
