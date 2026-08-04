import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/widgets/wb_states.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/taste_group_repository.dart';
import '../domain/taste_group_models.dart';

/// One Taste Group: members, picks, join/leave, add a pick.
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(tasteGroupsProvider);
    final group = groups.value?.where((g) => g.id == groupId).firstOrNull;
    final members = ref.watch(groupMembersProvider(groupId));
    final picks = ref.watch(groupPicksProvider(groupId));
    final myId = ref.watch(sessionProvider)?.user.id;

    void refreshAll() {
      ref
        ..invalidate(tasteGroupsProvider)
        ..invalidate(groupMembersProvider(groupId))
        ..invalidate(groupPicksProvider(groupId));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group == null ? 'Taste Group' : '${group.emoji ?? ''} ${group.name}'.trim(),
        ),
        actions: [
          if (group != null && group.isMember)
            TextButton(
              onPressed: () => _leave(context, ref, group),
              child: Text(group.isOwner ? 'Delete' : 'Leave'),
            ),
        ],
      ),
      floatingActionButton: group != null && group.isMember
          ? FloatingActionButton.extended(
              onPressed: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => _AddPickSheet(groupId: groupId),
                );
                refreshAll();
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add pick'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => refreshAll(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            if (group?.description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  WbSpacing.md,
                  WbSpacing.md,
                  WbSpacing.md,
                  0,
                ),
                child: Text(group!.description!),
              ),
            if (group != null && !group.isMember)
              Padding(
                padding: const EdgeInsets.all(WbSpacing.md),
                child: FilledButton.icon(
                  onPressed: () => _join(context, ref, refreshAll),
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Join group'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WbSpacing.md,
                WbSpacing.md,
                WbSpacing.md,
                WbSpacing.xs,
              ),
              child: Text(
                'Members',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(
              height: 92,
              child: members.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(WbSpacing.md),
                  child: WbSkeleton(height: 60),
                ),
                error: (e, _) => const SizedBox.shrink(),
                data: (list) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: WbSpacing.md),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: WbSpacing.md),
                  itemBuilder: (context, i) {
                    final m = list[i];
                    return InkWell(
                      onTap: () => context.pushNamed(
                        Routes.taster,
                        pathParameters: {'id': m.userId},
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: m.avatarUrl == null
                                ? null
                                : CachedNetworkImageProvider(m.avatarUrl!),
                            child: m.avatarUrl == null
                                ? Text(
                                    m.displayName.isEmpty
                                        ? '?'
                                        : m.displayName[0],
                                  )
                                : null,
                          ),
                          const SizedBox(height: WbSpacing.xs),
                          SizedBox(
                            width: 64,
                            child: Text(
                              m.isOwner ? '👑 ${m.displayName}' : m.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WbSpacing.md,
                WbSpacing.md,
                WbSpacing.md,
                WbSpacing.xs,
              ),
              child: Text(
                'Group picks',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            picks.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(WbSpacing.md),
                child: WbSkeleton(height: 72),
              ),
              error: (e, _) => WbErrorState(
                message: 'Picks could not be loaded.',
                onRetry: () => ref.invalidate(groupPicksProvider(groupId)),
              ),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(WbSpacing.lg),
                      child: WbEmptyState(
                        icon: Icons.restaurant_outlined,
                        title: 'No picks yet',
                        message: 'Members add the places this crew swears by.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final pick in list)
                          ListTile(
                            leading: const Icon(Icons.restaurant_outlined),
                            title: Text(
                              pick.restaurantName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: pick.note == null
                                ? null
                                : Text(
                                    pick.note!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            trailing:
                                (pick.addedBy == myId ||
                                    (group?.isOwner ?? false))
                                ? IconButton(
                                    tooltip: 'Remove pick',
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () async {
                                      await ref
                                          .read(tasteGroupRepositoryProvider)
                                          .removePick(pick.id);
                                      refreshAll();
                                    },
                                  )
                                : null,
                            onTap: () => context.pushNamed(
                              Routes.restaurant,
                              pathParameters: {'id': pick.restaurantId},
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join(
    BuildContext context,
    WidgetRef ref,
    VoidCallback refreshAll,
  ) async {
    try {
      await ref.read(tasteGroupRepositoryProvider).join(groupId);
      refreshAll();
    } on GroupException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not join the group.')),
      );
    }
  }

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    TasteGroup group,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.isOwner ? 'Delete this group?' : 'Leave this group?'),
        content: Text(
          group.isOwner
              ? 'You created it, so leaving deletes it for every member.'
              : 'You can rejoin any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(group.isOwner ? 'Delete' : 'Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(tasteGroupRepositoryProvider).leave(groupId);
    ref.invalidate(tasteGroupsProvider);
    if (context.mounted) context.pop();
  }
}

class _AddPickSheet extends ConsumerStatefulWidget {
  const _AddPickSheet({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_AddPickSheet> createState() => _AddPickSheetState();
}

class _AddPickSheetState extends ConsumerState<_AddPickSheet> {
  final _query = TextEditingController();
  final _note = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = const [];
  String? _selectedId;
  String? _selectedName;
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _note.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final rows = await ref
          .read(tasteGroupRepositoryProvider)
          .searchRestaurants(value);
      if (mounted) setState(() => _results = rows);
    });
  }

  Future<void> _submit() async {
    final id = _selectedId;
    if (id == null || _busy) return;
    setState(() => _busy = true);
    try {
      final added = await ref
          .read(tasteGroupRepositoryProvider)
          .addPick(
            widget.groupId,
            id,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That place is already picked.')),
        );
      }
    } on GroupException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
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
          Text('Add a pick', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: WbSpacing.md),
          TextField(
            controller: _query,
            decoration: const InputDecoration(
              labelText: 'Search restaurants',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: WbSpacing.sm),
          SizedBox(
            height: 180,
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'Search for a place the group should know about.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final r = _results[i];
                      final id = r['id'] as String;
                      return ListTile(
                        dense: true,
                        title: Text(r['name'] as String? ?? ''),
                        trailing: _selectedId == id
                            ? const Icon(Icons.check_circle,
                                color: WbColors.success)
                            : null,
                        onTap: () => setState(() {
                          _selectedId = id;
                          _selectedName = r['name'] as String?;
                        }),
                      );
                    },
                  ),
          ),
          TextField(
            controller: _note,
            maxLength: 280,
            decoration: InputDecoration(
              labelText: _selectedName == null
                  ? 'Why this place? (optional)'
                  : 'Why $_selectedName? (optional)',
              counterText: '',
            ),
          ),
          const SizedBox(height: WbSpacing.sm),
          FilledButton(
            onPressed: _selectedId == null || _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add to group'),
          ),
        ],
      ),
    );
  }
}
