import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/wb_states.dart';

/// Current-user profile. Milestone 7 builds the personal food map, stats,
/// badges and settings entry points; Milestone 3 gates it behind auth.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const WbEmptyState(
        icon: Icons.person_outline,
        title: 'Sign in to build your food map',
        message: 'Save places, follow Tasters and publish recommendations.',
      ),
    );
  }
}
