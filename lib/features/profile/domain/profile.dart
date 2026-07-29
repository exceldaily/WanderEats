import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String username,
    @JsonKey(name: 'display_name') required String displayName,
    String? bio,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'header_url') String? headerUrl,
    @JsonKey(name: 'home_city_id') String? homeCityId,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'is_demo') @Default(false) bool isDemo,
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
    @JsonKey(name: 'onboarding_completed')
    @Default(false)
    bool onboardingCompleted,
    @JsonKey(name: 'favorite_cuisines')
    @Default(<String>[])
    List<String> favoriteCuisines,
    @JsonKey(name: 'taste_tags') @Default(<String>[]) List<String> tasteTags,
    @JsonKey(name: 'banner_style') @Default('voyage') String bannerStyle,
    @JsonKey(name: 'taste_personality')
    @Default(<String, dynamic>{})
    Map<String, dynamic> tastePersonality,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
