import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent bottom navigation around the five tab branches.
/// IndexedStack in StatefulShellRoute preserves each tab's state.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
            tooltip: 'Map',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
            tooltip: 'Discover',
          ),
          NavigationDestination(
            // The create action gets stronger visual emphasis: filled circle.
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: scheme.secondary,
              child: const Icon(Icons.add, size: 20, color: Colors.white),
            ),
            label: 'Create',
            tooltip: 'Create',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Activity',
            tooltip: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
            tooltip: 'Profile',
          ),
        ],
      ),
    );
  }
}
