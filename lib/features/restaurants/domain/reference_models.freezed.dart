// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reference_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$City {

 String get id; String get name; String get slug;@JsonKey(name: 'country_id') String get countryId;@JsonKey(name: 'hero_photo_url') String? get heroPhotoUrl;
/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CityCopyWith<City> get copyWith => _$CityCopyWithImpl<City>(this as City, _$identity);

  /// Serializes this City to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is City&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.heroPhotoUrl, heroPhotoUrl) || other.heroPhotoUrl == heroPhotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,countryId,heroPhotoUrl);

@override
String toString() {
  return 'City(id: $id, name: $name, slug: $slug, countryId: $countryId, heroPhotoUrl: $heroPhotoUrl)';
}


}

/// @nodoc
abstract mixin class $CityCopyWith<$Res>  {
  factory $CityCopyWith(City value, $Res Function(City) _then) = _$CityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug,@JsonKey(name: 'country_id') String countryId,@JsonKey(name: 'hero_photo_url') String? heroPhotoUrl
});




}
/// @nodoc
class _$CityCopyWithImpl<$Res>
    implements $CityCopyWith<$Res> {
  _$CityCopyWithImpl(this._self, this._then);

  final City _self;
  final $Res Function(City) _then;

/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? countryId = null,Object? heroPhotoUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,heroPhotoUrl: freezed == heroPhotoUrl ? _self.heroPhotoUrl : heroPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [City].
extension CityPatterns on City {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _City value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _City() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _City value)  $default,){
final _that = this;
switch (_that) {
case _City():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _City value)?  $default,){
final _that = this;
switch (_that) {
case _City() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String slug, @JsonKey(name: 'country_id')  String countryId, @JsonKey(name: 'hero_photo_url')  String? heroPhotoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _City() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.countryId,_that.heroPhotoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String slug, @JsonKey(name: 'country_id')  String countryId, @JsonKey(name: 'hero_photo_url')  String? heroPhotoUrl)  $default,) {final _that = this;
switch (_that) {
case _City():
return $default(_that.id,_that.name,_that.slug,_that.countryId,_that.heroPhotoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String slug, @JsonKey(name: 'country_id')  String countryId, @JsonKey(name: 'hero_photo_url')  String? heroPhotoUrl)?  $default,) {final _that = this;
switch (_that) {
case _City() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.countryId,_that.heroPhotoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _City implements City {
  const _City({required this.id, required this.name, required this.slug, @JsonKey(name: 'country_id') required this.countryId, @JsonKey(name: 'hero_photo_url') this.heroPhotoUrl});
  factory _City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);

@override final  String id;
@override final  String name;
@override final  String slug;
@override@JsonKey(name: 'country_id') final  String countryId;
@override@JsonKey(name: 'hero_photo_url') final  String? heroPhotoUrl;

/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CityCopyWith<_City> get copyWith => __$CityCopyWithImpl<_City>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _City&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.heroPhotoUrl, heroPhotoUrl) || other.heroPhotoUrl == heroPhotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,countryId,heroPhotoUrl);

@override
String toString() {
  return 'City(id: $id, name: $name, slug: $slug, countryId: $countryId, heroPhotoUrl: $heroPhotoUrl)';
}


}

/// @nodoc
abstract mixin class _$CityCopyWith<$Res> implements $CityCopyWith<$Res> {
  factory _$CityCopyWith(_City value, $Res Function(_City) _then) = __$CityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug,@JsonKey(name: 'country_id') String countryId,@JsonKey(name: 'hero_photo_url') String? heroPhotoUrl
});




}
/// @nodoc
class __$CityCopyWithImpl<$Res>
    implements _$CityCopyWith<$Res> {
  __$CityCopyWithImpl(this._self, this._then);

  final _City _self;
  final $Res Function(_City) _then;

/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? countryId = null,Object? heroPhotoUrl = freezed,}) {
  return _then(_City(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,heroPhotoUrl: freezed == heroPhotoUrl ? _self.heroPhotoUrl : heroPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Cuisine {

 String get id; String get name; String get slug; String? get emoji;
/// Create a copy of Cuisine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CuisineCopyWith<Cuisine> get copyWith => _$CuisineCopyWithImpl<Cuisine>(this as Cuisine, _$identity);

  /// Serializes this Cuisine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Cuisine&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.emoji, emoji) || other.emoji == emoji));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,emoji);

@override
String toString() {
  return 'Cuisine(id: $id, name: $name, slug: $slug, emoji: $emoji)';
}


}

/// @nodoc
abstract mixin class $CuisineCopyWith<$Res>  {
  factory $CuisineCopyWith(Cuisine value, $Res Function(Cuisine) _then) = _$CuisineCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug, String? emoji
});




}
/// @nodoc
class _$CuisineCopyWithImpl<$Res>
    implements $CuisineCopyWith<$Res> {
  _$CuisineCopyWithImpl(this._self, this._then);

  final Cuisine _self;
  final $Res Function(Cuisine) _then;

/// Create a copy of Cuisine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? emoji = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,emoji: freezed == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Cuisine].
extension CuisinePatterns on Cuisine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Cuisine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Cuisine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Cuisine value)  $default,){
final _that = this;
switch (_that) {
case _Cuisine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Cuisine value)?  $default,){
final _that = this;
switch (_that) {
case _Cuisine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String? emoji)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Cuisine() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.emoji);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String? emoji)  $default,) {final _that = this;
switch (_that) {
case _Cuisine():
return $default(_that.id,_that.name,_that.slug,_that.emoji);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String slug,  String? emoji)?  $default,) {final _that = this;
switch (_that) {
case _Cuisine() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.emoji);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Cuisine implements Cuisine {
  const _Cuisine({required this.id, required this.name, required this.slug, this.emoji});
  factory _Cuisine.fromJson(Map<String, dynamic> json) => _$CuisineFromJson(json);

@override final  String id;
@override final  String name;
@override final  String slug;
@override final  String? emoji;

/// Create a copy of Cuisine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CuisineCopyWith<_Cuisine> get copyWith => __$CuisineCopyWithImpl<_Cuisine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CuisineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cuisine&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.emoji, emoji) || other.emoji == emoji));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,emoji);

@override
String toString() {
  return 'Cuisine(id: $id, name: $name, slug: $slug, emoji: $emoji)';
}


}

/// @nodoc
abstract mixin class _$CuisineCopyWith<$Res> implements $CuisineCopyWith<$Res> {
  factory _$CuisineCopyWith(_Cuisine value, $Res Function(_Cuisine) _then) = __$CuisineCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug, String? emoji
});




}
/// @nodoc
class __$CuisineCopyWithImpl<$Res>
    implements _$CuisineCopyWith<$Res> {
  __$CuisineCopyWithImpl(this._self, this._then);

  final _Cuisine _self;
  final $Res Function(_Cuisine) _then;

/// Create a copy of Cuisine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? emoji = freezed,}) {
  return _then(_Cuisine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,emoji: freezed == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Country {

 String get id; String get name;@JsonKey(name: 'iso_code') String get isoCode;@JsonKey(name: 'flag_emoji') String? get flagEmoji;
/// Create a copy of Country
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CountryCopyWith<Country> get copyWith => _$CountryCopyWithImpl<Country>(this as Country, _$identity);

  /// Serializes this Country to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Country&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isoCode, isoCode) || other.isoCode == isoCode)&&(identical(other.flagEmoji, flagEmoji) || other.flagEmoji == flagEmoji));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isoCode,flagEmoji);

@override
String toString() {
  return 'Country(id: $id, name: $name, isoCode: $isoCode, flagEmoji: $flagEmoji)';
}


}

/// @nodoc
abstract mixin class $CountryCopyWith<$Res>  {
  factory $CountryCopyWith(Country value, $Res Function(Country) _then) = _$CountryCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'iso_code') String isoCode,@JsonKey(name: 'flag_emoji') String? flagEmoji
});




}
/// @nodoc
class _$CountryCopyWithImpl<$Res>
    implements $CountryCopyWith<$Res> {
  _$CountryCopyWithImpl(this._self, this._then);

  final Country _self;
  final $Res Function(Country) _then;

/// Create a copy of Country
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isoCode = null,Object? flagEmoji = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isoCode: null == isoCode ? _self.isoCode : isoCode // ignore: cast_nullable_to_non_nullable
as String,flagEmoji: freezed == flagEmoji ? _self.flagEmoji : flagEmoji // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Country].
extension CountryPatterns on Country {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Country value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Country() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Country value)  $default,){
final _that = this;
switch (_that) {
case _Country():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Country value)?  $default,){
final _that = this;
switch (_that) {
case _Country() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'iso_code')  String isoCode, @JsonKey(name: 'flag_emoji')  String? flagEmoji)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Country() when $default != null:
return $default(_that.id,_that.name,_that.isoCode,_that.flagEmoji);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'iso_code')  String isoCode, @JsonKey(name: 'flag_emoji')  String? flagEmoji)  $default,) {final _that = this;
switch (_that) {
case _Country():
return $default(_that.id,_that.name,_that.isoCode,_that.flagEmoji);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'iso_code')  String isoCode, @JsonKey(name: 'flag_emoji')  String? flagEmoji)?  $default,) {final _that = this;
switch (_that) {
case _Country() when $default != null:
return $default(_that.id,_that.name,_that.isoCode,_that.flagEmoji);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Country implements Country {
  const _Country({required this.id, required this.name, @JsonKey(name: 'iso_code') required this.isoCode, @JsonKey(name: 'flag_emoji') this.flagEmoji});
  factory _Country.fromJson(Map<String, dynamic> json) => _$CountryFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'iso_code') final  String isoCode;
@override@JsonKey(name: 'flag_emoji') final  String? flagEmoji;

/// Create a copy of Country
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CountryCopyWith<_Country> get copyWith => __$CountryCopyWithImpl<_Country>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CountryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Country&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isoCode, isoCode) || other.isoCode == isoCode)&&(identical(other.flagEmoji, flagEmoji) || other.flagEmoji == flagEmoji));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isoCode,flagEmoji);

@override
String toString() {
  return 'Country(id: $id, name: $name, isoCode: $isoCode, flagEmoji: $flagEmoji)';
}


}

/// @nodoc
abstract mixin class _$CountryCopyWith<$Res> implements $CountryCopyWith<$Res> {
  factory _$CountryCopyWith(_Country value, $Res Function(_Country) _then) = __$CountryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'iso_code') String isoCode,@JsonKey(name: 'flag_emoji') String? flagEmoji
});




}
/// @nodoc
class __$CountryCopyWithImpl<$Res>
    implements _$CountryCopyWith<$Res> {
  __$CountryCopyWithImpl(this._self, this._then);

  final _Country _self;
  final $Res Function(_Country) _then;

/// Create a copy of Country
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isoCode = null,Object? flagEmoji = freezed,}) {
  return _then(_Country(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isoCode: null == isoCode ? _self.isoCode : isoCode // ignore: cast_nullable_to_non_nullable
as String,flagEmoji: freezed == flagEmoji ? _self.flagEmoji : flagEmoji // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
