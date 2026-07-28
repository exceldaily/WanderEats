import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/storage/media_uploader.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../restaurants/domain/restaurant.dart';
import '../../restaurants/presentation/restaurant_actions.dart';
import '../../restaurants/presentation/widgets/restaurant_picker_sheet.dart';
import '../data/recommendation_repository.dart';

/// The under-a-minute recommendation flow:
/// pick place -> photos -> short text -> what to order -> publish.
/// A draft persists locally so accidental exits lose nothing.
class CreateRecommendationScreen extends ConsumerStatefulWidget {
  const CreateRecommendationScreen({super.key, this.initialRestaurant});

  final RestaurantMarker? initialRestaurant;

  @override
  ConsumerState<CreateRecommendationScreen> createState() =>
      _CreateRecommendationScreenState();
}

class _CreateRecommendationScreenState
    extends ConsumerState<CreateRecommendationScreen> {
  static const _draftKey = 'wb_rec_draft_v1';

  // Rotating prompts that push useful specificity over generic praise.
  static const _prompts = [
    'What should someone order here?',
    'What made this place worth the trip?',
    'Who would you recommend this place to?',
    'What should visitors know before going?',
  ];

  RestaurantMarker? _restaurant;
  final _body = TextEditingController();
  final _order = TextEditingController();
  final List<File> _photos = [];
  int _priceImpression = 2;
  DateTime _visitedOn = DateTime.now();
  String _visibility = 'public';
  bool _busy = false;
  String? _error;
  late final int _promptIndex =
      DateTime.now().millisecondsSinceEpoch % _prompts.length;

  @override
  void initState() {
    super.initState();
    _restaurant = widget.initialRestaurant;
    unawaited(_restoreDraft());
    _body.addListener(_saveDraft);
    _order.addListener(_saveDraft);
  }

  @override
  void dispose() {
    _body.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    if (widget.initialRestaurant != null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return;
    try {
      final draft = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _body.text = (draft['body'] as String?) ?? '';
        _order.text = (draft['order'] as String?) ?? '';
        if (draft['restaurant'] != null) {
          _restaurant = RestaurantMarker.fromJson(
              (draft['restaurant'] as Map).cast<String, dynamic>());
        }
      });
    } catch (_) {/* corrupt draft: ignore */}
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _draftKey,
        jsonEncode({
          'body': _body.text,
          'order': _order.text,
          'restaurant': _restaurant?.toJson(),
        }));
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage(limit: 4);
    if (picked.isEmpty) return;
    setState(() {
      _photos
        ..clear()
        ..addAll(picked.take(4).map((x) => File(x.path)));
    });
  }

  Future<void> _publish() async {
    final session = ref.read(sessionProvider);
    final restaurant = _restaurant;
    if (session == null || restaurant == null) return;
    if (_body.text.trim().length < 10) {
      setState(() =>
          _error = 'Say a little more: at least 10 characters of real advice.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final photoUrls = <String>[];
      for (final photo in _photos) {
        photoUrls.add(await ref
            .read(mediaUploaderProvider)
            .uploadImage(file: photo, kind: 'rec'));
      }
      await ref.read(recommendationRepositoryProvider).create(
            userId: session.user.id,
            restaurantId: restaurant.id,
            body: _body.text.trim(),
            whatToOrder: _order.text.trim(),
            priceImpression: _priceImpression,
            visitedOn: _visitedOn,
            visibility: _visibility,
            photoUrls: photoUrls,
          );
      // A recommendation implies a visit.
      await ref.read(visitedIdsProvider.notifier).toggle(restaurant.id);
      unawaited(ref
          .read(analyticsProvider)
          .recommendationCreated(restaurantId: restaurant.id));
      await _clearDraft();
      // Server-side badge check; celebrate anything new.
      final badges = await ref.read(recommendationRepositoryProvider).awardBadges();
      if (!mounted) return;
      if (badges.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Badge unlocked: ${badges.join(', ')}')));
      }
      context.pushReplacementNamed(Routes.restaurant,
          pathParameters: {'id': restaurant.id});
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recommend a place')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(WbSpacing.md),
          children: [
            // 1. Restaurant
            Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text(_restaurant?.name ?? 'Choose a restaurant'),
                subtitle: _restaurant == null
                    ? const Text('Search by name')
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showRestaurantPicker(context);
                  if (picked != null) {
                    setState(() => _restaurant = picked);
                    unawaited(_saveDraft());
                  }
                },
              ),
            ),
            const SizedBox(height: WbSpacing.md),

            // 2. Photos
            Row(children: [
              for (final photo in _photos)
                Padding(
                  padding: const EdgeInsets.only(right: WbSpacing.sm),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(WbRadius.chip),
                    child:
                        Image.file(photo, width: 64, height: 64, fit: BoxFit.cover),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _pickPhotos,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_photos.isEmpty ? 'Add photos' : 'Change'),
              ),
            ]),
            const SizedBox(height: WbSpacing.md),

            // 3. The recommendation itself
            TextField(
              controller: _body,
              maxLength: 600,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                labelText: 'Your recommendation',
                hintText: _prompts[_promptIndex],
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: WbSpacing.sm),
            TextField(
              controller: _order,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'What to order',
                hintText: 'The dish you would send a friend for',
              ),
            ),
            const SizedBox(height: WbSpacing.md),

            // 4. Price + visit date + visibility
            Text('Price impression', style: theme.textTheme.labelLarge),
            const SizedBox(height: WbSpacing.xs),
            SegmentedButton<int>(
              segments: [
                for (var p = 1; p <= 4; p++)
                  ButtonSegment(value: p, label: Text('\$' * p)),
              ],
              selected: {_priceImpression},
              onSelectionChanged: (s) =>
                  setState(() => _priceImpression = s.first),
            ),
            const SizedBox(height: WbSpacing.md),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                      'Visited ${_visitedOn.year}-${_visitedOn.month.toString().padLeft(2, '0')}-${_visitedOn.day.toString().padLeft(2, '0')}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _visitedOn,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _visitedOn = picked);
                  },
                ),
              ),
              const SizedBox(width: WbSpacing.sm),
              DropdownMenu<String>(
                initialSelection: _visibility,
                onSelected: (v) =>
                    setState(() => _visibility = v ?? 'public'),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'public', label: 'Public'),
                  DropdownMenuEntry(value: 'followers', label: 'Followers'),
                  DropdownMenuEntry(value: 'private', label: 'Just me'),
                ],
              ),
            ]),
            if (_error != null) ...[
              const SizedBox(height: WbSpacing.md),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: WbSpacing.lg),
            FilledButton(
              onPressed:
                  (_busy || _restaurant == null) ? null : _publish,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publish recommendation'),
            ),
          ],
        ),
      ),
    );
  }
}
