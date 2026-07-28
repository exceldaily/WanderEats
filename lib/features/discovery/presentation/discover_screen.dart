import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/wb_states.dart';

/// Discover surface. Milestone 6 fills this with modular sections
/// (Trending Tasters, Hidden Gems, Popular Near You, ...).
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: const WbEmptyState(
        icon: Icons.explore_outlined,
        title: 'Discovery is being seeded',
        message: 'Trending Tasters and hidden gems appear here soon.',
      ),
    );
  }
}
