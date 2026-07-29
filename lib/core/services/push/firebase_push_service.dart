import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import 'push_service.dart';

/// Real FCM implementation. Requests notification permission, obtains the
/// device token and keeps it registered in wanderbites.device_tokens.
class FirebasePushService implements PushService {
  FirebasePushService(this._schema);

  final SupabaseQuerySchema _schema;

  @override
  Future<void> enableForCurrentUser() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    final token = await messaging.getToken();
    if (token != null) {
      await registerToken(token);
    }
    messaging.onTokenRefresh.listen(registerToken);
  }

  @override
  Future<void> registerToken(
    String token, {
    String platform = 'android',
  }) async {
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
