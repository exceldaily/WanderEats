import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/wb_states.dart';

/// Notifications inbox. Milestone 7 adds grouped items, read state and
/// deep links.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: const WbEmptyState(
        icon: Icons.notifications_none,
        title: 'No activity yet',
        message: 'Follow Tasters and cities to see updates here.',
      ),
    );
  }
}
