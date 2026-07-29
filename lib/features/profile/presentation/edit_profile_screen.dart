import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/media_uploader.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../restaurants/data/reference_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  String? _homeCityId;
  File? _newAvatar;
  File? _newHeader;
  bool _busy = false;
  String? _error;
  bool _initialized = false;

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uploader = ref.read(mediaUploaderProvider);
      final patch = <String, dynamic>{
        'display_name': _displayName.text.trim(),
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'home_city_id': _homeCityId,
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
            child: TextButton.icon(
              onPressed: () async {
                final f = await _pick();
                if (f != null) setState(() => _newHeader = f);
              },
              icon: const Icon(Icons.wallpaper_outlined, size: 18),
              label: Text(
                _newHeader == null
                    ? 'Change header image'
                    : 'Header image selected',
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
          const SizedBox(height: WbSpacing.xs),
          Wrap(
            spacing: WbSpacing.sm,
            runSpacing: WbSpacing.sm,
            children: [
              for (final city in cities)
                ChoiceChip(
                  label: Text(city.name),
                  selected: _homeCityId == city.id,
                  onSelected: (_) => setState(() => _homeCityId = city.id),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: WbSpacing.md),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
