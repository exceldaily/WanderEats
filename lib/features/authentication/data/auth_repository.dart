import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  /// Native Sign in with Apple.
  ///
  /// Uses Apple's own sheet and exchanges the resulting identity token with
  /// Supabase, rather than the browser OAuth flow the Google path uses. On
  /// iOS that distinction matters: guideline 4.8 expects the system sheet, and
  /// a web view for Apple sign-in is what gets apps rejected.
  ///
  /// The nonce is sent to Apple hashed and to Supabase raw. Apple signs the
  /// hash into the token, so Supabase can prove the token was minted for this
  /// request and not replayed.
  Future<void> signInWithApple() async {
    try {
      final rawNonce = _client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Apple did not return a sign-in token.');
      }

      await _client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // Cancelling is a choice, not a failure; surfacing an error for it would
      // be noise.
      if (e.code == AuthorizationErrorCode.canceled) return;
      throw AuthException('Apple sign-in did not complete.', cause: e);
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
