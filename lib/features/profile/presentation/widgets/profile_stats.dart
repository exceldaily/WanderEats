import 'package:flutter/material.dart';

import '../../../../app/theme/wb_tokens.dart';

/// Statistics card: two calm rows instead of five squeezed columns.
///
/// Row one is the social ledger (followers / following / recommendations),
/// row two is exploration (cities / countries) plus the Taster Score, which
/// gets the strongest treatment because it is the app's core currency.
class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key,
    required this.stats,
    this.showFollowing = true,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  final Map<String, dynamic>? stats;
  final bool showFollowing;

  /// When set, the followers / following cells become tappable and open the
  /// corresponding list.
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = stats;

    Widget cell({
      required IconData icon,
      required String label,
      required Object? value,
      Color? emphasis,
      VoidCallback? onTap,
    }) {
      final display = value == null ? '—' : '$value';
      final content = Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: emphasis ?? theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                display,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: emphasis,
                ),
              ),
            ],
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
      return Expanded(
        child: Semantics(
          label: '$label: $display',
          button: onTap != null,
          excludeSemantics: true,
          child: onTap == null
              ? content
              : InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(WbRadius.chip),
                  child: content,
                ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WbRadius.card),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: WbSpacing.md,
          horizontal: WbSpacing.sm,
        ),
        child: Column(
          children: [
            Row(
              children: [
                cell(
                  icon: Icons.group_outlined,
                  label: 'Followers',
                  value: s?['followers'],
                  onTap: onFollowersTap,
                ),
                if (showFollowing)
                  cell(
                    icon: Icons.person_add_alt_outlined,
                    label: 'Following',
                    value: s?['following'],
                    onTap: onFollowingTap,
                  ),
                cell(
                  icon: Icons.rate_review_outlined,
                  label: 'Recommendations',
                  value: s?['recommendations'],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: WbSpacing.sm),
              child: Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            Row(
              children: [
                cell(
                  icon: Icons.location_city_outlined,
                  label: 'Cities',
                  value: s?['cities_explored'],
                ),
                cell(
                  icon: Icons.public_outlined,
                  label: 'Countries',
                  value: s?['countries_visited'],
                ),
                cell(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Taster Score',
                  value: s?['reputation'],
                  emphasis: WbColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
