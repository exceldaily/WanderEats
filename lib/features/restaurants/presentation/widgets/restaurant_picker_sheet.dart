import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/wb_tokens.dart';
import '../../data/restaurant_repository.dart';
import '../../domain/restaurant.dart';

/// Bottom sheet to search and pick a restaurant (create flows).
Future<RestaurantMarker?> showRestaurantPicker(BuildContext context) {
  return showModalBottomSheet<RestaurantMarker>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _PickerSheet(),
  );
}

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
        final results =
            await ref.read(restaurantRepositoryProvider).searchByName(q);
        if (mounted && _controller.text.trim() == q) {
          setState(() => _results = results);
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
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
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _controller.text.trim().length < 2
                          ? 'Type to search'
                          : 'No matches',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) => ListTile(
                      leading: const Icon(Icons.restaurant),
                      title: Text(_results[i].name),
                      subtitle: Text('${_results[i].recCount} recommendations'),
                      onTap: () => Navigator.pop(context, _results[i]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
