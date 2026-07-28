import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../errors/app_exception.dart';
import '../networking/supabase_provider.dart';

/// Uploads images to the wanderbites-media bucket. Paths are always prefixed
/// with the uploader's uid (enforced server-side by storage policies) and
/// images are compressed before leaving the device.
class MediaUploader {
  MediaUploader(this._client);

  final SupabaseClient _client;

  static const _bucket = 'wanderbites-media';
  static const _maxBytes = 5 * 1024 * 1024;

  /// Compresses and uploads, returns the public URL.
  /// [kind] becomes a folder: avatar, header, rec, restaurant.
  Future<String> uploadImage({
    required File file,
    required String kind,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const AuthException('Sign in to upload photos.');
    }

    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 82,
      minWidth: 1600,
      minHeight: 1600,
      format: CompressFormat.jpeg,
    );
    final bytes = compressed ?? await file.readAsBytes();
    if (bytes.length > _maxBytes) {
      throw const ValidationException('Photo is too large even after compression (max 5 MB).');
    }

    final path =
        '$uid/$kind/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return _client.storage.from(_bucket).getPublicUrl(path);
    } on StorageException catch (e) {
      throw ServerException(cause: e);
    }
  }
}

final mediaUploaderProvider = Provider<MediaUploader>((ref) {
  return MediaUploader(ref.watch(supabaseProvider));
});
