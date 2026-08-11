// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['display_name'] as String,
  bio: json['bio'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  headerUrl: json['header_url'] as String?,
  homeCityId: json['home_city_id'] as String?,
  isVerified: json['is_verified'] as bool? ?? false,
  isDemo: json['is_demo'] as bool? ?? false,
  isAdmin: json['is_admin'] as bool? ?? false,
  onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
  favoriteCuisines:
      (json['favorite_cuisines'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  tasteTags:
      (json['taste_tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  bannerStyle: json['banner_style'] as String? ?? 'classic:voyage',
  headerFocusY: (json['header_focus_y'] as num?)?.toDouble() ?? 0.5,
  tastePersonality:
      json['taste_personality'] as Map<String, dynamic>? ??
      const <String, dynamic>{},
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'display_name': instance.displayName,
  'bio': instance.bio,
  'avatar_url': instance.avatarUrl,
  'header_url': instance.headerUrl,
  'home_city_id': instance.homeCityId,
  'is_verified': instance.isVerified,
  'is_demo': instance.isDemo,
  'is_admin': instance.isAdmin,
  'onboarding_completed': instance.onboardingCompleted,
  'favorite_cuisines': instance.favoriteCuisines,
  'taste_tags': instance.tasteTags,
  'banner_style': instance.bannerStyle,
  'header_focus_y': instance.headerFocusY,
  'taste_personality': instance.tastePersonality,
  'created_at': instance.createdAt.toIso8601String(),
};
