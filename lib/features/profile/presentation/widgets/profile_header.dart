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
                        errorWidget: (_, _, _) =>
                            _BrandBanner(bannerStyle: profile.bannerStyle),
                      )
                    : _BrandBanner(bannerStyle: profile.bannerStyle),
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
                  // Sample accounts are labelled wherever they appear: the
                  // product is about trusting real people's taste, so an
                  // invented Taster must never read as a real one.
                  if (profile.isDemo)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: DemoBadge(),
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

/// The selectable color palettes. Order here is display order in the edit
/// screen; every pair keeps the faint glyph texture readable.
const kBannerColors = [
  'voyage',
  'ember',
  'gold',
  'aqua',
  'night',
  'berry',
  'herb',
  'sunset',
];

({Color a, Color b}) bannerPalette(String color) => switch (color) {
  'ember' => (a: const Color(0xFFB3402A), b: WbColors.ember),
  'gold' => (a: const Color(0xFF9A6A0F), b: WbColors.warning),
  'aqua' => (a: const Color(0xFF2E6E75), b: const Color(0xFF6FA8AD)),
  'night' => (a: WbColors.nightSurface, b: const Color(0xFF34413B)),
  'berry' => (a: const Color(0xFF6B2D5C), b: const Color(0xFFB5507E)),
  'herb' => (a: const Color(0xFF3D6B3F), b: const Color(0xFF6FA05A)),
  'sunset' => (a: const Color(0xFFB3521E), b: const Color(0xFFE8935A)),
  _ => (a: WbColors.voyage, b: WbColors.voyageLight),
};

/// The selectable banner patterns. Each pairs with any of [kBannerColors], so
/// "design" and "color" are independent choices, not one combined list.
const kBannerDesigns = ['classic', 'ice_cream', 'bbq', 'coffee', 'pizza'];

String bannerDesignLabel(String design) => switch (design) {
  'ice_cream' => 'Ice cream',
  'bbq' => 'BBQ',
  'coffee' => 'Coffee',
  'pizza' => 'Pizza',
  _ => 'Classic',
};

List<IconData> _bannerGlyphs(String design) => switch (design) {
  'ice_cream' => const [Icons.icecream, Icons.icecream_outlined, Icons.cake_outlined],
  'bbq' => const [
    Icons.kebab_dining_outlined,
    Icons.local_fire_department,
    Icons.local_fire_department_outlined,
  ],
  'coffee' => const [
    Icons.emoji_food_beverage_outlined,
    Icons.bakery_dining_outlined,
  ],
  'pizza' => const [Icons.local_pizza_outlined],
  _ => const [
    Icons.ramen_dining_outlined,
    Icons.local_pizza_outlined,
    Icons.bakery_dining_outlined,
    Icons.emoji_food_beverage_outlined,
    Icons.kebab_dining_outlined,
    Icons.icecream_outlined,
  ],
};

/// `banner_style` is stored as `'<design>:<color>'`, e.g. `'bbq:ember'`. Every
/// row is backfilled to this shape (see migration 0020), so a value with no
/// colon is unexpected rather than a supported legacy case - it still falls
/// back safely rather than crashing a profile page over a stray value.
({String design, String color}) parseBannerStyle(String raw) {
  final i = raw.indexOf(':');
  if (i < 0) return (design: 'classic', color: raw);
  return (design: raw.substring(0, i), color: raw.substring(i + 1));
}

String composeBannerStyle(String design, String color) => '$design:$color';

/// Fallback cover: a quiet brand wash in the user's chosen color with a faint
/// scatter of glyphs matching their chosen design. Branded and restrained,
/// never a gray hole.
class _BrandBanner extends StatelessWidget {
  const _BrandBanner({required this.bannerStyle});

  final String bannerStyle;

  @override
  Widget build(BuildContext context) {
    final parsed = parseBannerStyle(bannerStyle);
    final palette = bannerPalette(parsed.color);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.a, palette.b],
        ),
      ),
      child: ClipRect(
        child: CustomPaint(
          painter: _GlyphPainter(_bannerGlyphs(parsed.design)),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Color swatch for the edit screen: a solid gradient dot, no pattern - the
/// pattern is chosen separately via [BannerDesignSwatch].
class BannerColorSwatch extends StatelessWidget {
  const BannerColorSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = bannerPalette(color);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Banner color $color',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WbRadius.chip),
        child: Container(
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [palette.a, palette.b]),
            borderRadius: BorderRadius.circular(WbRadius.chip),
            border: Border.all(
              width: selected ? 2.5 : 1,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

/// Design swatch for the edit screen: renders the actual pattern in the
/// currently-selected color, so picking a design previews it the way it will
/// really look rather than as a bare label.
class BannerDesignSwatch extends StatelessWidget {
  const BannerDesignSwatch({
    super.key,
    required this.design,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String design;
  final String color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Banner design ${bannerDesignLabel(design)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WbRadius.chip),
        child: Container(
          width: 76,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WbRadius.chip),
            border: Border.all(
              width: selected ? 2.5 : 1,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(WbRadius.chip - 3),
                child: SizedBox(
                  height: 40,
                  child: _BrandBanner(
                    bannerStyle: composeBannerStyle(design, color),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                bannerDesignLabel(design),
                style: theme.textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyphs);

  final List<IconData> glyphs;

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed grid, faint white: texture rather than decoration.
    var i = 0;
    for (double y = 14; y < size.height; y += 52) {
      for (double x = 18 + (i.isEven ? 0 : 34); x < size.width; x += 72) {
        final icon = glyphs[(i + (x ~/ 72)) % glyphs.length];
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
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.glyphs != glyphs;
}

/// Marks a sample account. Deliberately plain and always paired with the word
/// "Sample" - a colour or icon alone would not communicate this.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Sample account. Not a real person.',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 7,
          vertical: compact ? 1 : 2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(WbRadius.pill),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          'Sample',
          style:
              (compact
                      ? theme.textTheme.labelSmall
                      : theme.textTheme.labelMedium)
                  ?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
        ),
      ),
    );
  }
}
