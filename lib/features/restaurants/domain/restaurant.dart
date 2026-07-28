import 'package:freezed_annotation/freezed_annotation.dart';

part 'restaurant.freezed.dart';
part 'restaurant.g.dart';

/// Lightweight marker row returned by the restaurants_in_bounds /
/// nearby_restaurants RPCs. Small on purpose: hundreds may be in memory.
@freezed
abstract class RestaurantMarker with _$RestaurantMarker {
  const factory RestaurantMarker({
    required String id,
    required String name,
    required double lat,
    required double lng,
    @JsonKey(name: 'price_level') int? priceLevel,
    @JsonKey(name: 'rec_count') @Default(0) int recCount,
    @JsonKey(name: 'save_count') @Default(0) int saveCount,
    double? score,
    @JsonKey(name: 'distance_m') double? distanceM,
    @JsonKey(name: 'cover_photo_url') String? coverPhotoUrl,
    @JsonKey(name: 'city_id') String? cityId,
  }) = _RestaurantMarker;

  factory RestaurantMarker.fromJson(Map<String, dynamic> json) =>
      _$RestaurantMarkerFromJson(json);
}

/// Full restaurant row for the details screen.
@freezed
abstract class Restaurant with _$Restaurant {
  const factory Restaurant({
    required String id,
    required String name,
    @JsonKey(name: 'city_id') required String cityId,
    String? address,
    @JsonKey(name: 'price_level') int? priceLevel,
    String? phone,
    String? website,
    @JsonKey(name: 'opening_hours') Map<String, dynamic>? openingHours,
    @JsonKey(name: 'cover_photo_url') String? coverPhotoUrl,
    @JsonKey(name: 'rec_count') @Default(0) int recCount,
    @JsonKey(name: 'save_count') @Default(0) int saveCount,
    double? score,
    @JsonKey(name: 'is_seed') @Default(false) bool isSeed,
  }) = _Restaurant;

  factory Restaurant.fromJson(Map<String, dynamic> json) =>
      _$RestaurantFromJson(json);
}

/// restaurant_summary RPC payload: who recommends this place.
@freezed
abstract class RecommendingTaster with _$RecommendingTaster {
  const factory RecommendingTaster({
    required String id,
    required String username,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @Default(false) bool followed,
  }) = _RecommendingTaster;

  factory RecommendingTaster.fromJson(Map<String, dynamic> json) =>
      _$RecommendingTasterFromJson(json);
}

@freezed
abstract class RestaurantSummary with _$RestaurantSummary {
  const factory RestaurantSummary({
    @Default(<RecommendingTaster>[]) List<RecommendingTaster> tasters,
    @JsonKey(name: 'top_quote') Map<String, dynamic>? topQuote,
  }) = _RestaurantSummary;

  factory RestaurantSummary.fromJson(Map<String, dynamic> json) =>
      _$RestaurantSummaryFromJson(json);
}
