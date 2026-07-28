// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RestaurantMarker _$RestaurantMarkerFromJson(Map<String, dynamic> json) =>
    _RestaurantMarker(
      id: json['id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      priceLevel: (json['price_level'] as num?)?.toInt(),
      recCount: (json['rec_count'] as num?)?.toInt() ?? 0,
      saveCount: (json['save_count'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble(),
      distanceM: (json['distance_m'] as num?)?.toDouble(),
      coverPhotoUrl: json['cover_photo_url'] as String?,
      cityId: json['city_id'] as String?,
    );

Map<String, dynamic> _$RestaurantMarkerToJson(_RestaurantMarker instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'lat': instance.lat,
      'lng': instance.lng,
      'price_level': instance.priceLevel,
      'rec_count': instance.recCount,
      'save_count': instance.saveCount,
      'score': instance.score,
      'distance_m': instance.distanceM,
      'cover_photo_url': instance.coverPhotoUrl,
      'city_id': instance.cityId,
    };

_Restaurant _$RestaurantFromJson(Map<String, dynamic> json) => _Restaurant(
  id: json['id'] as String,
  name: json['name'] as String,
  cityId: json['city_id'] as String,
  address: json['address'] as String?,
  priceLevel: (json['price_level'] as num?)?.toInt(),
  phone: json['phone'] as String?,
  website: json['website'] as String?,
  openingHours: json['opening_hours'] as Map<String, dynamic>?,
  coverPhotoUrl: json['cover_photo_url'] as String?,
  recCount: (json['rec_count'] as num?)?.toInt() ?? 0,
  saveCount: (json['save_count'] as num?)?.toInt() ?? 0,
  score: (json['score'] as num?)?.toDouble(),
  isSeed: json['is_seed'] as bool? ?? false,
);

Map<String, dynamic> _$RestaurantToJson(_Restaurant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city_id': instance.cityId,
      'address': instance.address,
      'price_level': instance.priceLevel,
      'phone': instance.phone,
      'website': instance.website,
      'opening_hours': instance.openingHours,
      'cover_photo_url': instance.coverPhotoUrl,
      'rec_count': instance.recCount,
      'save_count': instance.saveCount,
      'score': instance.score,
      'is_seed': instance.isSeed,
    };

_RecommendingTaster _$RecommendingTasterFromJson(Map<String, dynamic> json) =>
    _RecommendingTaster(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      followed: json['followed'] as bool? ?? false,
    );

Map<String, dynamic> _$RecommendingTasterToJson(_RecommendingTaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'is_verified': instance.isVerified,
      'followed': instance.followed,
    };

_RestaurantSummary _$RestaurantSummaryFromJson(Map<String, dynamic> json) =>
    _RestaurantSummary(
      tasters:
          (json['tasters'] as List<dynamic>?)
              ?.map(
                (e) => RecommendingTaster.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <RecommendingTaster>[],
      topQuote: json['top_quote'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RestaurantSummaryToJson(_RestaurantSummary instance) =>
    <String, dynamic>{
      'tasters': instance.tasters,
      'top_quote': instance.topQuote,
    };
