import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/utils/plural.dart';
import '../../../core/widgets/wb_states.dart';
import '../../map/presentation/map_controller.dart';
import '../data/discovery_repository.dart';
import '../domain/global_area.dart';

/// Universal search: restaurants, tasters, lists, cities, cuisines, grouped.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _recentKey = 'wb_recent_searches_v1';
  static const _suggested = [
    'Pizza',
    'Austin',
    'Coffee',
    'Hidden Gems',
    'Brunch',
    'Vegan',
    'Sushi',
    'Bangkok street food',
  ];

  final _controller = TextEditingController();
  Timer? _debounce;
  Map<String, dynamic>? _results;
  GlobalSearchResults? _global;
  bool _loading = false;
  bool _globalLoading = false;
  String? _error;
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadRecent());
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _recent = prefs.getStringList(_recentKey) ?? []);
  }

  Future<void> _saveRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _recent = [query, ..._recent.where((s) => s != query)].take(8).toList();
    await prefs.setStringList(_recentKey, _recent);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value, {bool submitted = false}) async {
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = null;
        _global = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(discoveryRepositoryProvider)
          .searchAll(query);
      if (!mounted || _controller.text.trim() != query) return;
      final total = [
        'restaurants',
        'tasters',
        'lists',
        'cities',
        'cuisines',
      ].fold<int>(0, (n, k) => n + ((results[k] as List?)?.length ?? 0));
      unawaited(
        ref
            .read(analyticsProvider)
            .searchPerformed(query: query, resultCount: total),
      );
      unawaited(_saveRecent(query));
      setState(() => _results = results);

      // Reach worldwide when what we hold locally is thin, or when the user
      // explicitly submitted. This is the trip-planning path: searching a city
      // or a restaurant nobody has imported yet still has to work. It costs a
      // provider call, hence never on plain typing with good local hits.
      final localRestaurants = ((results['restaurants'] as List?)?.length ?? 0);
      final localCities = ((results['cities'] as List?)?.length ?? 0);
      if (submitted || localRestaurants + localCities < 3) {
        unawaited(_searchGlobal(query));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchGlobal(String query) async {
    setState(() => _globalLoading = true);
    final global = await ref
        .read(discoveryRepositoryProvider)
        .searchGlobal(query);
    if (!mounted || _controller.text.trim() != query) return;
    setState(() {
      _global = global;
      _globalLoading = false;
    });
  }

  /// Send the map to a searched place. The map imports restaurants for the
  /// area on arrival, so an untouched city fills in by itself.
  void _exploreArea(GlobalArea area) {
    ref
        .read(mapDestinationProvider.notifier)
        .go(
          MapDestination(
            lat: area.lat,
            lng: area.lng,
            label: area.name,
            neLat: area.neLat,
            neLng: area.neLng,
            swLat: area.swLat,
            swLng: area.swLng,
          ),
        );
    context.goNamed(Routes.map);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Restaurants, Tasters, cities, lists...',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: (v) => _search(v, submitted: true),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _results = null;
                  _global = null;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _body(theme)),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_error != null) {
      return WbErrorState(
        message: _error!,
        onRetry: () => _search(_controller.text, submitted: true),
      );
    }
    if (_results == null) {
      // Idle state: recent + suggested searches.
      return ListView(
        padding: const EdgeInsets.all(WbSpacing.md),
        children: [
          if (_recent.isNotEmpty) ...[
            Text(
              'Recent',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: WbSpacing.sm),
            Wrap(
              spacing: WbSpacing.sm,
              runSpacing: WbSpacing.sm,
              children: [
                for (final r in _recent)
                  ActionChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(r),
                    onPressed: () {
                      _controller.text = r;
                      unawaited(_search(r));
                    },
                  ),
              ],
            ),
            const SizedBox(height: WbSpacing.lg),
          ],
          Text(
            'Try searching',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: WbSpacing.sm),
          Wrap(
            spacing: WbSpacing.sm,
            runSpacing: WbSpacing.sm,
            children: [
              for (final s in _suggested)
                ActionChip(
                  label: Text(s),
                  onPressed: () {
                    _controller.text = s;
                    unawaited(_search(s));
                  },
                ),
            ],
          ),
        ],
      );
    }

    final restaurants = (_results!['restaurants'] as List?) ?? [];
    final tasters = (_results!['tasters'] as List?) ?? [];
    final lists = (_results!['lists'] as List?) ?? [];
    final cities = (_results!['cities'] as List?) ?? [];
    final cuisines = (_results!['cuisines'] as List?) ?? [];
    final empty =
        restaurants.isEmpty &&
        tasters.isEmpty &&
        lists.isEmpty &&
        cities.isEmpty &&
        cuisines.isEmpty;

    final areas = _global?.areas ?? const <GlobalArea>[];
    final globalRestaurants = _global?.restaurants ?? const [];

    if (empty && areas.isEmpty && globalRestaurants.isEmpty) {
      if (_globalLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return WbEmptyState(
        icon: Icons.search_off,
        title: 'Nothing found',
        message: _global == null
            ? 'Try a different spelling, or press search to look worldwide.'
            : 'Try a different spelling or a broader term.',
      );
    }

    Widget header(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(
        WbSpacing.md,
        WbSpacing.md,
        WbSpacing.md,
        WbSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return ListView(
      children: [
        // Places to go come first when present: for trip planning, picking the
        // destination is the move that unlocks everything else.
        if (areas.isNotEmpty) ...[
          header('Places to explore'),
          for (final a in areas)
            ListTile(
              leading: const Icon(Icons.travel_explore),
              title: Text(a.name),
              subtitle: a.subtitle.isEmpty ? null : Text(a.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exploreArea(a),
            ),
        ],
        if (_globalLoading)
          const Padding(
            padding: EdgeInsets.all(WbSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: WbSpacing.sm),
                Text('Searching worldwide...'),
              ],
            ),
          ),
        if (restaurants.isNotEmpty) ...[
          header('Restaurants'),
          for (final r in restaurants.cast<Map<String, dynamic>>())
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: Text(r['name'] as String),
              subtitle: Text(
                '${r['city_name']} · ${countOfDynamic(r['rec_count'], 'recommendation')}',
              ),
              onTap: () => context.pushNamed(
                Routes.restaurant,
                pathParameters: {'id': r['id'] as String},
              ),
            ),
        ],
        if (tasters.isNotEmpty) ...[
          header('Tasters'),
          for (final t in tasters.cast<Map<String, dynamic>>())
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(t['display_name'] as String),
              subtitle: Text('@${t['username']}'),
              trailing: t['is_verified'] == true
                  ? const Icon(
                      Icons.verified,
                      size: 18,
                      color: WbColors.voyageLight,
                    )
                  : null,
              onTap: () => context.pushNamed(
                Routes.taster,
                pathParameters: {'id': t['id'] as String},
              ),
            ),
        ],
        if (lists.isNotEmpty) ...[
          header('Lists'),
          for (final l in lists.cast<Map<String, dynamic>>())
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: Text(l['title'] as String),
              subtitle: Text(countOfDynamic(l['restaurant_count'], 'place')),
              onTap: () => context.pushNamed(
                Routes.list,
                pathParameters: {'id': l['id'] as String},
              ),
            ),
        ],
        if (cities.isNotEmpty) ...[
          header('Cities'),
          for (final c in cities.cast<Map<String, dynamic>>())
            ListTile(
              leading: const Icon(Icons.location_city),
              title: Text(c['name'] as String),
              subtitle: Text(c['country_name'] as String? ?? ''),
              onTap: () {
                _controller.text = c['name'] as String;
                unawaited(_search(c['name'] as String));
              },
            ),
        ],
        // Names found worldwide that we did not already hold locally.
        if (globalRestaurants.isNotEmpty) ...[
          header('Restaurants worldwide'),
          for (final r in globalRestaurants)
            ListTile(
              leading: const Icon(Icons.public),
              title: Text((r['name'] ?? 'Unnamed').toString()),
              subtitle: Text(
                (r['address'] ?? r['city_name'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                final id = r['id'];
                if (id is String) {
                  context.pushNamed(
                    Routes.restaurant,
                    pathParameters: {'id': id},
                  );
                }
              },
            ),
        ],
        if (cuisines.isNotEmpty) ...[
          header('Cuisines'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: WbSpacing.md),
            child: Wrap(
              spacing: WbSpacing.sm,
              children: [
                for (final c in cuisines.cast<Map<String, dynamic>>())
                  ActionChip(
                    label: Text('${c['emoji'] ?? ''} ${c['name']}'.trim()),
                    onPressed: () {
                      _controller.text = c['name'] as String;
                      unawaited(_search(c['name'] as String));
                    },
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: WbSpacing.xl),
      ],
    );
  }
}
