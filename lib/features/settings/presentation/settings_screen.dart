import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../premium/data/entitlement_service.dart';
import '../../premium/domain/entitlements.dart';
import '../../profile/data/profile_repository.dart';
import '../../safety/presentation/blocked_accounts_screen.dart';

/// Public site. Play requires a reachable privacy policy and a data-deletion
/// page, and linking them from Settings is what reviewers look for.
const _siteBase = 'https://wanderbites-gamma.vercel.app';

final settingsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  return ref.watch(profileRepositoryProvider).fetchSettings(session.user.id);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _update(WidgetRef ref, String key, Object? value) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    await ref.read(profileRepositoryProvider).updateSettings(session.user.id, {
      key: value,
    });
    ref.invalidate(settingsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final l10n = AppLocalizations.of(context);
    bool flag(String key, [bool fallback = true]) =>
        (settings?[key] as bool?) ?? fallback;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: WbSpacing.sm),
              children: [
                _Header(l10n.settingsNotifications),
                SwitchListTile(
                  title: Text(l10n.settingsPushNotifications),
                  value: flag('push_enabled'),
                  onChanged: (v) => _update(ref, 'push_enabled', v),
                ),
                SwitchListTile(
                  title: Text(l10n.settingsNewFollowers),
                  value: flag('notif_follows'),
                  onChanged: (v) => _update(ref, 'notif_follows', v),
                ),
                SwitchListTile(
                  title: Text(l10n.settingsComments),
                  value: flag('notif_comments'),
                  onChanged: (v) => _update(ref, 'notif_comments', v),
                ),
                SwitchListTile(
                  title: Text(l10n.settingsListActivity),
                  value: flag('notif_list_activity'),
                  onChanged: (v) => _update(ref, 'notif_list_activity', v),
                ),
                SwitchListTile(
                  title: Text(l10n.settingsTasterActivity),
                  value: flag('notif_taster_activity'),
                  onChanged: (v) => _update(ref, 'notif_taster_activity', v),
                ),
                SwitchListTile(
                  title: Text(l10n.settingsBadgeUnlocks),
                  value: flag('notif_badges'),
                  onChanged: (v) => _update(ref, 'notif_badges', v),
                ),
                _Header(l10n.settingsPrivacy),
                SwitchListTile(
                  title: Text(l10n.settingsPublicProfile),
                  subtitle: Text(l10n.settingsPublicProfileSubtitle),
                  value: flag('profile_public'),
                  onChanged: (v) => _update(ref, 'profile_public', v),
                ),
                SwitchListTile(
                  title: Text(l10n.settingsShowVisitedPublicly),
                  value: flag('show_visited_publicly'),
                  onChanged: (v) => _update(ref, 'show_visited_publicly', v),
                ),
                // Sits under Privacy rather than Account: managing who cannot
                // reach you is a privacy control, and it needs to be somewhere
                // people can find it without already knowing it exists.
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Blocked accounts'),
                  subtitle: const Text('People who cannot interact with you'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BlockedAccountsScreen(),
                    ),
                  ),
                ),
                _Header(l10n.settingsAccount),
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('WanderBites Premium'),
                  // A confirmed minor still may subscribe, but messaging must
                  // never be dangled in front of them as part of the pitch.
                  subtitle: Text(
                    (ref.watch(ageStatusProvider).value?.confirmed ?? false) &&
                            !(ref.watch(ageStatusProvider).value?.adult ??
                                false)
                        ? 'Taste Groups, trip planning and more'
                        : 'Messaging, Taste Groups, trip planning and more',
                  ),
                  onTap: () => context.pushNamed(Routes.premium),
                ),
                const _DateOfBirthTile(),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.settingsEditProfile),
                  onTap: () => context.pushNamed(Routes.editProfile),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.settingsSignOut),
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.goNamed(Routes.welcome);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    l10n.settingsDeleteAccount,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: Text(l10n.settingsDeleteAccountSubtitle),
                  onTap: () => _confirmDelete(context, ref),
                ),
                _Header(l10n.settingsAbout),
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: Text(l10n.settingsPrivacyPolicy),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openSite('/privacy'),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(l10n.settingsDeletionHowItWorks),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openSite('/delete-account'),
                ),
              ],
            ),
    );
  }

  Future<void> _openSite(String path) async {
    await launchUrl(
      Uri.parse('$_siteBase$path'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountDialogTitle),
        content: Text(l10n.deleteAccountDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteForever),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

/// Date-of-birth row. Unconfirmed accounts (anyone who onboarded before the
/// age gate shipped) can set it once; confirmed accounts see a locked state,
/// because self-service edits would defeat the 18+ gate.
class _DateOfBirthTile extends ConsumerWidget {
  const _DateOfBirthTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final age = ref.watch(ageStatusProvider).value ?? const AgeStatus.unknown();
    return ListTile(
      leading: const Icon(Icons.cake_outlined),
      title: const Text('Date of birth'),
      subtitle: Text(
        age.confirmed
            ? 'Confirmed. Contact support to correct it.'
            : 'Confirm your age to unlock 18+ features',
      ),
      trailing: age.confirmed ? const Icon(Icons.lock_outline, size: 18) : null,
      onTap: age.confirmed ? null : () => _confirm(context, ref),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'When were you born?',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null || !context.mounted) return;
    // Mirrors the server trigger so the refusal is friendly instead of a
    // generic server error.
    if (picked.isAfter(DateTime(now.year - 13, now.month, now.day))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WanderBites requires users to be at least 13 years old.'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm your date of birth'),
        content: Text(
          '${MaterialLocalizations.of(context).formatFullDate(picked)}\n\n'
          'This cannot be changed later without contacting support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(entitlementServiceProvider)
          .confirmDateOfBirth(session.user.id, picked);
      ref.invalidate(ageStatusProvider);
      ref.invalidate(entitlementsProvider);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
        WbSpacing.md,
        WbSpacing.md,
        WbSpacing.md,
        WbSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
