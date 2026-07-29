// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Recommendation _$RecommendationFromJson(Map<String, dynamic> json) =>
    _Recommendation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      restaurantId: json['restaurant_id'] as String,
      body: json['body'] as String,
      whatToOrder: json['what_to_order'] as String?,
      priceImpression: (json['price_impression'] as num?)?.toInt(),
      visitedOn: json['visited_on'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['profiles'] as Map<String, dynamic>?,
      restaurant: json['restaurants'] as Map<String, dynamic>?,
      photos:
          (json['recommendation_photos'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const <Map<String, dynamic>>[],
    );

Map<String, dynamic> _$RecommendationToJson(_Recommendation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'restaurant_id': instance.restaurantId,
      'body': instance.body,
      'what_to_order': instance.whatToOrder,
      'price_impression': instance.priceImpression,
      'visited_on': instance.visitedOn,
      'visibility': instance.visibility,
      'created_at': instance.createdAt.toIso8601String(),
      'profiles': instance.author,
      'restaurants': instance.restaurant,
      'recommendation_photos': instance.photos,
    };
