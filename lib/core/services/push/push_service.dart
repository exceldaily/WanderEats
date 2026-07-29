import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../networking/supabase_provider.dart';

/// Push notification facade. The real implementation (Firebase Cloud
/// Messaging) activates after `flutterfire configure`: it obtains the FCM
/// token, calls [registerToken], and refreshes it on rotation. Until then the
/// no-op keeps every call site honest with zero fake success.
abstract class PushService {
  /// Ask for POST_NOTIFICATIONS permission and register the device token.
  Future<void> enableForCurrentUser();

  /// Store/refresh a device token for the signed-in user.
  Future<void> registerToken(String token, {String platform = 'android'});

  /// Remove this device's token on sign-out.
  Future<void> unregisterToken(String token);
}

class NoopPushService implements PushService {
  NoopPushService(this._schema);

  final SupabaseQuerySchema _schema;

  @override
  Future<void> enableForCurrentUser() async {
    if (kDebugMode) {
      debugPrint('[push] Firebase not configured; see SETUP.md section 6');
    }
  }

  @override
  Future<void> registerToken(
    String token, {
    String platform = 'android',
  }) async {
    // Token persistence works today; only token GENERATION needs Firebase.
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    await _schema.from('device_tokens').upsert({
      'user_id': uid,
      'token': token,
      'platform': platform,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
  }

  @override
  Future<void> unregisterToken(String token) async {
    await _schema.from('device_tokens').delete().eq('token', token);
  }
}

/// Swapped for [FirebasePushService] in main.dart once Firebase has
/// initialized successfully; falls back to the no-op otherwise.
final pushServiceProvider = Provider<PushService>((ref) {
  return NoopPushService(ref.watch(wbSchemaProvider));
});
