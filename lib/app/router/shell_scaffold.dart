import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// Persistent bottom navigation around the five tab branches.
/// IndexedStack in StatefulShellRoute preserves each tab's state.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.navMap,
            tooltip: l10n.navMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: l10n.navDiscover,
            tooltip: l10n.navDiscover,
          ),
          NavigationDestination(
            // The create action gets stronger visual emphasis: filled circle.
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: scheme.secondary,
              child: const Icon(Icons.add, size: 20, color: Colors.white),
            ),
            label: l10n.navCreate,
            tooltip: l10n.navCreate,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications),
            label: l10n.navActivity,
            tooltip: l10n.navActivity,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
            tooltip: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
