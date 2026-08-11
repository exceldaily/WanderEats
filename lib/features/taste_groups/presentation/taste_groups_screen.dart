import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/widgets/wb_states.dart';
import '../../premium/data/entitlement_service.dart';
import '../../premium/domain/entitlements.dart';
import '../data/taste_group_repository.dart';
import '../domain/taste_group_models.dart';

/// Browse and create Taste Groups. Joining is free; only creation is the
/// premium capability, so the create button is where the gate lives.
class TasteGroupsScreen extends ConsumerWidget {
  const TasteGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(tasteGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Taste Groups')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('New group'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(tasteGroupsProvider.future),
        child: groups.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(WbSpacing.md),
            children: [
              for (var i = 0; i < 5; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: WbSpacing.md),
                  child: WbSkeleton(height: 72),
                ),
            ],
          ),
          error: (e, _) => WbErrorState(
            message: 'Groups could not be loaded.',
            onRetry: () => ref.invalidate(tasteGroupsProvider),
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    WbEmptyState(
                      icon: Icons.groups_outlined,
                      title: 'No groups yet',
                      message:
                          'Taste Groups are small crews around a shared '
                          'appetite. Start the first one.',
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _GroupTile(group: list[i]),
                ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    // The gate: an adult without premium gets the paywall, everyone else gets
    // the sheet. Age plays no part in group creation, so premiumRequired is
    // the only denial that can appear for a signed-in account.
    final denial = denialFor(ref, PremiumEntitlement.createTasteGroups);
    if (denial != null) {
      if (!context.mounted) return;
      if (denial.canBeSolvedByUpgrading) {
        unawaited(context.pushNamed(Routes.premium));
      } else {
        // Say why the button did nothing rather than appearing dead.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (denial) {
              EntitlementDenial.notSignedIn => 'Sign in to create a group.',
              _ => 'Group creation is not available on this account.',
            }),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreateGroupSheet(),
    );
    ref.invalidate(tasteGroupsProvider);
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});

  final TasteGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Text(group.emoji ?? '🍽️'),
      ),
      title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}'
        ' · ${group.pickCount} pick${group.pickCount == 1 ? '' : 's'}'
        '${group.isMember ? ' · Joined' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.pushNamed(
        Routes.tasteGroup,
        pathParameters: {'id': group.id},
      ),
    );
  }
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _emoji = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _emoji.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 3) {
      setState(() => _error = 'Give your group a name (at least 3 characters).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(tasteGroupRepositoryProvider)
          .create(
            name: name,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            emoji: _emoji.text.trim().isEmpty ? null : _emoji.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      unawaited(
        context.pushNamed(Routes.tasteGroup, pathParameters: {'id': id}),
      );
    } on GroupException catch (e) {
      if (!mounted) return;
      if (e.premiumRequired) {
        Navigator.of(context).pop();
        unawaited(context.pushNamed(Routes.premium));
        return;
      }
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'The group could not be created. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: WbSpacing.lg,
        right: WbSpacing.lg,
        top: WbSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + WbSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Taste Group',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: WbSpacing.md),
          Row(
            children: [
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _emoji,
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Emoji',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: WbSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WbSpacing.sm),
          TextField(
            controller: _description,
            maxLength: 280,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'What is this crew about? (optional)',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: WbSpacing.xs),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: WbSpacing.md),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create group'),
          ),
        ],
      ),
    );
  }
}
