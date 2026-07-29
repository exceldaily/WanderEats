import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/location/location_service.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/widgets/wb_states.dart';
import '../../map/presentation/map_controller.dart';
import '../domain/swipe_card.dart';
import 'biteswipe_controller.dart';
import 'widgets/swipe_card_view.dart';
import 'widgets/taster_preview_sheet.dart';

/// BiteSwipe: fast swipe discovery layered over the map, never replacing it.
/// Right saves, left skips, every gesture has a button twin, and the finish
/// screen funnels straight back to the map.
class BiteSwipeScreen extends ConsumerStatefulWidget {
  const BiteSwipeScreen({super.key});

  @override
  ConsumerState<BiteSwipeScreen> createState() => _BiteSwipeScreenState();
}

class _BiteSwipeScreenState extends ConsumerState<BiteSwipeScreen> {
  bool _completedLogged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  Future<void> _start() async {
    final pos = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted) return;
    if (pos != null) {
      await ref
          .read(biteSwipeControllerProvider.notifier)
          .load(lat: pos.latitude, lng: pos.longitude, locationLabel: 'Nearby');
      return;
    }
    // No location: fall back to the last place the user searched/flew to, or
    // ask them to pick somewhere rather than showing a random city's food.
    final dest = ref.read(mapDestinationProvider);
    if (dest != null) {
      await ref
          .read(biteSwipeControllerProvider.notifier)
          .load(lat: dest.lat, lng: dest.lng, locationLabel: dest.label);
    } else {
      // New York fallback matches the map's default camera.
      await ref
          .read(biteSwipeControllerProvider.notifier)
          .load(lat: 40.7128, lng: -74.0060, locationLabel: 'New York');
    }
  }

  Future<void> _save() async {
    unawaited(HapticFeedback.lightImpact());
    final card = ref.read(biteSwipeControllerProvider).current;
    await ref.read(biteSwipeControllerProvider.notifier).save();
    if (card != null) {
      unawaited(ref.read(analyticsProvider).deckSaved(restaurantId: card.id));
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text('Saved ${card.name}'),
              action: SnackBarAction(
                label: 'Add to list',
                onPressed: () =>
                    context.pushNamed(Routes.createList, extra: card.id),
              ),
            ),
          );
      }
    }
  }

  Future<void> _skip() async {
    unawaited(HapticFeedback.selectionClick());
    final state = ref.read(biteSwipeControllerProvider);
    final card = state.current;
    await ref.read(biteSwipeControllerProvider.notifier).skip();
    if (card != null) {
      unawaited(ref.read(analyticsProvider).deckSkipped(restaurantId: card.id));
    }
    // Ask why occasionally, never every time: every third skip.
    final skips = ref.read(biteSwipeControllerProvider).skippedCount;
    if (mounted && skips > 0 && skips % 3 == 0) {
      unawaited(_askSkipReason());
    }
  }

  Future<void> _askSkipReason() async {
    final reason = await showModalBottomSheet<SkipReason>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WbSpacing.md),
              child: Text(
                'Not feeling these? Tell us why (optional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: WbSpacing.sm),
            for (final r in SkipReason.values)
              ListTile(
                title: Text(r.label),
                onTap: () => Navigator.of(context).pop(r),
              ),
          ],
        ),
      ),
    );
    if (reason != null) {
      await ref
          .read(biteSwipeControllerProvider.notifier)
          .recordSkipReason(reason);
    }
  }

  Future<void> _undo() async {
    unawaited(HapticFeedback.selectionClick());
    unawaited(ref.read(analyticsProvider).deckUndo());
    await ref.read(biteSwipeControllerProvider.notifier).undo();
  }

  void _openDetails(SwipeCard card) {
    context.pushNamed(Routes.restaurant, pathParameters: {'id': card.id});
  }

  Future<void> _openTasters(SwipeCard card) async {
    unawaited(
      ref
          .read(analyticsProvider)
          .deckTasterPreviewOpened(restaurantId: card.id),
    );
    await showTasterPreviewSheet(context, restaurantId: card.id);
  }

  Future<void> _openFilters() async {
    final controller = ref.read(biteSwipeControllerProvider.notifier);
    final current = ref.read(biteSwipeControllerProvider).filters;
    final result = await showModalBottomSheet<BiteSwipeFilters>(
      context: context,
      showDragHandle: true,
      builder: (context) => _FilterSheet(initial: current),
    );
    if (result != null) {
      unawaited(ref.read(analyticsProvider).deckFiltersChanged());
      await controller.setFilters(result);
    }
  }

  void _viewSavedOnMap() {
    final state = ref.read(biteSwipeControllerProvider);
    unawaited(
      ref
          .read(analyticsProvider)
          .deckSavedViewedOnMap(count: state.savedIds.length),
    );
    unawaited(ref.read(biteSwipeControllerProvider.notifier).finish());
    context.goNamed(Routes.map);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(biteSwipeControllerProvider);

    // Log completion once per finished deck.
    if (state.finished && !_completedLogged && state.cards.isNotEmpty) {
      _completedLogged = true;
      unawaited(
        ref
            .read(analyticsProvider)
            .deckCompleted(
              saved: state.savedIds.length,
              tasters: state.tasterIds.length,
            ),
      );
    } else if (!state.finished) {
      _completedLogged = false;
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(ref.read(biteSwipeControllerProvider.notifier).finish());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BiteSwipe'),
              if (state.locationLabel != null)
                Text(
                  state.locationLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Filters',
              onPressed: _openFilters,
              icon: Badge(
                isLabelVisible: state.filters.isActive,
                child: const Icon(Icons.tune),
              ),
            ),
          ],
        ),
        body: SafeArea(child: _body(theme, state)),
      ),
    );
  }

  Widget _body(ThemeData theme, BiteSwipeState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return WbErrorState(
        message: state.error!,
        onRetry: () => ref.read(biteSwipeControllerProvider.notifier).refresh(),
      );
    }
    if (state.cards.isEmpty) {
      return WbEmptyState(
        icon: Icons.restaurant_outlined,
        title: 'No places to swipe here yet',
        message:
            'Try widening the radius or clearing filters — or explore the '
            'map to pull in this area first.',
        actionLabel: 'Adjust filters',
        onAction: _openFilters,
      );
    }
    if (state.finished) {
      return _CompletionView(
        state: state,
        onViewMap: _viewSavedOnMap,
        onRefresh: () =>
            ref.read(biteSwipeControllerProvider.notifier).refresh(),
        onFilters: _openFilters,
      );
    }

    final card = state.current!;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(WbSpacing.md),
            child: Stack(
              children: [
                // The card underneath peeks through during the drag so the
                // deck reads as a deck, not a single page.
                if (state.next != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: 0.96,
                        child: SwipeCardView(
                          key: ValueKey('under-${state.next!.id}'),
                          card: state.next!,
                          onTap: () {},
                          onTasters: () {},
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: DraggableSwipe(
                    key: ValueKey(card.id),
                    onSave: _save,
                    onSkip: _skip,
                    child: SwipeCardView(
                      card: card,
                      onTap: () => _openDetails(card),
                      onTasters: () => _openTasters(card),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            WbSpacing.lg,
            0,
            WbSpacing.lg,
            WbSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.close,
                label: 'Skip',
                onTap: _skip,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              _ActionButton(
                icon: Icons.undo,
                label: 'Undo',
                onTap: state.canUndo ? _undo : null,
                small: true,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              _ActionButton(
                icon: Icons.bookmark,
                label: 'Save',
                onTap: _save,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: WbSpacing.sm),
          child: Text(
            '${state.remaining} nearby to go',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Drag wrapper: threshold-based horizontal swipe with rotation, honoring
/// reduced-motion by skipping the fling animation.
class DraggableSwipe extends StatefulWidget {
  const DraggableSwipe({
    super.key,
    required this.child,
    required this.onSave,
    required this.onSkip,
  });

  final Widget child;
  final Future<void> Function() onSave;
  final Future<void> Function() onSkip;

  @override
  State<DraggableSwipe> createState() => _DraggableSwipeState();
}

class _DraggableSwipeState extends State<DraggableSwipe>
    with SingleTickerProviderStateMixin {
  double _dx = 0;
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  Future<void> _finish(double width) async {
    final threshold = width * 0.28;
    if (_dx > threshold) {
      await widget.onSave();
    } else if (_dx < -threshold) {
      await widget.onSkip();
    }
    if (mounted) setState(() => _dx = 0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final progress = (_dx / (width * 0.28)).clamp(-1.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(() => _dx += d.delta.dx),
      onHorizontalDragEnd: (_) => unawaited(_finish(width)),
      onHorizontalDragCancel: () => setState(() => _dx = 0),
      child: Transform.translate(
        offset: Offset(reduceMotion ? 0 : _dx, 0),
        child: Transform.rotate(
          angle: reduceMotion ? 0 : _dx / width * 0.15,
          child: Stack(
            children: [
              widget.child,
              // Directional hint labels; subtle, not dating-app stamps.
              if (progress.abs() > 0.15)
                Positioned(
                  top: WbSpacing.lg,
                  left: progress > 0 ? WbSpacing.lg : null,
                  right: progress < 0 ? WbSpacing.lg : null,
                  child: Material(
                    color: progress > 0
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(WbRadius.chip),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WbSpacing.md,
                        vertical: WbSpacing.xs,
                      ),
                      child: Text(progress > 0 ? 'Save' : 'Skip'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.small = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 48.0 : 64.0;
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            shape: const CircleBorder(),
            elevation: onTap == null ? 0 : WbElevation.raisedCard,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(
                  icon,
                  size: small ? 22 : 28,
                  color: onTap == null
                      ? Theme.of(context).disabledColor
                      : color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.state,
    required this.onViewMap,
    required this.onRefresh,
    required this.onFilters,
  });

  final BiteSwipeState state;
  final VoidCallback onViewMap;
  final VoidCallback onRefresh;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = state.savedIds.length;
    final tasters = state.tasterIds.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WbSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              saved > 0 ? Icons.celebration_outlined : Icons.done_all,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: WbSpacing.md),
            Text(
              saved > 0
                  ? 'You saved $saved '
                        '${saved == 1 ? 'restaurant' : 'restaurants'}'
                        '${tasters > 0 ? ' from $tasters ${tasters == 1 ? 'Taster' : 'Tasters'}' : ''}.'
                  : 'That\'s everything nearby.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: WbSpacing.lg),
            if (saved > 0)
              FilledButton.icon(
                onPressed: onViewMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('View Saved Bites on Map'),
              ),
            const SizedBox(height: WbSpacing.sm),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh the deck'),
            ),
            const SizedBox(height: WbSpacing.sm),
            TextButton(
              onPressed: onFilters,
              child: const Text('Change filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final BiteSwipeFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int? _maxPrice = widget.initial.maxPrice;
  late int _radius = widget.initial.radiusM;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(WbSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: WbSpacing.md),
            Text('Max price', style: theme.textTheme.labelLarge),
            const SizedBox(height: WbSpacing.xs),
            Wrap(
              spacing: WbSpacing.sm,
              children: [
                for (final p in [1, 2, 3, 4])
                  FilterChip(
                    label: Text('\$' * p),
                    selected: _maxPrice == p,
                    onSelected: (v) => setState(() => _maxPrice = v ? p : null),
                  ),
              ],
            ),
            const SizedBox(height: WbSpacing.md),
            Text(
              'Radius: ${(_radius / 1000).toStringAsFixed(1)} km',
              style: theme.textTheme.labelLarge,
            ),
            Slider(
              value: _radius.toDouble(),
              min: 1000,
              max: 15000,
              divisions: 14,
              label: '${(_radius / 1000).toStringAsFixed(1)} km',
              onChanged: (v) => setState(() => _radius = v.round()),
            ),
            const SizedBox(height: WbSpacing.md),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(const BiteSwipeFilters()),
                  child: const Text('Reset'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    BiteSwipeFilters(
                      maxPrice: _maxPrice,
                      radiusM: _radius,
                      cuisineId: widget.initial.cuisineId,
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
