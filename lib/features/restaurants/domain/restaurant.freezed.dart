// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RestaurantMarker {

 String get id; String get name; double get lat; double get lng;@JsonKey(name: 'price_level') int? get priceLevel;@JsonKey(name: 'rec_count') int get recCount;@JsonKey(name: 'save_count') int get saveCount; double? get score;@JsonKey(name: 'distance_m') double? get distanceM;@JsonKey(name: 'cover_photo_url') String? get coverPhotoUrl;@JsonKey(name: 'city_id') String? get cityId;
/// Create a copy of RestaurantMarker
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantMarkerCopyWith<RestaurantMarker> get copyWith => _$RestaurantMarkerCopyWithImpl<RestaurantMarker>(this as RestaurantMarker, _$identity);

  /// Serializes this RestaurantMarker to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantMarker&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.priceLevel, priceLevel) || other.priceLevel == priceLevel)&&(identical(other.recCount, recCount) || other.recCount == recCount)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.score, score) || other.score == score)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.coverPhotoUrl, coverPhotoUrl) || other.coverPhotoUrl == coverPhotoUrl)&&(identical(other.cityId, cityId) || other.cityId == cityId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,lat,lng,priceLevel,recCount,saveCount,score,distanceM,coverPhotoUrl,cityId);

@override
String toString() {
  return 'RestaurantMarker(id: $id, name: $name, lat: $lat, lng: $lng, priceLevel: $priceLevel, recCount: $recCount, saveCount: $saveCount, score: $score, distanceM: $distanceM, coverPhotoUrl: $coverPhotoUrl, cityId: $cityId)';
}


}

/// @nodoc
abstract mixin class $RestaurantMarkerCopyWith<$Res>  {
  factory $RestaurantMarkerCopyWith(RestaurantMarker value, $Res Function(RestaurantMarker) _then) = _$RestaurantMarkerCopyWithImpl;
@useResult
$Res call({
 String id, String name, double lat, double lng,@JsonKey(name: 'price_level') int? priceLevel,@JsonKey(name: 'rec_count') int recCount,@JsonKey(name: 'save_count') int saveCount, double? score,@JsonKey(name: 'distance_m') double? distanceM,@JsonKey(name: 'cover_photo_url') String? coverPhotoUrl,@JsonKey(name: 'city_id') String? cityId
});




}
/// @nodoc
class _$RestaurantMarkerCopyWithImpl<$Res>
    implements $RestaurantMarkerCopyWith<$Res> {
  _$RestaurantMarkerCopyWithImpl(this._self, this._then);

  final RestaurantMarker _self;
  final $Res Function(RestaurantMarker) _then;

/// Create a copy of RestaurantMarker
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? lat = null,Object? lng = null,Object? priceLevel = freezed,Object? recCount = null,Object? saveCount = null,Object? score = freezed,Object? distanceM = freezed,Object? coverPhotoUrl = freezed,Object? cityId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,priceLevel: freezed == priceLevel ? _self.priceLevel : priceLevel // ignore: cast_nullable_to_non_nullable
as int?,recCount: null == recCount ? _self.recCount : recCount // ignore: cast_nullable_to_non_nullable
as int,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,distanceM: freezed == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as double?,coverPhotoUrl: freezed == coverPhotoUrl ? _self.coverPhotoUrl : coverPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RestaurantMarker].
extension RestaurantMarkerPatterns on RestaurantMarker {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantMarker value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantMarker() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantMarker value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantMarker():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantMarker value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantMarker() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double lat,  double lng, @JsonKey(name: 'price_level')  int? priceLevel, @JsonKey(name: 'rec_count')  int recCount, @JsonKey(name: 'save_count')  int saveCount,  double? score, @JsonKey(name: 'distance_m')  double? distanceM, @JsonKey(name: 'cover_photo_url')  String? coverPhotoUrl, @JsonKey(name: 'city_id')  String? cityId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantMarker() when $default != null:
return $default(_that.id,_that.name,_that.lat,_that.lng,_that.priceLevel,_that.recCount,_that.saveCount,_that.score,_that.distanceM,_that.coverPhotoUrl,_that.cityId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double lat,  double lng, @JsonKey(name: 'price_level')  int? priceLevel, @JsonKey(name: 'rec_count')  int recCount, @JsonKey(name: 'save_count')  int saveCount,  double? score, @JsonKey(name: 'distance_m')  double? distanceM, @JsonKey(name: 'cover_photo_url')  String? coverPhotoUrl, @JsonKey(name: 'city_id')  String? cityId)  $default,) {final _that = this;
switch (_that) {
case _RestaurantMarker():
return $default(_that.id,_that.name,_that.lat,_that.lng,_that.priceLevel,_that.recCount,_that.saveCount,_that.score,_that.distanceM,_that.coverPhotoUrl,_that.cityId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double lat,  double lng, @JsonKey(name: 'price_level')  int? priceLevel, @JsonKey(name: 'rec_count')  int recCount, @JsonKey(name: 'save_count')  int saveCount,  double? score, @JsonKey(name: 'distance_m')  double? distanceM, @JsonKey(name: 'cover_photo_url')  String? coverPhotoUrl, @JsonKey(name: 'city_id')  String? cityId)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantMarker() when $default != null:
return $default(_that.id,_that.name,_that.lat,_that.lng,_that.priceLevel,_that.recCount,_that.saveCount,_that.score,_that.distanceM,_that.coverPhotoUrl,_that.cityId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RestaurantMarker implements RestaurantMarker {
  const _RestaurantMarker({required this.id, required this.name, required this.lat, required this.lng, @JsonKey(name: 'price_level') this.priceLevel, @JsonKey(name: 'rec_count') this.recCount = 0, @JsonKey(name: 'save_count') this.saveCount = 0, this.score, @JsonKey(name: 'distance_m') this.distanceM, @JsonKey(name: 'cover_photo_url') this.coverPhotoUrl, @JsonKey(name: 'city_id') this.cityId});
  factory _RestaurantMarker.fromJson(Map<String, dynamic> json) => _$RestaurantMarkerFromJson(json);

@override final  String id;
@override final  String name;
@override final  double lat;
@override final  double lng;
@override@JsonKey(name: 'price_level') final  int? priceLevel;
@override@JsonKey(name: 'rec_count') final  int recCount;
@override@JsonKey(name: 'save_count') final  int saveCount;
@override final  double? score;
@override@JsonKey(name: 'distance_m') final  double? distanceM;
@override@JsonKey(name: 'cover_photo_url') final  String? coverPhotoUrl;
@override@JsonKey(name: 'city_id') final  String? cityId;

/// Create a copy of RestaurantMarker
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantMarkerCopyWith<_RestaurantMarker> get copyWith => __$RestaurantMarkerCopyWithImpl<_RestaurantMarker>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantMarkerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantMarker&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.priceLevel, priceLevel) || other.priceLevel == priceLevel)&&(identical(other.recCount, recCount) || other.recCount == recCount)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.score, score) || other.score == score)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.coverPhotoUrl, coverPhotoUrl) || other.coverPhotoUrl == coverPhotoUrl)&&(identical(other.cityId, cityId) || other.cityId == cityId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,lat,lng,priceLevel,recCount,saveCount,score,distanceM,coverPhotoUrl,cityId);

@override
String toString() {
  return 'RestaurantMarker(id: $id, name: $name, lat: $lat, lng: $lng, priceLevel: $priceLevel, recCount: $recCount, saveCount: $saveCount, score: $score, distanceM: $distanceM, coverPhotoUrl: $coverPhotoUrl, cityId: $cityId)';
}


}

/// @nodoc
abstract mixin class _$RestaurantMarkerCopyWith<$Res> implements $RestaurantMarkerCopyWith<$Res> {
  factory _$RestaurantMarkerCopyWith(_RestaurantMarker value, $Res Function(_RestaurantMarker) _then) = __$RestaurantMarkerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double lat, double lng,@JsonKey(name: 'price_level') int? priceLevel,@JsonKey(name: 'rec_count') int recCount,@JsonKey(name: 'save_count') int saveCount, double? score,@JsonKey(name: 'distance_m') double? distanceM,@JsonKey(name: 'cover_photo_url') String? coverPhotoUrl,@JsonKey(name: 'city_id') String? cityId
});




}
/// @nodoc
class __$RestaurantMarkerCopyWithImpl<$Res>
    implements _$RestaurantMarkerCopyWith<$Res> {
  __$RestaurantMarkerCopyWithImpl(this._self, this._then);

  final _RestaurantMarker _self;
  final $Res Function(_RestaurantMarker) _then;

/// Create a copy of RestaurantMarker
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? lat = null,Object? lng = null,Object? priceLevel = freezed,Object? recCount = null,Object? saveCount = null,Object? score = freezed,Object? distanceM = freezed,Object? coverPhotoUrl = freezed,Object? cityId = freezed,}) {
  return _then(_RestaurantMarker(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,priceLevel: freezed == priceLevel ? _self.priceLevel : priceLevel // ignore: cast_nullable_to_non_nullable
as int?,recCount: null == recCount ? _self.recCount : recCount // ignore: cast_nullable_to_non_nullable
as int,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,distanceM: freezed == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as double?,coverPhotoUrl: freezed == coverPhotoUrl ? _self.coverPhotoUrl : coverPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Restaurant {

 String get id; String get name;@JsonKey(name: 'city_id') String get cityId; String? get address;@JsonKey(name: 'price_level') int? get priceLevel; String? get phone; String? get website;@JsonKey(name: 'opening_hours') Map<String, dynamic>? get openingHours;@JsonKey(name: 'cover_photo_url') String? get coverPhotoUrl;@JsonKey(name: 'rec_count') int get recCount;@JsonKey(name: 'save_count') int get saveCount; double? get score;@JsonKey(name: 'is_seed') bool get isSeed;
/// Create a copy of Restaurant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantCopyWith<Restaurant> get copyWith => _$RestaurantCopyWithImpl<Restaurant>(this as Restaurant, _$identity);

  /// Serializes this Restaurant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Restaurant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.address, address) || other.address == address)&&(identical(other.priceLevel, priceLevel) || other.priceLevel == priceLevel)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.website, website) || other.website == website)&&const DeepCollectionEquality().equals(other.openingHours, openingHours)&&(identical(other.coverPhotoUrl, coverPhotoUrl) || other.coverPhotoUrl == coverPhotoUrl)&&(identical(other.recCount, recCount) || other.recCount == recCount)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.score, score) || other.score == score)&&(identical(other.isSeed, isSeed) || other.isSeed == isSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,cityId,address,priceLevel,phone,website,const DeepCollectionEquality().hash(openingHours),coverPhotoUrl,recCount,saveCount,score,isSeed);

@override
String toString() {
  return 'Restaurant(id: $id, name: $name, cityId: $cityId, address: $address, priceLevel: $priceLevel, phone: $phone, website: $website, openingHours: $openingHours, coverPhotoUrl: $coverPhotoUrl, recCount: $recCount, saveCount: $saveCount, score: $score, isSeed: $isSeed)';
}


}

/// @nodoc
abstract mixin class $RestaurantCopyWith<$Res>  {
  factory $RestaurantCopyWith(Restaurant value, $Res Function(Restaurant) _then) = _$RestaurantCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'city_id') String cityId, String? address,@JsonKey(name: 'price_level') int? priceLevel, String? phone, String? website,@JsonKey(name: 'opening_hours') Map<String, dynamic>? openingHours,@JsonKey(name: 'cover_photo_url') String? coverPhotoUrl,@JsonKey(name: 'rec_count') int recCount,@JsonKey(name: 'save_count') int saveCount, double? score,@JsonKey(name: 'is_seed') bool isSeed
});




}
/// @nodoc
class _$RestaurantCopyWithImpl<$Res>
    implements $RestaurantCopyWith<$Res> {
  _$RestaurantCopyWithImpl(this._self, this._then);

  final Restaurant _self;
  final $Res Function(Restaurant) _then;

/// Create a copy of Restaurant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? cityId = null,Object? address = freezed,Object? priceLevel = freezed,Object? phone = freezed,Object? website = freezed,Object? openingHours = freezed,Object? coverPhotoUrl = freezed,Object? recCount = null,Object? saveCount = null,Object? score = freezed,Object? isSeed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,priceLevel: freezed == priceLevel ? _self.priceLevel : priceLevel // ignore: cast_nullable_to_non_nullable
as int?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,openingHours: freezed == openingHours ? _self.openingHours : openingHours // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,coverPhotoUrl: freezed == coverPhotoUrl ? _self.coverPhotoUrl : coverPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,recCount: null == recCount ? _self.recCount : recCount // ignore: cast_nullable_to_non_nullable
as int,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,isSeed: null == isSeed ? _self.isSeed : isSeed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Restaurant].
extension RestaurantPatterns on Restaurant {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Restaurant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Restaurant() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Restaurant value)  $default,){
final _that = this;
switch (_that) {
case _Restaurant():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Restaurant value)?  $default,){
final _that = this;
switch (_that) {
case _Restaurant() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'city_id')  String cityId,  String? address, @JsonKey(name: 'price_level')  int? priceLevel,  String? phone,  String? website, @JsonKey(name: 'opening_hours')  Map<String, dynamic>? openingHours, @JsonKey(name: 'cover_photo_url')  String? coverPhotoUrl, @JsonKey(name: 'rec_count')  int recCount, @JsonKey(name: 'save_count')  int saveCount,  double? score, @JsonKey(name: 'is_seed')  bool isSeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Restaurant() when $default != null:
return $default(_that.id,_that.name,_that.cityId,_that.address,_that.priceLevel,_that.phone,_that.website,_that.openingHours,_that.coverPhotoUrl,_that.recCount,_that.saveCount,_that.score,_that.isSeed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'city_id')  String cityId,  String? address, @JsonKey(name: 'price_level')  int? priceLevel,  String? phone,  String? website, @JsonKey(name: 'opening_hours')  Map<String, dynamic>? openingHours, @JsonKey(name: 'cover_photo_url')  String? coverPhotoUrl, @JsonKey(name: 'rec_count')  int recCount, @JsonKey(name: 'save_count')  int saveCount,  double? score, @JsonKey(name: 'is_seed')  bool isSeed)  $default,) {final _that = this;
switch (_that) {
case _Restaurant():
return $default(_that.id,_that.name,_that.cityId,_that.address,_that.priceLevel,_that.phone,_that.website,_that.openingHours,_that.coverPhotoUrl,_that.recCount,_that.saveCount,_that.score,_that.isSeed);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'city_id')  String cityId,  String? address, @JsonKey(name: 'price_level')  int? priceLevel,  String? phone,  String? website, @JsonKey(name: 'opening_hours')  Map<String, dynamic>? openingHours, @JsonKey(name: 'cover_photo_url')  String? coverPhotoUrl, @JsonKey(name: 'rec_count')  int recCount, @JsonKey(name: 'save_count')  int saveCount,  double? score, @JsonKey(name: 'is_seed')  bool isSeed)?  $default,) {final _that = this;
switch (_that) {
case _Restaurant() when $default != null:
return $default(_that.id,_that.name,_that.cityId,_that.address,_that.priceLevel,_that.phone,_that.website,_that.openingHours,_that.coverPhotoUrl,_that.recCount,_that.saveCount,_that.score,_that.isSeed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Restaurant implements Restaurant {
  const _Restaurant({required this.id, required this.name, @JsonKey(name: 'city_id') required this.cityId, this.address, @JsonKey(name: 'price_level') this.priceLevel, this.phone, this.website, @JsonKey(name: 'opening_hours') final  Map<String, dynamic>? openingHours, @JsonKey(name: 'cover_photo_url') this.coverPhotoUrl, @JsonKey(name: 'rec_count') this.recCount = 0, @JsonKey(name: 'save_count') this.saveCount = 0, this.score, @JsonKey(name: 'is_seed') this.isSeed = false}): _openingHours = openingHours;
  factory _Restaurant.fromJson(Map<String, dynamic> json) => _$RestaurantFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'city_id') final  String cityId;
@override final  String? address;
@override@JsonKey(name: 'price_level') final  int? priceLevel;
@override final  String? phone;
@override final  String? website;
 final  Map<String, dynamic>? _openingHours;
@override@JsonKey(name: 'opening_hours') Map<String, dynamic>? get openingHours {
  final value = _openingHours;
  if (value == null) return null;
  if (_openingHours is EqualUnmodifiableMapView) return _openingHours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'cover_photo_url') final  String? coverPhotoUrl;
@override@JsonKey(name: 'rec_count') final  int recCount;
@override@JsonKey(name: 'save_count') final  int saveCount;
@override final  double? score;
@override@JsonKey(name: 'is_seed') final  bool isSeed;

/// Create a copy of Restaurant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantCopyWith<_Restaurant> get copyWith => __$RestaurantCopyWithImpl<_Restaurant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Restaurant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.address, address) || other.address == address)&&(identical(other.priceLevel, priceLevel) || other.priceLevel == priceLevel)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.website, website) || other.website == website)&&const DeepCollectionEquality().equals(other._openingHours, _openingHours)&&(identical(other.coverPhotoUrl, coverPhotoUrl) || other.coverPhotoUrl == coverPhotoUrl)&&(identical(other.recCount, recCount) || other.recCount == recCount)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.score, score) || other.score == score)&&(identical(other.isSeed, isSeed) || other.isSeed == isSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,cityId,address,priceLevel,phone,website,const DeepCollectionEquality().hash(_openingHours),coverPhotoUrl,recCount,saveCount,score,isSeed);

@override
String toString() {
  return 'Restaurant(id: $id, name: $name, cityId: $cityId, address: $address, priceLevel: $priceLevel, phone: $phone, website: $website, openingHours: $openingHours, coverPhotoUrl: $coverPhotoUrl, recCount: $recCount, saveCount: $saveCount, score: $score, isSeed: $isSeed)';
}


}

/// @nodoc
abstract mixin class _$RestaurantCopyWith<$Res> implements $RestaurantCopyWith<$Res> {
  factory _$RestaurantCopyWith(_Restaurant value, $Res Function(_Restaurant) _then) = __$RestaurantCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'city_id') String cityId, String? address,@JsonKey(name: 'price_level') int? priceLevel, String? phone, String? website,@JsonKey(name: 'opening_hours') Map<String, dynamic>? openingHours,@JsonKey(name: 'cover_photo_url') String? coverPhotoUrl,@JsonKey(name: 'rec_count') int recCount,@JsonKey(name: 'save_count') int saveCount, double? score,@JsonKey(name: 'is_seed') bool isSeed
});




}
/// @nodoc
class __$RestaurantCopyWithImpl<$Res>
    implements _$RestaurantCopyWith<$Res> {
  __$RestaurantCopyWithImpl(this._self, this._then);

  final _Restaurant _self;
  final $Res Function(_Restaurant) _then;

/// Create a copy of Restaurant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? cityId = null,Object? address = freezed,Object? priceLevel = freezed,Object? phone = freezed,Object? website = freezed,Object? openingHours = freezed,Object? coverPhotoUrl = freezed,Object? recCount = null,Object? saveCount = null,Object? score = freezed,Object? isSeed = null,}) {
  return _then(_Restaurant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,priceLevel: freezed == priceLevel ? _self.priceLevel : priceLevel // ignore: cast_nullable_to_non_nullable
as int?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,openingHours: freezed == openingHours ? _self._openingHours : openingHours // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,coverPhotoUrl: freezed == coverPhotoUrl ? _self.coverPhotoUrl : coverPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,recCount: null == recCount ? _self.recCount : recCount // ignore: cast_nullable_to_non_nullable
as int,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,isSeed: null == isSeed ? _self.isSeed : isSeed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$RecommendingTaster {

 String get id; String get username;@JsonKey(name: 'display_name') String get displayName;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'is_verified') bool get isVerified; bool get followed;
/// Create a copy of RecommendingTaster
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendingTasterCopyWith<RecommendingTaster> get copyWith => _$RecommendingTasterCopyWithImpl<RecommendingTaster>(this as RecommendingTaster, _$identity);

  /// Serializes this RecommendingTaster to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecommendingTaster&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.followed, followed) || other.followed == followed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl,isVerified,followed);

@override
String toString() {
  return 'RecommendingTaster(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified, followed: $followed)';
}


}

/// @nodoc
abstract mixin class $RecommendingTasterCopyWith<$Res>  {
  factory $RecommendingTasterCopyWith(RecommendingTaster value, $Res Function(RecommendingTaster) _then) = _$RecommendingTasterCopyWithImpl;
@useResult
$Res call({
 String id, String username,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'is_verified') bool isVerified, bool followed
});




}
/// @nodoc
class _$RecommendingTasterCopyWithImpl<$Res>
    implements $RecommendingTasterCopyWith<$Res> {
  _$RecommendingTasterCopyWithImpl(this._self, this._then);

  final RecommendingTaster _self;
  final $Res Function(RecommendingTaster) _then;

/// Create a copy of RecommendingTaster
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? displayName = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? followed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,followed: null == followed ? _self.followed : followed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RecommendingTaster].
extension RecommendingTasterPatterns on RecommendingTaster {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecommendingTaster value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecommendingTaster() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecommendingTaster value)  $default,){
final _that = this;
switch (_that) {
case _RecommendingTaster():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecommendingTaster value)?  $default,){
final _that = this;
switch (_that) {
case _RecommendingTaster() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'is_verified')  bool isVerified,  bool followed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecommendingTaster() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl,_that.isVerified,_that.followed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'is_verified')  bool isVerified,  bool followed)  $default,) {final _that = this;
switch (_that) {
case _RecommendingTaster():
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl,_that.isVerified,_that.followed);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'is_verified')  bool isVerified,  bool followed)?  $default,) {final _that = this;
switch (_that) {
case _RecommendingTaster() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl,_that.isVerified,_that.followed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecommendingTaster implements RecommendingTaster {
  const _RecommendingTaster({required this.id, required this.username, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'is_verified') this.isVerified = false, this.followed = false});
  factory _RecommendingTaster.fromJson(Map<String, dynamic> json) => _$RecommendingTasterFromJson(json);

@override final  String id;
@override final  String username;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey() final  bool followed;

/// Create a copy of RecommendingTaster
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendingTasterCopyWith<_RecommendingTaster> get copyWith => __$RecommendingTasterCopyWithImpl<_RecommendingTaster>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendingTasterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecommendingTaster&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.followed, followed) || other.followed == followed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl,isVerified,followed);

@override
String toString() {
  return 'RecommendingTaster(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified, followed: $followed)';
}


}

/// @nodoc
abstract mixin class _$RecommendingTasterCopyWith<$Res> implements $RecommendingTasterCopyWith<$Res> {
  factory _$RecommendingTasterCopyWith(_RecommendingTaster value, $Res Function(_RecommendingTaster) _then) = __$RecommendingTasterCopyWithImpl;
@override @useResult
$Res call({
 String id, String username,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'is_verified') bool isVerified, bool followed
});




}
/// @nodoc
class __$RecommendingTasterCopyWithImpl<$Res>
    implements _$RecommendingTasterCopyWith<$Res> {
  __$RecommendingTasterCopyWithImpl(this._self, this._then);

  final _RecommendingTaster _self;
  final $Res Function(_RecommendingTaster) _then;

/// Create a copy of RecommendingTaster
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? displayName = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? followed = null,}) {
  return _then(_RecommendingTaster(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,followed: null == followed ? _self.followed : followed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$RestaurantSummary {

 List<RecommendingTaster> get tasters;@JsonKey(name: 'top_quote') Map<String, dynamic>? get topQuote;
/// Create a copy of RestaurantSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantSummaryCopyWith<RestaurantSummary> get copyWith => _$RestaurantSummaryCopyWithImpl<RestaurantSummary>(this as RestaurantSummary, _$identity);

  /// Serializes this RestaurantSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantSummary&&const DeepCollectionEquality().equals(other.tasters, tasters)&&const DeepCollectionEquality().equals(other.topQuote, topQuote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tasters),const DeepCollectionEquality().hash(topQuote));

@override
String toString() {
  return 'RestaurantSummary(tasters: $tasters, topQuote: $topQuote)';
}


}

/// @nodoc
abstract mixin class $RestaurantSummaryCopyWith<$Res>  {
  factory $RestaurantSummaryCopyWith(RestaurantSummary value, $Res Function(RestaurantSummary) _then) = _$RestaurantSummaryCopyWithImpl;
@useResult
$Res call({
 List<RecommendingTaster> tasters,@JsonKey(name: 'top_quote') Map<String, dynamic>? topQuote
});




}
/// @nodoc
class _$RestaurantSummaryCopyWithImpl<$Res>
    implements $RestaurantSummaryCopyWith<$Res> {
  _$RestaurantSummaryCopyWithImpl(this._self, this._then);

  final RestaurantSummary _self;
  final $Res Function(RestaurantSummary) _then;

/// Create a copy of RestaurantSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tasters = null,Object? topQuote = freezed,}) {
  return _then(_self.copyWith(
tasters: null == tasters ? _self.tasters : tasters // ignore: cast_nullable_to_non_nullable
as List<RecommendingTaster>,topQuote: freezed == topQuote ? _self.topQuote : topQuote // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [RestaurantSummary].
extension RestaurantSummaryPatterns on RestaurantSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantSummary value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantSummary value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<RecommendingTaster> tasters, @JsonKey(name: 'top_quote')  Map<String, dynamic>? topQuote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantSummary() when $default != null:
return $default(_that.tasters,_that.topQuote);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<RecommendingTaster> tasters, @JsonKey(name: 'top_quote')  Map<String, dynamic>? topQuote)  $default,) {final _that = this;
switch (_that) {
case _RestaurantSummary():
return $default(_that.tasters,_that.topQuote);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<RecommendingTaster> tasters, @JsonKey(name: 'top_quote')  Map<String, dynamic>? topQuote)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantSummary() when $default != null:
return $default(_that.tasters,_that.topQuote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RestaurantSummary implements RestaurantSummary {
  const _RestaurantSummary({final  List<RecommendingTaster> tasters = const <RecommendingTaster>[], @JsonKey(name: 'top_quote') final  Map<String, dynamic>? topQuote}): _tasters = tasters,_topQuote = topQuote;
  factory _RestaurantSummary.fromJson(Map<String, dynamic> json) => _$RestaurantSummaryFromJson(json);

 final  List<RecommendingTaster> _tasters;
@override@JsonKey() List<RecommendingTaster> get tasters {
  if (_tasters is EqualUnmodifiableListView) return _tasters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasters);
}

 final  Map<String, dynamic>? _topQuote;
@override@JsonKey(name: 'top_quote') Map<String, dynamic>? get topQuote {
  final value = _topQuote;
  if (value == null) return null;
  if (_topQuote is EqualUnmodifiableMapView) return _topQuote;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of RestaurantSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantSummaryCopyWith<_RestaurantSummary> get copyWith => __$RestaurantSummaryCopyWithImpl<_RestaurantSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantSummary&&const DeepCollectionEquality().equals(other._tasters, _tasters)&&const DeepCollectionEquality().equals(other._topQuote, _topQuote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasters),const DeepCollectionEquality().hash(_topQuote));

@override
String toString() {
  return 'RestaurantSummary(tasters: $tasters, topQuote: $topQuote)';
}


}

/// @nodoc
abstract mixin class _$RestaurantSummaryCopyWith<$Res> implements $RestaurantSummaryCopyWith<$Res> {
  factory _$RestaurantSummaryCopyWith(_RestaurantSummary value, $Res Function(_RestaurantSummary) _then) = __$RestaurantSummaryCopyWithImpl;
@override @useResult
$Res call({
 List<RecommendingTaster> tasters,@JsonKey(name: 'top_quote') Map<String, dynamic>? topQuote
});




}
/// @nodoc
class __$RestaurantSummaryCopyWithImpl<$Res>
    implements _$RestaurantSummaryCopyWith<$Res> {
  __$RestaurantSummaryCopyWithImpl(this._self, this._then);

  final _RestaurantSummary _self;
  final $Res Function(_RestaurantSummary) _then;

/// Create a copy of RestaurantSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tasters = null,Object? topQuote = freezed,}) {
  return _then(_RestaurantSummary(
tasters: null == tasters ? _self._tasters : tasters // ignore: cast_nullable_to_non_nullable
as List<RecommendingTaster>,topQuote: freezed == topQuote ? _self._topQuote : topQuote // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
