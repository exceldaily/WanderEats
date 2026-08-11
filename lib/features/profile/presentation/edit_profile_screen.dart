import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/media_uploader.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../premium/data/entitlement_service.dart';
import '../../premium/domain/entitlements.dart';
import '../../restaurants/data/reference_repository.dart';
import 'widgets/profile_header.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

/// Curated taste tag suggestions; users pick up to five. Their existing tags
/// always appear as options even if not in this list.
const kTasteTagSuggestions = [
  'Thai Food',
  'Bold Flavors',
  'Loves Spice',
  'Street Food',
  'Tries Anything',
  'Seafood',
  'Fine Dining',
  'Hidden Gems',
  'Desserts',
  'Local Favorites',
  'Budget Eats',
  'Coffee Hunter',
  'Vegan Friendly',
  'BBQ & Grill',
];

const _kMaxTasteTags = 5;

/// Selectable values per personality field, mirrored by the display card.
const kPersonalityOptions = {
  'flavor': ['Bold', 'Balanced', 'Delicate'],
  'spice': ['Mild', 'Medium', 'Hot'],
  'dining_style': ['Casual explorer', 'Planner', 'Fine diner', 'Grab & go'],
  'attitude': ['Will try anything', 'Comfort seeker', 'Health first'],
};

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  final _favoriteCuisine = TextEditingController();
  final _citySearch = TextEditingController();
  Timer? _cityDebounce;
  String? _homeCityId;

  /// Label for a home city picked via worldwide search (not yet in the
  /// cities chip list).
  String? _homeCityLabel;
  List<Map<String, dynamic>> _cityResults = [];
  bool _citySearching = false;
  String _bannerDesign = 'classic';
  String _bannerColor = 'voyage';
  File? _newAvatar;
  File? _newHeader;
  bool _busy = false;
  String? _error;
  bool _initialized = false;
  final List<String> _tasteTags = [];
  final Map<String, String?> _personality = {};

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    _favoriteCuisine.dispose();
    _citySearch.dispose();
    _cityDebounce?.cancel();
    super.dispose();
  }

  /// Worldwide city search: geocodes through the backend, which also
  /// registers the city so it becomes a real home_city_id.
  void _onCitySearchChanged(String value) {
    _cityDebounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() => _cityResults = []);
      return;
    }
    _cityDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _citySearching = true);
      try {
        final res = await Supabase.instance.client.functions.invoke(
          'places-search',
          body: {'query': q, 'areasOnly': true, 'ensureCity': true},
        );
        final data = res.data;
        if (!mounted || _citySearch.text.trim() != q) return;
        setState(() {
          _cityResults = data is Map
              ? ((data['areas'] as List?) ?? const [])
                    .whereType<Map>()
                    .where((a) => a['city_id'] is String)
                    .map((a) => a.cast<String, dynamic>())
                    .toList()
              : [];
        });
      } catch (_) {
        if (mounted) setState(() => _cityResults = []);
      } finally {
        if (mounted) setState(() => _citySearching = false);
      }
    });
  }

  bool get _hasPremiumLayouts =>
      hasEntitlement(ref, PremiumEntitlement.premiumProfileLayouts);

  /// Premium swatch tap: apply it with the entitlement, otherwise route to
  /// the paywall. This is a pure premium gate - age never applies to profile
  /// looks, so canBeSolvedByUpgrading is always true here.
  void _pickPremium(VoidCallback apply) {
    if (_hasPremiumLayouts) {
      apply();
    } else {
      unawaited(context.pushNamed(Routes.premium));
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uploader = ref.read(mediaUploaderProvider);
      final personality = <String, String>{
        for (final e in _personality.entries)
          if (e.value != null && e.value!.trim().isNotEmpty)
            e.key: e.value!.trim(),
        if (_favoriteCuisine.text.trim().isNotEmpty)
          'favorite_cuisine': _favoriteCuisine.text.trim(),
      };
      final patch = <String, dynamic>{
        'display_name': _displayName.text.trim(),
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'home_city_id': _homeCityId,
        'taste_tags': _tasteTags,
        'taste_personality': personality,
        'banner_style': composeBannerStyle(_bannerDesign, _bannerColor),
      };
      if (_newAvatar != null) {
        patch['avatar_url'] = await uploader.uploadImage(
          file: _newAvatar!,
          kind: 'avatar',
        );
      }
      if (_newHeader != null) {
        patch['header_url'] = await uploader.uploadImage(
          file: _newHeader!,
          kind: 'header',
        );
      }
      await ref.read(myProfileProvider.notifier).updateProfile(patch);
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<File?> _pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    return picked == null ? null : File(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_initialized) {
      _initialized = true;
      _displayName.text = profile.displayName;
      _bio.text = profile.bio ?? '';
      _homeCityId = profile.homeCityId;
      _tasteTags.addAll(profile.tasteTags);
      for (final key in kPersonalityOptions.keys) {
        _personality[key] = profile.tastePersonality[key] as String?;
      }
      _favoriteCuisine.text =
          (profile.tastePersonality['favorite_cuisine'] as String?) ?? '';
      final parsedBanner = parseBannerStyle(profile.bannerStyle);
      _bannerDesign = parsedBanner.design;
      _bannerColor = parsedBanner.color;
    }
    final cities = ref.watch(citiesProvider).value ?? [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: _busy ? const Text('Saving...') : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(WbSpacing.md),
        children: [
          Center(
            child: InkWell(
              onTap: () async {
                final f = await _pick();
                if (f != null) setState(() => _newAvatar = f);
              },
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _newAvatar != null
                    ? FileImage(_newAvatar!)
                    : (profile.avatarUrl != null
                              ? CachedNetworkImageProvider(profile.avatarUrl!)
                              : null)
                          as ImageProvider?,
                child: _newAvatar == null && profile.avatarUrl == null
                    ? const Icon(Icons.add_a_photo_outlined, size: 32)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: WbSpacing.sm),
          Center(
            // Custom banner photos are part of premium_profile_layouts; the
            // guard trigger enforces the same rule server-side. Tapping
            // without premium routes to the paywall, matching the swatches.
            child: TextButton.icon(
              onPressed: () => _pickPremium(() async {
                final f = await _pick();
                if (f != null && mounted) setState(() => _newHeader = f);
              }),
              icon: Icon(
                _hasPremiumLayouts
                    ? Icons.wallpaper_outlined
                    : Icons.lock_outline,
                size: 18,
              ),
              label: Text(
                _newHeader == null
                    ? 'Custom banner photo (Premium)'
                    : 'Banner photo selected',
              ),
            ),
          ),
          const SizedBox(height: WbSpacing.md),
          TextField(
            controller: _displayName,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          const SizedBox(height: WbSpacing.sm),
          TextField(
            controller: _bio,
            maxLength: 280,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          const SizedBox(height: WbSpacing.md),
          Text('Home city', style: theme.textTheme.labelLarge),
          Text(
            'Search any city in the world, or pick a popular one below.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: WbSpacing.xs),
          TextField(
            controller: _citySearch,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.travel_explore),
              hintText: 'Search cities worldwide',
              suffixIcon: _citySearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: _onCitySearchChanged,
          ),
          for (final a in _cityResults)
            ListTile(
              dense: true,
              leading: const Icon(Icons.location_city_outlined),
              title: Text(a['name'] as String? ?? ''),
              subtitle: a['country'] != null
                  ? Text(a['country'] as String)
                  : null,
              onTap: () => setState(() {
                _homeCityId = a['city_id'] as String;
                _homeCityLabel =
                    '${a['name']}${a['country'] != null ? ', ${a['country']}' : ''}';
                _cityResults = [];
                _citySearch.clear();
              }),
            ),
          if (_homeCityLabel != null && !cities.any((c) => c.id == _homeCityId))
            Padding(
              padding: const EdgeInsets.only(top: WbSpacing.xs),
              child: InputChip(
                avatar: const Icon(Icons.place_outlined, size: 16),
                label: Text(_homeCityLabel!),
                selected: true,
                onDeleted: () => setState(() {
                  _homeCityId = null;
                  _homeCityLabel = null;
                }),
              ),
            ),
          const SizedBox(height: WbSpacing.xs),
          Wrap(
            spacing: WbSpacing.sm,
            runSpacing: WbSpacing.sm,
            children: [
              for (final city in cities)
                ChoiceChip(
                  label: Text(city.name),
                  selected: _homeCityId == city.id,
                  onSelected: (_) => setState(() {
                    _homeCityId = city.id;
                    _homeCityLabel = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: WbSpacing.lg),
          Text('Profile banner', style: theme.textTheme.labelLarge),
          const SizedBox(height: WbSpacing.xs),
          Wrap(
            spacing: WbSpacing.sm,
            runSpacing: WbSpacing.sm,
            children: [
              for (final design in kBannerDesigns)
                BannerDesignSwatch(
                  design: design,
                  color: _bannerColor,
                  selected: _bannerDesign == design,
                  onTap: () => setState(() => _bannerDesign = design),
                ),
              for (final design in kPremiumBannerDesigns)
                BannerDesignSwatch(
                  design: design,
                  color: _bannerColor,
                  selected: _bannerDesign == design,
                  locked: !_hasPremiumLayouts,
                  onTap: () => _pickPremium(
                    () => setState(() => _bannerDesign = design),
                  ),
                ),
            ],
          ),
          const SizedBox(height: WbSpacing.sm),
          Wrap(
            spacing: WbSpacing.sm,
            runSpacing: WbSpacing.sm,
            children: [
              for (final color in kBannerColors)
                BannerColorSwatch(
                  color: color,
                  selected: _bannerColor == color,
                  onTap: () => setState(() => _bannerColor = color),
                ),
              for (final color in kPremiumBannerColors)
                BannerColorSwatch(
                  color: color,
                  selected: _bannerColor == color,
                  locked: !_hasPremiumLayouts,
                  onTap: () => _pickPremium(
                    () => setState(() => _bannerColor = color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: WbSpacing.lg),
          Text('Taste tags', style: theme.textTheme.labelLarge),
          Text(
            'Pick up to $_kMaxTasteTags that describe how you eat.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: WbSpacing.xs),
          Wrap(
            spacing: WbSpacing.sm,
            runSpacing: WbSpacing.sm,
            children: [
              for (final tag in {..._tasteTags, ...kTasteTagSuggestions})
                FilterChip(
                  label: Text(tag),
                  selected: _tasteTags.contains(tag),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        if (_tasteTags.length < _kMaxTasteTags) {
                          _tasteTags.add(tag);
                        } else {
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Up to $_kMaxTasteTags tags — remove one '
                                  'first.',
                                ),
                              ),
                            );
                        }
                      } else {
                        _tasteTags.remove(tag);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: WbSpacing.lg),
          Text('Taste personality', style: theme.textTheme.labelLarge),
          Text(
            'How you like to eat. All optional.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: WbSpacing.sm),
          for (final entry in kPersonalityOptions.entries) ...[
            Text(
              switch (entry.key) {
                'flavor' => 'Flavor',
                'spice' => 'Spice level',
                'dining_style' => 'Dining style',
                _ => 'Food attitude',
              },
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: WbSpacing.xs),
            Wrap(
              spacing: WbSpacing.sm,
              runSpacing: WbSpacing.sm,
              children: [
                for (final option in entry.value)
                  ChoiceChip(
                    label: Text(option),
                    selected: _personality[entry.key] == option,
                    onSelected: (v) => setState(
                      () => _personality[entry.key] = v ? option : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: WbSpacing.sm),
          ],
          TextField(
            controller: _favoriteCuisine,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Favorite cuisine',
              hintText: 'Thai, Oaxacan, Sichuan...',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: WbSpacing.md),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: WbSpacing.xl),
        ],
      ),
    );
  }
}
