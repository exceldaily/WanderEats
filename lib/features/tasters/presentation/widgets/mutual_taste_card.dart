import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../app/theme/wb_tokens.dart';
import '../../../../core/networking/supabase_provider.dart';
import '../../../profile/presentation/widgets/taste_tags.dart';

/// Real overlap between the signed-in viewer and this profile, computed
/// server-side. Empty result → the whole section stays invisible; nothing
/// here is ever fabricated to fill space.
final mutualTasteProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, otherId) async {
      try {
        return await ref
            .watch(wbSchemaProvider)
            .rpc<Map<String, dynamic>>(
              'mutual_taste',
              params: {'other': otherId},
            );
      } on PostgrestException {
        return const {};
      }
    });

/// "You both love…" — a small warm card listing genuine shared taste.
class MutualTasteCard extends ConsumerWidget {
  const MutualTasteCard({super.key, required this.tasterId});

  final String tasterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = ref.watch(mutualTasteProvider(tasterId)).value;
    if (data == null || data.isEmpty) return const SizedBox.shrink();

    final sharedTags = ((data['shared_tags'] as List?) ?? const [])
        .whereType<String>()
        .toList();
    final sameCuisine = data['same_cuisine'] as String?;
    final bothSaved = (data['both_saved'] as num?)?.toInt() ?? 0;
    final savedTheirRecs = (data['i_saved_their_recs'] as num?)?.toInt() ?? 0;

    final lines = <(IconData, String)>[
      if (sameCuisine != null)
        (Icons.ramen_dining_outlined, 'You both love $sameCuisine food'),
      if (bothSaved > 0)
        (
          Icons.bookmark_outline,
          bothSaved == 1
              ? 'You both saved the same restaurant'
              : 'You both saved $bothSaved of the same restaurants',
        ),
      if (savedTheirRecs > 0)
        (
          Icons.rate_review_outlined,
          savedTheirRecs == 1
              ? 'You saved a place they recommend'
              : 'You saved $savedTheirRecs places they recommend',
        ),
    ];

    if (sharedTags.isEmpty && lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: WbSpacing.sm + 4),
      child: Card(
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
                  const Icon(
                    Icons.favorite_outline,
                    size: 18,
                    color: WbColors.ember,
                  ),
                  const SizedBox(width: WbSpacing.sm),
                  Text(
                    'You both love…',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (sharedTags.isNotEmpty) ...[
                const SizedBox(height: WbSpacing.sm),
                TasteTags(tags: sharedTags, maxVisible: 4),
              ],
              for (final (icon, text) in lines) ...[
                const SizedBox(height: WbSpacing.sm),
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: WbSpacing.sm),
                    Expanded(
                      child: Text(text, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
