import 'package:flutter/material.dart';

import '../../../../app/theme/wb_tokens.dart';

/// The five personality fields we render, in display order. Stored as flat
/// keys in profiles.taste_personality; absent keys simply do not render.
const kPersonalityFields = [
  (key: 'flavor', label: 'Flavor', icon: Icons.bolt_outlined),
  (key: 'spice', label: 'Spice', icon: Icons.local_fire_department_outlined),
  (key: 'dining_style', label: 'Dining style', icon: Icons.deck_outlined),
  (
    key: 'favorite_cuisine',
    label: 'Favorite cuisine',
    icon: Icons.ramen_dining_outlined,
  ),
  (key: 'attitude', label: 'Food attitude', icon: Icons.explore_outlined),
];

/// Spice gets a tiny 3-step scale on top of the text value, because "Hot"
/// alone undersells it. Never the only signal: the text value stays.
int? spiceSteps(String? value) => switch (value?.toLowerCase()) {
  'mild' => 1,
  'medium' => 2,
  'hot' || 'very hot' || 'extra hot' => 3,
  _ => null,
};

/// "Taste Personality": one compact card that answers "how does this person
/// like to eat?" without reading like a questionnaire.
class TastePersonalityCard extends StatelessWidget {
  const TastePersonalityCard({
    super.key,
    required this.personality,
    this.onEdit,
  });

  final Map<String, dynamic> personality;

  /// Present only on the current user's own profile.
  final VoidCallback? onEdit;

  bool get _isEmpty => kPersonalityFields.every(
    (f) => (personality[f.key] as String?)?.trim().isEmpty ?? true,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WbRadius.card),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WbSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: WbSpacing.sm),
                Expanded(
                  child: Text(
                    'Taste Personality',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Edit taste personality',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: WbSpacing.sm),
            if (_isEmpty)
              onEdit == null
                  ? Text(
                      'No taste profile yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tell people how you like to eat — flavor, spice, '
                          'style.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: WbSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Set up your taste profile'),
                        ),
                      ],
                    )
            else
              Wrap(
                spacing: WbSpacing.lg,
                runSpacing: WbSpacing.sm + 2,
                children: [
                  for (final f in kPersonalityFields)
                    if ((personality[f.key] as String?)?.trim().isNotEmpty ??
                        false)
                      _PersonalityEntry(
                        icon: f.icon,
                        label: f.label,
                        value: (personality[f.key] as String).trim(),
                        steps: f.key == 'spice'
                            ? spiceSteps(personality[f.key] as String?)
                            : null,
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonalityEntry extends StatelessWidget {
  const _PersonalityEntry({
    required this.icon,
    required this.label,
    required this.value,
    this.steps,
  });

  final IconData icon;
  final String label;
  final String value;
  final int? steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (steps != null) ...[
                  const SizedBox(width: 6),
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: i < steps!
                            ? WbColors.ember
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
