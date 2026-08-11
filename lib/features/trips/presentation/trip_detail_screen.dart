import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/wb_states.dart';
import '../data/trip_repository.dart';
import '../domain/trip_models.dart';

/// One trip: an ordered, reorderable list of stops.
class TripDetailScreen extends ConsumerStatefulWidget {
  const TripDetailScreen({super.key, required this.tripId, this.tripName});

  final String tripId;
  final String? tripName;

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final stops = ref.watch(tripStopsProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripName ?? 'Trip'),
        actions: [
          IconButton(
            tooltip: 'Delete trip',
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteTrip,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final count = stops.value?.length ?? 0;
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (context) =>
                _AddStopSheet(tripId: widget.tripId, nextPosition: count + 1),
          );
          if (!context.mounted) return;
          ref.invalidate(tripStopsProvider(widget.tripId));
        },
        icon: const Icon(Icons.add),
        label: const Text('Add stop'),
      ),
      body: stops.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WbErrorState(
          message: 'Stops could not be loaded.',
          onRetry: () => ref.invalidate(tripStopsProvider(widget.tripId)),
        ),
        data: (list) => list.isEmpty
            ? const WbEmptyState(
                icon: Icons.restaurant_outlined,
                title: 'No stops yet',
                message:
                    'Add the places you want to eat, in the order you want '
                    'to eat them.',
              )
            : ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: list.length,
                // onReorderItem already adjusts newIndex for the removed row.
                onReorderItem: (oldIndex, newIndex) => _reorder(
                  list,
                  oldIndex,
                  newIndex,
                ),
                itemBuilder: (context, i) {
                  final s = list[i];
                  return ListTile(
                    key: ValueKey(s.id),
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    title: Text(
                      s.restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: s.note == null
                        ? null
                        : Text(
                            s.note!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: IconButton(
                      tooltip: 'Remove stop',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref
                              .read(tripRepositoryProvider)
                              .removeStop(s.id);
                        } on AppException catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                          return;
                        } catch (_) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Could not update the trip.'),
                            ),
                          );
                          return;
                        }
                        if (!mounted) return;
                        ref.invalidate(tripStopsProvider(widget.tripId));
                      },
                    ),
                    onTap: () => context.pushNamed(
                      Routes.restaurant,
                      pathParameters: {'id': s.restaurantId},
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _reorder(List<TripStop> list, int oldIndex, int newIndex) async {
    final ids = [for (final s in list) s.id];
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    try {
      await ref.read(tripRepositoryProvider).reorder(widget.tripId, ids);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the trip.')),
      );
    }
    // Refetch either way: on failure the list snaps back to the server order.
    if (!mounted) return;
    ref.invalidate(tripStopsProvider(widget.tripId));
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this trip?'),
        content: const Text('The itinerary and its stops will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(tripRepositoryProvider).deleteTrip(widget.tripId);
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete the trip.')),
      );
      return;
    }
    // Only leave the screen once the delete actually happened.
    if (!mounted) return;
    ref.invalidate(myTripsProvider);
    context.pop();
  }
}

class _AddStopSheet extends ConsumerStatefulWidget {
  const _AddStopSheet({required this.tripId, required this.nextPosition});

  final String tripId;
  final int nextPosition;

  @override
  ConsumerState<_AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends ConsumerState<_AddStopSheet> {
  final _query = TextEditingController();
  final _note = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = const [];
  String? _selectedId;
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _note.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final rows = await ref
            .read(tripRepositoryProvider)
            .searchRestaurants(value);
        if (mounted) setState(() => _results = rows);
      } catch (_) {
        if (!mounted) return;
        setState(() => _results = const []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search failed. Try again.')),
        );
      }
    });
  }

  Future<void> _submit() async {
    final id = _selectedId;
    if (id == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(tripRepositoryProvider)
          .addStop(
            widget.tripId,
            id,
            note: _note.text.trim(),
            position: widget.nextPosition,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The stop could not be added.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: WbSpacing.lg,
        right: WbSpacing.lg,
        top: WbSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + WbSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add a stop', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: WbSpacing.md),
          TextField(
            controller: _query,
            decoration: const InputDecoration(
              labelText: 'Search restaurants',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: WbSpacing.sm),
          SizedBox(
            height: 180,
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'Search for the next place on the route.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final r = _results[i];
                      final id = r['id'] as String;
                      return ListTile(
                        dense: true,
                        title: Text(r['name'] as String? ?? ''),
                        trailing: _selectedId == id
                            ? const Icon(
                                Icons.check_circle,
                                color: WbColors.success,
                              )
                            : null,
                        onTap: () => setState(() => _selectedId = id),
                      );
                    },
                  ),
          ),
          TextField(
            controller: _note,
            maxLength: 280,
            decoration: const InputDecoration(
              labelText: 'Note (optional): what to order, when to go',
              counterText: '',
            ),
          ),
          const SizedBox(height: WbSpacing.sm),
          FilledButton(
            onPressed: _selectedId == null || _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add stop'),
          ),
        ],
      ),
    );
  }
}
