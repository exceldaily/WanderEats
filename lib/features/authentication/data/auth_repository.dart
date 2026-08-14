import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';

/// Authentication against the shared Supabase project. WanderBites shares the
/// auth pool with other OrbitStack apps; what makes someone a WanderBites
/// user is their wanderbites.profiles row (created during onboarding).
class AuthRepository {
  AuthRepository(this._client);

  final sb.SupabaseClient _client;

  sb.Session? get currentSession => _client.auth.currentSession;
  String? get currentUserId => _client.auth.currentUser?.id;
  Stream<sb.AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Confirmation emails land on the WanderBites confirmed page, which
      // hands off to the app via the wanderbites:// deep link. Without this
      // the link falls back to the Supabase project's site URL, which is not
      // WanderBites (shared project).
      await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://wanderbites-gamma.vercel.app/confirmed',
      );
    } on sb.AuthException catch (e) {
      throw AuthException(_friendly(e), cause: e);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on sb.AuthException catch (e) {
      throw AuthException(_friendly(e), cause: e);
    }
  }

  /// Browser-based OAuth through the Supabase Google provider; the session
  /// returns via the wanderbites://callback deep link (PKCE).
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: 'wanderbites://callback',
      );
    } on sb.AuthException catch (e) {
      throw AuthException(_friendly(e), cause: e);
    }
  }

  /// Apple sign-in slot for the iOS release; same OAuth flow.
  Future<void> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(
        sb.OAuthProvider.apple,
        redirectTo: 'wanderbites://callback',
      );
    } on sb.AuthException catch (e) {
      throw AuthException(_friendly(e), cause: e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'wanderbites://callback',
      );
    } on sb.AuthException catch (e) {
      throw AuthException(_friendly(e), cause: e);
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Removes the WanderBites profile and all owned content (server-side
  /// cascade). The shared auth account itself is preserved because it may
  /// power sibling apps; see SECURITY.md.
  Future<void> deleteAccount() async {
    try {
      await _client.schema('wanderbites').rpc<void>('delete_account');
      await _client.auth.signOut();
    } on sb.PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  String _friendly(sb.AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Wrong email or password.';
    }
    if (msg.contains('already registered')) {
      return 'That email already has an account. Try signing in.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Wait a minute and try again.';
    }
    return 'Sign-in failed. ${e.message}';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});
