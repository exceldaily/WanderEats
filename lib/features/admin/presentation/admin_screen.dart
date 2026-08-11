import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/wb_states.dart';
import '../data/admin_repository.dart';

/// Support panel, reachable only from the admin row in Settings (which only
/// renders for is_admin accounts). Every action here is re-checked by the
/// database, so the screen is a convenience, not the security boundary.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin tools'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: const TabBarView(children: [_UsersTab(), _ReportsTab()]),
      ),
    );
  }
}

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<AdminUser> _results = const [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _run);
  }

  Future<void> _run() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final rows = await ref
          .read(adminRepositoryProvider)
          .search(_query.text);
      if (mounted) setState(() => _results = rows);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _act(Future<void> Function() action, String done) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(done)));
      await _run();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(adminRepositoryProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(WbSpacing.md),
          child: TextField(
            controller: _query,
            decoration: InputDecoration(
              labelText: 'Search by username, name, or email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: _search,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: WbSpacing.md),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: _results.isEmpty
              ? const WbEmptyState(
                  icon: Icons.support_agent_outlined,
                  title: 'Find an account',
                  message:
                      'Search for whoever needs help. Email search included.',
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final u = _results[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: WbSpacing.md,
                        vertical: WbSpacing.xs,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(WbSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${u.displayName} (@${u.username})',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) => switch (action) {
                                    'suspend' => _act(
                                      () => repo.setSuspended(
                                        u.id,
                                        !u.isSuspended,
                                      ),
                                      u.isSuspended
                                          ? 'Account unsuspended'
                                          : 'Account suspended',
                                    ),
                                    'comp' => _act(
                                      () => u.isPremium
                                          ? repo.revokeComp(u.id)
                                          : repo.grantComp(u.id),
                                      u.isPremium
                                          ? 'Comp revoked'
                                          : 'Premium comp granted',
                                    ),
                                    'dob' => _setDob(u),
                                    _ => null,
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'suspend',
                                      child: Text(
                                        u.isSuspended
                                            ? 'Unsuspend account'
                                            : 'Suspend account',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'comp',
                                      child: Text(
                                        u.isPremium
                                            ? 'Revoke premium comp'
                                            : 'Grant premium comp',
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'dob',
                                      child: Text('Set date of birth'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              u.email,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: WbSpacing.xs),
                            Wrap(
                              spacing: WbSpacing.xs,
                              children: [
                                if (u.isPremium)
                                  const _Tag('Premium', WbColors.warning),
                                if (u.ageConfirmed)
                                  _Tag(
                                    u.isAdult ? 'Adult' : 'Minor',
                                    u.isAdult
                                        ? WbColors.success
                                        : WbColors.danger,
                                  )
                                else
                                  const _Tag('Age unconfirmed', null),
                                if (u.isSuspended)
                                  const _Tag('Suspended', WbColors.danger),
                                if (u.isDemo) const _Tag('Demo', null),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _setDob(AdminUser u) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date of birth for @${u.username}',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    await _act(
      () => ref.read(adminRepositoryProvider).setDateOfBirth(u.id, picked),
      'Date of birth updated',
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(WbRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c),
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminReportsProvider.future),
      child: reports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WbErrorState(
          message: 'Reports could not be loaded.',
          onRetry: () => ref.invalidate(adminReportsProvider),
        ),
        data: (list) => list.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  WbEmptyState(
                    icon: Icons.shield_outlined,
                    title: 'No open reports',
                    message: 'A quiet queue is a healthy community.',
                  ),
                ],
              )
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final r = list[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: WbSpacing.md,
                      vertical: WbSpacing.xs,
                    ),
                    child: ListTile(
                      title: Text('${r.reason} · ${r.targetType}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (r.reportedUsername != null)
                            Text('About @${r.reportedUsername}'),
                          if (r.reporterUsername != null)
                            Text('Reported by @${r.reporterUsername}'),
                          if (r.details != null &&
                              r.details!.trim().isNotEmpty)
                            Text(
                              r.details!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (status) async {
                          await ref
                              .read(adminRepositoryProvider)
                              .resolveReport(r.id, status);
                          ref.invalidate(adminReportsProvider);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'actioned',
                            child: Text('Mark actioned'),
                          ),
                          PopupMenuItem(
                            value: 'dismissed',
                            child: Text('Dismiss'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
