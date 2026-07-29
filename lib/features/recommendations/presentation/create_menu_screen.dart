import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../restaurants/presentation/restaurant_actions.dart';
import '../../restaurants/presentation/widgets/restaurant_picker_sheet.dart';

/// Create hub: recommend, list, photos, visited.
class CreateMenuScreen extends ConsumerWidget {
  const CreateMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: ListView(
        padding: const EdgeInsets.all(WbSpacing.md),
        children: [
          _CreateAction(
            icon: Icons.rate_review_outlined,
            title: 'Recommend a restaurant',
            subtitle: 'Tell people why this place is worth the trip',
            onTap: () => context.pushNamed(Routes.createRecommendation),
          ),
          const SizedBox(height: WbSpacing.sm),
          _CreateAction(
            icon: Icons.playlist_add_outlined,
            title: 'Create a list',
            subtitle: 'Curate places like a playlist',
            onTap: () => context.pushNamed(Routes.createList),
          ),
          const SizedBox(height: WbSpacing.sm),
          _CreateAction(
            icon: Icons.add_a_photo_outlined,
            title: 'Add photos',
            subtitle: 'Share what you actually ate, with a quick rec',
            onTap: () => context.pushNamed(Routes.createRecommendation),
          ),
          const SizedBox(height: WbSpacing.sm),
          _CreateAction(
            icon: Icons.where_to_vote_outlined,
            title: 'Mark a restaurant visited',
            subtitle: 'Grow your personal food map',
            onTap: () async {
              final picked = await showRestaurantPicker(context);
              if (picked == null) return;
              final visited = ref.read(visitedIdsProvider).value ?? <String>{};
              if (visited.contains(picked.id)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${picked.name} is already on your map.'),
                    ),
                  );
                }
                return;
              }
              await ref.read(visitedIdsProvider.notifier).toggle(picked.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${picked.name} marked visited.')),
                );
              }
            },
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
