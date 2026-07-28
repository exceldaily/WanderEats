import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/storage/media_uploader.dart';
import '../../profile/data/profile_repository.dart';
import '../../restaurants/data/reference_repository.dart';
import 'auth_providers.dart';

/// Visual, brief onboarding: identity -> photo -> home city -> cuisines.
/// Photo, city and cuisines are skippable; identity is not.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;
  static const _stepCount = 4;

  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  File? _avatarFile;
  String? _homeCityId;
  final Set<String> _cuisineIds = {};

  Timer? _usernameDebounce;
  bool? _usernameAvailable;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pageController.dispose();
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  bool get _identityValid {
    final username = _username.text.trim();
    return _displayName.text.trim().isNotEmpty &&
        RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(username) &&
        _usernameAvailable == true;
  }

  void _checkUsername(String value) {
    _usernameDebounce?.cancel();
    setState(() => _usernameAvailable = null);
    final username = value.trim();
    if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(username)) return;
    _usernameDebounce = Timer(const Duration(milliseconds: 400), () async {
      final available = await ref
          .read(profileRepositoryProvider)
          .isUsernameAvailable(username);
      if (mounted && _username.text.trim() == username) {
        setState(() => _usernameAvailable = available);
      }
    });
  }

  void _next() {
    if (_step < _stepCount - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      unawaited(_finish());
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) setState(() => _avatarFile = File(picked.path));
  }

  Future<void> _finish() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await ref
            .read(mediaUploaderProvider)
            .uploadImage(file: _avatarFile!, kind: 'avatar');
      }
      await ref.read(myProfileProvider.notifier).completeOnboarding(
            username: _username.text.trim(),
            displayName: _displayName.text.trim(),
            bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
            homeCityId: _homeCityId,
            favoriteCuisines: _cuisineIds.toList(),
            avatarUrl: avatarUrl,
          );
      await ref.read(analyticsProvider).onboardingCompleted();
      if (mounted) context.goNamed(Routes.map);
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
      appBar: AppBar(
        title: const Text('Set up your profile'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / _stepCount,
            semanticsLabel: 'Onboarding progress',
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _identityStep(theme),
                  _photoStep(theme),
                  _cityStep(theme),
                  _cuisineStep(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(WbSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: WbSpacing.sm),
                      child: Text(_error!,
                          style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : (_step == 0 && !_identityValid ? null : _next),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_step == _stepCount - 1 ? 'Finish' : 'Continue'),
                  ),
                  if (_step > 0 && _step < _stepCount)
                    TextButton(
                      onPressed: _busy ? null : _next,
                      child: const Text('Skip for now'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(WbSpacing.lg),
      children: [
        Text('Who are you?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: WbSpacing.lg),
        TextField(
          controller: _displayName,
          textCapitalization: TextCapitalization.words,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Display name'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: WbSpacing.md),
        TextField(
          controller: _username,
          maxLength: 24,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixText: '@',
            helperText: 'Lowercase letters, numbers, underscores',
            suffixIcon: _usernameAvailable == null
                ? null
                : Icon(
                    _usernameAvailable! ? Icons.check_circle : Icons.cancel,
                    color: _usernameAvailable!
                        ? WbColors.success
                        : theme.colorScheme.error,
                  ),
          ),
          onChanged: _checkUsername,
        ),
        if (_usernameAvailable == false)
          Text('That username is taken.',
              style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: WbSpacing.md),
        TextField(
          controller: _bio,
          maxLength: 280,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Short bio (optional)',
            helperText: 'What kind of eater are you?',
          ),
        ),
      ],
    );
  }

  Widget _photoStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(WbSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Add a profile photo', style: theme.textTheme.headlineSmall),
          const SizedBox(height: WbSpacing.lg),
          InkWell(
            onTap: _pickAvatar,
            borderRadius: BorderRadius.circular(80),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage:
                  _avatarFile == null ? null : FileImage(_avatarFile!),
              child: _avatarFile == null
                  ? const Icon(Icons.add_a_photo_outlined, size: 36)
                  : null,
            ),
          ),
          const SizedBox(height: WbSpacing.md),
          TextButton(
            onPressed: _pickAvatar,
            child: Text(_avatarFile == null ? 'Choose a photo' : 'Change photo'),
          ),
        ],
      ),
    );
  }

  Widget _cityStep(ThemeData theme) {
    final cities = ref.watch(citiesProvider);
    return cities.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load cities: $e')),
      data: (list) => ListView(
        padding: const EdgeInsets.all(WbSpacing.lg),
        children: [
          Text('Where is home?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: WbSpacing.sm),
          Text('Your map starts here.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: WbSpacing.lg),
          Wrap(
            spacing: WbSpacing.sm,
            runSpacing: WbSpacing.sm,
            children: [
              for (final city in list)
                ChoiceChip(
                  label: Text(city.name),
                  selected: _homeCityId == city.id,
                  onSelected: (_) => setState(() => _homeCityId = city.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cuisineStep(ThemeData theme) {
    final cuisines = ref.watch(cuisinesProvider);
    return cuisines.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load cuisines: $e')),
      data: (list) => ListView(
        padding: const EdgeInsets.all(WbSpacing.lg),
        children: [
          Text('What do you crave?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: WbSpacing.sm),
          Text('Pick a few favorites to shape your discovery.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: WbSpacing.lg),
          Wrap(
            spacing: WbSpacing.sm,
            runSpacing: WbSpacing.sm,
            children: [
              for (final cuisine in list)
                FilterChip(
                  label: Text('${cuisine.emoji ?? ''} ${cuisine.name}'.trim()),
                  selected: _cuisineIds.contains(cuisine.id),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _cuisineIds.add(cuisine.id);
                    } else {
                      _cuisineIds.remove(cuisine.id);
                    }
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
