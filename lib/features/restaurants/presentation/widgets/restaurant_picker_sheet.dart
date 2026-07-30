import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/wb_tokens.dart';
import '../../../../core/utils/plural.dart';
import '../../../authentication/presentation/auth_providers.dart';
import '../../data/restaurant_repository.dart';
import '../../domain/restaurant.dart';

/// Bottom sheet to pick a restaurant for create flows. Three sources:
/// search by name, your saved places, your visited places — because the
/// place you want to recommend is usually one you already saved or ate at.
Future<RestaurantMarker?> showRestaurantPicker(BuildContext context) {
  return showModalBottomSheet<RestaurantMarker>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _PickerSheet(),
  );
}

enum _PickerSource { search, saved, visited }

/// Saved/visited restaurants as full rows, for the picker tabs.
final _collectionProvider = FutureProvider.autoDispose
    .family<List<Restaurant>, _PickerSource>((ref, source) async {
      final userId = ref.watch(sessionProvider)?.user.id;
      if (userId == null) return const [];
      final repo = ref.watch(restaurantRepositoryProvider);
      final ids = source == _PickerSource.saved
          ? await repo.fetchMySavedIds(userId)
          : await repo.fetchMyVisitedIds(userId);
      if (ids.isEmpty) return const [];
      return repo.fetchByIds(ids.toList());
    });

class _PickerSheet extends ConsumerStatefulWidget {
  const _PickerSheet();

  @override
  ConsumerState<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends ConsumerState<_PickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<RestaurantMarker> _results = [];
  bool _loading = false;
  _PickerSource _source = _PickerSource.search;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = value.trim();
      if (q.length < 2) {
        setState(() => _results = []);
        return;
      }
      setState(() => _loading = true);
      try {
        final results = await ref
            .read(restaurantRepositoryProvider)
            .searchByName(q);
        if (mounted && _controller.text.trim() == q) {
          setState(() => _results = results);
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  /// The picker returns a marker; collections hold full rows. Location is
  /// not used by the create flow, so zeroes are fine there.
  RestaurantMarker _toMarker(Restaurant r) => RestaurantMarker(
    id: r.id,
    name: r.name,
    lat: 0,
    lng: 0,
    priceLevel: r.priceLevel,
    recCount: r.recCount,
    saveCount: r.saveCount,
    coverPhotoUrl: r.coverPhotoUrl,
    cityId: r.cityId,
  );

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(isSignedInProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WbSpacing.md,
                WbSpacing.md,
                WbSpacing.md,
                0,
              ),
              child: SegmentedButton<_PickerSource>(
                segments: const [
                  ButtonSegment(
                    value: _PickerSource.search,
                    icon: Icon(Icons.search, size: 16),
                    label: Text('Search'),
                  ),
                  ButtonSegment(
                    value: _PickerSource.saved,
                    icon: Icon(Icons.bookmark_outline, size: 16),
                    label: Text('Saved'),
                  ),
                  ButtonSegment(
                    value: _PickerSource.visited,
                    icon: Icon(Icons.where_to_vote_outlined, size: 16),
                    label: Text('Visited'),
                  ),
                ],
                selected: {_source},
                onSelectionChanged: signedIn
                    ? (s) => setState(() => _source = s.first)
                    : null,
              ),
            ),
            if (_source == _PickerSource.search)
              Padding(
                padding: const EdgeInsets.all(WbSpacing.md),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search restaurants',
                  ),
                  onChanged: _onChanged,
                ),
              )
            else
              const SizedBox(height: WbSpacing.sm),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _source == _PickerSource.search
                  ? _searchResults(context)
                  : _collectionResults(context, _source),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchResults(BuildContext context) {
    if (_results.isEmpty) {
      return Center(
        child: Text(
          _controller.text.trim().length < 2 ? 'Type to search' : 'No matches',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, i) => ListTile(
        leading: const Icon(Icons.restaurant),
        title: Text(_results[i].name),
        subtitle: Text(countOf(_results[i].recCount, 'recommendation')),
        onTap: () => Navigator.pop(context, _results[i]),
      ),
    );
  }

  Widget _collectionResults(BuildContext context, _PickerSource source) {
    final theme = Theme.of(context);
    final items = ref.watch(_collectionProvider(source));
    return items.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load: $e')),
      data: (restaurants) {
        if (restaurants.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(WbSpacing.lg),
              child: Text(
                source == _PickerSource.saved
                    ? 'No saved restaurants yet. Save places from the map '
                          'or BiteSwipe first.'
                    : 'No visited restaurants yet. Mark places as visited '
                          'to recommend them quickly.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: restaurants.length,
          itemBuilder: (context, i) {
            final r = restaurants[i];
            return ListTile(
              leading: Icon(
                source == _PickerSource.saved
                    ? Icons.bookmark
                    : Icons.where_to_vote,
                color: source == _PickerSource.saved
                    ? WbColors.ember
                    : WbColors.success,
              ),
              title: Text(r.name),
              subtitle: r.address != null
                  ? Text(
                      r.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () => Navigator.pop(context, _toMarker(r)),
            );
          },
        );
      },
    );
  }
}
