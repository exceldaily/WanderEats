import 'package:flutter/material.dart';

import '../../../../app/theme/wb_tokens.dart';

/// Icon vocabulary for common taste tags. Unknown tags still render cleanly
/// with no icon, so free-form tags never break.
IconData? tasteTagIcon(String tag) {
  final t = tag.toLowerCase();
  if (t.contains('spice') || t.contains('spicy') || t.contains('hot')) {
    return Icons.local_fire_department_outlined;
  }
  if (t.contains('street')) return Icons.storefront_outlined;
  if (t.contains('seafood') || t.contains('fish')) {
    return Icons.set_meal_outlined;
  }
  if (t.contains('dessert') || t.contains('sweet')) {
    return Icons.icecream_outlined;
  }
  if (t.contains('coffee')) return Icons.coffee_outlined;
  if (t.contains('fine')) return Icons.wine_bar_outlined;
  if (t.contains('hidden') || t.contains('gem')) return Icons.diamond_outlined;
  if (t.contains('budget') || t.contains('cheap')) {
    return Icons.savings_outlined;
  }
  if (t.contains('local')) return Icons.place_outlined;
  if (t.contains('bold') || t.contains('flavor')) return Icons.bolt_outlined;
  if (t.contains('anything') || t.contains('adventur')) {
    return Icons.explore_outlined;
  }
  if (t.contains('vegan') || t.contains('veg')) return Icons.eco_outlined;
  if (t.contains('bbq') || t.contains('grill')) {
    return Icons.outdoor_grill_outlined;
  }
  if (t.contains('food')) return Icons.restaurant_outlined;
  return null;
}

/// Compact rounded pills describing what kind of eater someone is.
/// Shows up to [maxVisible] pills then a "+N" overflow chip; the row scrolls
/// horizontally so long translations never wrap into a wall.
class TasteTags extends StatelessWidget {
  const TasteTags({super.key, required this.tags, this.maxVisible = 5});

  final List<String> tags;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final visible = tags.take(maxVisible).toList();
    final overflow = tags.length - visible.length;

    Widget pill(String label, {IconData? icon, bool muted = false}) {
      final bg = muted
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.secondaryContainer;
      final fg = muted
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onSecondaryContainer;
      return Container(
        margin: const EdgeInsets.only(right: WbSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: WbSpacing.sm + 2,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(WbRadius.pill),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: 'Taste tags: ${tags.join(', ')}',
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final tag in visible) pill(tag, icon: tasteTagIcon(tag)),
            if (overflow > 0) pill('+$overflow', muted: true),
          ],
        ),
      ),
    );
  }
}
