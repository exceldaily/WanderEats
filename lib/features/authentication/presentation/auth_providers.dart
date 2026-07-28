import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/push/push_service.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../data/auth_repository.dart';

/// Live auth session. Emits on sign-in, sign-out, token refresh, deep links.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  // Re-evaluates on every auth event; falls back to the restored session.
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentSession;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider) != null;
});

/// The current user's WanderBites profile. Null when signed out OR when the
/// (shared-pool) account has not completed WanderBites onboarding yet.
final myProfileProvider =
    AsyncNotifierProvider<MyProfileController, Profile?>(MyProfileController.new);

class MyProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final session = ref.watch(sessionProvider);
    if (session == null) return null;
    final profile =
        await ref.read(profileRepositoryProvider).fetchProfile(session.user.id);
    // Restored sessions also need their device token kept current.
    if (profile != null) {
      unawaited(ref.read(pushServiceProvider).enableForCurrentUser());
    }
    return profile;
  }

  Future<void> completeOnboarding({
    required String username,
    required String displayName,
    String? bio,
    String? homeCityId,
    List<String> favoriteCuisines = const [],
    String? avatarUrl,
  }) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final profile = await ref.read(profileRepositoryProvider).createProfile(
          userId: session.user.id,
          username: username,
          displayName: displayName,
          bio: bio,
          homeCityId: homeCityId,
          favoriteCuisines: favoriteCuisines,
          avatarUrl: avatarUrl,
        );
    state = AsyncData(profile);
    unawaited(ref.read(pushServiceProvider).enableForCurrentUser());
  }

  Future<void> updateProfile(Map<String, dynamic> patch) async {
    final current = state.value;
    if (current == null) return;
    final updated =
        await ref.read(profileRepositoryProvider).updateProfile(current.id, patch);
    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = ref.read(sessionProvider);
      if (session == null) return null;
      return ref.read(profileRepositoryProvider).fetchProfile(session.user.id);
    });
  }
}

/// True while signed in but the WanderBites profile does not exist yet:
/// the router sends this state to onboarding.
final needsOnboardingProvider = Provider<bool>((ref) {
  final signedIn = ref.watch(isSignedInProvider);
  final profile = ref.watch(myProfileProvider);
  return signedIn && profile is AsyncData<Profile?> && profile.value == null;
});
