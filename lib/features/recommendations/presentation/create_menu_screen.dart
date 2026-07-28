import 'package:flutter/material.dart';

import '../../../app/theme/wb_tokens.dart';

/// Create hub: recommend a restaurant, create a list, add photos, mark
/// visited. Actions are wired to their flows by Milestones 5 and 6.
class CreateMenuScreen extends StatelessWidget {
  const CreateMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: ListView(
        padding: const EdgeInsets.all(WbSpacing.md),
        children: const [
          _CreateAction(
            icon: Icons.rate_review_outlined,
            title: 'Recommend a restaurant',
            subtitle: 'Tell people why this place is worth the trip',
          ),
          SizedBox(height: WbSpacing.sm),
          _CreateAction(
            icon: Icons.playlist_add_outlined,
            title: 'Create a list',
            subtitle: 'Curate places like a playlist',
          ),
          SizedBox(height: WbSpacing.sm),
          _CreateAction(
            icon: Icons.add_a_photo_outlined,
            title: 'Add photos',
            subtitle: 'Share what you actually ate',
          ),
          SizedBox(height: WbSpacing.sm),
          _CreateAction(
            icon: Icons.where_to_vote_outlined,
            title: 'Mark a restaurant visited',
            subtitle: 'Grow your personal food map',
          ),
        ],
      ),
    );
  }
}

class _CreateAction extends StatelessWidget {
  const _CreateAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  // Wired to the create flows in Milestones 5 and 6.
  VoidCallback? get onTap => null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: scheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        minVerticalPadding: WbSpacing.md,
      ),
    );
  }
}
