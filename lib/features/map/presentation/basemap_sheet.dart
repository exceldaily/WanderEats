import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/wb_tokens.dart';
import '../data/map_style_service.dart';
import '../domain/map_basemap.dart';

/// Lets the user pick how the map looks.
///
/// Deliberately a sheet rather than a row of chips on the map: this is a
/// set-once preference, and the map's edges belong to content.
class BasemapSheet extends ConsumerWidget {
  const BasemapSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => const BasemapSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(mapBasemapProvider).value ?? MapBasemap.auto;
    final theme = Theme.of(context);

    return SafeArea(
      child: RadioGroup<MapBasemap>(
        groupValue: current,
        onChanged: (value) {
          if (value == null) return;
          ref.read(mapBasemapProvider.notifier).select(value);
          Navigator.of(context).pop();
        },
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
                  Text('Map style', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Pick what is comfortable to look at. Your choice is kept '
                    'on this device.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (final basemap in MapBasemap.values)
              RadioListTile<MapBasemap>(
                value: basemap,
                title: Text(basemap.label),
                subtitle: Text(basemap.description),
                secondary: _Swatch(basemap: basemap),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small colour chip so the list can be scanned without reading it.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.basemap});

  final MapBasemap basemap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (land, water) = switch (basemap) {
      MapBasemap.auto => dark
          ? (const Color(0xFF121614), const Color(0xFF0E1518))
          : (const Color(0xFFFAF6F0), const Color(0xFFC8D7DC)),
      MapBasemap.warm => (const Color(0xFFFAF6F0), const Color(0xFFC8D7DC)),
      MapBasemap.slate => (const Color(0xFFE8E6E1), const Color(0xFFBCC9CD)),
      MapBasemap.sage => (const Color(0xFFDFE3DC), const Color(0xFFAEBFC2)),
      MapBasemap.night => (const Color(0xFF121614), const Color(0xFF0E1518)),
      MapBasemap.terrain => (const Color(0xFFE4DFD2), const Color(0xFFA8C4D4)),
      MapBasemap.satellite => (const Color(0xFF3F4A38), const Color(0xFF20384A)),
    };

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: land,
        borderRadius: BorderRadius.circular(WbRadius.chip),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(width: 34, height: 12, color: water),
      ),
    );
  }
}
