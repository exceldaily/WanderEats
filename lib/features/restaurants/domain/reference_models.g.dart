// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_City _$CityFromJson(Map<String, dynamic> json) => _City(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
  countryId: json['country_id'] as String,
  heroPhotoUrl: json['hero_photo_url'] as String?,
);

Map<String, dynamic> _$CityToJson(_City instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'country_id': instance.countryId,
  'hero_photo_url': instance.heroPhotoUrl,
};

_Cuisine _$CuisineFromJson(Map<String, dynamic> json) => _Cuisine(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
  emoji: json['emoji'] as String?,
);

Map<String, dynamic> _$CuisineToJson(_Cuisine instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'emoji': instance.emoji,
};

_Country _$CountryFromJson(Map<String, dynamic> json) => _Country(
  id: json['id'] as String,
  name: json['name'] as String,
  isoCode: json['iso_code'] as String,
  flagEmoji: json['flag_emoji'] as String?,
);

Map<String, dynamic> _$CountryToJson(_Country instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'iso_code': instance.isoCode,
  'flag_emoji': instance.flagEmoji,
};
