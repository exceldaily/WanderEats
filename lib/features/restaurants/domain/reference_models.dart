import 'package:freezed_annotation/freezed_annotation.dart';

part 'reference_models.freezed.dart';
part 'reference_models.g.dart';

@freezed
abstract class City with _$City {
  const factory City({
    required String id,
    required String name,
    required String slug,
    @JsonKey(name: 'country_id') required String countryId,
    @JsonKey(name: 'hero_photo_url') String? heroPhotoUrl,
  }) = _City;

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
}

@freezed
abstract class Cuisine with _$Cuisine {
  const factory Cuisine({
    required String id,
    required String name,
    required String slug,
    String? emoji,
  }) = _Cuisine;

  factory Cuisine.fromJson(Map<String, dynamic> json) =>
      _$CuisineFromJson(json);
}

@freezed
abstract class Country with _$Country {
  const factory Country({
    required String id,
    required String name,
    @JsonKey(name: 'iso_code') required String isoCode,
    @JsonKey(name: 'flag_emoji') String? flagEmoji,
  }) = _Country;

  factory Country.fromJson(Map<String, dynamic> json) =>
      _$CountryFromJson(json);
}
