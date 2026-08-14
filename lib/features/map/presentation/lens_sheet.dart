import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/wb_tokens.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/map_lens.dart';
import 'map_controller.dart';

/// Picks which map the user is looking at.
///
/// One sheet instead of a row of chips per lens: lenses are mutually
/// exclusive and change what the map *is*, so they deserve a deliberate
/// choice rather than a toolbar the user brushes against.
class LensSheet extends ConsumerWidget {
  const LensSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => const LensSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = ref.watch(mapControllerProvider).lens;
    final signedIn = ref.watch(isSignedInProvider);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: WbSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WbSpacing.lg,
              0,
              WbSpacing.lg,
              WbSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Map lens', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Change what this map is about.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final lens in MapLens.values)
            _LensTile(
              lens: lens,
              selected: lens == current,
              // Personal lenses read from the signed-in user, so offering them
              // signed out would promise a map that cannot exist.
              enabled: signedIn || !lens.requiresAccount,
              onTap: () {
                ref.read(mapControllerProvider.notifier).setLens(lens);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

class _LensTile extends StatelessWidget {
  const _LensTile({
    required this.lens,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final MapLens lens;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      enabled: enabled,
      selected: selected,
      leading: Icon(
        lens.icon,
        color: selected ? theme.colorScheme.primary : null,
      ),
      title: Text(lens.label),
      subtitle: Text(
        enabled ? lens.description : 'Sign in to use this lens',
      ),
      trailing: selected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: enabled ? onTap : null,
    );
  }
}
