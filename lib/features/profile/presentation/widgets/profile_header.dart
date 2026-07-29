import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/wb_tokens.dart';
import '../../../../core/networking/supabase_provider.dart';
import '../../domain/profile.dart';
import 'taste_tags.dart';

/// City name lookup for the location line; null id or a failed fetch simply
/// hides the row, never blocks the header.
final _cityNameProvider = FutureProvider.autoDispose.family<String?, String>((
  ref,
  cityId,
) async {
  try {
    final row = await ref
        .watch(wbSchemaProvider)
        .from('cities')
        .select('name, countries(name)')
        .eq('id', cityId)
        .maybeSingle();
    if (row == null) return null;
    final city = row['name'] as String?;
    final country = (row['countries'] as Map?)?['name'] as String?;
    return [city, country].whereType<String>().join(', ');
  } catch (_) {
    return null;
  }
});

/// Shared profile header for both the current user's profile and public
/// Taster profiles: compact cover banner, avatar overlapping its bottom edge,
/// identity block, taste tags, and a caller-provided action slot (Edit /
/// Follow+Share).
class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.actions,
    this.bannerHeight = 112,
  });

  final Profile profile;
  final List<Widget> actions;
  final double bannerHeight;

  static const double _avatarRadius = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cityId = profile.homeCityId;
    final location = cityId == null
        ? null
        : ref.watch(_cityNameProvider(cityId)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner + overlapping avatar. Banner stays short so content starts
        // quickly; fallback is a quiet brand gradient, not a gray hole.
        SizedBox(
          height: bannerHeight + _avatarRadius,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: bannerHeight,
                child: profile.headerUrl != null
                    ? CachedNetworkImage(
                        imageUrl: profile.headerUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const _BrandBanner(),
                      )
                    : const _BrandBanner(),
              ),
              Positioned(
                left: WbSpacing.md,
                bottom: 0,
                child: Semantics(
                  image: true,
                  label: 'Profile photo of ${profile.displayName}',
                  child: CircleAvatar(
                    radius: _avatarRadius + 3,
                    backgroundColor: theme.colorScheme.surface,
                    child: CircleAvatar(
                      radius: _avatarRadius,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: profile.avatarUrl == null
                          ? null
                          : CachedNetworkImageProvider(profile.avatarUrl!),
                      child: profile.avatarUrl == null
                          ? Text(
                              profile.displayName.characters.first
                                  .toUpperCase(),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              // Actions sit on the banner's bottom edge, right side.
              Positioned(
                right: WbSpacing.md,
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, a) in actions.indexed) ...[
                      if (i > 0) const SizedBox(width: WbSpacing.sm),
                      a,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            WbSpacing.md,
            WbSpacing.sm,
            WbSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (profile.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.verified,
                        color: WbColors.voyageLight,
                        size: 20,
                        semanticLabel: 'Verified Taster',
                      ),
                    ),
                ],
              ),
              Text(
                '@${profile.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (location != null && location.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: WbSpacing.sm),
                Text(
                  profile.bio!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (profile.tasteTags.isNotEmpty) ...[
                const SizedBox(height: WbSpacing.sm + 2),
                TasteTags(tags: profile.tasteTags),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Fallback cover: a quiet voyage-teal wash with a faint scatter of food
/// glyphs. Branded, restrained, and identical for everyone without a photo.
class _BrandBanner extends StatelessWidget {
  const _BrandBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WbColors.voyage, WbColors.voyageLight],
        ),
      ),
      child: ClipRect(
        child: CustomPaint(painter: _GlyphPainter(), size: Size.infinite),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  static const _glyphs = [
    Icons.ramen_dining_outlined,
    Icons.local_pizza_outlined,
    Icons.bakery_dining_outlined,
    Icons.emoji_food_beverage_outlined,
    Icons.kebab_dining_outlined,
    Icons.icecream_outlined,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed grid, faint white: texture rather than decoration.
    var i = 0;
    for (double y = 14; y < size.height; y += 52) {
      for (double x = 18 + (i.isEven ? 0 : 34); x < size.width; x += 72) {
        final icon = _glyphs[(i + (x ~/ 72)) % _glyphs.length];
        final painter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              fontSize: 22,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, Offset(x, y));
      }
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
